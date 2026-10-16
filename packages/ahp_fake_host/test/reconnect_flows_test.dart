/// Drives [AhpClient]'s reconnect against the scripted fake host over a real
/// WebSocket (AHP-004, AHP-022): a replay of what was missed while the
/// connection was down, snapshots when the host's replay buffer no longer
/// reaches back, channels the host lost (`missing`), an action lost with
/// the socket (rolled back), and a host that forgot the client
/// (`initialize` again).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:test/test.dart';

const _timeout = Duration(seconds: 10);

void main() {
  late FakeAhpHost host;
  late AhpClient client;
  late String chat;

  setUp(() async {
    host = FakeAhpHost(
      token: 'secret',
      stepDelay: const Duration(milliseconds: 100),
      slowDuration: const Duration(seconds: 1),
    );
    final url = await host.start();
    client = AhpClient(uri: url, pingInterval: Duration.zero);
    await client.connect();
    chat = (await client.openSession(seededSession))!;
  });

  tearDown(() async {
    await client.close();
    await host.close();
  });

  Future<HostState> until(bool Function(HostState state) test) async {
    if (test(client.state)) return client.state;
    return client.states.firstWhere(test).timeout(_timeout);
  }

  ChatState chatState() => client.state.chatChannels[chat]!.state;

  String text(List<ResponsePart>? parts) =>
      [...?parts?.whereType<MarkdownResponsePart>().map((p) => p.content)]
          .join();

  void send(String message) => client.dispatch(
    chat,
    ChatTurnStartedAction(
      turnId: 'turn-$message',
      startedAt: DateTime.now().toUtc().toIso8601String(),
      message: userMessage(message),
    ).toJson(),
  );

  /// Drops the connection and keeps the client out until [whileDown] is
  /// done, then waits until it is back.
  Future<void> outage([FutureOr<void> Function()? whileDown]) async {
    host.refuseConnections = true;
    await host.dropConnections();
    await until((s) => s.status == ConnectionStatus.reconnecting);
    await whileDown?.call();
    host.refuseConnections = false;
    await until((s) => s.status == ConnectionStatus.connected);
  }

  test('a turn that streamed while the client was away is replayed', () async {
    send('slow');
    await until(
      (s) => text(s.chatChannels[chat]!.state.activeTurn?.responseParts) != '',
    );
    final seq = client.state.serverSeq;
    await outage(() => Future<void>.delayed(const Duration(milliseconds: 600)));

    expect(client.state.missingChannels, isEmpty);
    expect(client.state.serverSeq, greaterThan(seq));
    final s = await until((s) => s.chatChannels[chat]!.state.turns.isNotEmpty);
    expect(
      text(s.chatChannels[chat]!.state.turns.single.responseParts),
      'Working on it slowly.',
    );
  });

  test('a client too far behind gets snapshots instead', () async {
    // No replay buffer: any missed action means snapshots.
    host.replayLimit = 0;
    send('slow');
    await until(
      (s) => text(s.chatChannels[chat]!.state.activeTurn?.responseParts) != '',
    );
    await outage(() => Future<void>.delayed(const Duration(milliseconds: 600)));

    expect(client.state.missingChannels, isEmpty);
    expect(
      text(
        chatState().activeTurn?.responseParts ??
            chatState().turns.lastOrNull?.responseParts,
      ),
      'Working on it slowly.',
    );
    final s = await until((s) => s.chatChannels[chat]!.state.turns.isNotEmpty);
    expect(s.chatChannels[chat]!.state, host.chat(seededChat));
  });

  test('an action lost with the connection is rolled back', () async {
    final failures = <ActionFailure>[];
    final subscription = client.failures.listen(failures.add);
    addTearDown(subscription.cancel);
    host.loseActions = true;
    send('never arrives');
    expect(chatState().activeTurn?.id, 'turn-never arrives');
    await outage(() => host.loseActions = false);

    expect(chatState().activeTurn, isNull);
    expect(client.state.chatChannels[chat]!.pending, isEmpty);
    expect(failures.single.kind, ActionFailureKind.connectionLost);
    // The chat still works.
    send('hello');
    final s = await until((s) => s.chatChannels[chat]!.state.turns.isNotEmpty);
    expect(
      text(s.chatChannels[chat]!.state.turns.single.responseParts),
      startsWith('You said: hello'),
    );
  });

  test('a session removed while the client was away is missing', () async {
    await outage(() => host.removeSession(seededSession));
    expect(client.state.missingChannels, containsAll([seededSession, chat]));
    expect(client.state.sessions[seededSession], isNull);
    expect(client.state.sessions[longSession], isNotNull);
  });
}
