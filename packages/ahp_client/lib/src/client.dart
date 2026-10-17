/// The I/O edge of the AHP client: socket, JSON-RPC peer, and reconnect
/// timer. Protocol logic lives in the pure functions this class calls.
library;

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth.dart';
import 'host_state.dart';
import 'channel_mirror.dart';
import 'connection_problems.dart';
import 'protocol.dart';
import 'protocol_version.dart';
import 'session_catalogue.dart';
import 'session_creation.dart';
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
  if (transportProblem(uri, page: transport.pageUri()) case final problem?) {
    throw ConnectionProblem(problem);
  }
  final handshake = handshakeFor(uri, tokenTransport);
  try {
    final WebSocketChannel channel = transport.openWebSocket(
      handshake.uri,
      handshake.headers,
    );
    await channel.ready;
    return channel.cast<String>();
  } on Object catch (error) {
    throw ConnectionProblem(
      describeTransportError(error, uri, web: transport.isWebTransport),
      error,
    );
  }
};

/// Opens a WebSocket to [uri] with the platform's default token placement
/// and waits for the handshake (AHP-001, AHP-002).
Future<StreamChannel<String>> connectWebSocket(Uri uri) =>
    webSocketConnector()(uri);

/// Whether [error] is a host's JSON-RPC "method not found" (`-32601`), for
/// optional commands such as `resolveSessionConfig` or `resourceList`.
bool isMethodNotFound(Object error) =>
    error is RpcException && error.code == -32601;

