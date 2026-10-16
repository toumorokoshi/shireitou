/// Integration test against a real pi-agent-host-protocol checkout.
///
/// Set `PI_AHP_HOST_DIR` to the checkout (default:
/// `../../../pi-agent-host-protocol`, a sibling of this repo). Skipped when
/// the checkout is missing. Run with `just test-integration`.
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

void main() {
  final available = File('$_hostDir/src/bin/pi-agent-host-protocol.ts')
      .existsSync();

  group('pi-agent-host-protocol', skip: available ? null : 'no checkout', () {
    late Process host;
    late Directory temp;
    late Uri url;

    setUpAll(() async {
      temp = await Directory.systemTemp.createTemp('shireitou-pi-');
      final port = await _freePort();
      host = await Process.start(
        'node',
        [
          'src/bin/pi-agent-host-protocol.ts',
          '--port',
          '$port',
          '--no-token',
          '--no-bridge',
          // Runs pi's bundled SDK, so the `pi` CLI is not needed.
          '--pi-mode',
          'embedded',
          '--cwd',
          temp.path,
          '--agent-dir',
          '${temp.path}/agent',
        ],
        workingDirectory: _hostDir,
        environment: {'PI_AGENT_HOST_PROTOCOL_DIR': '${temp.path}/settings'},
      );
      final listening = RegExp(r'listening on (ws://\S+)');
      url = Uri.parse(
        await host.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map(listening.firstMatch)
            .firstWhere((match) => match != null)
            .timeout(const Duration(seconds: 30))
            .then((match) => match!.group(1)!),
      );
      unawaited(host.stderr.drain<void>());
    });

    tearDownAll(() async {
      host.kill();
      await host.exitCode;
      await temp.delete(recursive: true);
    });

    test('initialize, listSessions and createSession', () async {
      final client = AhpClient(uri: url);
      addTearDown(client.close);
      await client.connect();

      expect(client.state.error, isNull);
      expect(client.state.status, ConnectionStatus.connected);
      expect(offeredProtocolVersions, contains(client.state.protocolVersion));
      expect(client.state.serverInfo?.name, 'pi-agent-host-protocol');
      expect(client.state.root!.agents.map((a) => a.provider), contains('pi'));

      final added = client.states.firstWhere(
        (s) => s.sessions.values.any(
          (summary) => summary.workingDirectories?.isNotEmpty ?? false,
        ),
      );
      final session = await client.createSession(
        provider: 'pi',
        workingDirectories: [Uri.directory(temp.path).toString()],
      );
      final state = await added.timeout(const Duration(seconds: 20));
      final id = session.split('/').last;
      // pi publishes `pi:/<id>` for a session created as `ahp-session:/<id>`.
      final summary = state.sessions.values.singleWhere(
        (s) => s.resource.endsWith(id),
      );
      expect(summary.status.isIdle, isTrue);

      await client.ping();
    });
  });
}
