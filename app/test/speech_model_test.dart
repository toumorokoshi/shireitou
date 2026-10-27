/// The dictation models (AV-047): their files, the stored choice, the
/// sherpa-onnx settings and the "Dictation model" menu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/dictation/dictation.dart';
import 'package:shireitou/src/dictation/dictation_io.dart';
import 'package:shireitou/src/dictation/dictation_model_menu.dart';
import 'package:shireitou/src/dictation/model_store.dart';
import 'package:shireitou/src/dictation/speech_model.dart';
import 'package:shireitou/src/dictation/speech_model_store.dart';
import 'package:shireitou/src/dictation/speech_worker.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/theme/app_theme.dart';

class _FakeDictation implements Dictation {
  _FakeDictation(this.model);

  @override
  final SpeechModel model;

  @override
  Future<bool> hasModel() async => false;

  @override
  Dictation withModel(SpeechModel model) => _FakeDictation(model);

  @override
  Future<void> choose(SpeechModel model) async {}

  @override
  Future<void> downloadModel({DownloadProgress? onProgress}) async {}

  @override
  Future<DictationSession> listen() => throw UnimplementedError();
}

void main() {
  group('speechModels', () {
    test('Whisper base.en is the default; ids are unique', () {
      expect(speechModels.first, whisperBaseEn);
      expect(speechModels.map((m) => m.id).toSet(), hasLength(2));
      expect(speechModelById(null), whisperBaseEn);
      expect(speechModelById('gone'), whisperBaseEn);
      expect(speechModelById(parakeetTdtV2.id), parakeetTdtV2);
    });

    test('Parakeet downloads a joiner; Whisper does not', () {
      expect(whisperBaseEn.files.map((f) => f.name), [
        'base.en-encoder.int8.onnx',
        'base.en-decoder.int8.onnx',
        'base.en-tokens.txt',
        'silero_vad.onnx',
      ]);
      expect(parakeetTdtV2.files.map((f) => f.name), [
        'encoder.int8.onnx',
        'decoder.int8.onnx',
        'joiner.int8.onnx',
        'tokens.txt',
        'silero_vad.onnx',
      ]);
      expect(whisperBaseEn.megabytes, 161);
      expect(parakeetTdtV2.megabytes, 662);
    });

    test('each model is pinned to a revision', () {
      for (final model in speechModels) {
        for (final file in model.files.where((f) => f != model.vad)) {
          expect(file.url, matches(RegExp(r'/resolve/[0-9a-f]{40}/')));
        }
      }
    });
  });

  group('speechModelConfig', () {
    test('Whisper runs as Whisper, in English', () {
      final config = speechModelConfig(
        ModelPaths(whisperBaseEn, '/m'),
        threads: 2,
      );
      expect(config.modelType, 'whisper');
      expect(config.whisper.encoder, '/m/base.en-encoder.int8.onnx');
      expect(config.whisper.language, 'en');
      expect(config.tokens, '/m/base.en-tokens.txt');
      expect(config.transducer.joiner, isEmpty);
      expect(config.numThreads, 2);
    });

    test('Parakeet runs as a NeMo transducer with its joiner', () {
      final paths = ModelPaths(parakeetTdtV2, '/m');
      expect(paths.joiner, '/m/joiner.int8.onnx');
      expect(ModelPaths(whisperBaseEn, '/m').joiner, isNull);
      final config = speechModelConfig(paths, threads: 4);
      expect(config.modelType, 'nemo_transducer');
      expect(config.transducer.encoder, '/m/encoder.int8.onnx');
      expect(config.transducer.decoder, '/m/decoder.int8.onnx');
      expect(config.transducer.joiner, '/m/joiner.int8.onnx');
      expect(config.tokens, '/m/tokens.txt');
      expect(config.whisper.encoder, isEmpty);
    });
  });

  group('speechModelProvider', () {
    test('loads the saved model and saves a new pick', () async {
      final prefs = MemoryPrefsStore({StoredSpeechModel.key: parakeetTdtV2.id});
      final container = ProviderContainer(
        overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(speechModelProvider), whisperBaseEn);
      await pumpEventQueue();
      expect(container.read(speechModelProvider), parakeetTdtV2);

      await container.read(speechModelProvider.notifier).set(whisperBaseEn);
      expect(container.read(speechModelProvider), whisperBaseEn);
      expect(prefs.values[StoredSpeechModel.key], whisperBaseEn.id);
    });
  });

  test('NativeDictation keeps a chosen model, also from withModel', () async {
    final chosen = <SpeechModel>[];
    final dictation = NativeDictation(onChoose: (m) async => chosen.add(m));
    final parakeet = dictation.withModel(parakeetTdtV2);
    expect(dictation.model, whisperBaseEn);
    expect(parakeet.model, parakeetTdtV2);
    await parakeet.choose(parakeetTdtV2);
    expect(chosen, [parakeetTdtV2]);
  });

  group('DictationModelMenu', () {
    Future<MemoryPrefsStore> pump(
      WidgetTester tester, {
      bool dictation = true,
    }) async {
      final prefs = MemoryPrefsStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsStoreProvider.overrideWithValue(prefs),
            dictationProvider.overrideWith(
              (ref) => dictation
                  ? _FakeDictation(ref.watch(speechModelProvider))
                  : null,
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(defaultTheme(Brightness.dark)),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    MenuAnchor(
                      menuChildren: const [DictationModelMenu()],
                      builder: (context, controller, _) => TextButton(
                        onPressed: controller.open,
                        child: const Text('open'),
                      ),
                    ),
                    Text('uses ${ref.watch(dictationProvider)?.model.id}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return prefs;
    }

    testWidgets('picks Parakeet, which dictation then uses', (tester) async {
      final prefs = await pump(tester);
      await tester.tap(find.text('Dictation model · Whisper base.en'));
      await tester.pumpAndSettle();
      expect(find.text('Fastest, smallest download · 161 MB'), findsOneWidget);
      expect(find.text('More accurate, slower · 662 MB'), findsOneWidget);
      await tester.tap(find.text('Parakeet TDT 0.6B v2'));
      await tester.pumpAndSettle();
      expect(prefs.values[StoredSpeechModel.key], parakeetTdtV2.id);
      expect(find.text('uses ${parakeetTdtV2.id}'), findsOneWidget);
    });

    testWidgets('is not shown without dictation', (tester) async {
      await pump(tester, dictation: false);
      expect(find.textContaining('Dictation model'), findsNothing);
    });
  });
}
