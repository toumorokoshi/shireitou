/// Reading a file over the system `ssh`, for platforms with `dart:io`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../terminal/ssh_command.dart';
import 'ssh_file_read.dart';

/// The bytes of [path] on [host], printed by `cat` over `ssh`; throws
/// [SshReadException] when `ssh` fails or the file is over [maxBytes].
Future<Uint8List> readFileOverSsh(
  String host,
  String path, {
  required int maxBytes,
}) async {
  final process = await Process.start(
    sshExecutable,
    sshReadFileArguments(host, path),
  );
  unawaited(process.stdin.close());
  final stderr = process.stderr.transform(utf8.decoder).join();
  final bytes = BytesBuilder(copy: false);
  var tooLarge = false;
  await for (final chunk in process.stdout) {
    bytes.add(chunk);
    if (bytes.length > maxBytes) {
      tooLarge = true;
      process.kill();
      break;
    }
  }
  final code = await process.exitCode;
  if (tooLarge) throw SshReadException('File too large (over $maxBytes bytes)');
  if (code != 0) throw SshReadException(sshErrorMessage(await stderr, code));
  return bytes.takeBytes();
}
