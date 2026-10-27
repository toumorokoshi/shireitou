/// Writing dictated speech into the composer (AV-047): pure functions
/// from the box's text and the transcript so far to the box's new text.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'live_transcriber.dart';

/// The transcript of one dictation so far: the utterances Whisper has
/// finished, and its current guess at the one still being spoken.
class Transcript {
  /// Creates a [Transcript].
  const Transcript({this.committed = const [], this.partial = ''});

  /// Finished utterances, oldest first.
  final List<String> committed;

  /// The utterance being spoken, re-transcribed as it grows; replaced by
  /// a committed one when the speaker pauses.
  final String partial;

  /// The utterances joined by spaces.
  String get text =>
      [...committed, partial].where((s) => s.isNotEmpty).join(' ');

  /// Whether nothing has been transcribed.
  bool get isEmpty => text.isEmpty;

  /// This transcript after [event].
  Transcript apply(TranscriptEvent event) => switch (event) {
    FinalTranscript(:final text) => commit(text),
    PartialTranscript(:final text) => guess(text),
  };

  /// This transcript with [utterance] finished.
  Transcript commit(String utterance) => Transcript(
    committed: [...committed, if (utterance.isNotEmpty) utterance],
  );

  /// This transcript with [utterance] as the current guess.
  Transcript guess(String utterance) =>
      Transcript(committed: committed, partial: utterance);

  @override
  bool operator ==(Object other) =>
      other is Transcript &&
      other.partial == partial &&
      listEquals(other.committed, committed);

  @override
  int get hashCode => Object.hash(partial, Object.hashAll(committed));

  @override
  String toString() => 'Transcript($committed, partial: $partial)';
}

/// Where a dictation writes: the box's text before and after its
/// selection when dictation started (a selection is replaced).
class DictationAnchor {
  /// Creates a [DictationAnchor].
  const DictationAnchor(this.before, this.after);

  /// The anchor at [value]'s selection, or at its end when it has none.
  factory DictationAnchor.at(TextEditingValue value) {
    final text = value.text;
    final selection = value.selection;
    if (!selection.isValid) return DictationAnchor(text, '');
    return DictationAnchor(
      selection.textBefore(text),
      selection.textAfter(text),
    );
  }

  /// Text before the dictated speech.
  final String before;

  /// Text after it.
  final String after;

  /// The box's value with [spoken] between [before] and [after],
  /// separated from them by a space where they do not end or start
  /// with whitespace, and the caret after it.
  TextEditingValue write(String spoken) {
    final lead = spoken.isNotEmpty && _needsSpace(before, atEnd: true)
        ? ' '
        : '';
    final trail = spoken.isNotEmpty && _needsSpace(after, atEnd: false)
        ? ' '
        : '';
    final head = '$before$lead$spoken';
    return TextEditingValue(
      text: '$head$trail$after',
      selection: TextSelection.collapsed(offset: head.length),
    );
  }

  static bool _needsSpace(String text, {required bool atEnd}) {
    if (text.isEmpty) return false;
    final char = atEnd ? text[text.length - 1] : text[0];
    return char.trim().isNotEmpty;
  }
}

/// Whisper's [text] without the sound tags it writes for non-speech
/// ("[BLANK_AUDIO]", "(wind blowing)", "*coughs*"), with whitespace
/// collapsed.
String cleanTranscript(String text) => text
    .replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)|\*[^*]*\*'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Little-endian 16-bit PCM bytes as samples in [-1, 1], with the odd
/// byte left over (to prepend to the next chunk).
({Float32List samples, Uint8List rest}) decodePcm16(Uint8List bytes) {
  final count = bytes.length ~/ 2;
  final data = ByteData.sublistView(bytes);
  final samples = Float32List(count);
  for (var i = 0; i < count; i++) {
    samples[i] = data.getInt16(i * 2, Endian.little) / 32768;
  }
  return (samples: samples, rest: Uint8List.sublistView(bytes, count * 2));
}
