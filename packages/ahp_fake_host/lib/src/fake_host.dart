/// A scripted AHP 1.0.0 host for tests (see `script.dart` for the flows).
///
/// The host keeps real protocol state and advances it with the client's
/// own reducers (`reduceSession`, `reduceChat`), so what it sends is what
/// a reducer-faithful host would send. Each accepted client action is
/// echoed with its origin; the script reacts to `chat/turnStarted` and
/// then waits for the approvals, answers and sign-ins it asked for.
library;

import 'dart:async';
import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'script.dart';

/// The agent provider the fake host offers.
const fakeProvider = 'fake';

/// The session the host starts with.
const seededSession = 'ahp-session:/scripted';

/// The default chat of [seededSession].
const seededChat = 'ahp-chat:/scripted';

/// Client actions the host accepts; anything else is rejected.
const clientDispatchable = <String>{
  'chat/turnStarted',
  'chat/turnCancelled',
  'chat/turnResume',
  'chat/pendingMessageSet',
  'chat/pendingMessageRemoved',
  'chat/queuedMessagesReordered',
  'chat/toolCallConfirmed',
  'chat/toolCallResultConfirmed',
  'chat/toolCallComplete',
  'chat/inputAnswerChanged',
  'chat/inputCompleted',
  'chat/draftChanged',
  'chat/isReadChanged',
  'chat/isArchivedChanged',
  'session/isReadChanged',
  'session/isArchivedChanged',
  'session/titleChanged',
};

/// A client action the host accepted, or (with [channel] `*`) a token
/// pushed with `authenticate`.
typedef ReceivedAction = ({String channel, JsonMap action});

class _Connection {
  _Connection(this.peer);

  final Peer peer;
  String? clientId;
  final subscriptions = <String>{};
}

/// A scripted AHP host. Serve it over WebSocket with [start], or connect
/// an in-memory channel with [serve].
class FakeAhpHost {
  /// Creates a host. A non-null [token] is required from clients, in the
  /// `tkn` query parameter or an `Authorization: Bearer` header. Scripted
  /// steps are [stepDelay] apart; background work ends after
  /// [backgroundDuration].
  FakeAhpHost({
    this.token,
    this.stepDelay = const Duration(milliseconds: 40),
    this.backgroundDuration = const Duration(seconds: 3),
    this.defaultDirectory = '/workspace',
  }) {
    _addSession(
      seededSession,
      seededChat,
      title: 'Scripted session',
      workingDirectories: [defaultDirectory],
    );
  }

  /// The connection token, if one is required.
  final String? token;

  /// The pause between scripted steps.
  final Duration stepDelay;

  /// How long background work runs before it is removed.
  final Duration backgroundDuration;

  /// The `defaultDirectory` sent in `initialize`.
  final String defaultDirectory;

  HttpServer? _server;
  final _connections = <_Connection>{};
  final _received = StreamController<ReceivedAction>.broadcast(sync: true);
  final _log = <ReceivedAction>[];
  final _rejected = <ReceivedAction>[];
  final _timers = <Timer>{};
  int _serverSeq = 0;
  int _ids = 0;

  final _sessions = <String, SessionState>{};
  final _chats = <String, ChatState>{};
  final _summaries = <String, SessionSummary>{};
  final _sessionOfChat = <String, String>{};

  /// Every accepted client action and `authenticate` call, in order.
  List<ReceivedAction> get received => List.unmodifiable(_log);

  /// Every rejected client action, in order.
  List<ReceivedAction> get rejected => List.unmodifiable(_rejected);

  /// Accepted client actions and `authenticate` calls as they arrive.
  Stream<ReceivedAction> get actions => _received.stream;

  /// The host's current state of [chat].
  ChatState? chat(String chat) => _chats[chat];

  /// The host's current state of [session].
  SessionState? session(String session) => _sessions[session];

  /// Listens on [port] (0 for any) at [address] and returns the URL to
  /// connect to, with `tkn` when a [token] is set.
  Future<Uri> start({int port = 0, String address = '127.0.0.1'}) async {
    final server = await HttpServer.bind(address, port);
    _server = server;
    server.listen(_onRequest);
    return Uri(
      scheme: 'ws',
      host: address,
      port: server.port,
      queryParameters: token == null ? null : {'tkn': token},
    );
  }

  /// Stops listening and closes every connection.
  Future<void> close() async {
    for (final timer in _timers) {
      timer.cancel();
    }
    await _server?.close(force: true);
    await Future.wait([for (final c in _connections) c.peer.close()]);
    _connections.clear();
    await _received.close();
  }

