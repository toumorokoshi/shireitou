/// Runs the scripted fake AHP host.
///
/// ```sh
/// dart run ahp_fake_host [--port 0] [--token <tkn>] [--no-token]
/// ```
///
/// Prints `ahp-fake-host listening on ws://127.0.0.1:<port>?tkn=<token>`.
library;

import 'dart:io';
import 'dart:math';

import 'package:ahp_fake_host/ahp_fake_host.dart';

Future<void> main(List<String> args) async {
  String? option(String name) {
    final index = args.indexOf(name);
    return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
  }

  final random = Random.secure();
  final token = args.contains('--no-token')
      ? null
      : option('--token') ??
            List.generate(
              16,
              (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
            ).join();
  final host = FakeAhpHost(token: token);
  final url = await host.start(port: int.tryParse(option('--port') ?? '') ?? 0);
  stdout.writeln('ahp-fake-host listening on $url');
  stdout.writeln(
    'Say ${[for (final s in Scenario.values) '"${s.keyword}"'].join(', ')} '
    'in a message to run a scripted flow.',
  );
  ProcessSignal.sigint.watch().listen((_) async {
    await host.close();
    exit(0);
  });
}
