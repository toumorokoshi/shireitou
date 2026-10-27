// Real Whisper base.en on a recorded sentence, fed in microphone-sized
// chunks through the worker isolate (AV-047). Downloads the model
// (~160 MB) into SHIREITOU_SPEECH_MODELS (default: the system temp
// folder) on first run; `just test-whisper` runs it (macOS and Linux).
@Tags(['whisper'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shireitou/src/dictation/dictation_session.dart';
import 'package:shireitou/src/dictation/dictation_text.dart';
import 'package:shireitou/src/dictation/model_store.dart';
import 'package:shireitou/src/dictation/speech_model.dart';
import 'package:shireitou/src/dictation/whisper_worker.dart';

const _sample =
    'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en/resolve/'
    '59eea950fc76df2453efb57e6c0fd334548e8ffe/test_wavs/0.wav';

void main() {
  test(
    'transcribes a sentence live, with guesses before the final text',
    () async {
      final root = Directory(
        Platform.environment['SHIREITOU_SPEECH_MODELS'] ??
            '${Directory.systemTemp.path}/shireitou-speech-models',
      );
      final paths = await ModelStore(root).ensure(whisperBaseEn);
      final wav = await _download(_sample, File('${root.path}/0.wav'));

      final chunks = StreamController<Uint8List>();
      final session = PumpedSession(
        audio: chunks.stream,
        engine: WhisperWorker.spawn(paths, library: _sherpaLibrary()),
        stopAudio: () => chunks.close(),
      );
      final seen = <Transcript>[];
      final done = session.transcripts.forEach(seen.add);

      // 100 ms of 16 kHz audio at a time, then a second of silence.
      final pcm = _pcmData(wav);
      const chunk = 3200;
      for (var i = 0; i < pcm.length; i += chunk) {
        chunks.add(
          Uint8List.sublistView(pcm, i, (i + chunk).clamp(0, pcm.length)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      chunks.add(Uint8List(32000));
      await session.stop();
      await done;

      final last = seen.last;
      expect(last.partial, isEmpty);
      expect(
        _words(last.text),
        contains('after early nightfall the yellow lamps would light up'),
      );
      expect(
        seen.where((t) => t.partial.isNotEmpty),
        isNotEmpty,
        reason: 'guesses are shown while the sentence is spoken',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

String _words(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '');

Future<Uint8List> _download(String url, File file) async {
  if (!await file.exists()) {
    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
  }
  return file.readAsBytes();
}

/// The `data` chunk of a 16-bit mono 16 kHz WAV file.
Uint8List _pcmData(Uint8List wav) {
  final data = ByteData.sublistView(wav);
  var offset = 12;
  while (offset + 8 <= wav.length) {
    final id = ascii.decode(wav.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    if (id == 'data') {
      return Uint8List.sublistView(wav, offset + 8, offset + 8 + size);
    }
    offset += 8 + size;
  }
  throw const FormatException('No data chunk');
}

/// sherpa-onnx's native library from the pub cache, as the worker takes
/// it: flutter_tester does not link the app's plugins.
String _sherpaLibrary() {
  var dir = Directory.current;
  while (!File('${dir.path}/.dart_tool/package_config.json').existsSync()) {
    dir = dir.parent;
  }
  final config = jsonDecode(
    File('${dir.path}/.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final package = Platform.isMacOS ? 'sherpa_onnx_macos' : 'sherpa_onnx_linux';
  final entry = (config['packages']! as List)
      .cast<Map<String, Object?>>()
      .firstWhere((p) => p['name'] == package);
  final root = Uri.parse(entry['rootUri']! as String).toFilePath();
  if (Platform.isMacOS) return '$root/macos';
  final arch = Abi.current() == Abi.linuxArm64 ? 'aarch64' : 'x64';
  return '$root/linux/$arch';
}
