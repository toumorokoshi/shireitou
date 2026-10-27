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

/// What every model of a [_FakeDictation] shares.
class _Shared {
  _Shared(this.ready, this.error);

  /// The ids of the models on disk.
  final Set<String> ready;
  final DictationException? error;
  final downloads = Completer<void>();
  final downloaded = <String>[];
  final chosen = <SpeechModel>[];
  final listenedWith = <String>[];
  final sessions = <_FakeSession>[];
}

class _FakeDictation implements Dictation {
  _FakeDictation({
    bool modelReady = true,
    Set<String>? ready,
    DictationException? error,
  }) : this._(
         _Shared(ready ?? {if (modelReady) whisperBaseEn.id}, error),
         whisperBaseEn,
       );

  _FakeDictation._(this._shared, this.model);

  final _Shared _shared;

  @override
  final SpeechModel model;

  bool get modelReady => _shared.ready.contains(model.id);
  Completer<void> get downloads => _shared.downloads;
  List<String> get downloaded => _shared.downloaded;
  List<SpeechModel> get chosen => _shared.chosen;
  List<String> get listenedWith => _shared.listenedWith;

  @override
  Future<bool> hasModel() async => modelReady;

  @override
  Dictation withModel(SpeechModel model) => _FakeDictation._(_shared, model);

  @override
  Future<void> choose(SpeechModel model) async => chosen.add(model);

  @override
  Future<void> downloadModel({DownloadProgress? onProgress}) async {
    downloaded.add(model.id);
    onProgress?.call(0.5);
    await downloads.future;
    _shared.ready.add(model.id);
  }

  @override
  Future<DictationSession> listen() async {
    if (_shared.error case final e?) throw e;
    listenedWith.add(model.id);
    return _shared.sessions.last;
  }

  _FakeSession next() {
    final session = _FakeSession();
    _shared.sessions.add(session);
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
    expect(find.text('Download a speech model?'), findsOneWidget);
    expect(find.text('Fastest, smallest download · 161 MB'), findsOneWidget);
    expect(find.text('More accurate, slower · 662 MB'), findsOneWidget);

    await tester.tap(find.text('Download (161 MB)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byTooltip('Downloading Whisper base.en (50%)'), findsOneWidget);
    expect(dictation.chosen, [whisperBaseEn]);

    dictation.downloads.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Stop dictation'), findsOneWidget);
    expect(dictation.listenedWith, [whisperBaseEn.id]);
  });

  testWidgets('the first download can be Parakeet', (tester) async {
    final dictation = _FakeDictation(modelReady: false)..next();
    await _pump(tester, dictation: dictation);

    await tester.tap(find.byTooltip('Dictate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parakeet TDT 0.6B v2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download (662 MB)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(
      find.byTooltip('Downloading Parakeet TDT 0.6B v2 (50%)'),
      findsOneWidget,
    );
    expect(dictation.chosen, [parakeetTdtV2]);
    expect(dictation.downloaded, [parakeetTdtV2.id]);

    dictation.downloads.complete();
    await tester.pump();
    await tester.pump();
    expect(dictation.listenedWith, [parakeetTdtV2.id]);
  });

  testWidgets('a model already on disk is used without a download', (
    tester,
  ) async {
    final dictation = _FakeDictation(ready: {parakeetTdtV2.id})..next();
    await _pump(tester, dictation: dictation);

    await tester.tap(find.byTooltip('Dictate'));
    await tester.pumpAndSettle();
    expect(find.text('More accurate, slower · downloaded'), findsOneWidget);
    await tester.tap(find.text('Parakeet TDT 0.6B v2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Parakeet TDT 0.6B v2'));
    await tester.pumpAndSettle();
    expect(dictation.downloaded, isEmpty);
    expect(dictation.chosen, [parakeetTdtV2]);
    expect(dictation.listenedWith, [parakeetTdtV2.id]);
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
    expect(dictation.chosen, isEmpty);
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
