/// The file viewer (AV-106): a file a reply names, read from the host
/// with `resourceRead`, with line numbers and syntax highlighting, scrolled
/// to the lines the reply pointed at.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../channels.dart';
import '../host_connection.dart';
import '../session_detail/code_highlight.dart';
import '../session_detail/copy_button.dart';
import '../theme/app_colors.dart';
import 'open_file_store.dart';

/// Files longer than this are shown without highlighting, which would
/// take too long.
const maxHighlightedLength = 200000;

/// The lines of [text], without the empty one after a final newline.
List<String> fileLines(String text) {
  final lines = text.split('\n');
  if (lines.length > 1 && lines.last.isEmpty) lines.removeLast();
  return lines;
}

/// Whether [text] looks binary (it has a NUL character).
bool looksBinary(String text) => text.contains('\u0000');

/// "L12" or "L12–20" for the lines of [file]; null without a line.
String? lineLabel(OpenedFile file) => switch ((file.line, file.endLine)) {
  (final line?, final end?) when end > line => 'L$line–$end',
  (final line?, _) => 'L$line',
  _ => null,
};

/// [file] in the session's side pane, with a close button ([onClose]) that
/// goes back to "Files changed".
class FileViewer extends ConsumerWidget {
  /// Creates a [FileViewer] for [file].
  const FileViewer({super.key, required this.file, this.onClose});

  /// The file.
  final OpenedFile file;

  /// Closes the viewer; no close button when null.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final lines = lineLabel(file);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: colors.mutedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Tooltip(
                  message: Uri.parse(file.uri).path,
                  child: Text(
                    file.label,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (lines != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    lines,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                ),
              CopyButton(text: () => file.label, tooltip: 'Copy path'),
              if (onClose case final close?)
                IconButton(
                  tooltip: 'Close file',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: close,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: FileContents(file: file)),
      ],
    );
  }
}

/// The contents of [file], loading, or why they could not be read.
class FileContents extends ConsumerWidget {
  /// Creates a [FileContents] for [file].
  const FileContents({super.key, required this.file});

  /// The file.
  final OpenedFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(
      resourceTextProvider((host: context.host, uri: file.uri)),
    );
    Widget message(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
    return text.when(
      data: (text) => looksBinary(text)
          ? message('${file.label} is a binary file.')
          : _Lines(
              key: ValueKey((file.uri, file.line, file.endLine)),
              text: text,
              path: file.uri,
              line: file.line,
              endLine: file.endLine,
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => message('Could not open ${file.label}: $error'),
    );
  }
}

class _Lines extends StatefulWidget {
  const _Lines({
    super.key,
    required this.text,
    required this.path,
    required this.line,
    required this.endLine,
  });

  final String text;
  final String path;
  final int? line;
  final int? endLine;

  @override
  State<_Lines> createState() => _LinesState();
}

class _LinesState extends State<_Lines> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  TextSpan? _highlighted;
  Object? _highlightKey;

  /// Whether the view has scrolled to the reply's line.
  bool _scrolled = false;

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  TextSpan _spans(String text, TextStyle base, Map<String, TextStyle> theme) {
    final key = (text, base, theme);
    if (_highlightKey != key) {
      _highlightKey = key;
      _highlighted = highlightCode(
        text,
        language: text.length > maxHighlightedLength
            ? null
            : languageForPath(Uri.parse(widget.path).path),
        base: base,
        theme: theme,
      );
    }
    return _highlighted!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final base = codeStyle(context);
    final fontSize = base.fontSize ?? 12;
    final height = base.height ?? 1.4;
    final lineHeight = fontSize * height;
    final strut = StrutStyle(
      fontSize: fontSize,
      height: height,
      forceStrutHeight: true,
    );
    final lines = fileLines(widget.text);
    final first = widget.line?.clamp(1, lines.length);
    final last = switch ((first, widget.endLine)) {
      (final f?, final e?) => e.clamp(f, lines.length),
      (final f?, null) => f,
      _ => null,
    };
    const padding = EdgeInsets.symmetric(vertical: 8);
    if (first != null && !_scrolled) {
      _scrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_vertical.hasClients) return;
        final target = (first - 4) * lineHeight;
        _vertical.jumpTo(
          target.clamp(0, _vertical.position.maxScrollExtent).toDouble(),
        );
      });
    }
    final gutter = Text(
      [for (var i = 1; i <= lines.length; i++) '$i'].join('\n'),
      textAlign: TextAlign.right,
      strutStyle: strut,
      style: base.copyWith(color: colors.mutedText),
    );
    final code = Text.rich(
      _spans(lines.join('\n'), base, colors.syntax),
      strutStyle: strut,
      softWrap: false,
    );
    return Scrollbar(
      controller: _vertical,
      child: SingleChildScrollView(
        controller: _vertical,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectionContainer.disabled(
              child: Padding(
                padding: padding.copyWith(left: 8, right: 12),
                child: gutter,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Stack(
                      children: [
                        if (first != null && last != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: padding.top + (first - 1) * lineHeight,
                            height: (last - first + 1) * lineHeight,
                            child: ColoredBox(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                        Padding(
                          padding: padding.copyWith(right: 12),
                          child: SelectionArea(child: code),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [file] on a page of its own, for layouts without the side pane.
class FileViewerPage extends StatelessWidget {
  /// Creates a [FileViewerPage] for [file].
  const FileViewerPage({super.key, required this.file});

  /// The file.
  final OpenedFile file;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(file.label, overflow: TextOverflow.ellipsis)),
    body: FileViewer(file: file),
  );
}

/// Pushes a [FileViewerPage] for [file], on the host of [context].
Future<void> openFilePage(BuildContext context, OpenedFile file) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HostScope(
          host: context.host,
          child: FileViewerPage(file: file),
        ),
      ),
    );
