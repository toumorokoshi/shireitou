/// Keeps the full report of each Flutter error in a file in debug builds
/// (AV-145).
///
/// The console prints only a run's first error in full and every later
/// one as an "Another exception was thrown" line. An error thrown in a
/// hover callback or a hit test leaves the mouse tracker asserting
/// `!_debugDuringDeviceUpdate` on every mouse move, so the one report
/// that names the cause scrolls out of sight in seconds.
library;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'error_log_io.dart' if (dart.library.js_interop) 'error_log_web.dart';

final _log = Logger('error_log');

/// How many distinct errors a run keeps, so a cascade cannot fill the
/// disk.
const maxLoggedErrors = 50;

/// The log's text for [details], reported at [time]: a dated header and
/// the full report, with its stack trace.
String errorLogEntry(FlutterErrorDetails details, DateTime time) =>
    '=== ${time.toIso8601String()} ===\n${'$details'.trimRight()}\n\n';

/// Passes each Flutter error to the handler already installed, then
/// gives [write] the [errorLogEntry] of each distinct error (by its
/// summary), up to [maxLoggedErrors] of them.
void logFlutterErrors(
  void Function(String entry) write, {
  DateTime Function() now = DateTime.now,
}) {
  final previous = FlutterError.onError;
  final seen = <String>{};
  FlutterError.onError = (details) {
    previous?.call(details);
    if (seen.length >= maxLoggedErrors) return;
    if (!seen.add(details.summary.toString())) return;
    write(errorLogEntry(details, now()));
  };
}

/// Starts the error log in debug builds of the desktop and mobile apps:
/// `logs/errors.log` in the app's support folder, the last run's kept
/// as `logs/errors.previous.log`.
Future<void> startErrorLog() async {
  if (!kDebugMode) return;
  final log = await openErrorLog();
  if (log == null) return;
  logFlutterErrors(log.write);
  _log.info('Full error reports go to ${log.path}');
}
