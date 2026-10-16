/// The I/O edge of the AHP client: socket, JSON-RPC peer, and reconnect
/// timer. Protocol logic lives in the pure functions this class calls.
library;

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'host_state.dart';
import 'protocol.dart';
import 'session_catalogue.dart';
import 'subscriptions.dart';
import 'wire.dart';

final _log = Logger('ahp_client');

/// Opens a text stream to a host. One JSON-RPC message per frame.
typedef ChannelConnector = Future<StreamChannel<String>> Function(Uri uri);

/// Opens a WebSocket to [uri] and waits for the handshake (AHP-001).
Future<StreamChannel<String>> connectWebSocket(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return channel.cast<String>();
}

/// Root-channel notifications that update the session catalogue.
const _catalogueNotifications = [
  'root/sessionAdded',
  'root/sessionRemoved',
  'root/sessionSummaryChanged',
];

/// A connection to one AHP host.
///
/// Holds [HostState] and publishes every change on [states]. Subscribes to
/// `ahp-root://` during `initialize` and keeps the session catalogue current.
class AhpClient {
  /// Creates a client for [uri]. Call [connect] to open it.
  AhpClient({
    required this.uri,
    String? clientId,
    this.clientInfo = const Implementation(name: 'shireitou'),
    this.locale,
    this.connector = connectWebSocket,
  }) : clientId = clientId ?? const Uuid().v4();

  /// Host URL, including the `tkn` query parameter when needed.
  final Uri uri;

  /// Stable client ID sent in `initialize` and `reconnect`.
  final String clientId;

  /// Client name and version sent in `initialize`.
  final Implementation clientInfo;

  /// BCP 47 locale sent in `initialize`.
  final String? locale;

  /// Opens the transport; replaced in tests.
  final ChannelConnector connector;

  final _states = StreamController<HostState>.broadcast();
  final _actions = StreamController<ActionEnvelope>.broadcast();
  HostState _state = const HostState();
  SubscriptionCounts _subscriptions = const {rootChannel: 1};
  Peer? _peer;
  bool _closed = false;
  bool _reconnecting = false;

  /// The current host state.
  HostState get state => _state;

  /// Every [HostState] change.
  Stream<HostState> get states => _states.stream;

  /// Every action envelope received, for channel observers.
  Stream<ActionEnvelope> get actions => _actions.stream;

  /// Connects, runs `initialize`, and loads the session catalogue.
  ///
  /// Errors are reported through [state] with [ConnectionStatus.failed].
  Future<void> connect() async {
    _closed = false;
    _set(_state.copyWith(status: ConnectionStatus.connecting, error: null));
    try {
      final peer = await _open();
      final result = InitializeResult.fromJson(
        await peer.sendRequest(
          'initialize',
          initializeParams(
            clientId: clientId,
            clientInfo: clientInfo.toJson(),
            initialSubscriptions: _subscriptions.keys.toList(),
            locale: locale,
          ),
        ) as JsonMap,
      );
      _set(applyInitializeResult(_state, result));
      await _loadSessions(peer);
      _set(_state.copyWith(status: ConnectionStatus.connected));
      _log.info(
        'connected to ${result.serverInfo?.name} '
        '(protocol ${result.protocolVersion})',
      );
    } on Object catch (error) {
      _log.warning('connect failed: ${_describe(error)}');
      await _closePeer();
      _set(
        _state.copyWith(
          status: ConnectionStatus.failed,
          error: _describe(error),
        ),
      );
    }
  }

  /// Closes the connection and stops reconnecting.
  Future<void> close() async {
    _closed = true;
    await _closePeer();
    _set(_state.copyWith(status: ConnectionStatus.disconnected));
  }

  /// Subscribes to [channel], sending `subscribe` only for the first
  /// observer (AHP-020). Returns the snapshot when one was requested.
  Future<Snapshot?> subscribe(String channel) async {
    final change = acquireSubscription(_subscriptions, channel);
    _subscriptions = change.counts;
    final peer = _peer;
    if (!change.sendToHost || peer == null) return null;
    final result =
        await peer.sendRequest('subscribe', {'channel': channel}) as JsonMap;
    final snapshot = switch (result['snapshot']) {
      final JsonMap json => Snapshot.fromJson(json),
      _ => null,
    };
    if (snapshot != null) _set(applySnapshot(_state, snapshot));
    return snapshot;
  }

