/// The chime on the desktop apps: the system's notification sound,
/// played by the platform's own sound player (see [chimeCommands]).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'chime.dart';

final _log = Logger('notifications');

/// The desktop [Chime], or null elsewhere. The target platform and the
/// real one (`dart:io`) must agree, so widget tests that pretend to be
/// another platform play nothing.
Chime? platformChime() {
  final real = switch (defaultTargetPlatform) {
    TargetPlatform.macOS => Platform.isMacOS,
    TargetPlatform.linux => Platform.isLinux,
    TargetPlatform.windows => Platform.isWindows,
    _ => false,
  };
  return real ? ProcessChime(chimeCommands(defaultTargetPlatform)) : null;
}

/// [Chime] that runs the first of [commands] that is installed and
/// succeeds.
class ProcessChime implements Chime {
  /// Creates a [ProcessChime].
  const ProcessChime(this.commands);

  /// The commands to try, in order.
  final List<ChimeCommand> commands;

  @override
  Future<void> play() async {
    for (final c in commands) {
      try {
        final result = await Process.run(c.executable, c.arguments);
        if (result.exitCode == 0) return;
        _log.fine('${c.executable} exited with ${result.exitCode}');
      } on ProcessException catch (error) {
        _log.fine('${c.executable} is not available: ${error.message}');
      }
    }
    _log.info('no program played the chime');
  }
}
