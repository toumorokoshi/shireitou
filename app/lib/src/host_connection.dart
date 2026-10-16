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
  final _rejections = StreamController<String>.broadcast();

  @override
  HostState build() {
    ref.onDispose(_dispose);
    return const HostState();
  }

  /// Reasons the host gave for rejecting this client's actions (AHP-022).
  Stream<String> get rejections => _rejections.stream;

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
    client.actions
        .where(
          (e) =>
              e.rejectionReason != null &&
              e.origin?.clientId == client.clientId,
        )
        .listen((e) => _rejections.add(e.rejectionReason!));
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

  /// Dispatches a client action on [channel] (write-ahead, AHP-022).
  void dispatch(String channel, JsonMap action) =>
      _connected.dispatch(channel, action);

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
        ChatAction.turnStarted(
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
    await _client?.close();
    _client = null;
  }
}
