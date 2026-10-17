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
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'fake_config.dart';
import 'fake_oauth_server.dart';
import 'script.dart';

/// The agent provider the fake host offers.
const fakeProvider = 'fake';

/// The session the host starts with.
const seededSession = 'ahp-session:/scripted';

/// The default chat of [seededSession].
const seededChat = 'ahp-chat:/scripted';

/// A seeded session with a long history, delivered as a window of the last
/// [turnWindow] turns plus `turnsNextCursor` (AHP-029).
const longSession = 'ahp-session:/long';

/// The default chat of [longSession].
const longChat = 'ahp-chat:/long';

/// How many turns [longChat] has.
const longTurnCount = 60;

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
  'session/configChanged',
  'session/mcpServerStartRequested',
  'session/mcpServerStopRequested',
  'session/mcpServerBackgroundRequested',
  'changeset/filesReviewChanged',
};

/// A client action the host accepted, or (with [channel] `*`) a token
/// pushed with `authenticate`.
typedef ReceivedAction = ({String channel, JsonMap action});

class _Connection {
  _Connection(this.peer);

  final Peer peer;
  String? clientId;
  final subscriptions = <String>{};

  /// The tokens this connection pushed with `authenticate`, by resource.
  final tokens = <String, String>{};
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
    this.slowDuration = const Duration(seconds: 4),
    this.name = 'ahp-fake-host',
    this.titlePrefix = '',
    this.completionTriggers = fakeCompletionTriggers,
    Duration tokenLifetime = const Duration(hours: 1),
  }) : oauthServer = FakeOAuthServer(tokenLifetime: tokenLifetime),
       directories = fakeDirectories(defaultDirectory),
       files = fakeFiles(defaultDirectory) {
    _addSession(
      longSession,
      longChat,
      title: '${titlePrefix}Long session',
      workingDirectories: [defaultDirectory],
    );
    final history = longHistory(longTurnCount, DateTime.utc(2026, 10, 1));
    _archive[longChat] = history.sublist(0, history.length - turnWindow);
    _chats[longChat] = _chats[longChat]!.copyWith(
      turns: history.sublist(history.length - turnWindow),
      turnsNextCursor: _cursorFor(_archive[longChat]!),
      modifiedAt: history.last.startedAt,
    );
    _addSession(
      seededSession,
      seededChat,
      title: '${titlePrefix}Scripted session',
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

  /// How long the `slow` flow keeps its turn running unless stopped.
  final Duration slowDuration;

  /// The `serverInfo.name` sent in `initialize`, which clients show as the
  /// host's name; give a second instance another one.
  final String name;

  /// Put before the seeded sessions' titles, to tell two hosts apart.
  final String titlePrefix;

  /// The `completionTriggerCharacters` sent in `initialize`. When empty,
  /// the host acts like one without completions: `completions` is not
  /// found, and clients fall back to the sessions' skills.
  final List<String> completionTriggers;

  /// The folders `resourceList` knows; [defaultDirectory] is a git
  /// repository on branch `main`. Creating a session in any other folder
  /// fails with `session/creationFailed`.
  final Set<String> directories;

  /// The files `resourceList` lists.
  final Set<String> files;

  /// The OAuth authorization server of the host's protected resources,
  /// started with the host by [start] (AHP-060). Tokens it issued, and
  /// [fakePersonalToken], are accepted by `authenticate`.
  final FakeOAuthServer oauthServer;

  /// [oauthServer]'s issuer once [start]ed; null for [serve]-only use.
  Uri? _issuer;

  /// Tokens the host was told have expired; never accepted again.
  final _expiredTokens = <String>{};

  HttpServer? _server;
  final _connections = <_Connection>{};
  final _received = StreamController<ReceivedAction>.broadcast(sync: true);
  final _log = <ReceivedAction>[];
  final _rejected = <ReceivedAction>[];
  final _timers = <Timer>{};
  int _serverSeq = 0;
  int _ids = 0;

  /// The protocol version each client initialized with, for `reconnect`.
  final _clientVersions = <String, String>{};

  /// The newest envelopes (at most [replayLimit]), replayed by `reconnect`.
  final _replay = <ActionEnvelope>[];

  /// While true, new WebSocket connections are refused (`503`), as if the
  /// host were down. Changeable at any time.
  bool refuseConnections = false;

  /// While true, `dispatchAction` messages are dropped unread, as if lost
  /// on the way: nothing is applied or echoed. Changeable at any time.
  bool loseActions = false;

  /// How many envelopes `reconnect` can replay; a client further behind
  /// gets snapshots.
  int replayLimit = 1000;

  final _sessions = <String, SessionState>{};
  final _chats = <String, ChatState>{};
  final _summaries = <String, SessionSummary>{};
  final _sessionOfChat = <String, String>{};
  final _terminals = <String, TerminalState>{};
  final _changesets = <String, ChangesetState>{};
  final _canvases = <String, CanvasState>{};
  final _contents = <String, String>{};

  /// Older turns of windowed chats, not in their state yet (AHP-029).
  final _archive = <String, List<Turn>>{};

  /// The client that started each running turn, by turn id.
  final _turnClients = <String, String>{};

  /// Client action types to reject (with a `rejectionReason`) even though
  /// they are client-dispatchable, so tests can check how a client rolls
  /// back an action the host refused. Changeable at any time.
  final rejectTypes = <String>{};

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

  /// The host's current state of the terminal [terminal].
  TerminalState? terminal(String terminal) => _terminals[terminal];

  /// The host's current state of the expanded changeset URI [changeset].
  ChangesetState? changeset(String changeset) => _changesets[changeset];

  /// Listens on [port] (0 for any) at [address] and returns the URL to
  /// connect to, with `tkn` when a [token] is set.
  Future<Uri> start({int port = 0, String address = '127.0.0.1'}) async {
    _issuer = await oauthServer.start(address: address);
    final server = await HttpServer.bind(address, port);
    _server = server;
    server.listen(_onRequest);
    return _url = Uri(
      scheme: 'ws',
      host: address,
      port: server.port,
      queryParameters: token == null ? null : {'tkn': token},
    );
  }

  /// The URL [start] returned, or null before it.
  Uri? get url => _url;
  Uri? _url;

  /// Serves a new connection in memory: a [ChannelConnector] for clients
  /// that should reach the host while [refuseConnections] keeps socket
  /// clients out.
  Future<StreamChannel<String>> connectInMemory(Uri _) async {
    final controller = StreamChannelController<String>();
    serve(controller.foreign);
    return controller.local;
  }

  /// Stops listening and closes every connection.
  Future<void> close() async {
    for (final timer in _timers) {
      timer.cancel();
    }
    await _server?.close(force: true);
    await oauthServer.close();
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
    if (refuseConnections) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }
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
      ..registerMethod('reconnect', (Parameters p) {
        return _reconnect(connection, p.value as JsonMap);
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
        _createSession(connection, p.value as JsonMap);
        return null;
      })
      ..registerMethod('resourceList', (Parameters p) {
        final params = ResourceListParams.fromJson(p.value as JsonMap);
        final entries = listFakeDirectory(
          pathOfUri(params.uri),
          directories,
          files,
        );
        if (entries == null) {
          throw RpcException(
            AhpErrorCodes.notFound,
            'not a directory: ${params.uri}',
          );
        }
        return ResourceListResult(entries: entries).toJson();
      })
      ..registerMethod('resolveSessionConfig', (Parameters p) {
        final params = ResolveSessionConfigParams.fromJson(p.value as JsonMap);
        final schema = sessionConfigSchema(
          params.workingDirectory,
          defaultDirectory,
        );
        return ResolveSessionConfigResult(
          schema: schema,
          values: resolvedConfigValues(schema, params.config),
        ).toJson();
      })
      ..registerMethod('sessionConfigCompletions', (Parameters p) {
        final params = SessionConfigCompletionsParams.fromJson(
          p.value as JsonMap,
        );
        return SessionConfigCompletionsResult(
          items: params.property == branchProperty
              ? branchCompletions(params.query)
              : const [],
        ).toJson();
      })
      ..registerMethod('completions', (Parameters p) {
        if (completionTriggers.isEmpty) {
          throw RpcException.methodNotFound('completions');
        }
        final params = CompletionsParams.fromJson(p.value as JsonMap);
        final session = _sessions[_sessionOfChat[params.channel]];
        return CompletionsResult(
          items: fakeCompletions(
            slashCommands(session?.customizations),
            params.text,
            params.offset,
          ),
        ).toJson();
      })
      ..registerMethod('fetchTurns', (Parameters p) {
        _fetchTurns(FetchTurnsParams.fromJson(p.value as JsonMap));
        return <String, Object?>{};
      })
      ..registerMethod('resourceRead', (Parameters p) {
        final params = ResourceReadParams.fromJson(p.value as JsonMap);
        final data = _contents[params.uri];
        if (data == null) {
          throw RpcException(
            AhpErrorCodes.notFound,
            'no content ${params.uri}',
          );
        }
        return ResourceReadResult(
          data: data,
          encoding: ContentEncoding.utf8,
          contentType: 'text/plain',
        ).toJson();
      })
      ..registerMethod('invokeChangesetOperation', (Parameters p) {
        return _invokeOperation(
          InvokeChangesetOperationParams.fromJson(p.value as JsonMap),
        );
      })
      ..registerMethod('moveChat', (Parameters p) {
        return _moveChat(MoveChatParams.fromJson(p.value as JsonMap));
      })
      ..registerMethod('authenticate', (Parameters p) {
        _authenticate(
          connection,
          AuthenticateParams.fromJson(p.value as JsonMap),
        );
        return <String, Object?>{};
      })
      ..registerMethod('dispatchAction', (Parameters p) {
        if (loseActions) return;
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
    _clientVersions[params.clientId] = version;
    final subscriptions = params.initialSubscriptions ?? const [];
    connection.subscriptions.addAll(subscriptions);
    return InitializeResult(
      protocolVersion: version,
      serverSeq: _serverSeq,
      serverInfo: Implementation(name: name, version: '0.1.0'),
      snapshots: [
        for (final channel in subscriptions)
          if (_snapshot(channel) case final snapshot?)
            Snapshot.fromJson(snapshot),
      ],
      defaultDirectory: defaultDirectory,
      completionTriggerCharacters: completionTriggers.isEmpty
          ? null
          : completionTriggers,
    ).toJson();
  }

  /// Resumes a client this host initialized: a replay of what it missed
  /// on the channels it names (unknown ones are `missing`), or snapshots
  /// when the replay buffer no longer reaches back far enough. A client
  /// this host never saw gets `-32008` and initializes again.
  JsonMap _reconnect(_Connection connection, JsonMap json) {
    final params = ReconnectParams.fromJson(json);
    if (!_clientVersions.containsKey(params.clientId)) {
      throw RpcException(AhpErrorCodes.notFound, 'unknown client');
    }
    connection.clientId = params.clientId;
    final known = params.subscriptions.where(
      (c) => c == rootChannel || _known(c),
    );
    connection.subscriptions.addAll(known);
    final oldest = _replay.isEmpty ? _serverSeq + 1 : _replay.first.serverSeq;
    if (params.lastSeenServerSeq + 1 < oldest) {
      return ReconnectSnapshotResult(
        snapshots: [
          for (final channel in known)
            if (_snapshot(channel) case final snapshot?)
              Snapshot.fromJson(snapshot),
        ],
      ).toJson();
    }
    return ReconnectReplayResult(
      actions: [
        for (final e in _replay)
          if (e.serverSeq > params.lastSeenServerSeq &&
              (e.rejectionReason == null
                  ? connection.subscriptions.contains(e.channel)
                  : e.origin?.clientId == params.clientId))
            e,
      ],
      missing: [
        for (final c in params.subscriptions)
          if (!connection.subscriptions.contains(c)) c,
      ],
    ).toJson();
  }

  /// Closes every client connection, as a dropped network would; clients
  /// reconnect (see [refuseConnections] to keep them out for a while).
  Future<void> dropConnections() async {
    final open = _connections.toList();
    _connections.clear();
    await Future.wait([for (final c in open) c.peer.close()]);
  }

  /// Removes [session] and its chats, as if another client or the host
  /// disposed it (`root/sessionRemoved`); a client that had it open finds
  /// it `missing` when it reconnects.
  void removeSession(String session) {
    final chats = _sessionOfChat.entries
        .where((e) => e.value == session)
        .map((e) => e.key)
        .toList();
    for (final chat in chats) {
      _chats.remove(chat);
      _sessionOfChat.remove(chat);
    }
    _sessions.remove(session);
    _summaries.remove(session);
    for (final c in _connections) {
      c.subscriptions
        ..remove(session)
        ..removeAll(chats);
    }
    _notifyRoot('root/sessionRemoved', {'session': session});
  }

  RootState get _root => RootState(
    agents: [
      const AgentInfo(
        provider: fakeProvider,
        displayName: 'Fake agent',
        description: 'Scripted host for tests',
        models: fakeModels,
      ),
      AgentInfo(
        provider: securedProvider,
        displayName: 'Secured agent',
        description: 'Needs a token for the fake agent service',
        models: fakeModels,
        protectedResources: [agentMetadata(_issuer)],
      ),
    ],
    activeSessions: _chats.values.where((c) => c.activeTurn != null).length,
  );

  JsonMap? _snapshot(String channel) {
    final state = channel == rootChannel
        ? _root.toJson()
        : _sessions[channel]?.toJson() ??
              _chats[channel]?.toJson() ??
              _terminals[channel]?.toJson() ??
              _changesetFor(channel)?.toJson() ??
              _canvases[channel]?.toJson();
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
      origin: state.origin,
      movable: state.movable,
      interactivity: state.interactivity,
    );
  }

  void _addSession(
    String session,
    String chat, {
    required String title,
    List<String>? workingDirectories,
    JsonMap? config,
    bool failed = false,
  }) {
    final now = _now();
    final directory = workingDirectories?.firstOrNull;
    final schema = sessionConfigSchema(
      directory == null ? null : 'file://${pathOfUri(directory)}',
      defaultDirectory,
    );
    final values = resolvedConfigValues(schema, config);
    // Like VS Code's host: the repository as the project, the branch in
    // `_meta.git` (a VS Code convention, not part of AHP).
    final inRepo =
        directory != null &&
        inRepository(pathOfUri(directory), defaultDirectory);
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
      lifecycle: failed ? SessionLifecycle.creating : SessionLifecycle.ready,
      config: SessionConfigState(schema: schema, values: values),
      activeClients: const [],
      chats: [_chatSummary(chat)],
      defaultChat: chat,
      changesets: sessionChangesets(session),
      serverTools: const [
        ToolDefinition(
          name: 'bash',
          title: 'Bash',
          description: 'Runs a shell',
        ),
        ToolDefinition(name: 'edit', title: 'Edit', description: 'Edits files'),
      ],
      customizations: const [
        McpServerCustomization(
          id: docsCustomizationId,
          uri: 'file:///workspace/.mcp.json',
          name: 'Example Docs',
          state: McpServerReadyState(),
        ),
        ...fakeCommandCustomizations,
      ],
    );
    _changesets['ahp-changeset:/${changesetKey(session)}/session'] =
        const ChangesetState(
          status: ChangesetStatus.ready,
          files: [],
          operations: changesetOperations,
        );
    if (failed) return;
    _summaries[session] = SessionSummary(
      provider: fakeProvider,
      title: title,
      status: _chats[chat]!.status,
      workingDirectories: workingDirectories,
      project: inRepo
          ? ProjectInfo(
              uri: 'file://$defaultDirectory',
              displayName: defaultDirectory.split('/').last,
            )
          : null,
      meta: inRepo
          ? {'git': gitMeta('${values[branchProperty] ?? 'main'}')}
          : null,
      resource: session,
      createdAt: now,
      modifiedAt: now,
      defaultChat: chat,
    );
  }

  /// The metadata of the protected resource [resource], if the host has
  /// one by that identifier.
  ProtectedResourceMetadata? _protectedResource(String resource) =>
      switch (resource) {
        docsResource => docsMetadata(_issuer),
        agentResource => agentMetadata(_issuer),
        _ => null,
      };

  /// Whether [token] is good for [resource]: [fakePersonalToken] or an
  /// unexpired token from [oauthServer], and not expired by the `expire`
  /// flow.
  bool _tokenValid(String? token, String resource) =>
      token != null &&
      !_expiredTokens.contains(token) &&
      (token == fakePersonalToken ||
          (_issuer != null && oauthServer.accepts(token, resource)));

  RpcException _authRequired(ProtectedResourceMetadata resource) =>
      RpcException(
        AhpErrorCodes.authRequired,
        'Sign in to ${resource.resourceName ?? resource.resource}',
        data: AuthRequiredErrorData(resources: [resource]).toJson(),
      );

  /// `authenticate`: an empty token signs [connection] out of the
  /// resource; a valid one is kept for the connection and recorded as
  /// `#authenticate`; anything else is `-32007`.
  void _authenticate(_Connection connection, AuthenticateParams params) {
    final resource = _protectedResource(params.resource);
    if (resource == null) {
      throw RpcException(
        error_code.INVALID_PARAMS,
        'unknown resource ${params.resource}',
      );
    }
    if (params.token.isEmpty) {
      connection.tokens.remove(params.resource);
      _record((
        channel: '*',
        action: {'type': '#revoke', 'resource': params.resource},
      ));
      return;
    }
    if (!_tokenValid(params.token, params.resource)) {
      throw _authRequired(resource);
    }
    connection.tokens[params.resource] = params.token;
    _record((
      channel: '*',
      action: {
        'type': '#authenticate',
        'resource': params.resource,
        'token': params.token,
        'expiresIn': ?params.expiresIn,
        'scopes': ?params.scopes,
        'clientId': ?connection.clientId,
      },
    ));
  }

  void _createSession(_Connection connection, JsonMap json) {
    final params = CreateSessionParams.fromJson(json);
    if (params.provider == securedProvider &&
        !_tokenValid(connection.tokens[agentResource], agentResource)) {
      throw _authRequired(agentMetadata(_issuer));
    }
    final session = params.channel;
    if (_sessions.containsKey(session)) {
      throw RpcException(AhpErrorCodes.sessionAlreadyExists, 'exists');
    }
    final id = session.split('/').last;
    final missing = [
      for (final d in params.workingDirectories ?? const <String>[])
        if (!directories.contains(pathOfUri(d))) d,
    ];
    _addSession(
      session,
      'ahp-chat:/$id',
      title: 'New session',
      workingDirectories: params.workingDirectories,
      config: params.config,
      failed: missing.isNotEmpty,
    );
    if (missing.isNotEmpty) {
      // Like pi: the request succeeds, the backend fails a moment later,
      // and the session is never listed.
      _later(() {
        _emit(
          session,
          SessionCreationFailedAction(
            error: ErrorInfo(
              errorType: 'creationFailed',
              message: 'No such folder: ${pathOfUri(missing.first)}',
            ),
          ).toJson(),
        );
      });
      return;
    }
    _notifyRoot('root/sessionAdded', {
      'channel': rootChannel,
      'summary': _summaries[session]!.toJson(),
    });
  }

  /// Runs [callback] after [stepDelay] unless the host closes first.
  void _later(void Function() callback) {
    late final Timer timer;
    timer = Timer(stepDelay, () {
      _timers.remove(timer);
      callback();
    });
    _timers.add(timer);
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
    _replay.add(ActionEnvelope.fromJson(envelope));
    if (_replay.length > replayLimit) _replay.removeAt(0);
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
    } else if (_terminals[channel] case final state?) {
      _terminals[channel] = reduceTerminalJson(state, action);
    } else if (_changesetFor(channel) case final state?) {
      _changesets[channel] = reduceChangesetJson(state, action);
    } else if (_canvases[channel] case final state?) {
      _canvases[channel] = reduceCanvasJson(state, action);
    }
  }

  bool _known(String channel) =>
      _sessions.containsKey(channel) ||
      _chats.containsKey(channel) ||
      _terminals.containsKey(channel) ||
      _changesetFor(channel) != null ||
      _canvases.containsKey(channel);

  /// The changeset at [uri]; a turn changeset of a known session that has
  /// no edits yet is created empty on demand.
  ChangesetState? _changesetFor(String uri) {
    if (_changesets[uri] case final state?) return state;
    final match = RegExp(r'^ahp-changeset:/([^/]+)/turn/[^/]+$')
        .firstMatch(uri);
    if (match == null) return null;
    final key = match.group(1)!;
    if (!_sessions.keys.any((s) => changesetKey(s) == key)) return null;
    return _changesets[uri] = const ChangesetState(
      status: ChangesetStatus.ready,
      files: [],
    );
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
    final old = _summaries[session];
    if (old == null) return;
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
        : !_known(channel)
        ? 'unknown channel $channel'
        : type == 'chat/turnStarted' && _chats[channel]!.activeTurn != null
        ? 'a turn is already running'
        : type == 'session/configChanged'
        ? _configRejection(channel, action)
        : rejectTypes.contains(type)
        ? '$type is refused by this test host'
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
      if (from.clientId case final clientId?) {
        _turnClients[started.turnId] = clientId;
      }
      unawaited(_runTurn(channel, started.turnId, started.message.text));
    }
  }

  /// Why a `session/configChanged` on [session] is refused: only settings
  /// the schema marks `sessionMutable` may change.
  String? _configRejection(String session, JsonMap action) {
    final schema = _sessions[session]?.config?.schema;
    if (schema == null) return 'the session has no settings';
    final keys = (action['config'] as JsonMap? ?? const {}).keys;
    final fixed = [
      for (final key in keys)
        if (schema.properties[key]?.sessionMutable != true) key,
    ];
    return fixed.isEmpty ? null : 'cannot change ${fixed.join(', ')}';
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
        Scenario.shell => _shellFlow(chat, turnId),
        Scenario.read => _readFlow(chat, turnId),
        Scenario.subagent => _subagentFlow(chat, turnId),
        Scenario.canvas => _canvasFlow(chat, turnId),
        Scenario.code => _codeFlow(chat, turnId),
        Scenario.slow => _slowFlow(chat, turnId),
        Scenario.cd => _cdFlow(chat, turnId),
        Scenario.settings => _settingsFlow(chat, turnId),
        Scenario.client => _clientToolFlow(chat, turnId, otherClientId),
        Scenario.delegate => _clientToolFlow(
          chat,
          turnId,
          _turnClients[turnId] ?? otherClientId,
        ),
        Scenario.todo => _todoFlow(chat, turnId),
        Scenario.plan => _planFlow(chat, turnId),
        Scenario.pr => _pullRequestFlow(chat, turnId),
        Scenario.expire => _expireFlow(chat, turnId),
        Scenario.choose => _chooseFlow(chat, turnId),
        Scenario.command => _commandFlow(chat, turnId),
        Scenario.result => _resultFlow(chat, turnId),
        Scenario.draft => _draftFlow(chat, turnId),
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
      origin: ChatOriginSideChat(chat: chat, turnId: turnId),
      movable: true,
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

  /// A tool call ([clientId]'s `open_browser`) that the host delegates to
  /// a client: it runs, listed as a `toolClientExecution` entry. The
  /// other client ([otherClientId]) completes it after a few steps; any
  /// other client is waited for.
  Future<bool> _clientToolFlow(
    String chat,
    String turnId,
    String clientId,
  ) async {
    final id = _nextId('browser');
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: 'open_browser',
        displayName: 'Open browser',
        contributor: ToolCallClientContributor(clientId: clientId),
      ).toJson(),
    );
    _emit(
      chat,
      ChatToolCallReadyAction(
        turnId: turnId,
        toolCallId: id,
        invocationMessage: const PlainString('Open the preview'),
        toolInput: const InlineToolInput('{"url":"http://localhost:3000"}'),
        confirmed: ToolCallConfirmationReason.notNeeded,
      ).toJson(),
    );
    final running = _toolCall<ToolCallRunningState>(chat, id)!;
    final entryId = 'client-$id';
    _setInputNeeded(
      chat,
      SessionToolClientExecutionRequest(
        id: entryId,
        chat: chat,
        turnId: turnId,
        clientId: clientId,
        toolCall: running,
      ),
    );
    _say(chat, turnId, 'Waiting for $clientId to open the preview.');
    final JsonMap? result;
    if (clientId == otherClientId) {
      for (var i = 0; i < 5; i++) {
        if (!await _step(chat, turnId)) {
          _removeInputNeeded(chat, entryId);
          return false;
        }
      }
      result = ChatToolCallCompleteAction(
        turnId: turnId,
        toolCallId: id,
        result: const ToolCallResult(
          success: true,
          pastTenseMessage: PlainString('Opened the preview'),
        ),
      ).toJson();
      _emit(chat, result);
    } else {
      result = await _waitFor(
        chat,
        turnId,
        (a) => a['type'] == 'chat/toolCallComplete' && a['toolCallId'] == id,
      );
    }
    _removeInputNeeded(chat, entryId);
    if (result == null || !await _step(chat, turnId)) return false;
    final outcome = ChatToolCallCompleteAction.fromJson(result).result;
    _say(
      chat,
      turnId,
      outcome.success
          ? '$clientId opened the preview.'
          : '$clientId could not open the preview: '
                '${outcome.error?.message ?? 'failed'}',
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
    final auth = docsAuth(_issuer);
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

  /// The connection of the client that started turn [turnId].
  _Connection? _turnConnection(String turnId) {
    final clientId = _turnClients[turnId];
    return _connections.where((c) => c.clientId == clientId).firstOrNull;
  }

  Future<bool> _expireFlow(String chat, String turnId) async {
    final connection = _turnConnection(turnId);
    final token = connection?.tokens.remove(docsResource);
    if (connection == null || token == null) {
      _say(chat, turnId, 'You are not signed in to Example Docs.');
      return true;
    }
    _expiredTokens.add(token);
    oauthServer.expire(token);
    connection.peer.sendNotification(
      'auth/required',
      AuthRequiredParams(
        channel: _sessionOfChat[chat]!,
        resource: docsMetadata(_issuer),
        reason: AuthRequiredReason.expired,
      ).toJson(),
    );
    _say(chat, turnId, 'Your Example Docs sign-in expired.');
    final renewed = await _waitFor(
      chat,
      turnId,
      (a) => a['type'] == '#authenticate' && a['resource'] == docsResource,
    );
    if (renewed == null || !await _step(chat, turnId)) return false;
    _say(chat, turnId, 'Signed in to Example Docs again.');
    return true;
  }

  /// Starts a `bash` call [id] and asks for confirmation with [ready],
  /// listed in `inputNeeded`; returns the answer (null when the turn
  /// ended), with the entry removed.
  Future<JsonMap?> _confirm(
    String chat,
    String turnId,
    String id,
    ChatToolCallReadyAction ready, {
    Future<void> Function(String requestId)? whileWaiting,
  }) async {
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: 'bash',
        displayName: 'Bash',
      ).toJson(),
    );
    _emit(chat, ready.toJson());
    final requestId = 'confirm-$id';
    _setInputNeeded(
      chat,
      SessionToolConfirmationRequest(
        id: requestId,
        chat: chat,
        turnId: turnId,
        toolCall: _toolCall<ToolCallPendingConfirmationState>(chat, id)!,
      ),
    );
    final answer = _waitFor(
      chat,
      turnId,
      (a) => a['type'] == 'chat/toolCallConfirmed' && a['toolCallId'] == id,
    );
    await whileWaiting?.call(requestId);
    final result = await answer;
    _removeInputNeeded(chat, requestId);
    return result;
  }

  Future<bool> _chooseFlow(String chat, String turnId) async {
    final id = _nextId('bash');
    _say(chat, turnId, 'The build folder is stale; I want to delete it.');
    final answer = await _confirm(
      chat,
      turnId,
      id,
      chooseReady(
        turnId,
        id,
        const ToolCallRiskAssessmentLoadingState(
          kind: ToolCallRiskAssessmentKind.judge,
        ),
      ),
      whileWaiting: (requestId) async {
        // The judge finishes while the user looks at the prompt.
        if (!await _step(chat, turnId)) return;
        if (_toolCall<ToolCallPendingConfirmationState>(chat, id) == null) {
          return;
        }
        _emit(chat, chooseReady(turnId, id, chooseRisk).toJson());
        _setInputNeeded(
          chat,
          SessionToolConfirmationRequest(
            id: requestId,
            chat: chat,
            turnId: turnId,
            toolCall: _toolCall<ToolCallPendingConfirmationState>(chat, id)!,
          ),
        );
      },
    );
    if (answer == null || !await _step(chat, turnId)) return false;
    final action = ChatToolCallConfirmedAction.fromJson(answer);
    if (action is ChatToolCallApprovedAction) {
      _emit(
        chat,
        ChatToolCallCompleteAction(
          turnId: turnId,
          toolCallId: id,
          result: const ToolCallResult(
            success: true,
            pastTenseMessage: PlainString('Ran `rm -rf build`'),
          ),
        ).toJson(),
      );
    }
    _say(chat, turnId, chooseReply(action));
    return true;
  }

  Future<bool> _commandFlow(String chat, String turnId) async {
    final id = _nextId('bash');
    final answer = await _confirm(chat, turnId, id, commandReady(turnId, id));
    if (answer == null || !await _step(chat, turnId)) return false;
    final action = ChatToolCallConfirmedAction.fromJson(answer);
    if (action is! ChatToolCallApprovedAction) {
      _say(chat, turnId, 'OK, I did not push.');
      return true;
    }
    // The reducer already applied an edited inline input.
    final input = switch (_toolCall<ToolCallRunningState>(
      chat,
      id,
    )?.toolInput) {
      InlineToolInput(:final value) => value,
      _ => action.editedToolInput ?? '',
    };
    final command = commandOf(input);
    _emit(
      chat,
      ChatToolCallCompleteAction(
        turnId: turnId,
        toolCallId: id,
        result: ToolCallResult(
          success: true,
          pastTenseMessage: PlainString('Ran `$command`'),
        ),
      ).toJson(),
    );
    _say(
      chat,
      turnId,
      action.editedToolInput == null
          ? 'Ran `$command` as proposed.'
          : 'Ran your edited command: `$command`.',
    );
    return true;
  }

  Future<bool> _resultFlow(String chat, String turnId) async {
    final id = _nextId('fetch');
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: 'fetch',
        displayName: 'Fetch',
      ).toJson(),
    );
    _emit(
      chat,
      ChatToolCallReadyAction(
        turnId: turnId,
        toolCallId: id,
        invocationMessage: const PlainString('Fetch the status page'),
        toolInput: const InlineToolInput(
          '{"url":"https://status.example.com"}',
        ),
        confirmed: ToolCallConfirmationReason.notNeeded,
      ).toJson(),
    );
    if (!await _step(chat, turnId)) return false;
    _emit(
      chat,
      ChatToolCallCompleteAction(
        turnId: turnId,
        toolCallId: id,
        result: fetchResult,
        requiresResultConfirmation: true,
      ).toJson(),
    );
    final requestId = 'result-$id';
    _setInputNeeded(
      chat,
      SessionToolConfirmationRequest(
        id: requestId,
        chat: chat,
        turnId: turnId,
        toolCall: _toolCall<ToolCallPendingResultConfirmationState>(chat, id)!,
      ),
    );
    final answer = await _waitFor(
      chat,
      turnId,
      (a) =>
          a['type'] == 'chat/toolCallResultConfirmed' && a['toolCallId'] == id,
    );
    _removeInputNeeded(chat, requestId);
    if (answer == null || !await _step(chat, turnId)) return false;
    _say(
      chat,
      turnId,
      answer['approved'] == true
          ? 'Using the result: all systems are operational.'
          : 'I discarded the fetched page.',
    );
    return true;
  }

  Future<bool> _draftFlow(String chat, String turnId) async {
    final request = releaseNotesRequest(_nextId('input'));
    _emit(chat, ChatInputRequestedAction(request: request).toJson());
    final entryId = 'input-${request.id}';
    _setInputNeeded(
      chat,
      SessionChatInputRequest(id: entryId, chat: chat, request: request),
    );
    final answer = _waitFor(
      chat,
      turnId,
      (a) => a['type'] == 'chat/inputCompleted' && a['requestId'] == request.id,
    );
    // Another client starts on the notes.
    if (await _step(chat, turnId)) {
      _emit(chat, otherClientDraftAction(request.id).toJson());
    }
    final completed = await answer;
    _removeInputNeeded(chat, entryId);
    if (completed == null || !await _step(chat, turnId)) return false;
    final drafts = _log
        .where(
          (r) =>
              r.channel == chat &&
              r.action['type'] == 'chat/inputAnswerChanged' &&
              r.action['requestId'] == request.id,
        )
        .length;
    _say(
      chat,
      turnId,
      '${answerReply(ChatInputCompletedAction.fromJson(completed))} '
      'Drafts synced: $drafts.',
    );
    return true;
  }

  Future<bool> _backgroundFlow(String chat, String turnId) async {
    final id = _nextId('shell');
    final terminal = 'ahp-terminal:/$id';
    const command = 'npm test -- --watch';
    _terminals[terminal] = TerminalState(
      title: command,
      content: const [],
      lifecycle: const TerminalRunningLifecycleState(),
      claim: TerminalSessionClaim(session: _sessionOfChat[chat]!, chat: chat),
      isPty: false,
    );
    _emit(
      chat,
      ChatBackgroundWorkSetAction(
        work: BackgroundShellWork(
          id: id,
          label: command,
          startedAt: _now(),
          command: command,
          terminal: terminal,
        ),
      ).toJson(),
    );
    _emit(
      terminal,
      const TerminalDataAction(data: 'Watching for changes…\n').toJson(),
    );
    _say(chat, turnId, 'The tests keep running in the background.');
    var runs = 0;
    late final Timer ticker;
    ticker = Timer.periodic(stepDelay * 5, (_) {
      _emit(
        terminal,
        TerminalDataAction(data: 'Run ${++runs}: 3 tests passed\n').toJson(),
      );
    });
    _timers.add(ticker);
    late final Timer timer;
    timer = Timer(backgroundDuration, () {
      _timers
        ..remove(timer)
        ..remove(ticker);
      ticker.cancel();
      _emit(terminal, const TerminalExitedAction(exitCode: 0).toJson());
      _emit(chat, ChatBackgroundWorkRemovedAction(id: id).toJson());
    });
    _timers.add(timer);
    return true;
  }

  /// Emits a completed tool call [toolName] with [result] (no approval).
  Future<bool> _toolRun(
    String chat,
    String turnId, {
    required String id,
    required String toolName,
    required String displayName,
    required String invocation,
    required String input,
    required ToolCallResult result,
    List<ToolResultContent>? liveContent,
    Future<bool> Function()? whileRunning,
  }) async {
    _emit(
      chat,
      ChatToolCallStartAction(
        turnId: turnId,
        toolCallId: id,
        toolName: toolName,
        displayName: displayName,
      ).toJson(),
    );
    _emit(
      chat,
      ChatToolCallReadyAction(
        turnId: turnId,
        toolCallId: id,
        invocationMessage: PlainString(invocation),
        toolInput: InlineToolInput(input),
        confirmed: ToolCallConfirmationReason.notNeeded,
      ).toJson(),
    );
    if (liveContent != null) {
      _emit(
        chat,
        ChatToolCallContentChangedAction(
          turnId: turnId,
          toolCallId: id,
          content: liveContent,
        ).toJson(),
      );
    }
    if (whileRunning != null && !await whileRunning()) return false;
    if (!await _step(chat, turnId)) return false;
    _emit(
      chat,
      ChatToolCallCompleteAction(
        turnId: turnId,
        toolCallId: id,
        result: result,
      ).toJson(),
    );
    return true;
  }

  Future<bool> _editFlow(String chat, String turnId) async {
    final id = _nextId('edit');
    final session = _sessionOfChat[chat]!;
    final file = readmeUri(defaultDirectory);
    final before = FileEditSide(
      uri: file,
      content: ContentRef(uri: 'ahp-content:/$id/before'),
    );
    final after = FileEditSide(
      uri: file,
      content: ContentRef(uri: 'ahp-content:/$id/after'),
    );
    _contents[before.content.uri] = readmeBefore;
    _contents[after.content.uri] = readmeAfter;
    const stats = FileEditDiffStats(added: 3, removed: 1);
    final ran = await _toolRun(
      chat,
      turnId,
      id: id,
      toolName: 'edit',
      displayName: 'Edit',
      invocation: 'Edit README.md',
      input: '{"path":"README.md"}',
      result: ToolCallResult(
        success: true,
        pastTenseMessage: const PlainString('Edited README.md'),
        content: [
          ToolResultFileEditContent(before: before, after: after, diff: stats),
        ],
      ),
    );
    if (!ran) return false;
    // The session changeset (and this turn's) now list the file.
    final changed = ChangesetFile(
      id: file,
      edit: FileEdit(before: before, after: after, diff: stats),
    );
    final key = changesetKey(session);
    for (final uri in [
      'ahp-changeset:/$key/session',
      'ahp-changeset:/$key/turn/$turnId',
    ]) {
      _changesetFor(uri);
      _emit(uri, ChangesetFileSetAction(file: changed).toJson());
    }
    _summaries[session] = _summaries[session]!.copyWith(changes: editChanges);
    _notifyRoot('root/sessionSummaryChanged', {
      'channel': rootChannel,
      'session': session,
      'changes': {'changes': editChanges.toJson()},
    });
    _say(chat, turnId, 'Edited README.md.');
    return true;
  }

  Future<bool> _shellFlow(String chat, String turnId) async {
    final id = _nextId('bash');
    final terminal = 'ahp-terminal:/$id';
    _terminals[terminal] = TerminalState(
      title: 'npm test',
      cwd: 'file://$defaultDirectory',
      content: const [],
      lifecycle: const TerminalRunningLifecycleState(),
      claim: TerminalSessionClaim(
        session: _sessionOfChat[chat]!,
        chat: chat,
        turnId: turnId,
        toolCallId: id,
      ),
      supportsCommandDetection: true,
      isPty: false,
    );
    final started = DateTime.now();
    final ran = await _toolRun(
      chat,
      turnId,
      id: id,
      toolName: 'bash',
      displayName: 'Bash',
      invocation: 'Run `npm test`',
      input: '{"command":"npm test"}',
      liveContent: [
        ToolResultTerminalContent(
          resource: terminal,
          title: 'npm test',
          isPty: false,
        ),
      ],
      whileRunning: () async {
        _emit(
          terminal,
          TerminalCommandExecutedAction(
            commandId: 'c1',
            commandLine: 'npm test',
            timestamp: started.millisecondsSinceEpoch,
          ).toJson(),
        );
        for (final line in shellOutput) {
          if (!await _step(chat, turnId)) return false;
          _emit(terminal, TerminalDataAction(data: '$line\n').toJson());
        }
        final duration = DateTime.now().difference(started).inMilliseconds;
        _emit(
          terminal,
          TerminalCommandFinishedAction(
            commandId: 'c1',
            exitCode: 0,
            durationMs: duration,
          ).toJson(),
        );
        _emit(terminal, const TerminalExitedAction(exitCode: 0).toJson());
        return true;
      },
      result: ToolCallResult(
        success: true,
        pastTenseMessage: const PlainString('Ran `npm test`'),
        content: [
          ToolResultTerminalContent(
            resource: terminal,
            title: 'npm test',
            isPty: false,
            result: TerminalCommandResult(
              exitCode: 0,
              preview: '${shellOutput.join('\n')}\n',
            ),
          ),
        ],
      ),
    );
    if (!ran) return false;
    _say(chat, turnId, 'All 3 tests passed.');
    return true;
  }

  Future<bool> _todoFlow(String chat, String turnId) async {
    final inputs = todoInputs();
    for (final input in inputs) {
      final ran = await _toolRun(
        chat,
        turnId,
        id: _nextId('todo'),
        toolName: 'TodoWrite',
        displayName: 'Update todo list',
        invocation: 'Update todo list',
        input: input,
        result: const ToolCallResult(
          success: true,
          pastTenseMessage: PlainString('Updated todo list'),
        ),
      );
      if (!ran) return false;
      if (input != inputs.last) {
        _say(chat, turnId, 'Working on the next step.');
        if (!await _step(chat, turnId)) return false;
      }
    }
    _say(chat, turnId, 'All 3 steps are done.');
    return true;
  }

  Future<bool> _planFlow(String chat, String turnId) async {
    _say(chat, turnId, planMarkdown);
    if (!await _step(chat, turnId)) return false;
    final request = planReviewRequest(_nextId('input'));
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

  Future<bool> _pullRequestFlow(String chat, String turnId) async {
    final session = _sessionOfChat[chat]!;
    final summary = _summaries[session]!;
    final meta = withPullRequestMeta({
      ...?summary.meta,
      if (summary.meta?['git'] == null) 'git': gitMeta('main'),
    });
    _emit(session, SessionMetaChangedAction(meta: meta).toJson());
    _summaries[session] = summary.copyWith(meta: meta);
    _notifyRoot('root/sessionSummaryChanged', {
      'channel': rootChannel,
      'session': session,
      'changes': {'_meta': meta},
    });
    _say(chat, turnId, 'Opened pull request #42: $fakePullRequestUrl');
    return true;
  }

  Future<bool> _readFlow(String chat, String turnId) async {
    for (final path in readFiles) {
      final ran = await _toolRun(
        chat,
        turnId,
        id: _nextId('read'),
        toolName: 'read',
        displayName: 'Read',
        invocation: 'Read $path',
        input: '{"path":"$path"}',
        result: ToolCallResult(
          success: true,
          pastTenseMessage: PlainString('Read $path'),
          content: [ToolResultTextContent(text: '// $path\n')],
        ),
      );
      if (!ran) return false;
    }
    _say(chat, turnId, 'I read ${readFiles.length} files.');
    return true;
  }

  Future<bool> _subagentFlow(String chat, String turnId) async {
    final session = _sessionOfChat[chat]!;
    final id = _nextId('task');
    final worker = '$chat-explorer-${++_ids}';
    _chats[worker] = ChatState(
      resource: worker,
      title: 'Explorer',
      status: SessionStatus.idle,
      modifiedAt: _now(),
      turns: const [],
      origin: ChatOriginTool(chat: chat, toolCallId: id),
      interactivity: ChatInteractivity.readOnly,
      movable: true,
    );
    _sessionOfChat[worker] = session;
    _emit(
      session,
      SessionChatAddedAction(summary: _chatSummary(worker)).toJson(),
    );
    final link = ToolResultSubagentContent(
      resource: worker,
      title: 'Explorer',
      agentName: 'explorer',
      description: 'Explore the repository',
    );
    final ran = await _toolRun(
      chat,
      turnId,
      id: id,
      toolName: 'task',
      displayName: 'Task',
      invocation: 'Delegate to the explorer',
      input: '{"agent":"explorer"}',
      liveContent: [link],
      whileRunning: () async {
        _emit(
          chat,
          ChatBackgroundWorkSetAction(
            work: BackgroundSubagentWork(
              id: id,
              label: 'Explorer',
              startedAt: _now(),
              chat: worker,
            ),
          ).toJson(),
        );
        final workerTurn = _nextId('turn');
        _emit(
          worker,
          ChatTurnStartedAction(
            turnId: workerTurn,
            startedAt: _now(),
            message: const Message(
              text: 'Explore the repository',
              origin: MessageOrigin(kind: MessageKind.agent),
            ),
          ).toJson(),
        );
        if (!await _step(chat, turnId)) return false;
        _say(worker, workerTurn, 'Found 3 modules: api, core and ui.');
        if (!await _step(chat, turnId)) return false;
        _endTurn(worker, workerTurn);
        _emit(chat, ChatBackgroundWorkRemovedAction(id: id).toJson());
        return true;
      },
      result: ToolCallResult(
        success: true,
        pastTenseMessage: const PlainString('The explorer finished'),
        content: [link],
      ),
    );
    if (!ran) return false;
    _say(chat, turnId, 'The explorer found 3 modules.');
    return true;
  }

  Future<bool> _canvasFlow(String chat, String turnId) async {
    final canvas = 'ahp-canvas:/${_nextId('canvas')}';
    _canvases[canvas] = CanvasState(
      instanceId: canvas,
      extensionId: 'fake.preview',
      extensionName: 'Fake preview',
      canvasId: 'web',
      title: 'App preview',
      status: 'Running',
      url: 'http://127.0.0.1:8080/',
    );
    _emit(
      chat,
      ChatCanvasesChangedAction(
        canvases: [
          ...?_chats[chat]!.canvases,
          CanvasReference(resource: canvas),
        ],
      ).toJson(),
    );
    _say(chat, turnId, 'I opened a preview canvas.');
    return true;
  }

  Future<bool> _codeFlow(String chat, String turnId) async {
    _say(chat, turnId, codeReply);
    return true;
  }

  Future<bool> _slowFlow(String chat, String turnId) async {
    final part = _nextId('md');
    _emit(
      chat,
      ChatResponsePartAction(
        turnId: turnId,
        part: MarkdownResponsePart(id: part, content: ''),
      ).toJson(),
    );
    for (final word in ['Working', ' on', ' it', ' slowly.']) {
      if (!await _step(chat, turnId)) return false;
      _emit(
        chat,
        ChatDeltaAction(turnId: turnId, partId: part, content: word).toJson(),
      );
    }
    final until = DateTime.now().add(slowDuration);
    while (DateTime.now().isBefore(until)) {
      if (!await _step(chat, turnId)) return false;
    }
    return true;
  }

  Future<bool> _settingsFlow(String chat, String turnId) async {
    final model = _chats[chat]?.activeTurn?.message.model;
    final config = _sessions[_sessionOfChat[chat]]?.config?.values;
    _say(chat, turnId, settingsReply(model, config));
    return true;
  }

  Future<bool> _cdFlow(String chat, String turnId) async {
    final directory = 'file://$defaultDirectory/packages/api';
    _emit(
      _sessionOfChat[chat]!,
      SessionWorkingDirectorySetAction(directory: directory).toJson(),
    );
    _emit(chat, ChatWorkingDirectorySetAction(directory: directory).toJson());
    _say(chat, turnId, 'Now also working in packages/api.');
    return true;
  }

  // ── Commands ─────────────────────────────────────────────────────────

  /// The `turnsNextCursor` for a chat with [archived] older turns left.
  String? _cursorFor(List<Turn> archived) =>
      archived.isEmpty ? null : 'before-${archived.length}';

  /// Loads the next page of [params]' chat's archived turns into its state
  /// (`chat/turnsLoaded`) before `fetchTurns` answers.
  void _fetchTurns(FetchTurnsParams params) {
    final chat = params.channel;
    final archived = _archive[chat] ?? const <Turn>[];
    final cursor = params.cursor;
    if (cursor != null && cursor != _cursorFor(archived)) {
      throw RpcException(error_code.INVALID_PARAMS, 'unknown cursor');
    }
    if (archived.isEmpty || !_chats.containsKey(chat)) return;
    final split = archived.length > turnWindow
        ? archived.length - turnWindow
        : 0;
    final page = archived.sublist(split);
    _archive[chat] = archived.sublist(0, split);
    _emit(
      chat,
      ChatTurnsLoadedAction(
        turns: page,
        turnsNextCursor: _cursorFor(_archive[chat]!),
      ).toJson(),
    );
  }

  Future<JsonMap> _invokeOperation(
    InvokeChangesetOperationParams params,
  ) async {
    final uri = params.channel;
    final state = _changesetFor(uri);
    if (state == null) {
      throw RpcException(AhpErrorCodes.notFound, 'no changeset $uri');
    }
    _record((
      channel: uri,
      action: {'type': '#invoke', 'operationId': params.operationId},
    ));
    void status(ChangesetOperationStatus status) => _emit(
      uri,
      ChangesetOperationStatusChangedAction(
        operationId: params.operationId,
        status: status,
      ).toJson(),
    );
    switch ((params.operationId, params.target)) {
      case ('commit', null):
        final count = state.files.length;
        status(ChangesetOperationStatus.running);
        await Future<void>.delayed(stepDelay);
        _emit(uri, const ChangesetClearedAction().toJson());
        status(ChangesetOperationStatus.idle);
        return InvokeChangesetOperationResult(
          message: PlainString(
            'Committed $count file${count == 1 ? '' : 's'}.',
          ),
        ).toJson();
      case ('revert', ChangesetOperationTargetResource(:final resource)):
        final file = state.files.where((f) => f.id == resource).firstOrNull;
        if (file == null) {
          throw RpcException(error_code.INVALID_PARAMS, 'no file $resource');
        }
        _emit(uri, ChangesetFileRemovedAction(fileId: file.id).toJson());
        return InvokeChangesetOperationResult(
          message: PlainString('Reverted ${resource.split('/').last}.'),
        ).toJson();
      default:
        throw RpcException(
          error_code.INVALID_PARAMS,
          'cannot run ${params.operationId} on that target',
        );
    }
  }

  /// Reorders a movable chat within its session (moving to another
  /// session is not scripted).
  JsonMap _moveChat(MoveChatParams params) {
    final chat = params.channel;
    final session = _sessionOfChat[chat];
    final state = session == null ? null : _sessions[session];
    if (state == null || !(_chats[chat]?.movable ?? false)) {
      throw RpcException(error_code.INVALID_PARAMS, '$chat is not movable');
    }
    final ChatMoveToSessionDestination(:after) = switch (params.destination) {
      final ChatMoveToSessionDestination d when d.session == session => d,
      _ => throw RpcException(
        error_code.INVALID_PARAMS,
        'only moves within the session are scripted',
      ),
    };
    final order = [
      for (final c in state.chats)
        if (c.resource != chat) c.resource,
    ];
    if (after != null && !order.contains(after)) {
      throw RpcException(error_code.INVALID_PARAMS, 'unknown anchor $after');
    }
    order.insert(after == null ? 0 : order.indexOf(after) + 1, chat);
    _emit(session!, SessionChatsReorderedAction(chats: order).toJson());
    return MoveChatResult(session: session).toJson();
  }
}
