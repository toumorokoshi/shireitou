/// The chime in the web build: two short notes through the Web Audio
/// API, so no sound file is downloaded.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

import 'chime.dart';

final _log = Logger('notifications');

/// The browser's [Chime], or null when it has no Web Audio API.
Chime? platformChime() =>
    globalContext.has('AudioContext') ? WebAudioChime() : null;

/// [Chime] on one shared `AudioContext`. Browsers only start audio
/// after the user has interacted with the page, which connecting to a
/// host always involves.
class WebAudioChime implements Chime {
  web.AudioContext? _context;

  /// The notes (Hz) and when each starts (seconds after the first).
  static const _notes = [(880.0, 0.0), (1318.5, 0.12)];

  @override
  Future<void> play() async {
    try {
      final context = _context ??= web.AudioContext();
      if (context.state == 'suspended') await context.resume().toDart;
      final now = context.currentTime;
      for (final (frequency, offset) in _notes) {
        final start = now + offset;
        final gain = context.createGain();
        gain.gain
          ..setValueAtTime(0.0001, start)
          ..exponentialRampToValueAtTime(0.2, start + 0.01)
          ..exponentialRampToValueAtTime(0.0001, start + 0.6);
        gain.connect(context.destination);
        final oscillator = context.createOscillator()..type = 'sine';
        oscillator.frequency.value = frequency;
        oscillator
          ..connect(gain)
          ..start(start)
          ..stop(start + 0.6);
      }
    } on Object catch (error) {
      _log.warning('could not play the chime: $error');
    }
  }
}
