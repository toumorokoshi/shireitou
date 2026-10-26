import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/dictation/dictation_text.dart';
import 'package:shireitou/src/dictation/live_transcriber.dart';

void main() {
  group('Transcript', () {
    test('joins finished utterances and the guess', () {
      final t = const Transcript()
          .apply(const PartialTranscript('Hello'))
          .apply(const FinalTranscript('Hello there.'))
          .apply(const PartialTranscript('How are'));
      expect(t.committed, ['Hello there.']);
      expect(t.text, 'Hello there. How are');
    });

    test('a finished utterance replaces the guess', () {
      final t = const Transcript(partial: 'How are')
          .apply(const FinalTranscript('How are you?'));
      expect(t, const Transcript(committed: ['How are you?']));
    });

    test('empty utterances add nothing', () {
      final t = const Transcript().apply(const FinalTranscript(''));
      expect(t.isEmpty, isTrue);
      expect(t.text, '');
    });
  });

  group('DictationAnchor', () {
    test('writes at the end of an empty box', () {
      final anchor = DictationAnchor.at(TextEditingValue.empty);
      expect(
        anchor.write('Fix the tests.'),
        const TextEditingValue(
          text: 'Fix the tests.',
          selection: TextSelection.collapsed(offset: 14),
        ),
      );
    });

    test('adds spaces between the speech and the text around it', () {
      final anchor = DictationAnchor.at(
        const TextEditingValue(
          text: 'Please then commit.',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      final value = anchor.write('run the tests');
      expect(value.text, 'Please run the tests then commit.');
      expect(value.selection, const TextSelection.collapsed(offset: 20));
    });

    test('adds no space next to whitespace', () {
      final anchor = DictationAnchor.at(
        const TextEditingValue(
          text: 'a\n b',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(anchor.write('x').text, 'a\nx b');
    });

    test('replaces the selection', () {
      final anchor = DictationAnchor.at(
        const TextEditingValue(
          text: 'use npm here',
          selection: TextSelection(baseOffset: 4, extentOffset: 7),
        ),
      );
      expect(anchor.write('pnpm').text, 'use pnpm here');
    });

    test('nothing spoken leaves the text as it was', () {
      final anchor = DictationAnchor.at(
        const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(anchor.write('').text, 'ab');
    });

    test('writes at the end without a selection', () {
      final anchor = DictationAnchor.at(const TextEditingValue(text: 'Hi'));
      expect(anchor.write('there').text, 'Hi there');
    });
  });

  test('cleanTranscript drops sound tags', () {
    expect(cleanTranscript(' [BLANK_AUDIO] '), '');
    expect(
      cleanTranscript('(wind blowing) Hello  *coughs* there'),
      'Hello there',
    );
    expect(cleanTranscript(' Ship it. '), 'Ship it.');
  });

  test('decodePcm16 converts samples and keeps the odd byte', () {
    final bytes = Uint8List.fromList([
      0x00,
      0x40,
      0x00,
      0xc0,
      0xff,
      0x7f,
      0x12,
    ]);
    final (:samples, :rest) = decodePcm16(bytes);
    expect(samples, [0.5, -0.5, closeTo(1, 1e-4)]);
    expect(rest, [0x12]);
  });
}
