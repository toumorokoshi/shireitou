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
///
/// Copying also puts HTML on the clipboard ([RichSelectionArea]), so
/// links and formatting survive a paste.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../clipboard/rich_clipboard.dart';
import '../clipboard/span_html.dart';
import '../files/file_paths.dart';
import 'link_menu.dart';

/// A piece of selected text and where it is on screen.
typedef SelectedPiece = ({Rect bounds, String text});

/// A piece of selected text, its HTML, and where it is on screen.
typedef RichPiece = ({Rect bounds, String text, String html});

/// The indexes of the non-empty [pieces] (in reading order), each with
/// whether it starts a new line: it is below the previous one, which did
/// not end one.
List<(int, bool)> _lines(List<SelectedPiece> pieces) {
  final lines = <(int, bool)>[];
  for (final (i, piece) in pieces.indexed) {
    if (piece.text.isEmpty) continue;
    final previous = lines.isEmpty ? null : pieces[lines.last.$1];
    lines.add((
      i,
      previous != null &&
          piece.bounds.top >= previous.bounds.bottom - 1 &&
          !previous.text.endsWith('\n'),
    ));
  }
  return lines;
}

/// [pieces] (in reading order) as one string: a piece below the previous
/// one starts a new line, and pieces on the same line (a list's bullet
/// and its text) are joined as they are.
String joinSelectedLines(List<SelectedPiece> pieces) => [
  for (final (i, newLine) in _lines(pieces))
    '${newLine ? '\n' : ''}${pieces[i].text}',
].join();

/// [pieces] joined as [joinSelectedLines] does, and their HTML with a
/// `<br>` where a line starts (blocks such as `<pre>` start their own).
({String text, String html}) joinRichPieces(List<RichPiece> pieces) {
  final plain = [
    for (final piece in pieces) (bounds: piece.bounds, text: piece.text),
  ];
  final html = StringBuffer();
  var block = false;
  for (final (i, newLine) in _lines(plain)) {
    final isBlock = pieces[i].html.startsWith('<pre>');
    if (newLine && !block && !isBlock) html.write('<br>');
    html.write(pieces[i].html);
    block = isBlock;
  }
  return (text: joinSelectedLines(plain), html: html.toString());
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

  /// The enclosing [RichSelectionArea]'s rows, which this one joins.
  Set<_LineSelectionState>? _rows;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rows = context
        .getInheritedWidgetOfExactType<_RichSelectionScope>()
        ?.rows;
    if (!identical(rows, _rows)) {
      _rows?.remove(this);
      _rows = rows?..add(this);
    }
  }

  @override
  void dispose() {
    _rows?.remove(this);
    _delegate.dispose();
    super.dispose();
  }

  /// The selected pieces with their HTML: rich text keeps its links (in
  /// a [LinkSecondaryTap], whose link spans report their URL to
  /// [linkHref]) and formatting, other pieces (code) are preformatted.
  List<RichPiece> richPieces() {
    final paragraphs = _paragraphs(context);
    return [
      for (final selectable in _delegate.selectables)
        if (selectable.getSelectedContent() case final SelectedContent data)
          (
            bounds: _globalBounds(selectable),
            text: data.plainText,
            html: _pieceHtml(selectable, data.plainText, paragraphs),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      SelectionContainer(delegate: _delegate, child: widget.child);
}

/// The rich text under [context], each with whether its link spans
/// report their URL (it is in a [LinkSecondaryTap]).
List<(RenderParagraph, bool)> _paragraphs(BuildContext context) {
  final found = <(RenderParagraph, bool)>[];
  void visit(Element element, bool links) {
    final hasLinks = links || element.widget is LinkSecondaryTap;
    if (element case RenderObjectElement(
      renderObject: final RenderParagraph paragraph,
    )) {
      found.add((paragraph, hasLinks));
    }
    element.visitChildElements((child) => visit(child, hasLinks));
  }

  context.visitChildElements((child) => visit(child, false));
  return found;
}

/// The HTML of [selectable]'s selected [text]: the spans of its paragraph
/// when it is one (a fragment of it, or the selection container `Text`
/// wraps it in, which covers the same box and reports offsets in the
/// paragraph's text), else a preformatted block.
String _pieceHtml(
  Selectable selectable,
  String text,
  List<(RenderParagraph, bool)> paragraphs,
) {
  final bounds = _globalBounds(selectable);
  for (final (paragraph, links) in paragraphs) {
    if (!paragraph.selectableBelongsToParagraph(selectable) &&
        bounds != _paragraphBounds(paragraph)) {
      continue;
    }
    final range = selectable.getSelection();
    if (range == null) break;
    return runsHtml(
      spanRuns(
        paragraph.text,
        math.min(range.startOffset, range.endOffset),
        math.max(range.startOffset, range.endOffset),
        hrefOf: links ? _spanHref : null,
      ),
    );
  }
  return preHtml(text);
}

Rect? _paragraphBounds(RenderParagraph paragraph) => paragraph.hasSize
    ? MatrixUtils.transformRect(
        paragraph.getTransformTo(null),
        Offset.zero & paragraph.size,
      )
    : null;

/// The URL of [span]'s link; none for the file paths the app made into
/// links, which only open on the host.
String? _spanHref(TextSpan span) => switch (span.recognizer) {
  final TapGestureRecognizer link => switch (linkHref(link)) {
    final href? when !href.startsWith(filePathHrefPrefix) => href,
    _ => null,
  },
  _ => null,
};

/// A [SelectionArea] whose copy (the shortcut and the context menu) puts
/// HTML on the clipboard along with the text, so links and formatting
/// survive a paste. Only the [LineSelection]s in [child] are copied.
class RichSelectionArea extends StatefulWidget {
  /// Creates a [RichSelectionArea] around [child].
  const RichSelectionArea({super.key, required this.child});

  /// The selectable content.
  final Widget child;

  @override
  State<RichSelectionArea> createState() => _RichSelectionAreaState();
}

class _RichSelectionAreaState extends State<RichSelectionArea> {
  final _rows = <_LineSelectionState>{};
  final _focus = FocusNode(debugLabel: 'RichSelectionArea');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    double top(_LineSelectionState row) => switch (row.context
        .findRenderObject()) {
      final RenderBox box when box.hasSize => box.localToGlobal(Offset.zero).dy,
      _ => 0,
    };
    final rows = _rows.toList()..sort((a, b) => top(a).compareTo(top(b)));
    final pieces = [for (final row in rows) ...row.richPieces()];
    if (pieces.isEmpty) return;
    final copied = joinRichPieces(pieces);
    await setRichClipboard(text: copied.text, html: copied.html);
  }

  Widget _contextMenu(BuildContext context, SelectableRegionState region) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: region.contextMenuAnchors,
        buttonItems: [
          for (final item in region.contextMenuButtonItems)
            item.type == ContextMenuButtonType.copy
                ? item.copyWith(
                    onPressed: () {
                      unawaited(_copy());
                      region.hideToolbar();
                    },
                  )
                : item,
        ],
      );

  @override
  Widget build(BuildContext context) => _RichSelectionScope(
    rows: _rows,
    child: Actions(
      actions: {CopySelectionTextIntent: _CopyAction(_focus, _copy)},
      child: SelectionArea(
        focusNode: _focus,
        contextMenuBuilder: _contextMenu,
        child: widget.child,
      ),
    ),
  );
}

