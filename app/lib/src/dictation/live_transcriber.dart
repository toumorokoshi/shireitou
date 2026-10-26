/// Live transcription with a batch model (AV-047): Whisper only
/// transcribes whole clips, so the utterance being spoken is
/// re-transcribed as it grows (a guess shown while talking), and a voice
/// activity detector ends each utterance at a pause, when it is
/// transcribed once more and kept.
library;

import 'dart:typed_data';

/// Finds speech in audio (Silero VAD in the app).
abstract interface class VoiceDetector {
  /// Adds samples.
  void accept(Float32List samples);

  /// Whether speech is going on at the end of the samples so far.
  bool get speaking;

  /// The utterances ended by a pause since the last call, oldest first.
  List<Float32List> takeUtterances();

  /// Ends the utterance in progress, for [takeUtterances].
  void flush();
}

/// Transcribes a clip; the text is trimmed.
typedef Transcribe = String Function(Float32List samples);

/// What [LiveTranscriber] reports.
sealed class TranscriptEvent {
  const TranscriptEvent(this.text);

  /// The text, possibly empty.
  final String text;
}

/// The current guess at the utterance being spoken.
final class PartialTranscript extends TranscriptEvent {
  /// Creates a [PartialTranscript].
  const PartialTranscript(super.text);

  @override
  bool operator ==(Object other) =>
      other is PartialTranscript && other.text == text;

  @override
  int get hashCode => Object.hash(PartialTranscript, text);

  @override
  String toString() => 'PartialTranscript($text)';
}

/// A finished utterance; replaces the guess.
final class FinalTranscript extends TranscriptEvent {
  /// Creates a [FinalTranscript].
  const FinalTranscript(super.text);

  @override
  bool operator ==(Object other) =>
      other is FinalTranscript && other.text == text;

  @override
  int get hashCode => Object.hash(FinalTranscript, text);

  @override
  String toString() => 'FinalTranscript($text)';
}

/// Turns audio into [TranscriptEvent]s with a [VoiceDetector] and a
/// batch [Transcribe].
class LiveTranscriber {
  /// Creates a [LiveTranscriber] for audio at [sampleRate].
  LiveTranscriber({
    required this.detector,
    required this.transcribe,
    this.sampleRate = 16000,
    this.guessEvery = const Duration(milliseconds: 400),
    this.preroll = const Duration(milliseconds: 300),
  });

  /// Finds the utterances.
  final VoiceDetector detector;

  /// Transcribes a clip.
  final Transcribe transcribe;

  /// Samples per second.
  final int sampleRate;

  /// How much new speech there must be before the guess is redone.
  final Duration guessEvery;

  /// Audio kept from before speech is detected, so the guess does not
  /// clip the first syllable.
  final Duration preroll;

  /// The audio of the utterance in progress (or the preroll when there
  /// is none).
  final _utterance = <double>[];
  bool _speaking = false;
  int _sinceGuess = 0;
  String _guess = '';

  int _samples(Duration d) => d.inMicroseconds * sampleRate ~/ 1000000;

  /// Adds [samples]; returns the utterances they finished and a new
  /// guess, if any.
  List<TranscriptEvent> accept(Float32List samples) {
    detector.accept(samples);
    _utterance.addAll(samples);
    final finished = _finished();
    if (finished.isNotEmpty) return finished;
    if (!_speaking && detector.speaking) _speaking = true;
    if (!_speaking) {
      _trimToPreroll();
      return const [];
    }
    _sinceGuess += samples.length;
    if (_sinceGuess < _samples(guessEvery)) return const [];
    _sinceGuess = 0;
    final guess = transcribe(Float32List.fromList(_utterance));
    if (guess == _guess) return const [];
    _guess = guess;
    return [PartialTranscript(guess)];
  }

  /// Ends the audio: the utterance in progress is finished.
  List<TranscriptEvent> finish() {
    detector.flush();
    final finished = _finished();
    if (finished.isNotEmpty || !_speaking) return finished;
    // Too short for the detector to call it speech, but a guess was
    // shown, so it is transcribed rather than dropped.
    final text = transcribe(Float32List.fromList(_utterance));
    _reset();
    return [
      if (text.isNotEmpty)
        FinalTranscript(text)
      else
        const PartialTranscript(''),
    ];
  }

  List<TranscriptEvent> _finished() {
    final utterances = detector.takeUtterances();
    if (utterances.isEmpty) return const [];
    _reset();
    return [
      for (final clip in utterances)
        if (transcribe(clip) case final text when text.isNotEmpty)
          FinalTranscript(text),
      // The guess is cleared even when the utterances were silence.
      const PartialTranscript(''),
    ];
  }

  void _reset() {
    _utterance.clear();
    _speaking = false;
    _sinceGuess = 0;
    _guess = '';
  }

  void _trimToPreroll() {
    final excess = _utterance.length - _samples(preroll);
    if (excess > 0) _utterance.removeRange(0, excess);
  }
}
