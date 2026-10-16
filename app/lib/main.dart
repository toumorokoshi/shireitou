import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'src/app.dart';
import 'src/desktop/desktop_window.dart';

Future<void> main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(
    (record) => debugPrint(
      '${record.time.toIso8601String()} ${record.level.name} '
      '${record.loggerName}: ${record.message}',
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  await setUpDesktopWindow();
  runApp(const ProviderScope(child: ShireitouApp()));
}
