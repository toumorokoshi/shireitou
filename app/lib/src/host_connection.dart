/// Riverpod state for the connection to one AHP host.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'hosts/host_store.dart';
import 'hosts/saved_hosts.dart';

/// The connected host's state. Widgets watch this; the [AhpClient] owns the
/// socket and publishes [HostState] changes.
final hostConnectionProvider = NotifierProvider<HostConnection, HostState>(
  HostConnection.new,
);

/// Holds the [AhpClient] for the current host and mirrors its state.
class HostConnection extends Notifier<HostState> {
  AhpClient? _client;
  StreamSubscription<HostState>? _subscription;
  StreamSubscription<ActionFailure>? _failureSubscription;
  final _failures = StreamController<ActionFailure>.broadcast();

  @override
  HostState build() {
    ref.onDispose(_dispose);
    return const HostState();
  }

  /// This client's actions that were undone: rejected by the host, not
  /// confirmed in time, or lost in a reconnect (AHP-022).
  Stream<ActionFailure> get failures => _failures.stream;

  /// Connects to [url], adding [token] as the `tkn` query parameter, and
  /// remembers the host (with its optional [name]) once connected. On
  /// native platforms the token is also sent as an `Authorization: Bearer`
  /// header (AHP-002).
  Future<void> connect(String url, {String? token, String? name}) async {
    await _dispose();
    final client = AhpClient(
      uri: withConnectionToken(Uri.parse(url.trim()), token?.trim()),
      clientInfo: const Implementation(name: 'shireitou', version: '0.1.0'),
    );
    _client = client;
    _subscription = client.states.listen((next) => state = next);
    _failureSubscription = client.failures.listen(_failures.add);
    await client.connect();
    if (client.state.status == ConnectionStatus.connected) {
      await ref
          .read(savedHostsProvider.notifier)
          .remember(
            SavedHost(
              url: url.trim(),
              token: token?.trim() ?? '',
              name: name?.trim() ?? '',
            ),
          );
    }
  }

  /// Closes the connection.
  Future<void> disconnect() async {
    await _dispose();
    state = const HostState();
  }

  /// Subscribes to [session] and its default chat; returns the chat URI.
  Future<String?> openSession(String session) =>
      _connected.openSession(session);

  /// Releases what [openSession] subscribed to.
  void closeSession(String session, String? chat) =>
      _client?.closeSession(session, chat);

  /// Subscribes to [channel], mirrored as [kind] (reference counted,
  /// AHP-020). Pair every call with [unsubscribe].
  Future<void> subscribe(String channel, ChannelKind kind) async {
    await _connected.subscribe(channel, kind: kind);
  }

  /// Releases a [subscribe].
  void unsubscribe(String channel) => _client?.unsubscribe(channel);

  /// Pages older turns into [chat] when the host windowed it (AV-068,
  /// AHP-029). False when there is nothing more to load.
  Future<bool> loadOlderTurns(String chat) => _connected.loadOlderTurns(chat);

  /// Reads a `ContentRef` [uri] (`resourceRead`), for example a side of a
  /// file edit.
  Future<ResourceReadResult> readResource(String uri) =>
      _connected.readResource(uri, encoding: ContentEncoding.utf8);

  /// Runs a host-declared changeset operation (AV-103).
  Future<InvokeChangesetOperationResult> invokeChangesetOperation(
    String changeset,
    String operationId, {
    ChangesetOperationTarget? target,
  }) => _connected.invokeChangesetOperation(
    changeset,
    operationId,
    target: target,
  );

  /// Moves [chat] within its session (`moveChat`, 1.0.0; AV-069).
  Future<MoveChatResult> moveChat(
    String chat,
    ChatMoveDestination destination,
  ) => _connected.moveChat(chat, destination);

  /// Dispatches a client action on [channel] (write-ahead, AHP-022).
  /// Throws [StateError] when not connected or when the negotiated protocol
  /// version does not know the action ([UnsupportedActionError]).
  void dispatch(String channel, JsonMap action) =>
      _connected.dispatch(channel, action);

  /// Pushes a bearer [token] for the protected [resource] (`authenticate`),
  /// for example to resume a tool call waiting on MCP sign-in.
  Future<void> authenticate({
    required String resource,
    required String token,
  }) => _connected.authenticate(resource: resource, token: token);

  /// Creates a session for [provider] in [workingDirectory] and sends
  /// [prompt] as its first turn (AV-040). Returns the session's URI as the
  /// host lists it.
  Future<String> startSession({
    required String provider,
    required String workingDirectory,
    required String prompt,
    ModelSelection? model,
  }) async {
    final client = _connected;
    final session = await client.createSession(
      provider: provider,
      workingDirectories: [workingDirectory],
    );
    final chat = await client.openSession(session);
    if (chat != null) {
      client.dispatch(
        chat,
        ChatTurnStartedAction(
          turnId: const Uuid().v4(),
          startedAt: DateTime.now().toUtc().toIso8601String(),
          message: userMessage(prompt, model: model),
        ).toJson(),
      );
    }
    client.closeSession(session, chat);
    return session;
  }

  AhpClient get _connected =>
      _client ?? (throw StateError('not connected to a host'));

  Future<void> _dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _failureSubscription?.cancel();
    _failureSubscription = null;
    await _client?.close();
    _client = null;
  }
}
