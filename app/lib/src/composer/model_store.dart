/// Keeps the user's last selected model on this device with
/// [prefsStoreProvider] (AV-041).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';
import '../session_detail/timeline_items.dart';

/// The default model choice from [models]: [preferred] if it exists in
/// [models], otherwise null (which displays as "Host default model").
ModelSelection? defaultModelChoice(
  List<SessionModelInfo> models,
  ModelSelection? preferred,
) {
  if (preferred == null) return null;
  return models.any((m) => m.id == preferred.id) ? preferred : null;
}

/// Resolves the model choice for [chat] among [models]: the model last
/// used in the chat if it exists in [models], otherwise [preferred] if
/// it exists in [models], or null ("Host default model").
ModelSelection? chatModelChoice({
  required ChatState chat,
  required List<SessionModelInfo> models,
  required ModelSelection? preferred,
}) {
  final fromChat = lastModelSelection(chat);
  if (fromChat != null) {
    return models.any((m) => m.id == fromChat.id) ? fromChat : null;
  }
  return defaultModelChoice(models, preferred);
}

/// Encodes [selection] as a JSON string for storage; null when [selection]
/// is null.
String? encodeModelSelection(ModelSelection? selection) {
  if (selection == null) return null;
  return jsonEncode(selection.toJson());
}

/// Decodes [raw] (a JSON string or model id) into a [ModelSelection]; null
/// when empty or invalid.
ModelSelection? decodeModelSelection(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, Object?>) {
      return ModelSelection.fromJson(decoded);
    }
    if (decoded is Map) {
      return ModelSelection.fromJson(decoded.cast<String, Object?>());
    }
    if (decoded is String && decoded.isNotEmpty) {
      return ModelSelection(id: decoded);
    }
  } catch (_) {
    return ModelSelection(id: trimmed);
  }
  return null;
}

/// The user's last selected model (AV-041), kept on this device with
/// [prefsStoreProvider].
final lastSelectedModelProvider =
    NotifierProvider<StoredModelSelection, ModelSelection?>(
      StoredModelSelection.new,
    );

/// Loads and saves the last selected [ModelSelection] across sessions.
class StoredModelSelection extends Notifier<ModelSelection?> {
  /// The [PrefsStore] key.
  static const key = 'last_selected_model';

  Future<void>? _loading;

  @override
  ModelSelection? build() {
    _loading = _load();
    return null;
  }

  Future<void> _load() async {
    final saved = await ref.read(prefsStoreProvider).read(key);
    if (!ref.mounted) return;
    state = decodeModelSelection(saved);
  }

  /// Saves [model] as the user's last selected model.
  Future<void> set(ModelSelection? model) async {
    await _loading;
    state = model;
    final encoded = encodeModelSelection(model);
    final prefs = ref.read(prefsStoreProvider);
    if (encoded == null) {
      await prefs.write(key, '');
    } else {
      await prefs.write(key, encoded);
    }
  }
}
