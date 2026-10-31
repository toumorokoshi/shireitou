/// Tests for the debug error log (AV-145): the entries it writes and
/// which errors it keeps.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/diagnostics/error_log.dart';

FlutterErrorDetails _error(String message) {
  try {
    throw StateError(message);
  } on StateError catch (e, stack) {
    return FlutterErrorDetails(
      exception: e,
      stack: stack,
      library: 'rendering library',
      context: ErrorDescription('during a hit test'),
    );
  }
}

/// Runs [body] with [logFlutterErrors] writing to the returned list and
/// a handler before it that counts calls, then puts the test's own
/// handler back.
(List<String>, int Function()) _withLog(void Function() body) {
  final original = FlutterError.onError;
  var previousCalls = 0;
  final entries = <String>[];
  try {
    FlutterError.onError = (_) => previousCalls++;
    logFlutterErrors(entries.add, now: () => DateTime.utc(2026, 10, 30));
    body();
  } finally {
    FlutterError.onError = original;
  }
  return (entries, () => previousCalls);
}

void main() {
  test('an entry has a dated header, the full report and the stack', () {
    final entry = errorLogEntry(_error('boom'), DateTime.utc(2026, 10, 30));

    expect(entry, startsWith('=== 2026-10-30T00:00:00.000Z ===\n'));
    expect(entry, contains('Bad state: boom'));
    expect(entry, contains('during a hit test'));
    expect(entry, contains('_error'));
    expect(entry, endsWith('\n\n'));
  });

  test('each distinct error is written once and still reported', () {
    final (entries, previousCalls) = _withLog(() {
      FlutterError.reportError(_error('first'));
      FlutterError.reportError(_error('first'));
      FlutterError.reportError(_error('second'));
    });

    expect(previousCalls(), 3);
    expect(entries, hasLength(2));
    expect(entries.first, contains('Bad state: first'));
    expect(entries.last, contains('Bad state: second'));
  });

  test('a cascade stops being written after maxLoggedErrors', () {
    final (entries, previousCalls) = _withLog(() {
      for (var i = 0; i < maxLoggedErrors + 10; i++) {
        FlutterError.reportError(_error('error $i'));
      }
    });

    expect(previousCalls(), maxLoggedErrors + 10);
    expect(entries, hasLength(maxLoggedErrors));
  });
}
