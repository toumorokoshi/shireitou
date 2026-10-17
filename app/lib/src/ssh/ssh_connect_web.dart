/// The web build's SSH connector: browsers cannot open TCP sockets.
library;

import 'ssh_settings.dart';
import 'ssh_shell.dart';

/// Whether this platform can open SSH terminals.
const sshSupported = false;

/// Why there is no SSH terminal here, for the user.
const sshUnsupportedReason =
    'SSH terminals need the desktop or mobile app: browsers cannot open the '
    'TCP connection SSH uses.';

/// Always throws: the web build cannot open SSH connections.
Future<SshShell> connectSsh(
  SshSettings settings, {
  required int columns,
  required int rows,
  required HostKeyCheck verifyHostKey,
}) async => throw const SshConnectError(sshUnsupportedReason);
