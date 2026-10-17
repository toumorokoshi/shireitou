/// The draggable edge of a resizable pane (AV-005).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// How wide the handle's hit area is; the pane's divider stays one pixel.
const paneResizeHandleWidth = 7.0;

/// An invisible strip over a pane's edge with a resize cursor: dragging
/// it calls [onDrag] with the pointer's horizontal movement, and
/// double-clicking it calls [onReset]. It goes in a [Stack] over the
/// pane's divider, so the divider stays one pixel wide while the strip is
/// easy to grab.
class PaneResizeHandle extends StatelessWidget {
  /// Creates a handle named [label] for screen readers.
  const PaneResizeHandle({
    super.key,
    required this.label,
    required this.onDrag,
    required this.onDragEnd,
    required this.onReset,
  });

  /// What the handle resizes, for screen readers ("Resize sidebar").
  final String label;

  /// Called with each drag's horizontal movement in logical pixels
  /// (positive to the right).
  final ValueChanged<double> onDrag;

  /// Called when a drag ends, to save the width.
  final VoidCallback onDragEnd;

  /// Called on a double-click, to go back to the default width.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The edge follows the pointer from where the drag began,
        // including the movement before the drag was recognised.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        onHorizontalDragEnd: (_) => onDragEnd(),
        onDoubleTap: onReset,
        child: const SizedBox(width: paneResizeHandleWidth),
      ),
    ),
  );
}
