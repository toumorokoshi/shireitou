/// The chime played when it is the user's turn (AV-121), beside the
/// notification: the interface, and the system sound each desktop
/// platform plays.
library;

import 'package:flutter/foundation.dart';

/// Plays the chime.
abstract interface class Chime {
  /// Plays the chime once; failures are logged, never thrown.
  Future<void> play();
}

/// A program that plays a sound, with its arguments.
typedef ChimeCommand = ({String executable, List<String> arguments});

const _freedesktopSound =
    '/usr/share/sounds/freedesktop/stereo/message-new-instant.oga';

/// The commands that play the system's notification sound on [platform],
/// in order of preference: the first one that runs and succeeds is the
/// chime. Empty where the app plays none (mobile notifications make
/// their own sound).
List<ChimeCommand> chimeCommands(TargetPlatform platform) => switch (platform) {
  TargetPlatform.macOS => const [
    (
      executable: '/usr/bin/afplay',
      arguments: ['/System/Library/Sounds/Glass.aiff'],
    ),
  ],
  // libcanberra plays the sound theme's sound; PulseAudio's and
  // PipeWire's players play the freedesktop theme's file directly.
  TargetPlatform.linux => const [
    (executable: 'canberra-gtk-play', arguments: ['--id=message-new-instant']),
    (executable: 'paplay', arguments: [_freedesktopSound]),
    (executable: 'pw-play', arguments: [_freedesktopSound]),
  ],
  TargetPlatform.windows => const [
    (
      executable: 'powershell.exe',
      arguments: [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(New-Object Media.SoundPlayer "$env:SystemRoot\Media\Windows Notify System Generic.wav").PlaySync()',
      ],
    ),
  ],
  _ => const [],
};
