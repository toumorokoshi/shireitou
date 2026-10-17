/// Integration tests against a real pi-agent-host-protocol checkout.
///
/// Set `PI_AHP_HOST_DIR` to the checkout (default:
/// `../../../pi-agent-host-protocol`, a sibling of this repo). Skipped when
/// the checkout is missing. Run with `just test-integration`.
///
/// The `model` group runs a real turn with the providers configured in
/// `~/.pi/agent`, so it costs tokens. It is excluded from
/// `just test-integration` (and CI); run it with `just test-model`. Sessions
/// go to a temp `--session-dir`, never to `~/.pi/agent/sessions`.
@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

final _hostDir =
    Platform.environment['PI_AHP_HOST_DIR'] ??
    '../../../pi-agent-host-protocol';

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// A pi-agent-host-protocol process listening on [url].
typedef PiHost = ({Process process, Directory temp, Uri url});

/// Starts pi in embedded mode with temp settings, sessions and working
/// directory. With [isolatedAgentDir], pi also gets an empty agent directory
/// (no model providers); otherwise it uses the user's `~/.pi/agent`. With
/// [token], pi requires a connection token and [PiHost.url] carries it as
/// `?tkn=`.
Future<PiHost> startPiHost({
  required bool isolatedAgentDir,
  bool token = false,
}) async {
  final temp = await Directory.systemTemp.createTemp('shireitou-pi-');
  final port = await _freePort();
  final process = await Process.start(
    'node',
    [
      'src/bin/pi-agent-host-protocol.ts',
      '--port',
      '$port',
      if (!token) '--no-token',
      '--no-bridge',
      // Runs pi's bundled SDK, so the `pi` CLI is not needed.
      '--pi-mode',
      'embedded',
      '--cwd',
      temp.path,
      '--session-dir',
      '${temp.path}/sessions',
      if (isolatedAgentDir) ...['--agent-dir', '${temp.path}/agent'],
    ],
    workingDirectory: _hostDir,
    environment: {'PI_AGENT_HOST_PROTOCOL_DIR': '${temp.path}/settings'},
  );
  final listening = RegExp(r'listening on (ws://\S+)');
  final url = Uri.parse(
    await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map(listening.firstMatch)
        .firstWhere((match) => match != null)
        .timeout(const Duration(seconds: 30))
        .then((match) => match!.group(1)!),
  );
  unawaited(process.stderr.drain<void>());
  return (process: process, temp: temp, url: url);
}

Future<void> stopPiHost(PiHost host) async {
  host.process.kill();
  await host.process.exitCode;
  await host.temp.delete(recursive: true);
}

