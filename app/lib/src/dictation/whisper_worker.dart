/// Whisper and Silero VAD through sherpa-onnx, in an isolate of their own
/// so that transcribing never blocks the UI (AV-047).
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'dictation_session.dart';
import 'dictation_text.dart';
import 'live_transcriber.dart';
import 'model_store.dart';

/// The sample rate Whisper and the VAD take.
const whisperSampleRate = 16000;

/// A [LiveTranscriber] running in another isolate. One request at a time:
/// the caller waits for [accept] before sending more audio, so audio that
/// arrives while Whisper works is sent as one batch next time and the
/// guesses keep up however fast the machine is.
class WhisperWorker implements SpeechEngine {
  WhisperWorker._(this._isolate, this._requests, this._replies);

  final Isolate _isolate;
  final SendPort _requests;
  final StreamIterator<Object?> _replies;

  /// Loads the model in a new isolate; [library] is the folder of
  /// sherpa-onnx's native library when it is not linked into the app
  /// (tests).
  static Future<WhisperWorker> spawn(
    ModelPaths paths, {
    String? library,
  }) async {
    final port = ReceivePort();
    final replies = StreamIterator<Object?>(port);
    final isolate = await Isolate.spawn(
      _main,
      (port.sendPort, paths, library),
      onError: port.sendPort,
      onExit: port.sendPort,
      debugName: 'whisper',
    );
    final first = await _next(replies);
    return WhisperWorker._(isolate, first as SendPort, replies);
  }

  @override
  Future<List<TranscriptEvent>> accept(Float32List samples) =>
      _ask(TransferableTypedData.fromList([samples]));

  @override
  Future<List<TranscriptEvent>> finish() => _ask(_finish);

  @override
  void kill() => _isolate.kill(priority: Isolate.immediate);

  Future<List<TranscriptEvent>> _ask(Object request) async {
    _requests.send(request);
    return (await _next(_replies) as List).cast<TranscriptEvent>();
  }

  static Future<Object?> _next(StreamIterator<Object?> replies) async {
    if (!await replies.moveNext()) {
      throw StateError('The Whisper isolate has stopped');
    }
    return switch (replies.current) {
      _Ok(:final value) => value,
      _Failed(:final message) => throw Exception('Whisper failed: $message'),
      // Isolate.spawn's onError: the error and its stack trace as strings.
      [final error, _] => throw Exception('Whisper failed: $error'),
      _ => throw StateError('The Whisper isolate has stopped'),
    };
  }
}

/// A reply from the isolate.
final class _Ok {
  const _Ok(this.value);
  final Object value;
}

/// The isolate's failure, which also ends it.
final class _Failed {
  const _Failed(this.message);
  final String message;
}

const _finish = 'finish';

Future<void> _main((SendPort, ModelPaths, String?) args) async {
  final (replies, paths, library) = args;
  final requests = ReceivePort();
  final sherpa.OfflineRecognizer recognizer;
  final sherpa.VoiceActivityDetector vad;
  try {
    sherpa.initBindings(library);
    recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: paths.encoder,
            decoder: paths.decoder,
            language: 'en',
          ),
          tokens: paths.tokens,
          modelType: 'whisper',
          numThreads: min(4, max(1, Platform.numberOfProcessors ~/ 2)),
          debug: false,
        ),
      ),
    );
    vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: paths.vad,
          minSilenceDuration: 0.6,
          // Whisper takes at most 30 s; shorter keeps each guess quick.
          maxSpeechDuration: 15,
        ),
        sampleRate: whisperSampleRate,
        debug: false,
      ),
      bufferSizeInSeconds: 60,
    );
  } catch (e) {
    replies.send(_Failed('$e'));
    requests.close();
    return;
  }
  final transcriber = LiveTranscriber(
    detector: _SileroDetector(vad),
    transcribe: (samples) => _transcribe(recognizer, samples),
    sampleRate: whisperSampleRate,
  );
  replies.send(_Ok(requests.sendPort));
  await for (final request in requests) {
    try {
      if (request == _finish) {
        replies.send(_Ok(transcriber.finish()));
        break;
      }
      final samples = (request as TransferableTypedData)
          .materialize()
          .asFloat32List();
      replies.send(_Ok(transcriber.accept(samples)));
    } catch (e) {
      replies.send(_Failed('$e'));
      break;
    }
  }
  requests.close();
  vad.free();
  recognizer.free();
}

String _transcribe(sherpa.OfflineRecognizer recognizer, Float32List samples) {
  final stream = recognizer.createStream();
  try {
    stream.acceptWaveform(samples: samples, sampleRate: whisperSampleRate);
    recognizer.decode(stream);
    return cleanTranscript(recognizer.getResult(stream).text);
  } finally {
    stream.free();
  }
}

/// Silero VAD, fed in the 512-sample windows it takes.
class _SileroDetector implements VoiceDetector {
  _SileroDetector(this._vad);

  final sherpa.VoiceActivityDetector _vad;
  static const _window = 512;
  var _rest = Float32List(0);

  @override
  void accept(Float32List samples) {
    final all = Float32List(_rest.length + samples.length)
      ..setAll(0, _rest)
      ..setAll(_rest.length, samples);
    var start = 0;
    for (; start + _window <= all.length; start += _window) {
      _vad.acceptWaveform(Float32List.sublistView(all, start, start + _window));
    }
    _rest = Float32List.fromList(Float32List.sublistView(all, start));
  }

  @override
  bool get speaking => _vad.isDetected();

  @override
  List<Float32List> takeUtterances() {
    final utterances = <Float32List>[];
    while (!_vad.isEmpty()) {
      utterances.add(_vad.front().samples);
      _vad.pop();
    }
    return utterances;
  }

  @override
  void flush() => _vad.flush();
}
