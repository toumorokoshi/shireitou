import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'src/app.dart';
import 'src/desktop/desktop_window.dart';
import 'src/desktop/sandbox_prefs.dart';
import 'src/prefs.dart';

/// Keeps the semantics tree on for browser tests (`app/web_test`), which
/// find widgets through it; built with `--dart-define=SHIREITOU_SEMANTICS=true`.
SemanticsHandle? testSemantics;

Future<void> main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(
    (record) => debugPrint(
      '${record.time.toIso8601String()} ${record.level.name} '
      '${record.loggerName}: ${record.message}',
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('SHIREITOU_SEMANTICS')) {
    testSemantics = SemanticsBinding.instance.ensureSemantics();
  }
  await migrateSandboxPrefs(SharedPrefsStore());
  await setUpDesktopWindow();
  runApp(const ProviderScope(child: ShireitouApp()));
}
