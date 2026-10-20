import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:test/test.dart';

/// Runs [pty] to the end and returns its output. Exit codes are not
/// checked here: the test runner reaps child processes itself, so the
/// pty's `waitpid` finds none and reads 0. The app's integration test
/// checks them.
Future<String> finish(Pty pty) async {
  final output = StringBuffer();
  final reading = pty.output.listen(
    (data) => output.write(utf8.decode(data, allowMalformed: true)),
  );
  await pty.exitCode.timeout(const Duration(seconds: 30));
  // The last output can arrive after the exit code.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  await reading.cancel();
  return '$output';
}

void main() {
  test('runs a program with its arguments in a terminal', () async {
    final pty = Platform.isWindows
        ? Pty.start('cmd.exe', arguments: ['/c', 'echo two words'])
        : Pty.start(
            '/bin/sh',
            arguments: [
              '-c',
              r'test -t 1 && echo "tty $TERM $1"',
              'sh',
              'two words',
            ],
          );
    final output = await finish(pty);
    expect(
      output,
      contains(
        Platform.isWindows ? 'two words' : 'tty xterm-256color two words',
      ),
    );
  });

  test('passes input, the size and the environment', () async {
    final pty = Pty.start(
      '/bin/sh',
      arguments: ['-c', r'read line; echo "$line $GREETING"; stty size'],
      environment: {'GREETING': 'hello'},
      rows: 30,
      columns: 100,
    );
    pty.write(Uint8List.fromList(utf8.encode('typed\n')));
    final output = await finish(pty);
    expect(output, contains('typed hello'));
    expect(output, contains('30 100'));
  }, testOn: '!windows');
}