  Future<void> _onRequest(HttpRequest request) async {
    final bearer = request.headers.value('authorization');
    final authorized =
        token == null ||
        request.uri.queryParameters['tkn'] == token ||
        bearer == 'Bearer $token';
    if (!authorized || !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = authorized
          ? HttpStatus.badRequest
          : HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    serve(IOWebSocketChannel(socket).cast<String>());
  }

  /// Serves one client connection over [channel] (one JSON-RPC message per
  /// string).
  void serve(StreamChannel<String> channel) {
    final connection = _Connection(Peer(channel));
    final peer = connection.peer;
    peer
      ..registerMethod('initialize', (Parameters p) {
        return _initialize(connection, p.value as JsonMap);
      })
      ..registerMethod('reconnect', (Parameters _) {
        // Clients fall back to `initialize`.
        throw RpcException(AhpErrorCodes.notFound, 'unknown client');
      })
      ..registerMethod('ping', (Parameters _) => null)
      ..registerMethod(
        'listSessions',
        (Parameters _) => {
          'items': [for (final s in _summaries.values) s.toJson()],
        },
      )
      ..registerMethod('subscribe', (Parameters p) {
        final channel = (p.value as JsonMap)['channel']! as String;
        final snapshot = _snapshot(channel);
        if (snapshot == null) {
          throw RpcException(AhpErrorCodes.notFound, 'no channel $channel');
        }
        connection.subscriptions.add(channel);
        return {'snapshot': snapshot};
      })
      ..registerMethod('unsubscribe', (Parameters p) {
        connection.subscriptions.remove((p.value as JsonMap)['channel']);
      })
      ..registerMethod('createSession', (Parameters p) {
        _createSession(p.value as JsonMap);
        return null;
      })
      ..registerMethod('fetchTurns', (Parameters _) => <String, Object?>{})
      ..registerMethod('authenticate', (Parameters p) {
        final params = AuthenticateParams.fromJson(p.value as JsonMap);
        _record((
          channel: '*',
          action: {
            'type': '#authenticate',
            'resource': params.resource,
            'token': params.token,
          },
        ));
        return <String, Object?>{};
      })
      ..registerMethod('dispatchAction', (Parameters p) {
        _dispatch(connection, p.value as JsonMap);
      })
      ..registerFallback((Parameters p) {
        throw RpcException.methodNotFound(p.method);
      });
    _connections.add(connection);
    unawaited(
      peer.listen().whenComplete(() => _connections.remove(connection)),
    );
  }

  JsonMap _initialize(_Connection connection, JsonMap json) {
    final params = InitializeParams.fromJson(json);
    final version = const [
      '1.0.0',
      '0.9.0',
    ].where(params.protocolVersions.contains).firstOrNull;
    if (version == null) {
      throw RpcException(
        AhpErrorCodes.unsupportedProtocolVersion,
        'unsupported protocol version',
        data: {
          'supportedVersions': ['1.0.0', '0.9.0'],
        },
      );
    }
    connection.clientId = params.clientId;
    final subscriptions = params.initialSubscriptions ?? const [];
    connection.subscriptions.addAll(subscriptions);
    return InitializeResult(
      protocolVersion: version,
      serverSeq: _serverSeq,
      serverInfo: const Implementation(name: 'ahp-fake-host', version: '0.1.0'),
      snapshots: [
        for (final channel in subscriptions)
          if (_snapshot(channel) case final snapshot?)
            Snapshot.fromJson(snapshot),
      ],
      defaultDirectory: defaultDirectory,
    ).toJson();
  }

  RootState get _root => RootState(
    agents: const [
      AgentInfo(
        provider: fakeProvider,
        displayName: 'Fake agent',
        description: 'Scripted host for tests',
        models: [
          SessionModelInfo(
            id: 'scripted',
            provider: fakeProvider,
            name: 'Scripted',
          ),
        ],
      ),
    ],
    activeSessions: _chats.values.where((c) => c.activeTurn != null).length,
  );

  JsonMap? _snapshot(String channel) {
    final state = channel == rootChannel
        ? _root.toJson()
        : _sessions[channel]?.toJson() ?? _chats[channel]?.toJson();
    return state == null
        ? null
        : {'resource': channel, 'state': state, 'fromSeq': _serverSeq};
  }

  String _now() => DateTime.now().toUtc().toIso8601String();

  String _nextId(String prefix) => '$prefix-${++_ids}';

  ChatSummary _chatSummary(String chat) {
    final state = _chats[chat]!;
    return ChatSummary(
      resource: chat,
      title: state.title,
      status: state.status,
      activity: state.activity,
      modifiedAt: state.modifiedAt,
      changes: state.changes,
    );
  }

  void _addSession(
    String session,
    String chat, {
    required String title,
    List<String>? workingDirectories,
  }) {
    final now = _now();
    _chats[chat] = ChatState(
      resource: chat,
      title: title,
      status: SessionStatus(
        SessionStatus.idle.bits | SessionStatus.isRead.bits,
      ),
      modifiedAt: now,
      turns: const [],
    );
    _sessionOfChat[chat] = session;
    _sessions[session] = SessionState(
      provider: fakeProvider,
      title: title,
      status: _chats[chat]!.status,
      workingDirectories: workingDirectories,
      lifecycle: SessionLifecycle.ready,
      activeClients: const [],
      chats: [_chatSummary(chat)],
      defaultChat: chat,
    );
    _summaries[session] = SessionSummary(
      provider: fakeProvider,
      title: title,
      status: _chats[chat]!.status,
      workingDirectories: workingDirectories,
      resource: session,
      createdAt: now,
      modifiedAt: now,
      defaultChat: chat,
    );
  }

  void _createSession(JsonMap json) {
    final params = CreateSessionParams.fromJson(json);
    final session = params.channel;
    if (_sessions.containsKey(session)) {
      throw RpcException(AhpErrorCodes.sessionAlreadyExists, 'exists');
    }
    final id = session.split('/').last;
    _addSession(
      session,
      'ahp-chat:/$id',
      title: 'New session',
      workingDirectories: params.workingDirectories,
    );
    _notifyRoot('root/sessionAdded', {
      'channel': rootChannel,
      'summary': _summaries[session]!.toJson(),
    });
  }

  void _notifyRoot(String method, JsonMap params) {
    for (final c in _connections) {
      if (c.subscriptions.contains(rootChannel)) {
        c.peer.sendNotification(method, params);
      }
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Applies [action] on [channel] and sends it to the channel's
  /// subscribers (and to [origin]'s connection, which may not be
  /// subscribed). A [rejection] is only sent back to the origin.
  void _emit(
    String channel,
    JsonMap action, {
    _Connection? from,
    int? clientSeq,
    String? rejection,
  }) {
    if (rejection == null) _apply(channel, action);
    final envelope = ActionEnvelope(
      channel: channel,
      action: action,
      serverSeq: ++_serverSeq,
      origin: from?.clientId == null || clientSeq == null
          ? null
          : ActionOrigin(clientId: from!.clientId!, clientSeq: clientSeq),
      rejectionReason: rejection,
    ).toJson();
    for (final c in _connections) {
      if (c == from ||
          (rejection == null && c.subscriptions.contains(channel))) {
        c.peer.sendNotification('action', envelope);
      }
    }
    if (rejection == null) _syncSummary(channel);
  }

  void _apply(String channel, JsonMap action) {
    if (_sessions[channel] case final state?) {
      _sessions[channel] = reduceSessionJson(state, action);
    } else if (_chats[channel] case final state?) {
      _chats[channel] = reduceChatJson(state, action);
    }
  }

  /// Keeps the session's chat list and catalogue entry in step with
  /// [channel]'s state.
  void _syncSummary(String channel) {
    final session = _sessionOfChat[channel] ?? channel;
    final state = _sessions[session];
    if (state == null) return;
    if (_chats.containsKey(channel)) {
      final summary = _chatSummary(channel);
      final listed = state.chats
          .where((c) => c.resource == channel)
          .firstOrNull;
      if (listed != null && listed != summary) {
        _emit(session, {
          'type': 'session/chatUpdated',
          'chat': channel,
          'changes': {
            'status': summary.status.bits,
            'activity': summary.activity,
            'modifiedAt': summary.modifiedAt,
          },
        });
        return;
      }
    }
    final chat = _chats[defaultChatOf(state)];
    final old = _summaries[session]!;
    final next = old.copyWith(
      title: state.title,
      status: summaryStatus(
        state.status,
        chat?.status ?? SessionStatus.idle,
        state.inputNeeded ?? const [],
      ),
      activity: chat?.activity,
      modifiedAt: chat?.modifiedAt ?? old.modifiedAt,
    );
    if (next == old) return;
    _summaries[session] = next;
    _notifyRoot('root/sessionSummaryChanged', {
      'channel': rootChannel,
      'session': session,
      'changes': {
        'title': next.title,
        'status': next.status.bits,
        'activity': next.activity,
        'modifiedAt': next.modifiedAt,
      },
    });
  }

  void _record(ReceivedAction received) {
    _log.add(received);
    if (!_received.isClosed) _received.add(received);
  }

  void _dispatch(_Connection from, JsonMap json) {
    final params = DispatchActionParams.fromJson(json);
    final channel = params.channel;
    final action = params.action.toJson();
    final type = action['type'];
    final rejection = !clientDispatchable.contains(type)
        ? '$type is not client-dispatchable'
        : !_sessions.containsKey(channel) && !_chats.containsKey(channel)
        ? 'unknown channel $channel'
        : type == 'chat/turnStarted' && _chats[channel]!.activeTurn != null
        ? 'a turn is already running'
        : null;
    _emit(
      channel,
      action,
      from: from,
      clientSeq: params.clientSeq,
      rejection: rejection,
    );
    if (rejection != null) {
      _rejected.add((channel: channel, action: action));
      return;
    }
    _record((channel: channel, action: action));
    if (type == 'chat/turnStarted') {
      final started = ChatTurnStartedAction.fromJson(action);
      unawaited(_runTurn(channel, started.turnId, started.message.text));
    }
  }

  // ── Script ───────────────────────────────────────────────────────────

  bool _active(String chat, String turnId) =>
      _chats[chat]?.activeTurn?.id == turnId;

  /// Waits [stepDelay]; false when the turn ended meanwhile.
  Future<bool> _step(String chat, String turnId) async {
    await Future<void>.delayed(stepDelay);
    return _active(chat, turnId);
  }

  /// The next client action on [chat] (or `authenticate` call) that
  /// passes [test], or null once turn [turnId] has ended.
  Future<JsonMap?> _waitFor(
    String chat,
    String turnId,
    bool Function(JsonMap action) test,
  ) {
    if (!_active(chat, turnId)) return Future.value();
    final done = Completer<JsonMap?>();
    late final StreamSubscription<ReceivedAction> subscription;
    subscription = _received.stream.listen(
      (received) {
        if (received.channel != chat && received.channel != '*') return;
        if (test(received.action)) {
          done.complete(received.action);
        } else if (!_active(chat, turnId)) {
          done.complete(null);
        } else {
          return;
        }
        unawaited(subscription.cancel());
      },
      onDone: () {
        if (!done.isCompleted) done.complete(null);
      },
    );
    return done.future;
  }

  void _say(String chat, String turnId, String text) => _emit(
    chat,
    ChatResponsePartAction(
      turnId: turnId,
      part: MarkdownResponsePart(id: _nextId('md'), content: text),
    ).toJson(),
  );

  T? _toolCall<T extends ToolCallState>(String chat, String toolCallId) {
    for (final part in _chats[chat]?.activeTurn?.responseParts ?? const []) {
      if (part case ToolCallResponsePart(:final T toolCall)
          when toolCall.toolCallId == toolCallId) {
        return toolCall;
      }
    }
    return null;
  }

  Future<void> _runTurn(String chat, String turnId, String text) async {
    final scenarios = scenariosFor(text);
    if (!await _step(chat, turnId)) return;
    if (scenarios.isEmpty) _say(chat, turnId, echoReply(text));
    for (final scenario in scenarios) {
      final finished = await switch (scenario) {
        Scenario.tool => _toolFlow(chat, turnId),
        Scenario.ask => _askFlow(chat, turnId),
        Scenario.side => _sideFlow(chat, turnId),
        Scenario.auth => _authFlow(chat, turnId),
        Scenario.background => _backgroundFlow(chat, turnId),
        Scenario.edit => _editFlow(chat, turnId),
      };
      if (!finished || !await _step(chat, turnId)) return;
    }
    _endTurn(chat, turnId);
  }

  void _endTurn(String chat, String turnId) {
    final active = _chats[chat]!.activeTurn!;
    final started = DateTime.parse(active.startedAt);
    _emit(
      chat,
      ChatTurnCompleteAction(
        turnId: turnId,
        duration: DateTime.now().difference(started).inMilliseconds,
      ).toJson(),
    );
    if (_chats[chat]!.steeringMessage case final steering?) {
      _emit(
        chat,
        ChatPendingMessageRemovedAction(
          kind: PendingMessageKind.steering,
          id: steering.id,
        ).toJson(),
      );
    }
    // Queued messages start the next turn.
    final queued = _chats[chat]!.queuedMessages?.firstOrNull;
    if (queued != null) {
      final next = _nextId('turn');
      _emit(
        chat,
        ChatTurnStartedAction(
          turnId: next,
          startedAt: _now(),
          message: queued.message,
          queuedMessageId: queued.id,
        ).toJson(),
      );
      unawaited(_runTurn(chat, next, queued.message.text));
    }
  }

  void _setInputNeeded(String chat, SessionInputRequest request) => _emit(
    _sessionOfChat[chat]!,
    SessionInputNeededSetAction(request: request).toJson(),
  );

  void _removeInputNeeded(String chat, String id) => _emit(
    _sessionOfChat[chat]!,
    SessionInputNeededRemovedAction(id: id).toJson(),
  );

  Future<bool> _toolFlow(String chat, String turnId) async {
    final id = _nextId('bash');
    _say(chat, turnId, 'I need to look at the files first.');
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: 'bash',
        displayName: 'Bash',
      ).toJson(),
    );
    _emit(chat, toolReady(turnId, id).toJson());
    final pending = _toolCall<ToolCallPendingConfirmationState>(chat, id)!;
    final requestId = 'confirm-$id';
    _setInputNeeded(
      chat,
      SessionToolConfirmationRequest(
        id: requestId,
        chat: chat,
        turnId: turnId,
        toolCall: pending,
      ),
    );
    final answer = await _waitFor(
      chat,
      turnId,
      (a) => a['type'] == 'chat/toolCallConfirmed' && a['toolCallId'] == id,
    );
    _removeInputNeeded(chat, requestId);
    if (answer == null) return false;
    final approved = answer['approved'] == true;
    if (!await _step(chat, turnId)) return false;
    if (approved) {
      _emit(
        chat,
        ChatToolCallCompleteAction(
          turnId: turnId,
          toolCallId: id,
          result: toolResult(),
        ).toJson(),
      );
      _say(chat, turnId, 'The folder has 3 entries.');
    } else {
      _say(chat, turnId, 'OK, I did not run it.');
    }
    return true;
  }

  Future<bool> _askFlow(String chat, String turnId) async {
    final request = deploymentRequest(_nextId('input'));
    _emit(chat, ChatInputRequestedAction(request: request).toJson());
    final entryId = 'input-${request.id}';
    _setInputNeeded(
      chat,
      SessionChatInputRequest(id: entryId, chat: chat, request: request),
    );
    final answer = await _waitFor(
      chat,
      turnId,
      (a) => a['type'] == 'chat/inputCompleted' && a['requestId'] == request.id,
    );
    _removeInputNeeded(chat, entryId);
    if (answer == null) return false;
    if (!await _step(chat, turnId)) return false;
    _say(chat, turnId, answerReply(ChatInputCompletedAction.fromJson(answer)));
    return true;
  }

  Future<bool> _sideFlow(String chat, String turnId) async {
    final session = _sessionOfChat[chat]!;
    final side = '$chat-reviewer-${++_ids}';
    _chats[side] = ChatState(
      resource: side,
      title: 'Reviewer',
      status: SessionStatus.idle,
      modifiedAt: _now(),
      turns: const [],
    );
    _sessionOfChat[side] = session;
    _emit(
      session,
      SessionChatAddedAction(summary: _chatSummary(side)).toJson(),
    );
    final sideTurn = _nextId('turn');
    _emit(
      side,
      ChatTurnStartedAction(
        turnId: sideTurn,
        startedAt: _now(),
        message: const Message(
          text: 'Review the branch',
          origin: MessageOrigin(kind: MessageKind.agent),
        ),
      ).toJson(),
    );
    final request = sideRequest(_nextId('input'));
    _emit(side, ChatInputRequestedAction(request: request).toJson());
    final entryId = 'input-${request.id}';
    _setInputNeeded(
      side,
      SessionChatInputRequest(id: entryId, chat: side, request: request),
    );
    _say(chat, turnId, 'I asked the reviewer chat; it needs your decision.');
    final answer = await _waitFor(
      side,
      sideTurn,
      (a) => a['type'] == 'chat/inputCompleted' && a['requestId'] == request.id,
    );
    _removeInputNeeded(side, entryId);
    if (_active(side, sideTurn)) _endTurn(side, sideTurn);
    if (answer == null || !await _step(chat, turnId)) return false;
    _say(
      chat,
      turnId,
      'The reviewer chat got: '
      '${answerReply(ChatInputCompletedAction.fromJson(answer))}',
    );
    return true;
  }

  Future<bool> _authFlow(String chat, String turnId) async {
    final id = _nextId('search');
    const contributor = ToolCallMcpContributor(
      customizationId: docsCustomizationId,
    );
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: 'search_docs',
        displayName: 'Search docs',
        contributor: contributor,
      ).toJson(),
    );
    _emit(
      chat,
      ChatToolCallReadyAction(
        turnId: turnId,
        toolCallId: id,
        invocationMessage: const PlainString('Search Example Docs'),
        toolInput: const InlineToolInput('{"query":"deploy"}'),
        confirmed: ToolCallConfirmationReason.notNeeded,
      ).toJson(),
    );
    if (!await _step(chat, turnId)) return false;
    final auth = docsAuth();
    _emit(
      chat,
      ChatToolCallAuthRequiredAction(
        turnId: turnId,
        toolCallId: id,
        auth: auth,
      ).toJson(),
    );
    final waiting = _toolCall<ToolCallAuthRequiredState>(chat, id)!;
    final requestId = 'auth-$id';
    _setInputNeeded(
      chat,
      SessionToolAuthenticationRequest(
        id: requestId,
        chat: chat,
        turnId: turnId,
        toolCall: waiting,
      ),
    );
    final answer = await _waitFor(
      chat,
      turnId,
      (a) =>
          (a['type'] == '#authenticate' &&
              a['resource'] == auth.resource.resource) ||
          (a['type'] == 'chat/toolCallComplete' && a['toolCallId'] == id),
    );
    _removeInputNeeded(chat, requestId);
    if (answer == null) return false;
    if (answer['type'] == '#authenticate') {
      _emit(
        chat,
        ChatToolCallAuthResolvedAction(turnId: turnId, toolCallId: id).toJson(),
      );
      if (!await _step(chat, turnId)) return false;
      _emit(
        chat,
        ChatToolCallCompleteAction(
          turnId: turnId,
          toolCallId: id,
          result: const ToolCallResult(
            success: true,
            pastTenseMessage: PlainString('Searched Example Docs'),
            content: [ToolResultTextContent(text: '2 pages about deploy')],
          ),
        ).toJson(),
      );
      _say(chat, turnId, 'Signed in. I found 2 pages.');
    } else {
      _say(chat, turnId, 'Sign-in was cancelled, so I skipped the search.');
    }
    return true;
  }

  Future<bool> _backgroundFlow(String chat, String turnId) async {
    final id = _nextId('shell');
    _emit(
      chat,
      ChatBackgroundWorkSetAction(
        work: BackgroundShellWork(
          id: id,
          label: 'npm test -- --watch',
          startedAt: _now(),
          command: 'npm test -- --watch',
        ),
      ).toJson(),
    );
    _say(chat, turnId, 'The tests keep running in the background.');
    late final Timer timer;
    timer = Timer(backgroundDuration, () {
      _timers.remove(timer);
      _emit(chat, ChatBackgroundWorkRemovedAction(id: id).toJson());
    });
    _timers.add(timer);
    return true;
  }

  Future<bool> _editFlow(String chat, String turnId) async {
    final id = _nextId('edit');
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: 'edit',
        displayName: 'Edit',
      ).toJson(),
    );
    _emit(
      chat,
      ChatToolCallReadyAction(
        turnId: turnId,
        toolCallId: id,
        invocationMessage: const PlainString('Edit README.md'),
        toolInput: const InlineToolInput('{"path":"README.md"}'),
        confirmed: ToolCallConfirmationReason.notNeeded,
      ).toJson(),
    );
    if (!await _step(chat, turnId)) return false;
    _emit(
      chat,
      ChatToolCallCompleteAction(
        turnId: turnId,
        toolCallId: id,
        result: const ToolCallResult(
          success: true,
          pastTenseMessage: PlainString('Edited README.md'),
        ),
      ).toJson(),
    );
    final session = _sessionOfChat[chat]!;
    _summaries[session] = _summaries[session]!.copyWith(changes: editChanges);
    _notifyRoot('root/sessionSummaryChanged', {
      'channel': rootChannel,
      'session': session,
      'changes': {'changes': editChanges.toJson()},
    });
    _say(chat, turnId, 'Edited README.md.');
    return true;
  }
}
