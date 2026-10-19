/// Selecting and copying text in the timeline (AV-061). Two gaps in
/// Flutter's `SelectionArea` break copying code blocks:
///
/// - It joins the selected text of each widget with nothing between them,
///   so a code block pastes glued to the paragraphs around it.
///   [LineSelection] starts a new line between pieces on different lines.
/// - A scroll view nested in the selection treats a drag point left of it
///   as before it even when the point is below it, so a drag starting at
///   the left of the text under an indented code block also selects the
///   whole block. [ScrollSelection] places such points by row alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A piece of selected text and where it is on screen.
typedef SelectedPiece = ({Rect bounds, String text});

/// [pieces] (in reading order) as one string: a piece below the previous
/// one starts a new line, and pieces on the same line (a list's bullet
/// and its text) are joined as they are.
String joinSelectedLines(List<SelectedPiece> pieces) {
  final buffer = StringBuffer();
  SelectedPiece? previous;
  for (final piece in pieces) {
    if (piece.text.isEmpty) continue;
    if (previous != null &&
        piece.bounds.top >= previous.bounds.bottom - 1 &&
        !previous.text.endsWith('\n')) {
      buffer.write('\n');
    }
    buffer.write(piece.text);
    previous = piece;
  }
  return buffer.toString();
}

/// A selection edge at [local], relative to a box of [size]: above the box
/// moves it before the box's top left, below it past the bottom right, so
/// only the row decides whether it is before or after the box's content.
Offset rowWiseEdge(Offset local, Size size) => local.dy < 0
    ? const Offset(-1, -1)
    : local.dy > size.height
    ? Offset(size.width + 1, size.height + 1)
    : local;

/// Copies the selection in [child] with [joinSelectedLines].
class LineSelection extends StatefulWidget {
  /// Creates a [LineSelection] around [child].
  const LineSelection({super.key, required this.child});

  /// The selectable content.
  final Widget child;

  @override
  State<LineSelection> createState() => _LineSelectionState();
}

class _LineSelectionState extends State<LineSelection> {
  final _delegate = _LineSelectionDelegate();

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SelectionContainer(delegate: _delegate, child: widget.child);
}

class _LineSelectionDelegate extends StaticSelectionContainerDelegate {
  @override
  SelectedContent? getSelectedContent() {
    final pieces = <SelectedPiece>[
      for (final selectable in selectables)
        if (selectable.getSelectedContent() case final SelectedContent data)
          (bounds: _globalBounds(selectable), text: data.plainText),
    ];
    if (pieces.isEmpty) return null;
    return SelectedContent(plainText: joinSelectedLines(pieces));
  }
}

Rect _globalBounds(Selectable selectable) => MatrixUtils.transformRect(
  selectable.getTransformTo(null),
  Offset.zero & selectable.size,
);

/// Wraps a scroll view in a selection so drags that start outside it
/// place their edges with [rowWiseEdge].
class ScrollSelection extends StatefulWidget {
  /// Creates a [ScrollSelection] around [child].
  const ScrollSelection({super.key, required this.child});

  /// The scroll view.
  final Widget child;

  @override
  State<ScrollSelection> createState() => _ScrollSelectionState();
}

class _ScrollSelectionState extends State<ScrollSelection> {
  final _delegate = _ScrollSelectionDelegate();

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SelectionContainer(delegate: _delegate, child: widget.child);
}

class _ScrollSelectionDelegate extends StaticSelectionContainerDelegate {
  /// Whether the current drag started inside; null before it starts.
  bool? _startedInside;

  @override
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    _startedInside = null;
    return super.handleClearSelection(event);
  }

  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    final global = event.globalPosition;
    final toLocal = hasSize && global.isFinite
        ? Matrix4.tryInvert(getTransformTo(null))
        : null;
    if (toLocal == null) return super.handleSelectionEdgeUpdate(event);
    final local = MatrixUtils.transformPoint(toLocal, global);
    final size = containerSize;
    _startedInside ??= (Offset.zero & size).contains(local);
    final edge = rowWiseEdge(local, size);
    if (_startedInside! || edge == local) {
      return super.handleSelectionEdgeUpdate(event);
    }
    final moved = MatrixUtils.transformPoint(getTransformTo(null), edge);
    return super.handleSelectionEdgeUpdate(
      event.type == SelectionEventType.startEdgeUpdate
          ? SelectionEdgeUpdateEvent.forStart(
              globalPosition: moved,
              granularity: event.granularity,
            )
          : SelectionEdgeUpdateEvent.forEnd(
              globalPosition: moved,
              granularity: event.granularity,
            ),
    );
  }
}
