/// Pure logic for opening a session's folder in a code editor (AV-015):
/// the editors, where a host's folders are (this computer or over SSH)
/// and the URL that opens a folder there.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import '../session_list/folder_grouping.dart';

/// The editors a folder opens in. All three are VS Code builds that
/// handle the same URLs under their own scheme.
enum CodeEditor {
  /// Visual Studio Code.
  vscode('VS Code', 'vscode'),

  /// Visual Studio Code Insiders.
  vscodeInsiders('VS Code Insiders', 'vscode-insiders'),

  /// Cursor.
  cursor('Cursor', 'cursor');

  const CodeEditor(this.label, this.scheme);

  /// The editor's name.
  final String label;

  /// The URL scheme the editor registers with the system.
  final String scheme;
}

/// The label of the menu items and buttons that open a folder in [editor].
String openInEditorLabel(CodeEditor editor) => 'Open in ${editor.label}';

/// The default SSH port.
const defaultSshPort = 22;

/// Where a host's folders are, as seen from this device.
enum EditorLocation {
  /// On this computer: the AHP host runs here.
  thisComputer,

  /// On another machine, reached with the editor's Remote - SSH.
  ssh,
}

/// Where the folders of one AHP host open: on this computer, or on the
/// SSH [host] (an address or a `~/.ssh/config` alias) as [user] (empty
/// for the SSH config's or the current user) on [port].
@immutable
class EditorTarget {
  /// Creates a target.
  const EditorTarget({
    required this.location,
    this.host = '',
    this.port = defaultSshPort,
    this.user = '',
  });

  /// Reads a target written by [toJson], or the host, port and user of
  /// the SSH terminal's former settings (no `location`); null if [json]
  /// is malformed.
  static EditorTarget? fromJson(Object? json) {
    if (json is! Map) return null;
    final location = EditorLocation.values.asNameMap()[json['location']];
    final host = json['host'];
    final port = json['port'];
    final user = json['user'];
    if (location == null && (host is! String || host.isEmpty)) return null;
    return EditorTarget(
      location: location ?? EditorLocation.ssh,
      host: host is String ? host : '',
      port: port is int && validSshPort(port) ? port : defaultSshPort,
      user: user is String ? user : '',
    );
  }

  /// Where the folders are.
  final EditorLocation location;

  /// The SSH host, for [EditorLocation.ssh].
  final String host;

  /// The SSH port, for [EditorLocation.ssh].
  final int port;

  /// The SSH user, for [EditorLocation.ssh]; empty for the default.
  final String user;

  /// A label such as `user@host:2222` (the port only when not 22), or
  /// "this computer".
  String get label => switch (location) {
    EditorLocation.thisComputer => 'this computer',
    EditorLocation.ssh =>
      '${user.isEmpty ? '' : '$user@'}$host'
          '${port == defaultSshPort ? '' : ':$port'}',
  };

  /// JSON for the prefs store.
  Map<String, Object> toJson() => {
    'location': location.name,
    'host': host,
    'port': port,
    'user': user,
  };

  @override
  bool operator ==(Object other) =>
      other is EditorTarget &&
      other.location == location &&
      other.host == host &&
      other.port == port &&
      other.user == user;

  @override
  int get hashCode => Object.hash(location, host, port, user);

  @override
  String toString() => 'EditorTarget($label)';
}

/// Whether [port] is a TCP port number.
bool validSshPort(int port) => port > 0 && port < 65536;

/// Whether [host] (a URL's host) is this computer.
bool isLoopbackHost(String host) {
  final name = host.toLowerCase();
  return name == 'localhost' ||
      name.endsWith('.localhost') ||
      name == '::1' ||
      name == '[::1]' ||
      name.startsWith('127.');
}

/// The target of an AHP host at [hostUrl] that has none yet: this
/// computer for a loopback address, else SSH to the URL's host on
/// port 22.
EditorTarget defaultEditorTarget(String hostUrl) {
  final host = Uri.tryParse(hostUrl.trim())?.host ?? '';
  return isLoopbackHost(host)
      ? const EditorTarget(location: EditorLocation.thisComputer)
      : EditorTarget(location: EditorLocation.ssh, host: host);
}

/// Why [target] cannot be used, or null when it can.
String? editorTargetProblem(EditorTarget target) => switch (target) {
  EditorTarget(location: EditorLocation.thisComputer) => null,
  EditorTarget(:final host) when host.trim().isEmpty => 'Enter the SSH host.',
  EditorTarget(:final port) when !validSshPort(port) =>
    'Enter a port from 1 to 65535.',
  _ => null,
};

/// The Remote - SSH authority of [host] as [user] on [port]: `user@host`
/// when that survives the editor lowercasing URL authorities, else the
/// hex-encoded JSON (`hostName`, `user`, `port`) Remote - SSH also reads.
String sshRemoteAuthority(String host, {String user = '', int port = 22}) {
  final plain = '${user.isEmpty ? '' : '$user@'}$host';
  if (port == defaultSshPort &&
      plain == plain.toLowerCase() &&
      !host.contains(':')) {
    return plain;
  }
  final json = jsonEncode({
    'hostName': host,
    if (user.isNotEmpty) 'user': user,
    if (port != defaultSshPort) 'port': port,
  });
  return [
    for (final byte in utf8.encode(json))
      byte.toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// The URL that opens [folder] (an absolute path) in [editor] at
/// [target]: `<scheme>://file<folder>` on this computer, else
/// `<scheme>://vscode-remote/ssh-remote+<authority><folder>`.
Uri openInEditorUri(
  CodeEditor editor,
  EditorTarget target,
  String folder,
) => switch (target.location) {
  EditorLocation.thisComputer => Uri(
    scheme: editor.scheme,
    host: 'file',
    path: folder,
  ),
  EditorLocation.ssh => Uri(
    scheme: editor.scheme,
    host: 'vscode-remote',
    path:
        '/ssh-remote+${sshRemoteAuthority(target.host.trim(), user: target.user.trim(), port: target.port)}'
        '$folder',
  ),
};

/// [key] (a folder key, [folderKeyOf]) when it is an absolute path an
/// editor can open, else null.
String? editorFolder(String? key) =>
    key != null && key.startsWith('/') ? key : null;

/// The folder of [summary] to open in an editor: its working directory
/// or project as a path, or null when it has none or it is not a `file:`
/// path.
String? sessionDirectory(SessionSummary? summary) =>
    editorFolder(summary == null ? null : folderKeyOf(summary));
