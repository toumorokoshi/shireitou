/// Whether the review pane is open on wide layouts (AV-003), and its
/// width (AV-005), kept on this device with [prefsStoreProvider]. Closed
/// by default.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';

/// Whether the review pane beside the timeline is open.
final reviewPaneOpenProvider = NotifierProvider<StoredFlag, bool>(
  () => StoredFlag('review_pane_open'),
);

/// The review pane's width until the user drags its edge.
const defaultReviewPaneWidth = 380.0;

/// The review pane's width, which the user sets by dragging its edge.
final reviewPaneWidthProvider = NotifierProvider<StoredWidth, double>(
  () => StoredWidth('review_pane_width', defaultReviewPaneWidth),
);
