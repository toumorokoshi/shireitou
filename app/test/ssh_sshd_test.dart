/// Drives `connectSsh` against a real OpenSSH server: a throwaway `sshd`
/// on a free port, run as the current user with generated keys. Skipped
/// where `sshd` or `ssh-keygen` is not installed.
@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/ssh/ssh_connect.dart';
import 'package:shireitou/src/ssh/ssh_settings.dart';
import 'package:shireitou/src/ssh/ssh_shell.dart';

const _sshd = '/usr/sbin/sshd';

String? _skipReason() {
  if (!File(_sshd).existsSync()) return 'no $_sshd';
  try {
    Process.runSync('ssh-keygen', ['-?']);
  } on ProcessException {
    return 'no ssh-keygen';
  }
  return null;
}

Future<void> _keygen(String path, {String passphrase = ''}) async {
  final result = await Process.run('ssh-keygen', [
    '-q',
    '-t',
    'ed25519',
    '-N',
    passphrase,
    '-f',
    path,
  ]);
  if (result.exitCode != 0) throw StateError('ssh-keygen: ${result.stderr}');
}

/// Reads [shell]'s output until it contains [text].
Future<String> _readUntil(Stream<String> output, String text) => output
    .transform(
      StreamTransformer<String, String>.fromBind((chunks) async* {
        final seen = StringBuffer();
        await for (final chunk in chunks) {
          seen.write(chunk);
          yield '$seen';
        }
      }),
    )
    .firstWhere((seen) => seen.contains(text))
    .timeout(const Duration(seconds: 20));

void main() {
  final skip = _skipReason();
  late Directory dir;
  late Process sshd;
  late int port;
  late String user;
  late String privateKey;
  final sshdLog = StringBuffer();

  setUpAll(() async {
    if (skip != null) return;
    dir = await Directory.systemTemp.createTemp('shireitou-sshd');
    user =
        Platform.environment['USER'] ??
        (await Process.run('id', ['-un'])).stdout.toString().trim();
    await _keygen('${dir.path}/host_key');
    await _keygen('${dir.path}/client_key', passphrase: 'open sesame');
    privateKey = await File('${dir.path}/client_key').readAsString();
    await File('${dir.path}/authorized_keys')
        .writeAsString(await File('${dir.path}/client_key.pub').readAsString());
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = socket.port;
    await socket.close();
    await File('${dir.path}/sshd_config').writeAsString('''
Port $port
ListenAddress 127.0.0.1
HostKey ${dir.path}/host_key
AuthorizedKeysFile ${dir.path}/authorized_keys
PidFile ${dir.path}/sshd.pid
StrictModes no
UsePAM no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
''');
    sshd = await Process.start(_sshd, [
      '-D',
      '-e',
      '-f',
      '${dir.path}/sshd_config',
    ]);
    sshd.stdout.transform(utf8.decoder).listen(sshdLog.write);
    sshd.stderr.transform(utf8.decoder).listen(sshdLog.write);
    // Wait for it to listen.
    for (var i = 0; i < 50; i++) {
      try {
        await (await Socket.connect('127.0.0.1', port)).close();
        return;
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    fail('sshd did not start: $sshdLog');
  });

  tearDownAll(() async {
    if (skip != null) return;
    sshd.kill();
    await sshd.exitCode;
    await dir.delete(recursive: true);
  });

  SshSettings settings({String passphrase = 'open sesame'}) => SshSettings(
    host: '127.0.0.1',
    port: port,
    user: user,
    auth: SshAuthMethod.privateKey,
    privateKey: privateKey,
    passphrase: passphrase,
  );

  test('opens a shell with a pty, runs a command and resizes', () async {
    KnownHostKey? presented;
    final SshShell shell;
    try {
      shell = await connectSsh(
        settings(),
        columns: 80,
        rows: 24,
        verifyHostKey: (key) {
          presented = key;
          return true;
        },
      );
    } on Object catch (error) {
      fail('$error\nsshd: $sshdLog');
    }
    expect(presented?.type, 'ssh-ed25519');
    expect(presented?.fingerprint, startsWith('SHA256:'));
    final output = shell.output
        .cast<List<int>>()
        .transform(utf8.decoder)
        .asBroadcastStream();
    shell.resize(132, 40);
    shell.write(
      Uint8List.fromList(
        utf8.encode(
          "${changeDirectoryCommand('/')}stty size; echo do\${x}ne\n",
        ),
      ),
    );
    final seen = await _readUntil(output, 'done');
    expect(seen, contains('40 132'));
    shell.write(Uint8List.fromList(utf8.encode('exit\n')));
    await shell.done.timeout(const Duration(seconds: 20));
  }, skip: skip);

  test('refuses a host key the check rejects', () async {
    await expectLater(
      connectSsh(
        settings(),
        columns: 80,
        rows: 24,
        verifyHostKey: (_) => false,
      ),
      throwsA(
        predicate(
          (Object error) =>
              describeSshError(error, settings()).contains('host key'),
        ),
      ),
    );
  }, skip: skip);

  test('reports a wrong passphrase', () async {
    await expectLater(
      connectSsh(
        settings(passphrase: 'wrong'),
        columns: 80,
        rows: 24,
        verifyHostKey: (_) => true,
      ),
      throwsA(
        predicate(
          (Object error) =>
              describeSshError(error, settings()).contains('passphrase'),
        ),
      ),
    );
  }, skip: skip);
}