class _RichSelectionScope extends InheritedWidget {
  const _RichSelectionScope({required this.rows, required super.child});

  final Set<_LineSelectionState> rows;

  @override
  bool updateShouldNotify(_RichSelectionScope oldWidget) =>
      !identical(rows, oldWidget.rows);
}

/// Overrides the copy shortcut of the selection focused by [focus] with
/// [copy]; text fields inside it keep their own copy.
class _CopyAction extends Action<CopySelectionTextIntent> {
  _CopyAction(this.focus, this.copy);

  final FocusNode focus;
  final Future<void> Function() copy;

  @override
  Object? invoke(CopySelectionTextIntent intent) {
    if (!focus.hasPrimaryFocus) return callingAction?.invoke(intent);
    unawaited(copy());
    return null;
  }
}

/// Copies the selection in [child], such as a column of diff lines inside
/// a scroll view, with [joinSelectedLines]. Unlike [LineSelection] it is
/// not a row of its [RichSelectionArea], so it can sit inside one.
class JoinedLines extends StatefulWidget {
  /// Creates a [JoinedLines] around [child].
  const JoinedLines({super.key, required this.child});

  /// The selectable lines.
  final Widget child;

  @override
  State<JoinedLines> createState() => _JoinedLinesState();
}

class _JoinedLinesState extends State<JoinedLines> {
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
  SelectedContent? getSelectedContent() => _joinedContent(selectables);
}

/// The selected content of [selectables] joined with [joinSelectedLines].
SelectedContent? _joinedContent(List<Selectable> selectables) {
  final pieces = <SelectedPiece>[
    for (final selectable in selectables)
      if (selectable.getSelectedContent() case final SelectedContent data)
        (bounds: _globalBounds(selectable), text: data.plainText),
  ];
  if (pieces.isEmpty) return null;
  return SelectedContent(plainText: joinSelectedLines(pieces));
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
