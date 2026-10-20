/// Pure logic for the terminal panel (AV-016): the SSH host of an AHP
/// host, the system `ssh` command that opens a shell there (in a
/// session's folder), and the `ssh://` link used where there is no pty.
library;

/// The executable the terminal runs: the system's OpenSSH client, found
/// on `PATH`. Its user, keys, port and jump hosts come from
/// `~/.ssh/config`.
const sshExecutable = 'ssh';

/// The SSH host of the AHP host at [hostUrl]: its URL's host (an address
/// or a name), or null when the URL has none or [validSshHost] refuses it.
String? sshHostOf(String hostUrl) {
  final host = Uri.tryParse(hostUrl.trim())?.host ?? '';
  return validSshHost(host) ? host : null;
}

/// Whether [host] can be passed to `ssh` as the destination: not empty,
/// not an option (a leading `-`, such as `-oProxyCommand=…`), and without
/// whitespace or control characters.
bool validSshHost(String host) =>
    host.isNotEmpty &&
    !host.startsWith('-') &&
    !host.codeUnits.any((unit) => unit <= 0x20 || unit == 0x7f);

/// [value] as one word for a POSIX shell: in single quotes, with each
/// single quote closed, escaped and reopened.
String shellQuote(String value) => "'${value.replaceAll("'", r"'\''")}'";

/// The arguments to [sshExecutable] that open a login shell on [host]:
/// just the host, or with [directory] a pty (`-t`) and a command that
/// changes to it first (staying in the home folder if it is missing).
List<String> sshArguments(String host, {String? directory}) => [
  if (directory != null) '-t',
  '--',
  host,
  if (directory != null)
    'cd ${shellQuote(directory)} 2>/dev/null; exec "\$SHELL" -l',
];

/// The environment of the `ssh` process: this app's environment (so
/// `SSH_AUTH_SOCK`, `HOME` and Windows' profile folders reach it), with
/// `TERM` set to what the terminal emulates.
Map<String, String> sshEnvironment(Map<String, String> environment) => {
  ...environment,
  'TERM': 'xterm-256color',
};

/// The `ssh://<host>` link that opens [host] in the system's SSH app
/// (iOS, Android and the web, which have no pty). IPv6 addresses are
/// bracketed.
Uri sshUri(String host) => Uri(scheme: 'ssh', host: host);

/// A tab's label: the last part of [directory] and the [host]
/// (`app · 10.0.0.5`), or the host alone.
String terminalLabel(String host, {String? directory}) {
  final folder = directory?.split('/').where((s) => s.isNotEmpty).lastOrNull;
  return folder == null ? host : '$folder · $host';
}
