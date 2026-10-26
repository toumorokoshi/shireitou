/// Plain text whose file paths are links that open the file (AV-106),
/// such as a tool call's summary ("Read src/app.dart").
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../session_detail/link_menu.dart';
import 'file_paths.dart';
import 'open_file_store.dart';

/// [text] with the file paths in it ([findFileReferences]) as links, below
/// a [FileLinkScope]; plain text without one or without paths.
class FilePathText extends StatefulWidget {
  /// Creates a [FilePathText] for [text].
  const FilePathText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  /// The text.
  final String text;

  /// Its style.
  final TextStyle? style;

  /// See [Text.maxLines].
  final int? maxLines;

  /// See [Text.overflow].
  final TextOverflow? overflow;

  @override
  State<FilePathText> createState() => _FilePathTextState();
}

class _FilePathTextState extends State<FilePathText> {
  final _recognizers = <TapGestureRecognizer>[];
  List<InlineSpan>? _spans;
  Object? _spansKey;

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  /// The spans of [text], built again only when it, [openFile] or [link]
  /// change, so the recognizers live as long as the text that uses them.
  List<InlineSpan>? _spansOf(String text, OpenFile? openFile, TextStyle link) {
    final key = (text, openFile, link);
    if (key == _spansKey) return _spans;
    _spansKey = key;
    _disposeRecognizers();
    final matches = openFile == null
        ? const <FileMatch>[]
        : findFileReferences(text);
    if (matches.isEmpty) return _spans = null;
    var at = 0;
    final spans = <InlineSpan>[];
    for (final match in matches) {
      if (match.start > at) {
        spans.add(TextSpan(text: text.substring(at, match.start)));
      }
      final path = text.substring(match.start, match.end);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => followLink(filePathHref(path), openFile: openFile);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: path, style: link, recognizer: recognizer));
      at = match.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return _spans = spans;
  }

  @override
  Widget build(BuildContext context) {
    final spans = _spansOf(
      widget.text,
      FileLinkScope.maybeOf(context),
      TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
    if (spans == null) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
