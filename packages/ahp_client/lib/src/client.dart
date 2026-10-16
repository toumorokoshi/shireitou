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
import 'session_wire.dart';
import 'subscriptions.dart';
import 'transport_io.dart'
    if (dart.library.js_interop) 'transport_web.dart'
    as transport;
import 'wire.dart';

final _log = Logger('ahp_client');

/// Opens a text stream to a host. One JSON-RPC message per frame.
typedef ChannelConnector = Future<StreamChannel<String>> Function(Uri uri);

/// The platform's default [TokenTransport]: [TokenTransport.query] on web,
/// [TokenTransport.queryAndHeader] on native platforms (AHP-002).
const defaultTokenTransport = transport.defaultTokenTransport;

/// A [ChannelConnector] that opens a WebSocket and places the connection
/// token per [tokenTransport] (AHP-001, AHP-002). On web, only
/// [TokenTransport.query] works.
ChannelConnector webSocketConnector({
  TokenTransport tokenTransport = defaultTokenTransport,
}) => (uri) async {
  final handshake = handshakeFor(uri, tokenTransport);
  final WebSocketChannel channel = transport.openWebSocket(
    handshake.uri,
    handshake.headers,
  );
  await channel.ready;
  return channel.cast<String>();
};

/// Opens a WebSocket to [uri] with the platform's default token placement
/// and waits for the handshake (AHP-001, AHP-002).
Future<StreamChannel<String>> connectWebSocket(Uri uri) =>
    webSocketConnector()(uri);

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

  /// Host URL, including the `tkn` query parameter when needed. The
  /// [connector] decides whether the token also (or instead) goes in a
  /// header.
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
  int _clientSeq = 0;
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
  /// observer (AHP-020). Session and chat snapshots ([kind]) are mirrored in
  /// [HostState]. Returns the snapshot when one was requested.
  Future<Snapshot?> subscribe(
    String channel, {
    ChannelKind kind = ChannelKind.other,
  }) async {
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
    if (snapshot != null) _set(applySnapshot(_state, snapshot, kind));
    return snapshot;
  }

  /// Releases [channel], sending `unsubscribe` for the last observer.
  void unsubscribe(String channel) {
    final change = releaseSubscription(_subscriptions, channel);
    _subscriptions = change.counts;
    if (change.sendToHost) {
      _peer?.sendNotification('unsubscribe', {'channel': channel});
      _set(removeChannel(_state, channel));
    }
  }

  /// Subscribes to [session] and its default chat, and returns the chat URI
  /// (null when the session has no chat). Release both with
  /// [closeSession].
  Future<String?> openSession(String session) async {
    await subscribe(session, kind: ChannelKind.session);
    final state = _state.sessionChannels[session]?.state;
    final chat = state == null ? null : defaultChatOf(state);
    if (chat != null) await subscribe(chat, kind: ChannelKind.chat);
    return chat;
  }

  /// Releases the subscriptions taken by [openSession].
  void closeSession(String session, String? chat) {
    if (chat != null) unsubscribe(chat);
    unsubscribe(session);
  }

  /// Dispatches a client [action] on [channel] (AHP-022) and returns its
  /// `clientSeq`.
  ///
  /// The action is applied to the channel's mirror at once; the host's echo
  /// confirms it, or a `rejectionReason` rolls it back.
  int dispatch(String channel, JsonMap action) {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    final clientSeq = ++_clientSeq;
    _set(
      applyDispatchedAction(_state, channel, (
        clientSeq: clientSeq,
        action: action,
      )),
    );
    peer.sendNotification('dispatchAction', {
      'channel': channel,
      'clientSeq': clientSeq,
      'action': action,
    });
    return clientSeq;
  }

  /// Asks the host to page older turns into [chat] (`fetchTurns`). The turns
  /// arrive as a `chat/turnsLoaded` action.
  Future<void> fetchTurns(String chat, {String? cursor}) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    await peer.sendRequest('fetchTurns', {'channel': chat, 'cursor': ?cursor});
  }

  /// Creates a session with a client-chosen `ahp-session:/<uuid>` URI
  /// (AHP-040), retrying with a new URI on `-32003 SessionAlreadyExists`.
  ///
  /// Waits until the session appears in the catalogue and returns its
  /// catalogue key, which may differ from the URI sent (see
  /// [resolveSessionResource]).
  Future<String> createSession({
    String? provider,
    List<String>? workingDirectories,
    JsonMap? config,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    for (var attempt = 0; ; attempt++) {
      final session = 'ahp-session:/${const Uuid().v4()}';
      try {
        await peer.sendRequest('createSession', {
          'channel': session,
          'provider': ?provider,
          'workingDirectories': ?workingDirectories,
          'config': ?config,
        });
      } on RpcException catch (error) {
        if (error.code == AhpErrorCodes.sessionAlreadyExists && attempt < 2) {
          continue;
        }
        rethrow;
      }
      final listed = resolveSessionResource(_state.sessions, session);
      if (listed != null) return listed;
      return states
          .map((state) => resolveSessionResource(state.sessions, session))
          .firstWhere((resource) => resource != null)
          .then((resource) => resource!)
          .timeout(timeout);
    }
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
        _set(applyEnvelope(_state, envelope, clientId: clientId));
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
          _set(applyReconnectResult(_state, result, clientId: clientId));
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
