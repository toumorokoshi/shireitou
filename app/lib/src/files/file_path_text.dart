/// Plain text whose file paths (AV-106) and `/skill` references are links
/// that open the file or skill target, such as a user turn, a tool call's
/// summary ("Read src/app.dart"), or reasoning text.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../session_detail/link_menu.dart';
import 'file_paths.dart';
import 'open_file_store.dart';
import 'skill_links.dart';

/// [text] with the file paths ([findFileReferences], below a [FileLinkScope])
/// and skill references ([findSkillReferences], below a [SkillLinkScope] or
/// from [attachments]) as links; plain text when none are found.
class FilePathText extends StatefulWidget {
  /// Creates a [FilePathText] for [text].
  const FilePathText(
    this.text, {
    super.key,
    this.attachments,
    this.style,
    this.maxLines,
    this.overflow,
  });

  /// The text.
  final String text;

  /// Optional attachments on a user message (used for skill references).
  final List<MessageAttachment>? attachments;

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
  List<TextLinkMatch>? _matchesKey;
  OpenFile? _openFileKey;
  TextStyle? _linkKey;

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

  /// The spans of [text], built again only when [matches], [openFile] or
  /// [link] change, so the recognizers live as long as the text that uses
  /// them.
  List<InlineSpan>? _spansOf(
    String text,
    List<TextLinkMatch> matches,
    OpenFile? openFile,
    TextStyle link,
  ) {
    if (listEquals(matches, _matchesKey) &&
        openFile == _openFileKey &&
        link == _linkKey) {
      return _spans;
    }
    _matchesKey = matches;
    _openFileKey = openFile;
    _linkKey = link;
    _disposeRecognizers();
    if (matches.isEmpty) return _spans = null;
    var at = 0;
    final spans = <InlineSpan>[];
    for (final match in matches) {
      if (match.start > at) {
        spans.add(TextSpan(text: text.substring(at, match.start)));
      }
      final label = text.substring(match.start, match.end);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => followLink(match.href, openFile: openFile);
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: label, style: link, recognizer: recognizer));
      at = match.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return _spans = spans;
  }

  @override
  Widget build(BuildContext context) {
    final openFile = FileLinkScope.maybeOf(context);
    final skills = SkillLinkScope.maybeOf(context);
    final skillMatches = findSkillReferences(
      widget.text,
      skills,
      attachments: widget.attachments,
    );
    final fileMatches = openFile == null
        ? const <FileMatch>[]
        : findFileReferences(widget.text);
    final matches = mergeTextLinkMatches(
      skillMatches,
      fileMatches,
      widget.text,
    );
    final spans = _spansOf(
      widget.text,
      matches,
      openFile,
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
    return LinkSecondaryTap(
      onLink: (link) {
        if (linkHref(link) case final href?) {
          unawaited(showLinkDialog(context, href));
        }
      },
      child: Text.rich(
        TextSpan(children: spans),
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}
