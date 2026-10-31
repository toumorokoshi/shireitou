/// The error log's file on the desktop and mobile apps (AV-145).
library;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('error_log');

/// Where the log is and how to add an entry to it.
typedef ErrorLogFile = ({String path, void Function(String entry) write});

/// Starts a fresh `logs/errors.log` in the app's support folder, keeping
/// the last run's as `logs/errors.previous.log`; null when the folder
/// cannot be written.
Future<ErrorLogFile?> openErrorLog() async {
  try {
    final support = await getApplicationSupportDirectory();
    final dir = await Directory('${support.path}/logs').create(recursive: true);
    final file = File('${dir.path}/errors.log');
    if (file.existsSync()) file.renameSync('${dir.path}/errors.previous.log');
    file.writeAsStringSync('');
    return (path: file.path, write: (String entry) => _append(file, entry));
  } on Exception catch (e) {
    _log.warning('Cannot open the error log: $e');
    return null;
  }
}

void _append(File file, String entry) {
  try {
    file.writeAsStringSync(entry, mode: FileMode.append, flush: true);
  } on FileSystemException catch (e) {
    _log.warning('Cannot write the error log: $e');
  }
}
