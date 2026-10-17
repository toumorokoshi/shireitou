import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';

/// The `clientId` of every [FakeHostConnection].
const testClientId = 'test-client';

/// The host the fake connections stand for.
const testHost = SavedHost(url: 'ws://127.0.0.1:1', name: 'test host');

/// Overrides that make [connections] (by host) the app's hosts, open
/// when their state is connected or reconnecting. One [connection]
/// stands for [testHost].
List<Override> hostOverrides({
  FakeHostConnection? connection,
  Map<SavedHost, FakeHostConnection> connections = const {},
}) {
  final all = {...connections, testHost: ?connection};
  return [
    hostConnectionProvider.overrideWith2(
      (key) =>
          all.entries.where((e) => e.key.key == key).firstOrNull?.value ??
          FakeHostConnection(const HostState(), host: key),
    ),
    openHostsProvider.overrideWith(
      () => _FixedOpenHosts([
        for (final MapEntry(key: host, value: c) in all.entries)
          if (c.initial.status == ConnectionStatus.connected ||
              c.initial.status == ConnectionStatus.reconnecting)
            host,
      ]),
    ),
  ];
}

class _FixedOpenHosts extends OpenHosts {
  _FixedOpenHosts(this.initial);

  final List<SavedHost> initial;

  @override
  List<SavedHost> build() => initial;
}

/// A [HostConnection] with fixed state that records dispatched actions.
/// [connect] adopts [connectResult] (default: [initial]).
class FakeHostConnection extends HostConnection {
  FakeHostConnection(this.initial, {String host = '', this.connectResult})
    : super(host.isEmpty ? testHost.key : host);

  final HostState initial;

  /// The state [connect] ends in.
  final HostState? connectResult;

  /// URLs passed to [connect].
  final connected = <String>[];

  @override
  Future<void> connect(String url, {String? token, String? name}) async {
    connected.add(url);
    state = connectResult ?? initial;
  }

  @override
  Future<void> disconnect() async => state = const HostState();

  /// (channel, action) pairs, in order.
  final dispatched = <(String, JsonMap)>[];

  /// Undone actions to report to the UI.
  final failureController = StreamController<ActionFailure>.broadcast();

  @override
  Stream<ActionFailure> get failures => failureController.stream;

  @override
  HostState build() => initial;

  @override
  Future<String?> openSession(String session) async => 'ahp-chat:/1';

  @override
  void closeSession(String session, String? chat) {}

  /// Returns the action's `clientSeq` (its 1-based position in
  /// [dispatched]).
  @override
  int dispatch(String channel, JsonMap action) {
    dispatched.add((channel, action));
    return dispatched.length;
  }

  @override
  String? get clientId => testClientId;

  /// (resource, token) pairs pushed with `authenticate`.
  final authenticated = <(String, String)>[];

  @override
  Future<void> pushToken(String resource, ResourceToken token) async =>
      authenticated.add((resource, token.token));

  /// Channels passed to [subscribe], in order.
  final subscribed = <String>[];

  @override
  Future<void> subscribe(String channel, ChannelKind kind) async =>
      subscribed.add(channel);

  @override
  void unsubscribe(String channel) {}

  /// Chats [loadOlderTurns] was called for.
  final loadedOlder = <String>[];

  /// The state [loadOlderTurns] moves to, as if the older turns arrived;
  /// null keeps the state.
  HostState? olderState;

  @override
  Future<bool> loadOlderTurns(String chat) async {
    loadedOlder.add(chat);
    final older = olderState;
    if (older == null) return false;
    state = older;
    return true;
  }

  /// Content served by [readResource], by URI.
  final contents = <String, String>{};

  @override
  Future<ResourceReadResult> readResource(String uri) async =>
      ResourceReadResult(
        data: contents[uri] ?? (throw StateError('no content $uri')),
        encoding: ContentEncoding.utf8,
      );

  /// (changeset, operation, target) of each invoked operation.
  final invoked = <(String, String, ChangesetOperationTarget?)>[];

  @override
  Future<InvokeChangesetOperationResult> invokeChangesetOperation(
    String changeset,
    String operationId, {
    ChangesetOperationTarget? target,
  }) async {
    invoked.add((changeset, operationId, target));
    return InvokeChangesetOperationResult(
      message: PlainString('Ran $operationId.'),
    );
  }

  /// (chat, destination) of each move.
  final moved = <(String, ChatMoveDestination)>[];

  @override
  Future<MoveChatResult> moveChat(
    String chat,
    ChatMoveDestination destination,
  ) async {
    moved.add((chat, destination));
    return const MoveChatResult(session: 'pi:/1');
  }

  /// Folders served by [listDirectory], by path.
  final folders = <String, List<String>>{};

  @override
  Future<List<DirectoryEntry>> listDirectory(String uri) async {
    final path = Uri.parse(uri).path;
    final names = folders[path] ?? (throw StateError('not a folder $path'));
    return [
      for (final name in names)
        DirectoryEntry(name: name, type: DirectoryEntryType.directory),
    ];
  }

  /// What [resolveSessionConfig] answers; no settings by default.
  ResolveSessionConfigResult settings = const ResolveSessionConfigResult(
    schema: SessionConfigSchema(properties: {}),
    values: {},
  );

  /// The `config` of each [resolveSessionConfig] call.
  final resolved = <JsonMap?>[];

  @override
  Future<ResolveSessionConfigResult> resolveSessionConfig({
    String? provider,
    String? workingDirectory,
    JsonMap? config,
  }) async {
    resolved.add(config);
    return settings;
  }

  @override
  Future<List<SessionConfigValueItem>> sessionConfigCompletions({
    required String property,
    String? provider,
    String? workingDirectory,
    JsonMap? config,
    String? query,
  }) async => [
    for (final value in const ['main', 'fix/crash'])
      if (value.contains(query ?? ''))
        SessionConfigValueItem(value: value, label: value),
  ];

  /// What [completions] answers.
  List<CompletionItem> completionItems = const [];

  /// The (chat, text, offset) of each [completions] call.
  final completionRequests = <(String, String, int)>[];

  @override
  Future<List<CompletionItem>> completions({
    required String chat,
    required String text,
    required int offset,
  }) async {
    completionRequests.add((chat, text, offset));
    return completionItems;
  }

  /// The arguments of each [startSession] call.
  final started =
      <
        ({
          String provider,
          String directory,
          String prompt,
          List<MessageAttachment> attachments,
          ModelSelection? model,
          JsonMap? config,
        })
      >[];

  /// Thrown by [startSession] when set.
  Object? startError;

  @override
  Future<String> startSession({
    required String provider,
    required String workingDirectory,
    required String prompt,
    List<MessageAttachment> attachments = const [],
    ModelSelection? model,
    JsonMap? config,
  }) async {
    started.add((
      provider: provider,
      directory: workingDirectory,
      prompt: prompt,
      attachments: attachments,
      model: model,
      config: config,
    ));
    if (startError case final error?) throw error;
    // pi:/1, then pi:/2, ... for parallel runs.
    return 'pi:/${started.length}';
  }

  /// The `type`s of the dispatched actions.
  List<Object?> get types => [for (final (_, a) in dispatched) a['type']];
}
