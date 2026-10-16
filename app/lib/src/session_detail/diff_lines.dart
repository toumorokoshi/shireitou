/// Pure line diffs for file edits (AV-065, AV-101): which lines were
/// added and removed, unchanged regions collapsed around the changes, and
/// rows for a side-by-side view. The edit script comes from
/// `diffutil_dart` (Myers' algorithm).
library;

import 'package:diffutil_dart/diffutil.dart';

/// How a line of a diff changed.
enum DiffLineKind {
  /// In both versions.
  same,

  /// Only in the new version.
  added,

  /// Only in the old version.
  removed,
}

/// One line of a unified diff.
class DiffLine {
  /// Creates a [DiffLine].
  const DiffLine(this.kind, this.text, {this.oldNumber, this.newNumber});

  /// How the line changed.
  final DiffLineKind kind;

  /// The line, without its newline.
  final String text;

  /// 1-based line number in the old version, unless [kind] is added.
  final int? oldNumber;

  /// 1-based line number in the new version, unless [kind] is removed.
  final int? newNumber;

  @override
  bool operator ==(Object other) =>
      other is DiffLine &&
      other.kind == kind &&
      other.text == text &&
      other.oldNumber == oldNumber &&
      other.newNumber == newNumber;

  @override
  int get hashCode => Object.hash(kind, text, oldNumber, newNumber);

  @override
  String toString() =>
      '${switch (kind) {
        DiffLineKind.same => ' ',
        DiffLineKind.added => '+',
        DiffLineKind.removed => '-',
      }}$text';
}

/// [text] split into lines; a final newline does not start another line.
List<String> splitLines(String text) {
  if (text.isEmpty) return const [];
  final lines = text.split('\n');
  if (lines.last.isEmpty) lines.removeLast();
  return [
    for (final l in lines) l.endsWith('\r') ? l.substring(0, l.length - 1) : l,
  ];
}

class _Entry {
  _Entry(this.kind, this.text);

  DiffLineKind kind;
  final String text;
}

/// The unified diff from [before] to [after], every line included. Within
/// each changed region, removed lines come before added ones.
List<DiffLine> diffLines(String before, String after) {
  final oldLines = splitLines(before);
  final newLines = splitLines(after);
  // Replay the edit script on the old lines, keeping removed lines in
  // place (marked) so they can be shown.
  final entries = [for (final l in oldLines) _Entry(DiffLineKind.same, l)];
  int indexOfLive(int position) {
    var live = 0;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].kind == DiffLineKind.removed) continue;
      if (live == position) return i;
      live++;
    }
    return entries.length;
  }

  final updates = calculateListDiff<String>(
    oldLines,
    newLines,
  ).getUpdatesWithData();
  for (final update in updates) {
    switch (update) {
      case DataRemove(:final position):
        entries[indexOfLive(position)].kind = DiffLineKind.removed;
      case DataInsert(:final position, :final data):
        entries.insert(indexOfLive(position), _Entry(DiffLineKind.added, data));
      case DataChange(:final position, :final newData):
        final index = indexOfLive(position);
        entries[index].kind = DiffLineKind.removed;
        entries.insert(index + 1, _Entry(DiffLineKind.added, newData));
      case DataMove():
        break; // Moves are not detected.
    }
  }
  // Removed lines first within each changed run, then number them.
  final ordered = <_Entry>[];
  final run = <_Entry>[];
  void flush() {
    ordered
      ..addAll(run.where((e) => e.kind == DiffLineKind.removed))
      ..addAll(run.where((e) => e.kind == DiffLineKind.added));
    run.clear();
  }

  for (final e in entries) {
    if (e.kind == DiffLineKind.same) {
      flush();
      ordered.add(e);
    } else {
      run.add(e);
    }
  }
  flush();
  var oldNumber = 0;
  var newNumber = 0;
  return [
    for (final e in ordered)
      switch (e.kind) {
        DiffLineKind.same => DiffLine(
          e.kind,
          e.text,
          oldNumber: ++oldNumber,
          newNumber: ++newNumber,
        ),
        DiffLineKind.removed => DiffLine(
          e.kind,
          e.text,
          oldNumber: ++oldNumber,
        ),
        DiffLineKind.added => DiffLine(e.kind, e.text, newNumber: ++newNumber),
      },
  ];
}

/// Lines added and removed in [lines].
({int added, int removed}) diffStats(List<DiffLine> lines) => (
  added: lines.where((l) => l.kind == DiffLineKind.added).length,
  removed: lines.where((l) => l.kind == DiffLineKind.removed).length,
);

/// A stretch of a diff: lines to show, or unchanged lines collapsed.
sealed class DiffChunk {
  const DiffChunk(this.lines);

  /// The lines in this chunk.
  final List<DiffLine> lines;
}

/// Lines shown: changes and their context.
class ShownLines extends DiffChunk {
  /// Creates [ShownLines].
  const ShownLines(super.lines);
}

/// Unchanged lines hidden until the user expands them (AV-101).
class CollapsedLines extends DiffChunk {
  /// Creates [CollapsedLines].
  const CollapsedLines(super.lines);
}

/// [lines] with unchanged stretches longer than twice [context] (plus
/// one) collapsed, keeping [context] lines around each change.
List<DiffChunk> diffChunks(List<DiffLine> lines, {int context = 3}) {
  final keep = List.filled(lines.length, false);
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].kind == DiffLineKind.same) continue;
    for (var j = i - context; j <= i + context; j++) {
      if (j >= 0 && j < lines.length) keep[j] = true;
    }
  }
  final chunks = <DiffChunk>[];
  var start = 0;
  while (start < lines.length) {
    var end = start;
    while (end < lines.length && keep[end] == keep[start]) {
      end++;
    }
    final slice = lines.sublist(start, end);
    // A gap of a line or two is not worth a "show more" row.
    chunks.add(
      keep[start] || slice.length <= 2
          ? ShownLines(slice)
          : CollapsedLines(slice),
    );
    start = end;
  }
  // Merge neighbouring shown chunks.
  final merged = <DiffChunk>[];
  for (final c in chunks) {
    if (c is ShownLines && merged.lastOrNull is ShownLines) {
      merged.last = ShownLines([...merged.last.lines, ...c.lines]);
    } else {
      merged.add(c);
    }
  }
  return merged;
}

/// One row of a side-by-side diff: the old line on the left, the new one
/// on the right; either may be empty.
typedef SideBySideRow = ({DiffLine? left, DiffLine? right});

/// [lines] as side-by-side rows: unchanged lines on both sides, and each
/// changed run's removed and added lines paired up in order.
List<SideBySideRow> sideBySideRows(List<DiffLine> lines) {
  final rows = <SideBySideRow>[];
  final removed = <DiffLine>[];
  final added = <DiffLine>[];
  void flush() {
    for (var i = 0; i < removed.length || i < added.length; i++) {
      rows.add((
        left: i < removed.length ? removed[i] : null,
        right: i < added.length ? added[i] : null,
      ));
    }
    removed.clear();
    added.clear();
  }

  for (final line in lines) {
    switch (line.kind) {
      case DiffLineKind.same:
        flush();
        rows.add((left: line, right: line));
      case DiffLineKind.removed:
        removed.add(line);
      case DiffLineKind.added:
        added.add(line);
    }
  }
  flush();
  return rows;
}
