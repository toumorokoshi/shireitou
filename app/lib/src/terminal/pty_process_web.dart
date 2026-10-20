/// The web has no pty; the terminal panel opens an `ssh://` link there.
library;

import 'pty_process.dart';

/// Throws: browsers cannot start processes.
PtyProcess startPty(
  String executable,
  List<String> arguments, {
  required Map<String, String> environment,
  required int rows,
  required int columns,
}) => throw UnsupportedError('Browsers cannot start processes.');

/// No environment on the web.
Map<String, String> processEnvironment() => const {};
