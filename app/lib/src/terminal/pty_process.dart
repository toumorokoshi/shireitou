/// A process in a pseudo-terminal (AV-016), behind an interface tests
/// replace. `pty_process_io.dart` starts one with `flutter_pty` where
/// `dart:ffi` exists; the web has none.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pty_process_web.dart'
    if (dart.library.ffi) 'pty_process_io.dart'
    as platform;

/// A running process attached to a pty.
abstract interface class PtyProcess {
  /// What the process writes to the terminal.
  Stream<Uint8List> get output;

  /// Completes with the exit code when the process ends.
  Future<int> get exitCode;

  /// Sends [data] (typed keys, pasted text) to the process.
  void write(Uint8List data);

  /// Tells the process the terminal is [rows] by [columns].
  void resize(int rows, int columns);

  /// Ends the process.
  void kill();
}

/// Starts [executable] with [arguments] and [environment] in a pty of
/// [rows] by [columns].
typedef PtySpawner = PtyProcess Function(
  String executable,
  List<String> arguments, {
  required Map<String, String> environment,
  required int rows,
  required int columns,
});

/// Starts processes in a pty; tests replace it with a fake.
final ptySpawnerProvider = Provider<PtySpawner>((ref) => platform.startPty);

/// The environment the app was started with, passed on to the process;
/// tests replace it.
final processEnvironmentProvider = Provider<Map<String, String>>(
  (ref) => platform.processEnvironment(),
);

/// Whether the terminal panel can run `ssh` here: the desktop apps, which
/// have a pty and a system SSH client. The web, iOS and Android open an
/// `ssh://` link instead.
bool get ptySupported =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      _ => false,
    };
