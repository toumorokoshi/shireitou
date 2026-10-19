/// Pure logic for opening a session's folder in VS Code (AV-015): the
/// `vscode://` link to the folder on this machine, or on the host over
/// VS Code's Remote - SSH extension.
library;

import 'dart:convert';

import '../ssh/ssh_settings.dart';

/// The host names that mean the AHP host runs on this machine.
const _loopbackHosts = {'localhost', '127.0.0.1', '::1'};

/// Whether the AHP host at [hostUrl] runs on this machine.
bool isLocalHost(String hostUrl) =>
    _loopbackHosts.contains(Uri.tryParse(hostUrl.trim())?.host.toLowerCase());

/// The Remote - SSH authority for [ssh]: `user@host` (or `host` without a
/// user, so the SSH config picks one), or, with a port other than 22, the
/// hex-encoded JSON `{"hostName":…,"user":…,"port":…}` the extension also
/// reads.
String remoteSshAuthority(SshSettings ssh) {
  final host = ssh.host.trim();
  final user = ssh.user.trim();
  if (ssh.port == defaultSshPort) return user.isEmpty ? host : '$user@$host';
  final json = jsonEncode({
    'hostName': host,
    if (user.isNotEmpty) 'user': user,
    'port': ssh.port,
  });
  return utf8
      .encode(json)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// The link that opens [directory] (an absolute POSIX path on the AHP
/// host at [hostUrl]) in VS Code: the local folder when the host runs on
/// this machine, else the folder over SSH with [ssh], or the host's
/// address from its URL when it has no SSH settings.
Uri vscodeFolderUri({
  required String directory,
  required String hostUrl,
  SshSettings? ssh,
}) {
  if (isLocalHost(hostUrl)) {
    return Uri(scheme: 'vscode', host: 'file', path: directory);
  }
  final authority = remoteSshAuthority(ssh ?? defaultSshSettings(hostUrl));
  return Uri(
    scheme: 'vscode',
    host: 'vscode-remote',
    path: '/ssh-remote+$authority$directory',
  );
}
