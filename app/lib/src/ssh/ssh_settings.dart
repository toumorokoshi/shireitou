/// Pure logic for SSH terminals to a host (AV-014): the per-host
/// settings, trust-on-first-use host key decisions and the command that
/// changes to a session's folder.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import '../session_list/folder_grouping.dart';

/// The default SSH port.
const defaultSshPort = 22;

/// How the SSH client proves who the user is.
enum SshAuthMethod {
  /// A password, kept in secure storage.
  password,

  /// A private key in PEM or OpenSSH format (pasted or read from a file),
  /// with an optional passphrase, kept in secure storage.
  privateKey,

  /// The keys of the running SSH agent (`SSH_AUTH_SOCK`).
  agent,
}

/// The SSH settings of one AHP host, secrets included (they are stored
/// in secure storage with the rest).
@immutable
class SshSettings {
  /// Creates SSH settings.
  const SshSettings({
    required this.host,
    this.port = defaultSshPort,
    this.user = '',
    this.auth = SshAuthMethod.password,
    this.password = '',
    this.privateKey = '',
    this.passphrase = '',
  });

  /// Reads settings written by [toJson]; null if [json] is malformed.
  static SshSettings? fromJson(Object? json) {
    if (json is! Map) return null;
    final host = json['host'];
    if (host is! String || host.isEmpty) return null;
    final port = json['port'];
    String text(String key) => switch (json[key]) {
      final String value => value,
      _ => '',
    };
    return SshSettings(
      host: host,
      port: port is int && validSshPort(port) ? port : defaultSshPort,
      user: text('user'),
      auth:
          SshAuthMethod.values.asNameMap()[json['auth']] ??
          SshAuthMethod.password,
      password: text('password'),
      privateKey: text('privateKey'),
      passphrase: text('passphrase'),
    );
  }

  /// The SSH server's host name or address.
  final String host;

  /// The SSH server's port.
  final int port;

  /// The user to log in as.
  final String user;

  /// How to authenticate.
  final SshAuthMethod auth;

  /// The password, for [SshAuthMethod.password].
  final String password;

  /// The private key text, for [SshAuthMethod.privateKey].
  final String privateKey;

  /// The private key's passphrase; empty when it has none.
  final String passphrase;

  /// The `host:port` the host key is remembered under.
  String get target => sshTarget(host, port);

  /// A label such as `user@host:2222` (the port only when not 22).
  String get label =>
      '${user.isEmpty ? '' : '$user@'}$host'
      '${port == defaultSshPort ? '' : ':$port'}';

  /// JSON for secure storage.
  Map<String, Object> toJson() => {
    'host': host,
    'port': port,
    'user': user,
    'auth': auth.name,
    'password': password,
    'privateKey': privateKey,
    'passphrase': passphrase,
  };

  @override
  bool operator ==(Object other) =>
      other is SshSettings &&
      other.host == host &&
      other.port == port &&
      other.user == user &&
      other.auth == auth &&
      other.password == password &&
      other.privateKey == privateKey &&
      other.passphrase == passphrase;

  @override
  int get hashCode =>
      Object.hash(host, port, user, auth, password, privateKey, passphrase);

  @override
  String toString() => 'SshSettings($label, ${auth.name})';
}

/// Whether [port] is a TCP port number.
bool validSshPort(int port) => port > 0 && port < 65536;

/// The `host:port` key of an SSH server, for its remembered host key.
String sshTarget(String host, int port) => '${host.toLowerCase()}:$port';

/// Settings for an AHP host at [hostUrl] that has none yet: the SSH host
/// is the URL's host, on port 22.
SshSettings defaultSshSettings(String hostUrl) =>
    SshSettings(host: Uri.tryParse(hostUrl.trim())?.host ?? '');

/// Why [settings] cannot be used to connect, or null when they can.
String? sshSettingsProblem(SshSettings settings) {
  if (settings.host.trim().isEmpty) return 'Enter the SSH host.';
  if (!validSshPort(settings.port)) return 'Enter a port from 1 to 65535.';
  if (settings.user.trim().isEmpty) return 'Enter the user to log in as.';
  return switch (settings.auth) {
    SshAuthMethod.privateKey when settings.privateKey.trim().isEmpty =>
      'Paste a private key or load one from a file.',
    _ => null,
  };
}

/// A host key remembered on first use: its algorithm and its OpenSSH
/// SHA256 fingerprint (`SHA256:…`).
typedef KnownHostKey = ({String type, String fingerprint});

/// What to do with the host key an SSH server presents.
enum HostKeyDecision {
  /// No key is remembered for the server: trust this one and remember it.
  trustNew,

  /// It is the remembered key.
  matches,

  /// It differs from the remembered key: refuse to connect.
  changed,
}

/// Decides on the key [presented] by a server whose remembered key is
/// [known] (null when none is).
HostKeyDecision decideHostKey(KnownHostKey? known, KnownHostKey presented) =>
    switch (known) {
      null => HostKeyDecision.trustNew,
      _ when known == presented => HostKeyDecision.matches,
      _ => HostKeyDecision.changed,
    };

/// The error shown when the server at [target] presents [presented]
/// instead of the remembered [known] key.
String changedHostKeyMessage(
  String target,
  KnownHostKey known,
  KnownHostKey presented,
) =>
    'The host key of $target has changed, so the connection was refused. '
    'It may have been reinstalled, or someone may be intercepting the '
    'connection.\n'
    'Remembered: ${known.type} ${known.fingerprint}\n'
    'Presented:  ${presented.type} ${presented.fingerprint}\n'
    'If the change is expected, choose "Forget host key" in the SSH '
    'settings and connect again.';

/// Encodes the remembered host keys, by [sshTarget].
String encodeKnownHosts(Map<String, KnownHostKey> hosts) => jsonEncode({
  for (final MapEntry(:key, :value) in hosts.entries)
    key: {'type': value.type, 'fingerprint': value.fingerprint},
});

/// Decodes [encoded] from [encodeKnownHosts]; malformed entries are
/// dropped.
Map<String, KnownHostKey> decodeKnownHosts(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const {};
  try {
    final json = jsonDecode(encoded);
    if (json is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (key is String && value is Map)
          if ((value['type'], value['fingerprint']) case (
            final String type,
            final String fingerprint,
          ))
            key: (type: type, fingerprint: fingerprint),
    };
  } on FormatException {
    return const {};
  }
}

/// [text] quoted for a POSIX shell: in single quotes, with each single
/// quote written as `'\''`.
String shellQuote(String text) => "'${text.replaceAll("'", r"'\''")}'";

/// The line typed into a new shell to change to [directory] (a session's
/// folder), clearing the screen after so the prompt starts at the top.
String changeDirectoryCommand(String directory) =>
    'cd ${shellQuote(directory)} && clear\n';

/// The folder of [summary] to open its SSH terminal in: its working
/// directory or project as a path, or null when it has none or it is not
/// a `file:` path.
String? sessionDirectory(SessionSummary? summary) {
  final key = summary == null ? null : folderKeyOf(summary);
  return key != null && key.startsWith('/') ? key : null;
}
