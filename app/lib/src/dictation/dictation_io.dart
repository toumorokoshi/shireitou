/// Dictation on the desktop and mobile apps: the microphone through
/// `record`, the speech model through sherpa-onnx (AV-047).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'dictation.dart';
import 'dictation_session.dart';
import 'model_store.dart';
import 'speech_model.dart';
import 'speech_worker.dart';

/// The native [Dictation] with [model]. The target platform and the real
/// one (`dart:io`) must agree, so widget tests that pretend to be another
/// platform get none.
Dictation? platformDictation(SpeechModel model) {
  final real = switch (defaultTargetPlatform) {
    TargetPlatform.macOS => Platform.isMacOS,
    TargetPlatform.linux => Platform.isLinux,
    TargetPlatform.windows => Platform.isWindows,
    TargetPlatform.android => Platform.isAndroid,
    TargetPlatform.iOS => Platform.isIOS,
    _ => false,
  };
  return real ? NativeDictation(model: model) : null;
}

/// [Dictation] with models kept in the app's support folder.
class NativeDictation implements Dictation {
  /// Creates a [NativeDictation].
  NativeDictation({this.model = whisperBaseEn});

  @override
  final SpeechModel model;

  late final Future<ModelStore> _store = getApplicationSupportDirectory().then(
    (dir) => ModelStore(Directory('${dir.path}/models')),
  );

  @override
  Future<bool> hasModel() async => (await _store).has(model);

  @override
  Future<void> downloadModel({DownloadProgress? onProgress}) async {
    await (await _store).ensure(model, onProgress: onProgress);
  }

  @override
  Future<DictationSession> listen() async {
    final paths = await (await _store).ensure(model);
    final recorder = AudioRecorder();
    final Stream<Uint8List> audio;
    try {
      if (!await recorder.hasPermission()) {
        throw const DictationException(
          'shireitou may not use the microphone. Allow it in the system '
          'settings, then try again.',
        );
      }
      audio = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: speechSampleRate,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
        ),
      );
    } on DictationException {
      await recorder.dispose();
      rethrow;
    } catch (e) {
      await recorder.dispose();
      throw DictationException('The microphone could not be opened: $e');
    }
    return PumpedSession(
      audio: audio,
      engine: SpeechWorker.spawn(paths),
      stopAudio: () async {
        await recorder.stop();
        await recorder.dispose();
      },
    );
  }
}
