/// The sidebar's folder order and collapsed sections, kept
/// on this device with [prefsStoreProvider].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';
import 'folder_order.dart';

/// The ids of the folders the user dragged into place, in order
/// ([orderFolders]).
final folderOrderProvider = NotifierProvider<StoredIds, List<String>>(
  () => StoredIds('folder_order'),
);

/// The ids of the collapsed sections and folders in the sidebar
/// ([sidebarRows]).
final collapsedNodesProvider = NotifierProvider<StoredIds, List<String>>(
  () => StoredIds('sidebar_collapsed'),
);

/// Loads, changes and saves a list of ids under one prefs key.
class StoredIds extends Notifier<List<String>> {
  /// Creates a [StoredIds] kept under [key].
  StoredIds(this.key);

  /// The [PrefsStore] key the ids are saved under.
  final String key;

  Future<void>? _loading;

  @override
  List<String> build() {
    _loading = _load();
    return const [];
  }

  Future<void> _load() async {
    state = decodeIds(await ref.read(prefsStoreProvider).read(key));
  }

  /// Replaces the ids with [change] of the loaded ids and saves them;
  /// nothing is saved when they are the same.
  Future<void> change(
    Iterable<String> Function(List<String> ids) change,
  ) async {
    await _loading;
    final ids = [...change(state)];
    if (listEquals(ids, state)) return;
    state = ids;
    await ref.read(prefsStoreProvider).write(key, encodeIds(ids));
  }
}