/// Gets tokens for [resources] after a command failed with `-32007
/// AuthRequired` and pushes them; true when the command should be retried
/// (AHP-061). See [HostAuthenticator].
typedef AuthRequiredHandler = Future<bool> Function(
  List<ProtectedResourceMetadata> resources,
);

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
    this.pingInterval = const Duration(seconds: 15),
    this.pingTimeout = const Duration(seconds: 10),
    this.pendingActionTimeout = const Duration(seconds: 30),
    this.handshakeTimeout = const Duration(seconds: 20),
    this.protocolVersions = offeredProtocolVersions,
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

  /// Versions offered in `initialize`, most preferred first (AHP-003).
  /// Offering only `0.9.0` exercises the degraded mode against a host that
  /// supports both.
  final List<String> protocolVersions;

  /// How often to send a liveness `ping` while connected (AHP-005).
  /// [Duration.zero] disables liveness pings.
  final Duration pingInterval;

  /// How long a liveness `ping` may take before the socket is treated as
  /// dead and the client reconnects (AHP-004).
  final Duration pingTimeout;

  /// How long a dispatched action may stay unechoed before it is rolled
  /// back and reported as [ActionFailureKind.timedOut] (AHP-022).
  /// [Duration.zero] disables the timeout.
  final Duration pendingActionTimeout;

  /// How long opening the socket and each handshake request
  /// (`initialize`, `reconnect`, `listSessions`) may take before the
  /// attempt is abandoned and, when reconnecting, tried again (AHP-004).
  /// Without it a socket that never answers (after the device slept, or
  /// behind a proxy that swallowed the host) stalls reconnecting forever.
  /// [Duration.zero] disables the timeout.
  final Duration handshakeTimeout;

  final _states = StreamController<HostState>.broadcast();
  final _actions = StreamController<ActionEnvelope>.broadcast();
  final _failures = StreamController<ActionFailure>.broadcast();
  final _authRequired = StreamController<AuthRequiredParams>.broadcast();
  final _pendingTimers = <Timer>{};
  final _loadingTurns = <String>{};
  final _subscribing = <String, Future<Snapshot?>>{};
  Timer? _pingTimer;
  bool _pingInFlight = false;
  HostState _state = const HostState();
  SubscriptionCounts _subscriptions = const {rootChannel: 1};
  Peer? _peer;
  int _clientSeq = 0;
  bool _closed = false;
  bool _initialized = false;

  /// Bumped by [connect] and [close], so a reconnect loop or socket from an
  /// earlier connection stops instead of replacing the current one.
  int _generation = 0;

  /// The generation whose reconnect loop is running, if any.
  int? _reconnectingGeneration;

  /// Completes to end the current reconnect backoff early.
  Completer<void>? _backoff;

  bool get _reconnecting => _reconnectingGeneration == _generation;

  /// The current host state.
  HostState get state => _state;

  /// Every [HostState] change.
  Stream<HostState> get states => _states.stream;

  /// Every action envelope received, for channel observers.
  Stream<ActionEnvelope> get actions => _actions.stream;

  /// This client's dispatched actions that were rolled back: rejected by
  /// the host, not echoed in time, or lost in a reconnect (AHP-022).
  Stream<ActionFailure> get failures => _failures.stream;

  /// `auth/required` notifications: a protected resource needs a (new)
  /// token (AHP-061). They are not replayed after a reconnect.
  Stream<AuthRequiredParams> get authRequired => _authRequired.stream;

  /// Called when a command fails with `-32007 AuthRequired`; when it
  /// returns true the command is sent once more (AHP-061). Without it the
  /// error reaches the caller.
  AuthRequiredHandler? onAuthRequired;

  /// Connects, runs `initialize`, and loads the session catalogue.
  ///
  /// Errors are reported through [state] with [ConnectionStatus.failed].
  /// With [retry], a host that cannot be reached right now (see
  /// [isTransientConnectError]) is instead retried with backoff, as
  /// [ConnectionStatus.reconnecting] with the last [HostState.error], until
  /// it answers or [close] is called; this returns after the first attempt.
  Future<void> connect({bool retry = false}) async {
    _closed = false;
    final generation = ++_generation;
    _endBackoff();
    _set(_state.copyWith(status: ConnectionStatus.connecting, error: null));
    try {
      final peer = await _open(generation);
      final result = await _initialize(peer, _subscriptions.keys.toList());
      _set(applyInitializeResult(_state, result));
      await _loadSessions(peer);
      _set(_state.copyWith(status: ConnectionStatus.connected));
      _startPings(peer);
      _log.info(
        'connected to ${result.serverInfo?.name} '
        '(protocol ${result.protocolVersion})',
      );
    } on Object catch (error) {
      _log.warning('connect failed: ${_describe(error)}');
      if (generation != _generation) return;
      await _closePeer();
      _set(_state.copyWith(error: _describe(error)));
      if (retry && !_closed && isTransientConnectError(error)) {
        unawaited(_reconnectLoop(generation));
      } else {
        _set(_state.copyWith(status: ConnectionStatus.failed));
      }
    }
  }

  /// Checks the connection now instead of waiting: while reconnecting the
  /// next attempt starts at once, and while connected a liveness `ping` is
  /// sent. For when the app returns to the foreground or the network comes
  /// back, after the backoff may have grown to its cap.
  void checkConnection() {
    if (_closed) return;
    if (_reconnecting) {
      _endBackoff();
    } else if (_peer case final peer?
        when _state.status == ConnectionStatus.connected) {
      unawaited(_checkLiveness(peer));
    }
  }

  /// Closes the connection and stops reconnecting.
  Future<void> close() async {
    _closed = true;
    _generation++;
    _endBackoff();
    _stopPings();
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
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
    if (!change.sendToHost || peer == null) {
      // A later observer waits for the first one's snapshot, so the channel
      // is mirrored when this returns.
      await _subscribing[channel]?.catchError((Object _) => null);
      return null;
    }
    final request = _subscribeOnHost(peer, channel, kind);
    _subscribing[channel] = request;
    try {
      return await request;
    } finally {
      if (identical(_subscribing[channel], request)) {
        unawaited(_subscribing.remove(channel));
      }
    }
  }

  Future<Snapshot?> _subscribeOnHost(
    Peer peer,
    String channel,
    ChannelKind kind,
  ) async {
    if (_state.missingChannels.contains(channel)) {
      _set(
        _state.copyWith(
          missingChannels: Set.unmodifiable(
            {..._state.missingChannels}..remove(channel),
          ),
        ),
      );
    }
    final result = await _request('subscribe', {'channel': channel}) as JsonMap;
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
  /// confirms it. A `rejectionReason`, no echo within
  /// [pendingActionTimeout], or a reconnect before the echo rolls it back
  /// and reports it on [failures].
  ///
  /// Throws [StateError] when not connected (also while reconnecting), and
  /// [UnsupportedActionError] when the negotiated protocol version does not
  /// know the action.
  int dispatch(String channel, JsonMap action) {
    final peer = _peer;
    if (peer == null || _state.status != ConnectionStatus.connected) {
      throw StateError('not connected');
    }
    final type = action['type'];
    final version = _state.protocolVersion;
    if (type is String && !isActionKnownToVersion(type, version)) {
      throw UnsupportedActionError(type, version!);
    }
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
    _expireLater(channel, clientSeq);
    return clientSeq;
  }

  void _expireLater(String channel, int clientSeq) {
    if (pendingActionTimeout <= Duration.zero) return;
    late final Timer timer;
    timer = Timer(pendingActionTimeout, () {
      _pendingTimers.remove(timer);
      final (:state, :failure) = expirePendingAction(
        _state,
        channel,
        clientSeq,
      );
      if (failure == null) return;
      _log.warning('no echo for $failure; rolled back');
      _set(state);
      _fail(failure);
    });
    _pendingTimers.add(timer);
  }

  void _fail(ActionFailure failure) {
    if (!_failures.isClosed) _failures.add(failure);
  }

  /// Asks the host to page older turns into [chat] (`fetchTurns`). The turns
  /// arrive as a `chat/turnsLoaded` action.
  Future<void> fetchTurns(String chat, {String? cursor}) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    await _request('fetchTurns', {'channel': chat, 'cursor': ?cursor});
  }

  /// Loads the next page of older turns into [chat] when its mirror has a
  /// `turnsNextCursor` (windowed delivery, AHP-029 and AV-068). Returns
  /// false when there is nothing to load or a load for [chat] is already
  /// running. The turns arrive as `chat/turnsLoaded` before this returns.
  Future<bool> loadOlderTurns(String chat) async {
    final cursor = _state.chatChannels[chat]?.state.turnsNextCursor;
    if (cursor == null || !_loadingTurns.add(chat)) return false;
    try {
      await fetchTurns(chat, cursor: cursor);
      return true;
    } finally {
      _loadingTurns.remove(chat);
    }
  }

  /// Reads the content behind a `ContentRef` [uri] (`resourceRead`), for
  /// example the two sides of a file edit.
  Future<ResourceReadResult> readResource(
    String uri, {
    ContentEncoding? encoding,
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    return ResourceReadResult.fromJson(
      await _request(
        'resourceRead',
        ResourceReadParams(uri: uri, encoding: encoding).toJson(),
      ) as JsonMap,
    );
  }

  /// Runs the host-declared operation [operationId] on the expanded
  /// [changeset] URI (`invokeChangesetOperation`, AHP-027), on the whole
  /// changeset or on [target]. Progress arrives as changeset actions.
  Future<InvokeChangesetOperationResult> invokeChangesetOperation(
    String changeset,
    String operationId, {
    ChangesetOperationTarget? target,
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    return InvokeChangesetOperationResult.fromJson(
      await _request(
        'invokeChangesetOperation',
        InvokeChangesetOperationParams(
          channel: changeset,
          operationId: operationId,
          target: target,
        ).toJson(),
      ) as JsonMap,
    );
  }

  /// Moves [chat] within or between sessions (`moveChat`, 1.0.0 only).
  /// The new order arrives as `session/chatsReordered`. Throws
  /// [UnsupportedFeatureError] when the host negotiated 0.9.0.
  Future<MoveChatResult> moveChat(
    String chat,
    ChatMoveDestination destination,
  ) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    final version = _state.protocolVersion;
    if (!supportsFeature(version, ProtocolFeature.moveChat)) {
      throw UnsupportedFeatureError(ProtocolFeature.moveChat, version!);
    }
    return MoveChatResult.fromJson(
      await _request(
        'moveChat',
        MoveChatParams(channel: chat, destination: destination).toJson(),
      ) as JsonMap,
    );
  }

  /// Creates a session with a client-chosen `ahp-session:/<uuid>` URI
  /// (AHP-040), retrying with a new URI on `-32003 SessionAlreadyExists`.
  /// [config] carries the values collected with [resolveSessionConfig].
  ///
  /// Waits until the session appears in the catalogue and returns its
  /// catalogue key, which may differ from the URI sent (see
  /// [resolveSessionResource]). Meanwhile it watches the session channel,
  /// so a backend that fails to start (`session/creationFailed`, or a
  /// snapshot whose `lifecycle` is `creationFailed`) throws
  /// [SessionCreationFailedError] at once instead of waiting for [timeout].
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
        await _request('createSession', {
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
      return _awaitCreated(session, timeout);
    }
  }

  Future<String> _awaitCreated(String session, Duration timeout) async {
    // Hosts that publish the session under another URI (pi) may refuse
    // the sent one; then only the catalogue tells.
    final watched = subscribe(session, kind: ChannelKind.session).then(
      (_) => true,
      onError: (Object error) {
        _log.fine('not watching $session while it starts: $error');
        return false;
      },
    );
    try {
      final outcome =
          creationOutcome(_state, session) ??
          await states
              .map((state) => creationOutcome(state, session))
              .firstWhere((outcome) => outcome != null)
              .timeout(timeout);
      return switch (outcome!) {
        SessionCreated(:final resource) => resource,
        SessionCreationFailed(:final error) => throw SessionCreationFailedError(
          session,
          error,
        ),
      };
    } finally {
      unawaited(
        watched.then((subscribed) {
          if (subscribed) unsubscribe(session);
        }),
      );
    }
  }

  /// Lists the directory [uri] on the host's filesystem (`resourceList`),
  /// for a remote folder picker (AV-043). Throws the host's JSON-RPC error
  /// when [uri] is not a readable directory or the host does not offer
  /// `resourceList` (`-32601`).
  Future<List<DirectoryEntry>> listDirectory(String uri) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    return ResourceListResult.fromJson(
      await _request('resourceList', ResourceListParams(uri: uri).toJson())
          as JsonMap,
    ).entries;
  }

  /// Asks the host which session settings (such as a mode or a branch) an
  /// agent takes in [workingDirectory], given the [config] chosen so far
  /// (`resolveSessionConfig`, AV-041). The result's `values` include the
  /// host's defaults and go to [createSession] as `config`.
  Future<ResolveSessionConfigResult> resolveSessionConfig({
    String? provider,
    String? workingDirectory,
    JsonMap? config,
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    return ResolveSessionConfigResult.fromJson(
      await _request(
        'resolveSessionConfig',
        ResolveSessionConfigParams(
          provider: provider,
          workingDirectory: workingDirectory,
          config: config,
        ).toJson(),
      ) as JsonMap,
    );
  }

  /// The values the host suggests for the session setting [property] whose
  /// schema has `enumDynamic` (`sessionConfigCompletions`), matching
  /// [query].
  Future<List<SessionConfigValueItem>> sessionConfigCompletions({
    required String property,
    String? provider,
    String? workingDirectory,
    JsonMap? config,
    String? query,
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    return SessionConfigCompletionsResult.fromJson(
      await _request(
        'sessionConfigCompletions',
        SessionConfigCompletionsParams(
          property: property,
          provider: provider,
          workingDirectory: workingDirectory,
          config: config,
          query: query,
        ).toJson(),
      ) as JsonMap,
    ).items;
  }

  /// The host's completions for [text] typed in [chat] with the cursor at
  /// [offset] (`completions`, AHP-044), in the order the host suggests.
  Future<List<CompletionItem>> completions({
    required String chat,
    required String text,
    required int offset,
  }) async => CompletionsResult.fromJson(
    await _request(
      'completions',
      CompletionsParams(
        channel: chat,
        kind: CompletionItemKind.userMessage,
        text: text,
        offset: offset,
      ).toJson(),
    ) as JsonMap,
  ).items;

  /// Pushes a bearer [token] for the protected [resource] (`authenticate`,
  /// AHP-060), for example to resume a tool call waiting on MCP sign-in.
  Future<void> authenticate({
    required String resource,
    required String token,
    int? expiresIn,
    List<String>? scopes,
  }) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    if (expiresIn != null &&
        !supportsFeature(_state.protocolVersion, ProtocolFeature.tokenExpiry)) {
      expiresIn = null;
    }
    await peer.sendRequest(
      'authenticate',
      AuthenticateParams(
        resource: resource,
        token: token,
        expiresIn: expiresIn,
        scopes: scopes,
      ).toJson(),
    );
  }

  /// Sends a protocol-level `ping`.
  Future<void> ping() async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    await peer.sendRequest('ping', {'channel': rootChannel});
  }

  /// Sends [method] on the current connection; after a `-32007
  /// AuthRequired` error, lets [onAuthRequired] sign in and sends it once
  /// more (AHP-061).
  Future<Object?> _request(String method, Object? params) async {
    final peer = _peer;
    if (peer == null) throw StateError('not connected');
    try {
      return await peer.sendRequest(method, params);
    } on RpcException catch (error) {
      final handler = onAuthRequired;
      if (error.code != AhpErrorCodes.authRequired || handler == null) {
        rethrow;
      }
      final resources = authRequiredResources(error.data);
      if (resources.isEmpty || !await handler(resources)) rethrow;
      final again = _peer;
      if (again == null) throw StateError('not connected');
      return again.sendRequest(method, params);
    }
  }

  /// Opens a socket for the connection [generation]. A socket that opens
  /// after the attempt timed out, or after [close], is closed again.
  Future<Peer> _open(int generation) async {
    final opening = connector(uri);
    final StreamChannel<String> channel;
    try {
      channel = await _timed(opening, 'opening the connection');
    } on ConnectionProblem catch (error) {
      if (error.cause is TimeoutException) {
        unawaited(
          opening.then((opened) => opened.sink.close(), onError: (Object _) {}),
        );
      }
      rethrow;
    }
    if (generation != _generation) {
      unawaited(channel.sink.close());
      throw StateError('connection closed while opening');
    }
    final peer = Peer(channel);
    peer
      ..registerMethod('ping', (Parameters _) => null)
      ..registerMethod('action', (Parameters params) {
        final envelope = ActionEnvelope.fromJson(params.value as JsonMap);
        _set(applyEnvelope(_state, envelope, clientId: clientId));
        _actions.add(envelope);
        if (rejectionOf(envelope, clientId: clientId) case final failure?) {
          _fail(failure);
        }
      })
      ..registerMethod('auth/required', (Parameters params) {
        final notification = AuthRequiredParams.fromJson(
          params.value as JsonMap,
        );
        _log.info('${notification.resource.resource} needs sign-in');
        if (!_authRequired.isClosed) _authRequired.add(notification);
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
        await _timed(
          peer.sendRequest('listSessions', {
            'channel': rootChannel,
            'cursor': ?cursor,
          }),
          'listSessions',
        ) as JsonMap,
      );
      summaries.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    _set(_state.copyWith(sessions: catalogueFromSummaries(summaries)));
  }

  void _onDisconnect() {
    _peer = null;
    _stopPings();
    if (_closed ||
        _reconnecting ||
        _state.status != ConnectionStatus.connected) {
      return;
    }
    unawaited(_reconnectLoop(_generation));
  }

  /// Sends `initialize` on [peer] with [subscriptions].
  Future<InitializeResult> _initialize(
    Peer peer,
    List<String> subscriptions,
  ) async {
    final result = InitializeResult.fromJson(
      await _timed(
        peer.sendRequest(
          'initialize',
          initializeParams(
            clientId: clientId,
            clientInfo: clientInfo.toJson(),
            initialSubscriptions: subscriptions,
            locale: locale,
            protocolVersions: protocolVersions,
          ),
        ),
        'initialize',
      ) as JsonMap,
    );
    _initialized = true;
    return result;
  }

  /// Runs `initialize` again on [peer] after a reconnect the host could not
  /// resume, and drops the channels it has no snapshot for.
  Future<void> _reinitialize(Peer peer, List<String> subscriptions) async {
    final result = await _initialize(peer, subscriptions);
    _clearPendingActions();
    final missing = unresumedChannels(_state, result.snapshots);
    _set(applyMissingChannels(applyInitializeResult(_state, result), missing));
    _dropSubscriptions(missing);
  }

  /// Reconnects with backoff (AHP-004) for the connection [generation].
  /// Falls back to `initialize` when the host no longer knows this client
  /// (`-32008 NotFound`), and sends it first when it never initialized
  /// (`connect(retry: true)`); a failure there that retrying cannot fix
  /// ends the loop as [ConnectionStatus.failed].
  Future<void> _reconnectLoop(int generation) async {
    _reconnectingGeneration = generation;
    _set(_state.copyWith(status: ConnectionStatus.reconnecting));
    bool current() => !_closed && generation == _generation;
    for (var attempt = 0; current(); attempt++) {
      await _wait(reconnectDelay(attempt));
      if (!current()) break;
      try {
        final peer = await _open(generation);
        final subscriptions = _subscriptions.keys.toList();
        if (!_initialized) {
          final result = await _initialize(peer, subscriptions);
          _set(applyInitializeResult(_state, result));
        } else {
          await _resume(peer, subscriptions);
        }
        // Whatever the host accepted is in the replay or snapshot; actions
        // still pending were lost with the old socket.
        _clearPendingActions();
        // Catalogue notifications are not replayed, so reload the list.
        await _loadSessions(peer);
        if (!current()) break;
        _set(_state.copyWith(status: ConnectionStatus.connected, error: null));
        _startPings(peer);
        _log.info('reconnected after ${attempt + 1} attempt(s)');
        break;
      } on Object catch (error) {
        _log.fine('reconnect attempt ${attempt + 1} failed: $error');
        if (!current()) break;
        await _closePeer();
        _set(_state.copyWith(error: _describe(error)));
        if (!_initialized && !isTransientConnectError(error)) {
          _set(_state.copyWith(status: ConnectionStatus.failed));
          break;
        }
      }
    }
    if (_reconnectingGeneration == generation) _reconnectingGeneration = null;
  }

  /// Resumes this client's subscriptions on [peer] with `reconnect`.
  Future<void> _resume(Peer peer, List<String> subscriptions) async {
    try {
      final result = ReconnectResult.fromJson(
        await _timed(
          peer.sendRequest(
            'reconnect',
            reconnectParams(
              clientId: clientId,
              lastSeenServerSeq: _state.serverSeq,
              subscriptions: subscriptions,
            ),
          ),
          'reconnect',
        ) as JsonMap,
      );
      if (result is ReconnectResultUnknown) {
        // A result kind newer than this client: start over.
        await _reinitialize(peer, subscriptions);
      } else {
        // A snapshot replaces mirrors without echoing anything, so report
        // their pending actions first; a replay echoes the accepted ones.
        if (result is ReconnectSnapshotResult) _clearPendingActions();
        final missing = missingAfterReconnect(_state, result);
        _set(applyReconnectResult(_state, result, clientId: clientId));
        _dropSubscriptions(missing);
      }
    } on RpcException catch (error) {
      if (error.code != AhpErrorCodes.notFound) rethrow;
      await _reinitialize(peer, subscriptions);
    }
  }

  /// Waits [delay] before the next reconnect attempt, or less when
  /// [checkConnection] or [close] ends the wait.
  Future<void> _wait(Duration delay) {
    final backoff = _backoff = Completer<void>();
    final timer = Timer(delay, _endBackoff);
    return backoff.future.whenComplete(timer.cancel);
  }

  void _endBackoff() {
    final backoff = _backoff;
    _backoff = null;
    if (backoff != null && !backoff.isCompleted) backoff.complete();
  }

  /// [request] with [handshakeTimeout]; a timeout throws a
  /// [ConnectionProblem] naming [what] the host did not answer.
  Future<T> _timed<T>(Future<T> request, String what) =>
      handshakeTimeout <= Duration.zero
      ? request
      : request.timeout(
          handshakeTimeout,
          onTimeout: () => throw ConnectionProblem(
            'The host did not finish $what within '
            '${handshakeTimeout.inSeconds} s.',
            TimeoutException(what, handshakeTimeout),
          ),
        );

  /// Rolls back every pending action and reports each one as
  /// [ActionFailureKind.connectionLost].
  void _clearPendingActions() {
    final (:state, :failures) = clearAllPendingActions(_state);
    if (failures.isEmpty) return;
    _set(state);
    failures.forEach(_fail);
  }

  /// Forgets every observer of the [missing] channels: the host can no
  /// longer resume them, so later `unsubscribe` calls are no-ops.
  void _dropSubscriptions(List<String> missing) {
    if (missing.isEmpty) return;
    _log.info('host could not resume ${missing.join(', ')}');
    _subscriptions = Map.unmodifiable(
      {..._subscriptions}..removeWhere((key, _) => missing.contains(key)),
    );
  }

  /// Sends a liveness `ping` every [pingInterval] on [peer] (AHP-005).
  void _startPings(Peer peer) {
    _stopPings();
    if (pingInterval <= Duration.zero) return;
    _pingTimer = Timer.periodic(pingInterval, (_) => _checkLiveness(peer));
  }

  void _stopPings() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingInFlight = false;
  }

  Future<void> _checkLiveness(Peer peer) async {
    if (_pingInFlight || !identical(_peer, peer)) return;
    _pingInFlight = true;
    try {
      await peer
          .sendRequest('ping', {'channel': rootChannel})
          .timeout(pingTimeout);
    } on Object catch (error) {
      if (isLivenessFailure(error) && identical(_peer, peer)) {
        _log.warning('ping failed ($error); reconnecting');
        _onDisconnect();
        unawaited(peer.close());
      }
    } finally {
      if (identical(_peer, peer)) _pingInFlight = false;
    }
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
