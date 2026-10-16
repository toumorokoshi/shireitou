/// Diff widgets for file edits (AV-065 inline previews, AV-101 the diff
/// viewer): unified and side-by-side views with syntax highlighting and
/// collapsible unchanged regions. File contents are `ContentRef`s read
/// with `resourceRead`.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../channels.dart';
import '../host_connection.dart';
import 'code_highlight.dart';
import 'diff_lines.dart';

/// Widths at or above which the full diff viewer offers side by side.
const sideBySideMinWidth = 900.0;

final _diffCache = <(String?, String?), List<DiffLine>>{};

/// [diffLines] of two content references' text, cached by their URIs
/// (content behind a `ContentRef` does not change), keeping the 64 most
/// recent.
List<DiffLine> _cachedDiff(
  String? beforeUri,
  String? afterUri,
  String before,
  String after,
) {
  final key = (beforeUri, afterUri);
  final cached = _diffCache.remove(key);
  final lines = cached ?? diffLines(before, after);
  _diffCache[key] = lines;
  if (_diffCache.length > 64) _diffCache.remove(_diffCache.keys.first);
  return lines;
}

/// A short path for [uri]: its last two segments.
String shortPath(String uri) {
  final path = Uri.tryParse(uri)?.path ?? uri;
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  return segments.length <= 2
      ? segments.join('/')
      : segments.sublist(segments.length - 2).join('/');
}

/// "+3 −1" for [stats].
String diffStatsLabel(int? added, int? removed) =>
    '+${added ?? 0} −${removed ?? 0}';

/// Loads both sides of a file edit and shows the diff. [maxLines] limits
/// an inline preview (changes and context only); null shows the whole
/// diff with collapsible unchanged regions.
class FileEditDiff extends ConsumerWidget {
  /// Creates a [FileEditDiff] for [before] and [after] (either may be
  /// absent, for creations and deletions) of the file at [path].
  const FileEditDiff({
    super.key,
    required this.before,
    required this.after,
    required this.path,
    this.maxLines,
    this.sideBySide = false,
  });

  /// The old content, if the file existed.
  final ContentRef? before;

  /// The new content, unless the file was deleted.
  final ContentRef? after;

  /// The file path, for the highlighting language.
  final String path;

  /// At most this many lines (an inline preview), or null for all.
  final int? maxLines;

  /// Side-by-side rather than unified.
  final bool sideBySide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<String> side(ContentRef? content) => content == null
        ? const AsyncData('')
        : ref.watch(
            resourceTextProvider((host: context.host, uri: content.uri)),
          );
    final old = side(before);
    final current = side(after);
    if (old.hasError || current.hasError) {
      return _Message(
        'Could not load the file contents: ${old.error ?? current.error}',
      );
    }
    if (!old.hasValue || !current.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      );
    }
    final lines = _cachedDiff(
      before?.uri,
      after?.uri,
      old.requireValue,
      current.requireValue,
    );
    if (lines.isEmpty) return const _Message('No changes.');
    final language = languageForPath(path);
    final maxLines = this.maxLines;
    if (maxLines != null) {
      final shown = [
        for (final chunk in diffChunks(lines, context: 2))
          if (chunk is ShownLines) ...chunk.lines,
      ];
      return _DiffLines(
        lines: shown.take(maxLines).toList(),
        language: language,
        more: shown.length > maxLines ? shown.length - maxLines : 0,
      );
    }
    return sideBySide
        ? _SideBySide(rows: sideBySideRows(lines), language: language)
        : _ChunkedDiff(chunks: diffChunks(lines), language: language);
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(8), child: Text(text));
}

Color? _lineColor(BuildContext context, DiffLineKind? kind) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (kind) {
    DiffLineKind.added =>
      dark ? const Color(0xFF12361F) : const Color(0xFFE6FFEC),
    DiffLineKind.removed =>
      dark ? const Color(0xFF4A1D20) : const Color(0xFFFFEBE9),
    _ => null,
  };
}

String _marker(DiffLineKind kind) => switch (kind) {
  DiffLineKind.added => '+',
  DiffLineKind.removed => '−',
  DiffLineKind.same => ' ',
};

