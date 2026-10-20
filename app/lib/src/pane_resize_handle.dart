/// The draggable edge of a resizable pane (AV-005) or panel (AV-016).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// How wide the handle's hit area is; the pane's divider stays one pixel.
const paneResizeHandleWidth = 7.0;

/// An invisible strip over a pane's edge with a resize cursor: dragging
/// it calls [onDrag] with the pointer's movement along [axis], and
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
    this.axis = Axis.horizontal,
  });

  /// What the handle resizes, for screen readers ("Resize sidebar").
  final String label;

  /// Called with each drag's movement in logical pixels along [axis]
  /// (positive to the right, or down).
  final ValueChanged<double> onDrag;

  /// Called when a drag ends, to save the size.
  final VoidCallback onDragEnd;

  /// Called on a double-click, to go back to the default size.
  final VoidCallback onReset;

  /// The direction the edge moves: sideways for a pane's side edge, up
  /// and down for a panel's top edge.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    return Semantics(
      label: label,
      child: MouseRegion(
        cursor: horizontal
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // The edge follows the pointer from where the drag began,
          // including the movement before the drag was recognised.
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragUpdate: horizontal
              ? (details) => onDrag(details.delta.dx)
              : null,
          onHorizontalDragEnd: horizontal ? (_) => onDragEnd() : null,
          onVerticalDragUpdate: horizontal
              ? null
              : (details) => onDrag(details.delta.dy),
          onVerticalDragEnd: horizontal ? null : (_) => onDragEnd(),
          onDoubleTap: onReset,
          child: horizontal
              ? const SizedBox(width: paneResizeHandleWidth)
              : const SizedBox(height: paneResizeHandleWidth),
        ),
      ),
    );
  }
}
