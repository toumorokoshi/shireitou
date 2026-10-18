/// Drives [AhpClient] against a real pi-agent-host-protocol host whose model
/// is pi's scripted faux provider (`scripts/pi-faux-host.ts`, no API key):
/// streamed replies, tool calls, cancelling, and reconnecting after a
/// dropped connection (replay), a host restart (`initialize` again), a
/// channel the host lost (`missing`) and an action lost with the socket
/// (rolled back). A [TcpRelay] in front of pi breaks the connection.
///
/// Needs a pi-agent-host-protocol checkout with `npm ci` (`PI_AHP_HOST_DIR`,
/// default a sibling of this repo); skipped without one. Run with
/// `just test-integration`.
@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _timeout = Duration(seconds: 30);

void main() {
  late PiFauxHost pi;
  late TcpRelay relay;
  late AhpClient client;

  setUp(() async {
    pi = await PiFauxHost.start();
    relay = TcpRelay(target: pi.port);
    await relay.start();
    client = AhpClient(uri: relay.relayed(pi.url), pingInterval: Duration.zero);
    await client.connect();
    expect(client.state.status, ConnectionStatus.connected);
  });

  tearDown(() async {
    await client.close();
    await relay.close();
    await pi.stop();
  });

  Future<HostState> until(bool Function(HostState state) test) async {
    if (test(client.state)) return client.state;
    return client.states.firstWhere(test).timeout(_timeout);
  }

  Future<(String, String)> newSession() async {
    final session = await client.createSession(
      provider: 'pi',
      workingDirectories: [Uri.directory(pi.workspace).toString()],
    );
    return (session, (await client.openSession(session))!);
  }

  void send(String chat, String text, {String? id}) => client.dispatch(
    chat,
    ChatTurnStartedAction(
      turnId: id ?? 'turn-${DateTime.now().microsecondsSinceEpoch}',
      startedAt: DateTime.now().toUtc().toIso8601String(),
      message: userMessage(text),
    ).toJson(),
  );

  ChatState chatOf(HostState s, String chat) => s.chatChannels[chat]!.state;

  String replyOf(Turn turn) => turn.responseParts
      .whereType<MarkdownResponsePart>()
      .map((p) => p.content)
      .join();

  String activeText(HostState s, String chat) {
    final turn = chatOf(s, chat).activeTurn;
    return turn == null
        ? ''
        : turn.responseParts
              .whereType<MarkdownResponsePart>()
              .map((p) => p.content)
              .join();
  }

  Future<Turn> finished(String chat, int count) async {
    final s = await until(
      (s) =>
          chatOf(s, chat).turns.length >= count &&
          chatOf(s, chat).activeTurn == null,
    );
    return chatOf(s, chat).turns[count - 1];
  }

  test('streams a reply and runs a tool', () async {
    final (_, chat) = await newSession();
    send(chat, 'hello');
    final first = await finished(chat, 1);
    expect(first.state, TurnState.complete);
    expect(replyOf(first), 'pi faux reply: hello');

    send(chat, 'run a tool');
    final second = await finished(chat, 2);
    expect(second.state, TurnState.complete);
    final call = second.responseParts
        .whereType<ToolCallResponsePart>()
        .single
        .toolCall;
    expect(call, isA<ToolCallCompletedState>());
    expect(replyOf(second), contains('The bash tool printed: hello from pi'));
  });

  test('a session in a folder pi does not have fails at once', () async {
    await expectLater(
      client.createSession(
        provider: 'pi',
        workingDirectories: ['file:///no/such/folder'],
      ),
      throwsA(
        isA<RpcException>().having(
          (e) => e.message,
          'message',
          contains('not a local directory'),
        ),
      ),
    );
  });

  test('editing the running message restarts from it (AV-088)', () async {
    final (_, chat) = await newSession();
    send(chat, 'one', id: 'one');
    await finished(chat, 1);
    send(chat, 'slow', id: 'slow');
    await until((s) => activeText(s, chat).contains('word10 '));
    client.dispatch(chat, const ChatTruncatedAction(turnId: 'one').toJson());
    send(chat, 'history please');
    final edited = await finished(chat, 2);
    expect(
      [for (final t in chatOf(client.state, chat).turns) t.message.text],
      ['one', 'history please'],
    );
    expect(replyOf(edited), 'pi faux history: one | history please');
  });

  test('cancels a running turn', () async {
    final (_, chat) = await newSession();
    send(chat, 'slow', id: 'slow');
    await until((s) => activeText(s, chat).contains('word10 '));
    client.dispatch(
      chat,
      const ChatTurnCancelledAction(turnId: 'slow', duration: 0).toJson(),
    );
    final turn = await finished(chat, 1);
    expect(turn.state, TurnState.cancelled);
    expect(replyOf(turn), isNot(contains('done.')));
  });

  test(
    'a dropped connection resumes with a replay of what was missed',
    () async {
      final (session, chat) = await newSession();
      send(chat, 'slow', id: 'slow');
      await until((s) => activeText(s, chat).contains('word10 '));

      // The link goes down for a while; the turn keeps streaming on pi.
      relay
        ..refusing = true
        ..drop();
      await until((s) => s.status == ConnectionStatus.reconnecting);
      final before = activeText(client.state, chat).length;
      await Future<void>.delayed(const Duration(seconds: 2));
      relay.refusing = false;
      await until((s) => s.status == ConnectionStatus.connected);
      expect(client.state.missingChannels, isEmpty);
      // The replay carried the deltas sent while the client was away.
      expect(activeText(client.state, chat).length, greaterThan(before + 100));

      final turn = await finished(chat, 1);
      expect(turn.state, TurnState.complete);
      expect(replyOf(turn), endsWith('word3000 done.'));
      // Nothing was lost or doubled: the text is what pi wrote.
      expect(
        replyOf(turn),
        'Counting slowly: '
        '${[for (var i = 1; i <= 3000; i++) 'word$i'].join(' ')} done.',
      );
      expect(client.state.sessions[session], isNotNull);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test('an action lost with the connection is rolled back', () async {
    final (session, _) = await newSession();
    final original = client.state.sessionChannels[session]!.state.title;
    final failures = <ActionFailure>[];
    final subscription = client.failures.listen(failures.add);
    addTearDown(subscription.cancel);

    relay.hold();
    client.dispatch(
      session,
      const SessionTitleChangedAction(title: 'Never arrives').toJson(),
    );
    expect(client.state.sessionChannels[session]!.state.title, 'Never arrives');
    relay.drop();
    await until((s) => s.status == ConnectionStatus.reconnecting);
    await until((s) => s.status == ConnectionStatus.connected);

    expect(client.state.sessionChannels[session]!.state.title, original);
    expect(client.state.sessionChannels[session]!.pending, isEmpty);
    expect(failures.single.kind, ActionFailureKind.connectionLost);
  });

  test('a session removed while disconnected is reported missing', () async {
    final (session, chat) = await newSession();
    relay
      ..refusing = true
      ..drop();
    await until((s) => s.status == ConnectionStatus.reconnecting);

    // Another client disposes the empty session meanwhile.
    final other = WebSocketChannel.connect(pi.url);
    await other.ready;
    final replies = other.stream.map((m) => jsonDecode(m as String) as Map);
    final answers = replies.asBroadcastStream();
    Future<Object?> request(int id, String method, JsonMap params) async {
      other.sink.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'method': method,
          'params': params,
        }),
      );
      final reply = await answers.firstWhere((m) => m['id'] == id);
      expect(reply['error'], isNull);
      return reply['result'];
    }

    await request(1, 'initialize', {
      'channel': rootChannel,
      'protocolVersions': ['1.0.0'],
      'clientId': 'other',
    });
    await request(2, 'disposeSession', {'channel': session});
    await other.sink.close();

    relay.refusing = false;
    await until((s) => s.status == ConnectionStatus.connected);
    expect(client.state.missingChannels, containsAll([session, chat]));
    expect(client.state.sessions[session], isNull);
  });

  test('after a host restart the client initializes again and keeps '
      'its sessions', () async {
    final (session, chat) = await newSession();
    send(chat, 'hello');
    await finished(chat, 1);
    final (empty, _) = await newSession();

    pi = await pi.restart();
    relay.target = pi.port;
    await until((s) => s.status == ConnectionStatus.reconnecting);
    await until((s) => s.status == ConnectionStatus.connected);

    // The session with a turn was saved by pi and comes back with its
    // history; the empty one was never saved and is gone.
    expect(client.state.missingChannels, contains(empty));
    expect(client.state.missingChannels, isNot(contains(session)));
    expect(client.state.sessions.keys, contains(session));
    expect(replyOf(chatOf(client.state, chat).turns.single), contains('hello'));

    send(chat, 'again');
    final turn = await finished(chat, 2);
    expect(replyOf(turn), 'pi faux reply: again');
  }, timeout: const Timeout(Duration(minutes: 1)));
}
