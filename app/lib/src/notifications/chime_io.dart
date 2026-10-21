/// The chime on the desktop and mobile apps, through SoLoud
/// (`flutter_soloud`, miniaudio over Core Audio, WASAPI, ALSA or
/// PulseAudio, and AAudio).
library;

import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import 'chime.dart';

final _log = Logger('notifications');

/// The native [Chime]. The target platform and the real one
/// (`dart:io`) must agree, so widget tests that pretend to be another
/// platform play nothing.
Chime? platformChime() {
  final real = switch (defaultTargetPlatform) {
    TargetPlatform.macOS => Platform.isMacOS,
    TargetPlatform.linux => Platform.isLinux,
    TargetPlatform.windows => Platform.isWindows,
    TargetPlatform.android => Platform.isAndroid,
    TargetPlatform.iOS => Platform.isIOS,
    _ => false,
  };
  return real ? SoLoudChime() : null;
}

/// [Chime] on SoLoud. The engine runs only while the chime plays: an
/// open output stream keeps the audio hardware awake (and on macOS
/// holds off idle sleep) for an app that runs all day.
class SoLoudChime implements Chime {
  Future<void>? _playing;

  /// Time after the sound ends before the engine stops.
  static const _tail = Duration(milliseconds: 200);

  @override
  Future<void> play() =>
      _playing ??= _play().whenComplete(() => _playing = null);

  Future<void> _play() async {
    final soloud = SoLoud.instance;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Ambient: mixes with other apps' audio and follows the silent
        // switch, instead of stopping the user's music.
        final session = await AudioSession.instance;
        await session.configure(
          const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.ambient,
          ),
        );
      }
      await soloud.init();
      final sound = await soloud.loadAsset(chimeAsset);
      soloud.play(sound);
      await Future<void>.delayed(soloud.getLength(sound) + _tail);
    } on Object catch (error) {
      _log.warning('could not play the chime: $error');
    } finally {
      if (soloud.isInitialized) soloud.deinit();
    }
  }
}
