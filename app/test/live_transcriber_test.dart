import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/dictation/live_transcriber.dart';

/// Speech is any sample of 1; an utterance ends at [endAfter] zeros.
class _FakeDetector implements VoiceDetector {
  _FakeDetector() : endAfter = 4;

  final int endAfter;
  final _current = <double>[];
  final _done = <Float32List>[];
  var _silence = 0;
  var flushed = false;

  @override
  void accept(Float32List samples) {
    for (final s in samples) {
      if (s == 1) {
        _current.add(s);
        _silence = 0;
      } else if (_current.isNotEmpty && ++_silence >= endAfter) {
        _done.add(Float32List.fromList(_current));
        _current.clear();
      }
    }
  }

  @override
  bool get speaking => _current.isNotEmpty;

  @override
  List<Float32List> takeUtterances() {
    final out = [..._done];
    _done.clear();
    return out;
  }

  @override
  void flush() {
    flushed = true;
    if (_current.length >= 3) {
      _done.add(Float32List.fromList(_current));
      _current.clear();
    }
  }
}

Float32List _audio(List<double> s) => Float32List.fromList(s);

void main() {
  late List<int> transcribed;
  // Says how many speech samples the clip holds.
  String transcribe(Float32List clip) {
    transcribed.add(clip.length);
    return 'n${clip.where((s) => s == 1).length}';
  }

  LiveTranscriber make({VoiceDetector? detector}) => LiveTranscriber(
    detector: detector ?? _FakeDetector(),
    transcribe: transcribe,
    sampleRate: 10,
    guessEvery: const Duration(milliseconds: 200),
    preroll: const Duration(milliseconds: 100),
  );

  setUp(() => transcribed = []);

  test('silence is never transcribed', () {
    final live = make();
    expect(live.accept(_audio([0, 0, 0, 0, 0, 0])), isEmpty);
    expect(live.finish(), isEmpty);
    expect(transcribed, isEmpty);
  });

  test('guesses while speaking, then finishes at a pause', () {
    final live = make();
    expect(live.accept(_audio([1])), isEmpty);
    expect(live.accept(_audio([1])), [const PartialTranscript('n2')]);
    expect(live.accept(_audio([1])), isEmpty);
    expect(live.accept(_audio([1])), [const PartialTranscript('n4')]);
    expect(live.accept(_audio([0, 0, 0, 0])), [
      const FinalTranscript('n4'),
      const PartialTranscript(''),
    ]);
  });

  test('the guess includes the preroll before speech', () {
    final live = make();
    live.accept(_audio([0, 0, 0, 0, 0]));
    live.accept(_audio([1, 1]));
    // One sample of preroll and two of speech.
    expect(transcribed, [3]);
  });

  test('an unchanged guess is not reported again', () {
    final live = make();
    expect(live.accept(_audio([1, 1])), [const PartialTranscript('n2')]);
    expect(live.accept(_audio([0, 0])), isEmpty);
  });

  test('finish ends the utterance in progress', () {
    final detector = _FakeDetector();
    final live = make(detector: detector);
    live.accept(_audio([1, 1, 1]));
    expect(live.finish(), [
      const FinalTranscript('n3'),
      const PartialTranscript(''),
    ]);
    expect(detector.flushed, isTrue);
  });

  test('finish transcribes speech too short for the detector', () {
    final live = make();
    live.accept(_audio([1, 1]));
    expect(live.finish(), [const FinalTranscript('n2')]);
  });

  test('a later utterance starts afresh', () {
    final live = make();
    live.accept(_audio([1, 1, 0, 0, 0, 0]));
    expect(live.accept(_audio([1, 1, 1])), [const PartialTranscript('n3')]);
  });
}
