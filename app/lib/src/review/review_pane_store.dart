/// Whether the review pane is open on wide layouts (AV-003), kept on this
/// device with [prefsStoreProvider]. Closed by default.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';

/// Whether the review pane beside the timeline is open.
final reviewPaneOpenProvider = NotifierProvider<StoredFlag, bool>(
  () => StoredFlag('review_pane_open'),
);
