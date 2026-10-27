/// Keeps the chosen dictation model on this device with
/// [prefsStoreProvider] (AV-047).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';
import 'speech_model.dart';

/// The model dictation uses; the first of [speechModels] until it loads
/// and when unset.
final speechModelProvider = NotifierProvider<StoredSpeechModel, SpeechModel>(
  StoredSpeechModel.new,
);

/// Loads and saves the chosen [SpeechModel].
class StoredSpeechModel extends Notifier<SpeechModel> {
  /// The [PrefsStore] key.
  static const key = 'speech_model';

  Future<void>? _loading;

  @override
  SpeechModel build() {
    _loading = _load();
    return speechModels.first;
  }

  Future<void> _load() async {
    final saved = await ref.read(prefsStoreProvider).read(key);
    if (!ref.mounted) return;
    state = speechModelById(saved);
  }

  /// Picks [model] and saves it.
  Future<void> set(SpeechModel model) async {
    await _loading;
    state = model;
    await ref.read(prefsStoreProvider).write(key, model.id);
  }
}
