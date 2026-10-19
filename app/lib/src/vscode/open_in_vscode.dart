/// Opens a session's folder in VS Code (AV-015) with the link from
/// `vscode_link.dart`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../hosts/saved_hosts.dart';
import '../ssh/ssh_settings.dart';
import '../ssh/ssh_store.dart';
import 'vscode_link.dart';

/// The label of the button and menu item that open a session in VS Code.
const openInVsCodeLabel = 'Open in VS Code';

/// Whether the platform can have VS Code: not on iOS or Android.
bool get vscodeSupported =>
    kIsWeb ||
    (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android);

/// Opens a link with the system's handler, returning whether it did;
/// tests replace it.
final vscodeLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Opens [directory] on the AHP [host] in VS Code, over SSH with the
/// host's SSH settings when it is another machine. Says so when VS Code
/// does not open.
Future<void> openInVsCode(
  BuildContext context,
  WidgetRef ref,
  SavedHost host,
  String directory,
) async {
  SshSettings? ssh;
  try {
    ssh = await ref.read(sshStoreProvider).loadSettings(host.key);
  } on Object {
    ssh = null;
  }
  final uri = vscodeFolderUri(
    directory: directory,
    hostUrl: host.url,
    ssh: ssh,
  );
  bool opened;
  try {
    opened = await ref.read(vscodeLauncherProvider)(uri);
  } on Object {
    opened = false;
  }
  if (opened || !context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const SnackBar(
      content: Text(
        'Could not open VS Code. Is it installed, with the Remote - SSH '
        'extension for remote hosts?',
      ),
    ),
  );
}
