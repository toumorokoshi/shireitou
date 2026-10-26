/// The composer's microphone button (AV-047), on a fake [Dictation].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/dictation/dictation.dart';
import 'package:shireitou/src/dictation/dictation_text.dart';
import 'package:shireitou/src/dictation/speech_model.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

class _FakeSession implements DictationSession {
  final controller = StreamController<Transcript>();
  var stopped = false;
  var cancelled = false;

  @override
  Stream<Transcript> get transcripts => controller.stream;

  @override
  Future<void> stop() async {
    stopped = true;
    controller.add(const Transcript(committed: ['Run the tests.']));
    await controller.close();
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    await controller.close();
  }
}

class _FakeDictation implements Dictation {
  _FakeDictation({this.modelReady = true, this.error});

  bool modelReady;
  final DictationException? error;
  final downloads = Completer<void>();
  final sessions = <_FakeSession>[];

  @override
  SpeechModel get model => whisperBaseEn;

  @override
  Future<bool> hasModel() async => modelReady;

  @override
  Future<void> downloadModel({DownloadProgress? onProgress}) async {
    onProgress?.call(0.5);
    await downloads.future;
    modelReady = true;
  }

  @override
  Future<DictationSession> listen() async {
    if (error case final e?) throw e;
    return sessions.last;
  }

  _FakeSession next() {
    final session = _FakeSession();
    sessions.add(session);
    return session;
  }
}

Future<List<String>> _pump(
  WidgetTester tester, {
  Dictation? dictation,
  TextEditingController? controller,
}) async {
  final sent = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FollowUpInput(
            working: false,
            dictation: dictation,
            controller: controller,
            onSend: (text, {required steer, model, attachments = const []}) =>
                sent.add(text),
          ),
        ),
      ),
    ),
  );
  return sent;
}

String _text(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('no microphone without dictation', (tester) async {
    await _pump(tester);
    expect(find.byTooltip('Dictate'), findsNothing);
  });

  testWidgets('writes the words into the box as they are spoken', (
    tester,
  ) async {
    final dictation = _FakeDictation();
    final session = dictation.next();
    final text = TextEditingController(text: 'Please then commit.')
      ..selection = const TextSelection.collapsed(offset: 6);
    final sent = await _pump(tester, dictation: dictation, controller: text);

    await tester.tap(find.byTooltip('Dictate'));
    await tester.pump();
    expect(find.byTooltip('Stop dictation'), findsOneWidget);

    session.controller.add(const Transcript(partial: 'Run'));
    await tester.pump();
    expect(_text(tester), 'Please Run then commit.');

    session.controller.add(const Transcript(partial: 'run the tests'));
    await tester.pump();
    expect(_text(tester), 'Please run the tests then commit.');
    expect(text.selection, const TextSelection.collapsed(offset: 20));

    await tester.tap(find.byTooltip('Stop dictation'));
    await tester.pump();
    expect(session.stopped, isTrue);
    expect(_text(tester), 'Please Run the tests. then commit.');
    expect(find.byTooltip('Dictate'), findsOneWidget);
    expect(sent, isEmpty);
  });

  testWidgets('says it is listening in an empty box', (tester) async {
    final dictation = _FakeDictation()..next();
    await _pump(tester, dictation: dictation);
    await tester.tap(find.byTooltip('Dictate'));
    await tester.pump();
    expect(find.text('Listening…'), findsOneWidget);
  });

  testWidgets('typing stops dictation and keeps the text', (tester) async {
    final dictation = _FakeDictation();
    final session = dictation.next();
    await _pump(tester, dictation: dictation);
    await tester.tap(find.byTooltip('Dictate'));
    await tester.pump();
    session.controller.add(const Transcript(partial: 'Hello'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Hello world');
    await tester.pump();
    expect(session.cancelled, isTrue);
    expect(find.byTooltip('Dictate'), findsOneWidget);
    expect(_text(tester), 'Hello world');
  });

  testWidgets('offers to download the model on first use', (tester) async {
    final dictation = _FakeDictation(modelReady: false)..next();
    await _pump(tester, dictation: dictation);

    await tester.tap(find.byTooltip('Dictate'));
    await tester.pumpAndSettle();
    expect(find.text('Download the speech model?'), findsOneWidget);
    expect(find.textContaining('161 MB'), findsWidgets);

    await tester.tap(find.text('Download (161 MB)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byTooltip('Downloading Whisper base.en (50%)'), findsOneWidget);

    dictation.downloads.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Stop dictation'), findsOneWidget);
  });

  testWidgets('declining the download does nothing', (tester) async {
    final dictation = _FakeDictation(modelReady: false);
    await _pump(tester, dictation: dictation);
    await tester.tap(find.byTooltip('Dictate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dictate'), findsOneWidget);
    expect(dictation.modelReady, isFalse);
  });

  testWidgets('a microphone that cannot open is reported', (tester) async {
    final dictation = _FakeDictation(
      error: const DictationException('No microphone'),
    );
    await _pump(tester, dictation: dictation);
    await tester.tap(find.byTooltip('Dictate'));
    await tester.pump();
    expect(find.text('No microphone'), findsOneWidget);
    expect(find.byTooltip('Dictate'), findsOneWidget);
  });
}
