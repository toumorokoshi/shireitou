/// The chime in the web build: [chimeAsset] decoded and played by the
/// browser's Web Audio API, which needs no WebAssembly audio engine.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
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
  Future<web.AudioBuffer>? _sound;

  Future<web.AudioBuffer> _decode(web.AudioContext context) async {
    final data = await rootBundle.load(chimeAsset);
    final bytes = Uint8List.sublistView(data);
    return context
        .decodeAudioData(Uint8List.fromList(bytes).buffer.toJS)
        .toDart;
  }

  @override
  Future<void> play() async {
    try {
      final context = _context ??= web.AudioContext();
      if (context.state == 'suspended') await context.resume().toDart;
      final sound = await (_sound ??= _decode(context));
      context.createBufferSource()
        ..buffer = sound
        ..connect(context.destination)
        ..start();
    } on Object catch (error) {
      _sound = null;
      _log.warning('could not play the chime: $error');
    }
  }
}
