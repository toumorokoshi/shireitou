import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/dictation/dictation.dart';
import 'package:shireitou/src/dictation/dictation_session.dart';
import 'package:shireitou/src/dictation/dictation_text.dart';
import 'package:shireitou/src/dictation/live_transcriber.dart';

/// Guesses the number of samples so far for each batch; finish commits it. Each
/// request waits for [release] when [hold] is set.
class _FakeEngine implements SpeechEngine {
  final batches = <int>[];
  var total = 0;
  var killed = false;
  var finished = false;
  bool hold = false;
  Completer<void>? _gate;

  void release() => _gate?.complete();

  Future<void> _wait() async {
    if (!hold) return;
    _gate = Completer();
    await _gate!.future;
  }

  @override
  Future<List<TranscriptEvent>> accept(Float32List samples) async {
    batches.add(samples.length);
    total += samples.length;
    await _wait();
    return [PartialTranscript('$total')];
  }

  @override
  Future<List<TranscriptEvent>> finish() async {
    finished = true;
    return [FinalTranscript('$total')];
  }

  @override
  void kill() => killed = true;
}

Uint8List _pcm(int samples) => Uint8List(samples * 2);

void main() {
  late StreamController<Uint8List> mic;
  late _FakeEngine engine;
  late Completer<SpeechEngine> loading;
  late PumpedSession session;
  late List<Transcript> seen;
  late Future<void> done;
  var micStopped = false;

  setUp(() {
    mic = StreamController();
    engine = _FakeEngine();
    loading = Completer();
    micStopped = false;
    session = PumpedSession(
      audio: mic.stream,
      engine: loading.future,
      stopAudio: () async {
        micStopped = true;
        if (!mic.isClosed) await mic.close();
      },
    );
    seen = [];
    done = session.transcripts.forEach(seen.add);
  });

  test('keeps audio while the model loads, then sends it at once', () async {
    mic.add(_pcm(100));
    mic.add(_pcm(50));
    await pumpEventQueue();
    expect(engine.batches, isEmpty);
    loading.complete(engine);
    await pumpEventQueue();
    expect(engine.batches, [150]);
    expect(seen.last.partial, '150');
  });

  test('batches audio that arrives while the engine works', () async {
    loading.complete(engine);
    engine.hold = true;
    mic.add(_pcm(10));
    await pumpEventQueue();
    mic.add(_pcm(20));
    mic.add(_pcm(30));
    await pumpEventQueue();
    expect(engine.batches, [10]);
    engine.hold = false;
    engine.release();
    await pumpEventQueue();
    expect(engine.batches, [10, 50]);
  });

  test('joins an odd byte with the next chunk', () async {
    loading.complete(engine);
    mic.add(Uint8List(3));
    await pumpEventQueue();
    mic.add(Uint8List(1));
    await pumpEventQueue();
    expect(engine.total, 2);
  });

  test('stop transcribes the rest, then ends', () async {
    loading.complete(engine);
    mic.add(_pcm(40));
    await session.stop();
    await done;
    expect(micStopped, isTrue);
    expect(engine.finished, isTrue);
    expect(seen.last, const Transcript(committed: ['40']));
  });

  test('stop before the model loads still transcribes', () async {
    mic.add(_pcm(40));
    await session.stop();
    loading.complete(engine);
    await done;
    expect(seen.last, const Transcript(committed: ['40']));
  });

  test('cancel ends at once and stops the engine', () async {
    loading.complete(engine);
    await pumpEventQueue();
    await session.cancel();
    await done;
    expect(micStopped, isTrue);
    expect(engine.killed, isTrue);
    expect(engine.finished, isFalse);
  });

  test('an engine that fails to load is reported', () async {
    loading.completeError(Exception('no model'));
    await expectLater(done, throwsA(isA<DictationException>()));
    expect(micStopped, isTrue);
  });
}