  /// Releases [channel], sending `unsubscribe` for the last observer.
  void unsubscribe(String channel) {
    final change = releaseSubscription(_subscriptions, channel);
    _subscriptions = change.counts;
    if (change.sendToHost) {
      _peer?.sendNotification('unsubscribe', {'channel': channel});
    }
  }

  /// Creates a session with a client-chosen `ahp-session:/<uuid>` URI and
  /// returns that URI.
  Future<String> createSession({
    String? provider,
    List<String>? workingDirectories,
    JsonMap? config,
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    final session = 'ahp-session:/${const Uuid().v4()}';
    await peer.sendRequest('createSession', {
      'channel': session,
      'provider': ?provider,
      'workingDirectories': ?workingDirectories,
      'config': ?config,
    });
    return session;
  }

  /// Sends a protocol-level `ping`.
  Future<void> ping() async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    await peer.sendRequest('ping', {'channel': rootChannel});
  }

  Future<Peer> _open() async {
    final peer = Peer(await connector(uri));
    peer
      ..registerMethod('ping', (Parameters _) => null)
      ..registerMethod('action', (Parameters params) {
        final envelope = ActionEnvelope.fromJson(params.value as JsonMap);
        _set(applyEnvelope(_state, envelope));
        _actions.add(envelope);
      })
      ..registerFallback((Parameters params) {
        _log.fine('ignored ${params.method}');
        throw RpcException.methodNotFound(params.method);
      });
    for (final method in _catalogueNotifications) {
      peer.registerMethod(method, (Parameters params) {
        _set(
          _state.copyWith(
            sessions: applyRootNotification(
              _state.sessions,
              method,
              params.value as JsonMap,
            ),
          ),
        );
      });
    }
    _peer = peer;
    unawaited(
      peer.listen().whenComplete(() {
        if (identical(_peer, peer)) _onDisconnect();
      }),
    );
    return peer;
  }

  Future<void> _loadSessions(Peer peer) async {
    final summaries = <SessionSummary>[];
    String? cursor;
    do {
      final page = ListSessionsResult.fromJson(
        await peer.sendRequest('listSessions', {
          'channel': rootChannel,
          'cursor': ?cursor,
        }) as JsonMap,
      );
      summaries.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    _set(_state.copyWith(sessions: catalogueFromSummaries(summaries)));
  }

  void _onDisconnect() {
    _peer = null;
    if (_closed ||
        _reconnecting ||
        _state.status != ConnectionStatus.connected) {
      return;
    }
    unawaited(_reconnectLoop());
  }

  /// Reconnects with backoff (AHP-004). Falls back to `initialize` when the
  /// host no longer knows this client (`-32008 NotFound`).
  Future<void> _reconnectLoop() async {
    _reconnecting = true;
    _set(_state.copyWith(status: ConnectionStatus.reconnecting));
    for (var attempt = 0; !_closed; attempt++) {
      await Future<void>.delayed(reconnectDelay(attempt));
      if (_closed) break;
      try {
        final peer = await _open();
        final subscriptions = _subscriptions.keys.toList();
        try {
          final result = ReconnectResult.fromJson(
            await peer.sendRequest(
              'reconnect',
              reconnectParams(
                clientId: clientId,
                lastSeenServerSeq: _state.serverSeq,
                subscriptions: subscriptions,
              ),
            ) as JsonMap,
          );
          _set(applyReconnectResult(_state, result));
        } on RpcException catch (error) {
          if (error.code != AhpErrorCodes.notFound) rethrow;
          final result = InitializeResult.fromJson(
            await peer.sendRequest(
              'initialize',
              initializeParams(
                clientId: clientId,
                clientInfo: clientInfo.toJson(),
                initialSubscriptions: subscriptions,
                locale: locale,
              ),
            ) as JsonMap,
          );
          _set(applyInitializeResult(_state, result));
        }
        // Catalogue notifications are not replayed, so reload the list.
        await _loadSessions(peer);
        _set(_state.copyWith(status: ConnectionStatus.connected, error: null));
        _log.info('reconnected after ${attempt + 1} attempt(s)');
        break;
      } on Object catch (error) {
        _log.fine('reconnect attempt ${attempt + 1} failed: $error');
        await _closePeer();
        _set(_state.copyWith(error: _describe(error)));
      }
    }
    _reconnecting = false;
  }

  Future<void> _closePeer() async {
    final peer = _peer;
    _peer = null;
    await peer?.close();
  }

  void _set(HostState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  static String _describe(Object error) => switch (error) {
    RpcException(:final code, :final message, :final data) => describeRpcError(
      code,
      message,
      data,
    ),
    _ => error.toString(),
  };
}
