import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shireitou/src/dictation/model_store.dart';
import 'package:shireitou/src/dictation/speech_model.dart';

const _model = SpeechModel(
  id: 'tiny',
  label: 'Tiny',
  encoder: ModelFile('enc', 'https://m.test/enc', 4),
  decoder: ModelFile('dec', 'https://m.test/dec', 6),
  tokens: ModelFile('tok', 'https://m.test/tok', 2),
  vad: ModelFile('vad', 'https://m.test/vad', 3),
);

void main() {
  late Directory root;
  late List<String> requested;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('model_store_test');
    requested = [];
  });
  tearDown(() => root.delete(recursive: true));

  ModelStore store({Map<String, int> short = const {}}) => ModelStore(
    root,
    client: () => MockClient.streaming((request, _) async {
      final file = request.url.pathSegments.last;
      requested.add(file);
      final size = [
        _model.encoder,
        _model.decoder,
        _model.tokens,
        _model.vad,
      ].firstWhere((f) => f.name == file).bytes;
      return http.StreamedResponse(
        Stream.value(List.filled(short[file] ?? size, 7)),
        200,
      );
    }),
  );

  test('downloads every file once, reporting progress', () async {
    final progress = <double>[];
    final paths = await store().ensure(_model, onProgress: progress.add);
    expect(requested, ['enc', 'dec', 'tok', 'vad']);
    expect(paths.decoder, '${root.path}/tiny/dec');
    expect(await File(paths.vad).length(), 3);
    expect(progress.last, 1);
    expect(progress, orderedEquals([...progress]..sort()));
    expect(await store().has(_model), isTrue);

    requested.clear();
    await store().ensure(_model);
    expect(requested, isEmpty);
  });

  test('a cut download is not kept', () async {
    await expectLater(
      store(short: {'dec': 2}).ensure(_model),
      throwsA(isA<HttpException>()),
    );
    expect(File('${root.path}/tiny/dec').existsSync(), isFalse);
    expect(File('${root.path}/tiny/dec.part').existsSync(), isFalse);
    expect(await store().has(_model), isFalse);

    requested.clear();
    await store().ensure(_model);
    expect(requested, ['dec', 'tok', 'vad']);
  });

  test('a failed request is reported', () async {
    final failing = ModelStore(
      root,
      client: () => MockClient((_) async => http.Response('gone', 404)),
    );
    await expectLater(failing.ensure(_model), throwsA(isA<HttpException>()));
  });
}
