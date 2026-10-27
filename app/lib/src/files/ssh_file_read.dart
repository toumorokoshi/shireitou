/// The text of a file the viewer opens (AV-106): read over the system
/// `ssh` from the AHP host, as the terminal panel (AV-016) reaches it, on
/// the desktop apps, and with the host's `resourceRead` elsewhere or when
/// `ssh` cannot read it.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../channels.dart';
import '../hosts/open_hosts.dart';
import '../terminal/pty_process.dart';
import '../terminal/ssh_command.dart';
import 'ssh_file_read_web.dart'
    if (dart.library.io) 'ssh_file_read_io.dart'
    as platform;

final _log = Logger('ssh_file_read');

/// The most the viewer reads over `ssh`, as much as pi's `resourceRead`.
const maxSshReadBytes = 16 * 1024 * 1024;

/// Why `ssh` could not read a file.
class SshReadException implements Exception {
  /// Creates an [SshReadException] with [message].
  const SshReadException(this.message);

  /// What went wrong, such as `ssh`'s or `cat`'s error.
  final String message;

  @override
  String toString() => message;
}

/// The message for an `ssh` that exited with [code]: the last line of its
/// [stderr] (`cat: …: No such file or directory`), or the code.
String sshErrorMessage(String stderr, int code) =>
    const LineSplitter()
        .convert(stderr)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .lastOrNull ??
    'ssh exited with code $code';

/// Reads the file at [path] on the SSH [host], at most [maxBytes].
typedef SshFileReader = Future<Uint8List> Function(
  String host,
  String path, {
  required int maxBytes,
});

/// Reads files over the system `ssh`; tests replace it.
final sshFileReaderProvider = Provider<SshFileReader>(
  (ref) => platform.readFileOverSsh,
);

/// Whether the viewer reads files over `ssh`: where the terminal panel
/// runs it ([ptySupported]); tests replace it.
final sshFileReadSupportedProvider = Provider<bool>((ref) => ptySupported);

/// The SSH host of the open AHP host [hostKey], or null when it is not
/// open or its URL has no host to SSH to.
String? sshHostOfOpenHost(Ref ref, String hostKey) => switch (ref
    .read(openHostsProvider)
    .where((host) => host.key == hostKey)
    .firstOrNull) {
  final host? => sshHostOf(host.url),
  null => null,
};

/// The path of a `file:` [uri], or null for other URIs.
String? filePathOfUri(String uri) {
  final parsed = Uri.tryParse(uri);
  if (parsed == null || parsed.scheme != 'file') return null;
  return parsed.toFilePath(windows: false);
}

/// The text of the `file:` URI [resource] on its host: over `ssh` when
/// [sshFileReadSupportedProvider] allows and the host has an SSH host,
/// else (or when `ssh` fails and `resourceRead` succeeds) with
/// `resourceRead`. When both fail, the error is `ssh`'s, and it is not
/// retried, so a missing file does not start `ssh` again and again.
final fileTextProvider = FutureProvider.autoDispose
    .family<String, HostResource>(retry: (_, _) => null, (ref, resource) async {
      Future<String> viaHost() => readResourceText(ref, resource);
      final path = filePathOfUri(resource.uri);
      final sshHost = ref.watch(sshFileReadSupportedProvider) && path != null
          ? sshHostOfOpenHost(ref, resource.host)
          : null;
      if (path == null || sshHost == null) return viaHost();
      try {
        final bytes = await ref.read(sshFileReaderProvider)(
          sshHost,
          path,
          maxBytes: maxSshReadBytes,
        );
        return utf8.decode(bytes, allowMalformed: true);
      } on Object catch (sshError, stack) {
        _log.info('ssh could not read $path on $sshHost: $sshError');
        try {
          return await viaHost();
        } on Object catch (hostError) {
          _log.info('resourceRead could not read $path: $hostError');
          Error.throwWithStackTrace(sshError, stack);
        }
      }
    });
