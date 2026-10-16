import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:shireitou/src/host_connection.dart';

/// A [HostConnection] with fixed state that records dispatched actions.
class FakeHostConnection extends HostConnection {
  FakeHostConnection(this.initial);

  final HostState initial;

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

  @override
  void dispatch(String channel, JsonMap action) =>
      dispatched.add((channel, action));

  /// (resource, token) pairs pushed with `authenticate`.
  final authenticated = <(String, String)>[];

  @override
  Future<void> authenticate({
    required String resource,
    required String token,
  }) async => authenticated.add((resource, token));

  /// Channels passed to [subscribe], in order.
  final subscribed = <String>[];

  @override
  Future<void> subscribe(String channel, ChannelKind kind) async =>
      subscribed.add(channel);

  @override
  void unsubscribe(String channel) {}

  /// Chats [loadOlderTurns] was called for.
  final loadedOlder = <String>[];

  @override
  Future<bool> loadOlderTurns(String chat) async {
    loadedOlder.add(chat);
    return false;
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

  /// The `type`s of the dispatched actions.
  List<Object?> get types => [for (final (_, a) in dispatched) a['type']];
}