/// One diff line: line numbers, marker and highlighted text.
class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.language,
    this.numbers = 2,
  });

  final DiffLine line;
  final String? language;

  /// How many line number columns: 2 (old and new) or 1 (side by side).
  final int numbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = codeStyle(context);
    final muted = base.copyWith(color: theme.colorScheme.onSurfaceVariant);
    String number(int? n) => (n?.toString() ?? '').padLeft(4);
    return Container(
      color: _lineColor(context, line.kind),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numbers == 2
                ? '${number(line.oldNumber)} ${number(line.newNumber)} '
                : '${number(line.newNumber ?? line.oldNumber)} ',
            style: muted,
          ),
          Text('${_marker(line.kind)} ', style: muted),
          Text.rich(
            highlightCode(
              line.text,
              language: language,
              base: base,
              brightness: theme.brightness,
            ),
            softWrap: false,
          ),
        ],
      ),
    );
  }
}

/// A scrollable block of monospace rows, wide lines scrolling sideways.
class _CodeArea extends StatelessWidget {
  const _CodeArea({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(6),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _DiffLines extends StatelessWidget {
  const _DiffLines({
    required this.lines,
    required this.language,
    this.more = 0,
  });

  final List<DiffLine> lines;
  final String? language;
  final int more;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _CodeArea(
        children: [
          for (final line in lines) _LineRow(line: line, language: language),
        ],
      ),
      if (more > 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$more more lines',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}

/// The whole unified diff; unchanged regions are collapsed rows that
/// expand when tapped (AV-101).
class _ChunkedDiff extends StatefulWidget {
  const _ChunkedDiff({required this.chunks, required this.language});

  final List<DiffChunk> chunks;
  final String? language;

  @override
  State<_ChunkedDiff> createState() => _ChunkedDiffState();
}

class _ChunkedDiffState extends State<_ChunkedDiff> {
  final _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CodeArea(
      children: [
        for (final (i, chunk) in widget.chunks.indexed)
          if (chunk is CollapsedLines && !_expanded.contains(i))
            InkWell(
              onTap: () => setState(() => _expanded.add(i)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '⋯ Show ${chunk.lines.length} unchanged lines',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else
            for (final line in chunk.lines)
              _LineRow(line: line, language: widget.language),
      ],
    );
  }
}

class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.rows, required this.language});

  final List<SideBySideRow> rows;
  final String? language;

  @override
  Widget build(BuildContext context) {
    Widget side(DiffLine? line) => line == null
        ? const SizedBox(height: 18)
        : _LineRow(line: line, language: language, numbers: 1);
    Widget column(DiffLine? Function(SideBySideRow) pick) => Expanded(
      child: _CodeArea(children: [for (final row in rows) side(pick(row))]),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column((r) => r.left),
        const SizedBox(width: 8),
        column((r) => r.right),
      ],
    );
  }
}

/// A full-screen diff of one file, unified or side by side (the latter on
/// wide layouts), with the file's other actions in [actions].
class FileDiffPage extends StatefulWidget {
  /// Creates a [FileDiffPage].
  const FileDiffPage({
    super.key,
    required this.title,
    required this.before,
    required this.after,
    required this.path,
    this.actions = const [],
  });

  /// The page title (the file).
  final String title;

  /// The old content.
  final ContentRef? before;

  /// The new content.
  final ContentRef? after;

  /// The file path.
  final String path;

  /// Extra app bar actions.
  final List<Widget> actions;

  @override
  State<FileDiffPage> createState() => _FileDiffPageState();
}

class _FileDiffPageState extends State<FileDiffPage> {
  bool _sideBySide = true;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= sideBySideMinWidth;
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title, overflow: TextOverflow.ellipsis),
          actions: [
            if (wide)
              IconButton(
                tooltip: _sideBySide ? 'Unified view' : 'Side-by-side view',
                icon: Icon(
                  _sideBySide
                      ? Icons.view_agenda_outlined
                      : Icons.vertical_split,
                ),
                onPressed: () => setState(() => _sideBySide = !_sideBySide),
              ),
            ...widget.actions,
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FileEditDiff(
            before: widget.before,
            after: widget.after,
            path: widget.path,
            sideBySide: wide && _sideBySide,
          ),
        ),
      );
    },
  );
}

/// Opens [FileDiffPage] for a file edit.
Future<void> openFileDiff(
  BuildContext context, {
  required ContentRef? before,
  required ContentRef? after,
  required String uri,
  List<Widget> actions = const [],
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => HostScope(
      host: context.host,
      child: FileDiffPage(
        title: shortPath(uri),
        before: before,
        after: after,
        path: uri,
        actions: actions,
      ),
    ),
  ),
);
