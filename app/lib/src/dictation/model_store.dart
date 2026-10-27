/// Downloads speech models and keeps them on disk (AV-047).
library;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'speech_model.dart';

/// The model's files on disk.
class ModelPaths {
  /// Creates [ModelPaths] for [model] in [folder].
  ModelPaths(this.model, String folder)
    : encoder = '$folder/${model.encoder.name}',
      decoder = '$folder/${model.decoder.name}',
      tokens = '$folder/${model.tokens.name}',
      vad = '$folder/${model.vad.name}';

  /// The model.
  final SpeechModel model;

  /// The files' paths.
  final String encoder, decoder, tokens, vad;
}

/// Keeps speech models in [root], one folder each, downloading what is
/// missing.
class ModelStore {
  /// Creates a [ModelStore].
  ModelStore(this.root, {http.Client Function()? client})
    : _client = client ?? http.Client.new;

  /// The models' folder.
  final Directory root;
  final http.Client Function() _client;

  String _folder(SpeechModel model) => '${root.path}/${model.id}';

  /// Whether every file of [model] has been downloaded.
  Future<bool> has(SpeechModel model) async {
    for (final file in model.files) {
      final f = File('${_folder(model)}/${file.name}');
      if (!await f.exists() || await f.length() != file.bytes) return false;
    }
    return true;
  }

  /// [model]'s files, downloading the missing ones first.
  Future<ModelPaths> ensure(
    SpeechModel model, {
    DownloadProgress? onProgress,
  }) async {
    final folder = Directory(_folder(model));
    await folder.create(recursive: true);
    var done = 0;
    final client = _client();
    try {
      for (final file in model.files) {
        final target = File('${folder.path}/${file.name}');
        if (!await target.exists() || await target.length() != file.bytes) {
          await _download(client, file, target, (received) {
            onProgress?.call((done + received) / model.bytes);
          });
        }
        done += file.bytes;
        onProgress?.call(done / model.bytes);
      }
    } finally {
      client.close();
    }
    return ModelPaths(model, folder.path);
  }

  /// Downloads [file] beside [target], then renames it, so a cut
  /// download never looks finished.
  static Future<void> _download(
    http.Client client,
    ModelFile file,
    File target,
    void Function(int received) onReceived,
  ) async {
    final response = await client.send(
      http.Request('GET', Uri.parse(file.url)),
    );
    if (response.statusCode != 200) {
      throw HttpException(
        'Downloading ${file.name} failed (HTTP ${response.statusCode})',
        uri: Uri.parse(file.url),
      );
    }
    final part = File('${target.path}.part');
    final sink = part.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onReceived(received);
      }
    } finally {
      await sink.close();
    }
    if (received != file.bytes) {
      await part.delete();
      throw HttpException(
        'Downloading ${file.name} stopped at $received of ${file.bytes} '
        'bytes',
        uri: Uri.parse(file.url),
      );
    }
    await part.rename(target.path);
  }
}
