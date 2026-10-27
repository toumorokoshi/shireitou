/// A dictation: microphone audio through a transcriber, as a stream of
/// transcripts (AV-047).
library;

import 'dart:async';
import 'dart:typed_data';

import 'dictation.dart';
import 'dictation_text.dart';
import 'live_transcriber.dart';

/// A transcriber that takes one request at a time (the speech isolate).
abstract interface class SpeechEngine {
  /// Adds audio; returns the events it caused.
  Future<List<TranscriptEvent>> accept(Float32List samples);

  /// Ends the audio; returns the last events. The engine is done after.
  Future<List<TranscriptEvent>> finish();

  /// Stops the engine at once.
  void kill();
}

/// A [DictationSession] that feeds 16-bit PCM [audio] to an [engine]
/// that may still be loading: audio is kept until the engine is ready
/// and while it works, then sent in one batch, so nothing said while the
/// model loads is lost.
class PumpedSession implements DictationSession {
  /// Starts a session; `stopAudio` stops the microphone, after which
  /// [audio] must end.
  PumpedSession({
    required Stream<Uint8List> audio,
    required Future<SpeechEngine> engine,
    required this._stopAudio,
  }) {
    _audio = audio.listen(
      _onAudio,
      onError: _fail,
      onDone: () {
        _audioDone = true;
        _pump();
      },
    );
    engine.then((e) {
      if (_closed) return e.kill();
      _engine = e;
      _pump();
    }, onError: _fail);
  }

  final Future<void> Function() _stopAudio;
  late final StreamSubscription<Uint8List> _audio;
  final _transcripts = StreamController<Transcript>();
  SpeechEngine? _engine;
  var _transcript = const Transcript();
  var _rest = Uint8List(0);
  final _pending = <Float32List>[];
  var _busy = false;
  var _stopping = false;
  var _audioDone = false;
  var _closed = false;

  @override
  Stream<Transcript> get transcripts => _transcripts.stream;

  @override
  Future<void> stop() async {
    if (_stopping || _closed) return;
    _stopping = true;
    await _stopAudio();
  }

  @override
  Future<void> cancel() async {
    if (_closed) return;
    _close();
    await _audio.cancel();
    await _stopAudio();
  }

  void _onAudio(Uint8List bytes) {
    final (:samples, :rest) = decodePcm16(
      _rest.isEmpty
          ? bytes
          : (BytesBuilder()
                  ..add(_rest)
                  ..add(bytes))
                .toBytes(),
    );
    _rest = Uint8List.fromList(rest);
    if (samples.isNotEmpty) _pending.add(samples);
    _pump();
  }

  Future<void> _pump() async {
    final engine = _engine;
    if (_busy || _closed || engine == null) return;
    _busy = true;
    try {
      if (_pending.isNotEmpty) {
        _apply(await engine.accept(_takePending()));
      } else if (_stopping && _audioDone) {
        _apply(await engine.finish());
        _close();
        return;
      } else {
        return;
      }
    } catch (e) {
      _fail(e);
      return;
    } finally {
      _busy = false;
    }
    unawaited(_pump());
  }

  Float32List _takePending() {
    final all = Float32List(_pending.fold(0, (n, s) => n + s.length));
    var offset = 0;
    for (final s in _pending) {
      all.setAll(offset, s);
      offset += s.length;
    }
    _pending.clear();
    return all;
  }

  void _apply(List<TranscriptEvent> events) {
    if (_closed) return;
    final next = events.fold(_transcript, (t, e) => t.apply(e));
    if (next == _transcript) return;
    _transcript = next;
    _transcripts.add(next);
  }

  void _fail(Object error) {
    if (_closed) return;
    _transcripts.addError(
      error is DictationException ? error : DictationException('$error'),
    );
    _close();
    unawaited(_audio.cancel());
    unawaited(_stopAudio());
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _engine?.kill();
    unawaited(_transcripts.close());
  }
}