void main() {
  final available = File('$_hostDir/src/bin/pi-agent-host-protocol.ts')
      .existsSync();
  final skip = available ? null : 'no checkout';

  group('pi-agent-host-protocol', skip: skip, () {
    late PiHost host;
    setUpAll(() async => host = await startPiHost(isolatedAgentDir: true));
    tearDownAll(() => stopPiHost(host));

    test('initialize, listSessions, createSession and subscribe', () async {
      final client = AhpClient(uri: host.url);
      addTearDown(client.close);
      await client.connect();

      expect(client.state.error, isNull);
      expect(client.state.status, ConnectionStatus.connected);
      expect(offeredProtocolVersions, contains(client.state.protocolVersion));
      expect(client.state.serverInfo?.name, 'pi-agent-host-protocol');
      expect(client.state.root!.agents.map((a) => a.provider), contains('pi'));

      final session = await client.createSession(
        provider: 'pi',
        workingDirectories: [Uri.directory(host.temp.path).toString()],
      );
      // pi publishes `pi:/<id>` for a session created as `ahp-session:/<id>`.
      expect(session, startsWith('pi:/'));
      expect(client.state.sessions[session]!.status.isIdle, isTrue);

      final chat = await client.openSession(session);
      expect(chat, isNotNull);
      expect(
        client.state.sessionChannels[session]!.state.lifecycle,
        SessionLifecycle.ready,
      );
      expect(client.state.chatChannels[chat]!.state.turns, isEmpty);

      // A rejected action is echoed with a reason and rolled back.
      final rejected = client.actions.firstWhere(
        (e) => e.rejectionReason != null,
      );
      client.dispatch(
        chat!,
        const ChatTurnCancelledAction(turnId: 'none', duration: 0).toJson(),
      );
      expect((await rejected).rejectionReason, 'No active turn');
      expect(client.state.chatChannels[chat]!.pending, isEmpty);

      await client.ping();
    });

    test('completes the agent directory\'s skills after /', () async {
      final skill = File('${host.temp.path}/agent/skills/greet/SKILL.md');
      await skill.create(recursive: true);
      await skill.writeAsString(
        '---\nname: greet\ndescription: Says hello\n---\nSay hello.\n',
      );
      final client = AhpClient(uri: host.url);
      addTearDown(client.close);
      await client.connect();
      expect(client.state.completionTriggerCharacters, ['/']);
      final session = await client.createSession(
        provider: 'pi',
        workingDirectories: [Uri.directory(host.temp.path).toString()],
      );
      final chat = (await client.openSession(session))!;
      final items = await client.completions(
        chat: chat,
        text: '/gre',
        offset: 4,
      );
      final item = items.singleWhere(
        (i) => i.attachment.label.contains('greet'),
      );
      expect(item.insertText, '/skill:greet ');
      expect((item.rangeStart, item.rangeEnd), (0, 4));
      expect(item.attachment.meta?['description'], 'Says hello');
    });

    test('negotiates 0.9.0 when offered only that', () async {
      final client = AhpClient(
        uri: host.url,
        protocolVersions: const ['0.9.0'],
      );
      addTearDown(client.close);
      await client.connect();
      expect(client.state.error, isNull);
      expect(client.state.protocolVersion, '0.9.0');
      expect(unavailableFeatures('0.9.0'), isNotEmpty);
      final session = client.state.sessions.keys.firstOrNull;
      if (session == null) return;
      final chat = await client.openSession(session);
      expect(
        () => client.dispatch(chat!, const {
          'type': 'chat/isReadChanged',
          'isRead': true,
        }),
        throwsA(isA<UnsupportedActionError>()),
      );
    });
  });

  group('pi with a connection token', skip: skip, () {
    late PiHost host;
    setUpAll(
      () async => host = await startPiHost(isolatedAgentDir: true, token: true),
    );
    tearDownAll(() => stopPiHost(host));

    test(
      'accepts the native handshake (Authorization header and tkn)',
      () async {
        expect(connectionTokenOf(host.url), isNotNull);
        final client = AhpClient(uri: host.url);
        addTearDown(client.close);
        await client.connect();
        expect(client.state.error, isNull);
        expect(client.state.status, ConnectionStatus.connected);
      },
    );

    test('rejects a connection without the token', () async {
      final client = AhpClient(
        uri: Uri.parse(host.url.toString().split('?').first),
      );
      addTearDown(client.close);
      await client.connect();
      expect(client.state.status, ConnectionStatus.failed);
    });
  });

  group('pi with a model provider', tags: ['model'], skip: skip, () {
    late PiHost host;
    setUpAll(() async => host = await startPiHost(isolatedAgentDir: false));
    tearDownAll(() => stopPiHost(host));

    test('sends a message and streams the reply', () async {
      final client = AhpClient(uri: host.url);
      addTearDown(client.close);
      await client.connect();
      final session = await client.createSession(
        provider: 'pi',
        workingDirectories: [Uri.directory(host.temp.path).toString()],
      );
      final chat = (await client.openSession(session))!;
      ChatState chatState(HostState s) => s.chatChannels[chat]!.state;

      final streamed = <String>[];
      final subscription = client.states.listen((s) {
        final text = chatState(s).activeTurn?.responseParts
            .whereType<MarkdownResponsePart>()
            .lastOrNull
            ?.content;
        if (text != null && text.isNotEmpty) streamed.add(text);
      });
      addTearDown(subscription.cancel);

      final done = client.states.firstWhere(
        (s) => chatState(s).turns.isNotEmpty,
      );
      client.dispatch(
        chat,
        ChatTurnStartedAction(
          turnId: 'turn-1',
          startedAt: DateTime.now().toUtc().toIso8601String(),
          message: userMessage('Reply with just the word ok.'),
        ).toJson(),
      );
      // The optimistic turn shows before the host echoes it.
      expect(chatState(client.state).activeTurn?.id, 'turn-1');

      final turn = chatState(await done.timeout(const Duration(minutes: 2)))
          .turns
          .single;
      expect(turn.state, TurnState.complete, reason: '${turn.responseParts}');
      final reply = turn.responseParts
          .whereType<MarkdownResponsePart>()
          .last
          .content;
      expect(reply.toLowerCase(), contains('ok'));
      expect(streamed, isNotEmpty);
      expect(client.state.chatChannels[chat]!.pending, isEmpty);
    });
  });
}
