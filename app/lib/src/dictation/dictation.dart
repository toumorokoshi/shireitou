/// Dictation into the composer (AV-047): speech to text with an open
/// model (Whisper or Parakeet), run on this device by sherpa-onnx. Audio
/// never leaves it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dictation_io.dart' if (dart.library.js_interop) 'dictation_web.dart';
import 'dictation_text.dart';
import 'speech_model.dart';
import 'speech_model_store.dart';

/// Turns the microphone into text.
abstract interface class Dictation {
  /// The model that transcribes.
  SpeechModel get model;

  /// Whether [model] is on disk.
  Future<bool> hasModel();

  /// This dictation with [model] instead; [choose] keeps it.
  Dictation withModel(SpeechModel model);

  /// Makes [model] the one dictation uses from now on, kept on this
  /// device.
  Future<void> choose(SpeechModel model);

  /// Downloads [model].
  Future<void> downloadModel({DownloadProgress? onProgress});

  /// Starts listening; the model must be on disk. Throws a
  /// [DictationException] when the microphone cannot be opened.
  Future<DictationSession> listen();
}

/// One dictation, from the button press until it is stopped.
abstract interface class DictationSession {
  /// The transcript so far, each time it changes; done after [stop] has
  /// transcribed the last utterance, or after [cancel].
  Stream<Transcript> get transcripts;

  /// Stops the microphone and transcribes what was still being said.
  Future<void> stop();

  /// Stops the microphone and drops what was not transcribed yet.
  Future<void> cancel();
}

/// Why dictation could not start or went wrong, for people.
class DictationException implements Exception {
  /// Creates a [DictationException].
  const DictationException(this.message);

  /// The message.
  final String message;

  @override
  String toString() => message;
}

/// Dictation on this platform with the chosen [speechModelProvider]; null
/// where it is not supported (the web app, and widget tests that pretend
/// to be another platform).
final dictationProvider = Provider<Dictation?>(
  (ref) => platformDictation(
    ref.watch(speechModelProvider),
    choose: ref.read(speechModelProvider.notifier).set,
  ),
);
