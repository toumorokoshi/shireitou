/// Whether the review pane is open on wide layouts (AV-003), kept on this
/// device with [prefsStoreProvider]. Closed by default.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';

const _key = 'review_pane_open';

/// Whether the review pane beside the timeline is open.
final reviewPaneOpenProvider = NotifierProvider<ReviewPaneOpen, bool>(
  ReviewPaneOpen.new,
);

/// Loads, toggles and saves whether the review pane is open.
class ReviewPaneOpen extends Notifier<bool> {
  Future<void>? _loading;

  @override
  bool build() {
    _loading = _load();
    return false;
  }

  Future<void> _load() async {
    state = await ref.read(prefsStoreProvider).read(_key) == 'true';
  }

  /// Opens the pane when closed, and closes it when open.
  Future<void> toggle() async {
    await _loading;
    state = !state;
    await ref.read(prefsStoreProvider).write(_key, '$state');
  }
}
