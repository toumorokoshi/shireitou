/// Markdown inline syntaxes that turn file paths in replies into links
/// (AV-106): `` `src/a.dart:12` `` code spans and bare paths in prose.
/// Their links' targets are [filePathHref]s.
library;

import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

import 'file_paths.dart';

/// The syntaxes to give a `MarkdownBody` whose file paths open files.
final List<md.InlineSyntax> fileLinkSyntaxes = [
  _OuterLinkSyntax(),
  _FilePathCodeSyntax(),
  _FilePathTextSyntax(),
];

/// The default link syntax, but a link's text keeps no links of its own:
/// `[main.dart](/work/lib/main.dart)` opens the link's target, not the
/// `main.dart` the path syntaxes found in its text (links do not nest).
class _OuterLinkSyntax extends md.LinkSyntax {
  @override
  md.Node createNode(
    String destination,
    String? title, {
    required List<md.Node> Function() getChildren,
  }) => super.createNode(
    destination,
    title,
    getChildren: () => _withoutLinks(getChildren()),
  );
}

/// [nodes] with each link replaced by its content, at any depth.
List<md.Node> _withoutLinks(List<md.Node> nodes) => [
  for (final node in nodes)
    if (node is md.Element && node.tag == 'a')
      ..._withoutLinks(node.children ?? const [])
    else if (node is md.Element && node.children != null)
      md.Element(node.tag, _withoutLinks(node.children!))
        ..attributes.addAll(node.attributes)
    else
      node,
];

/// A one-backtick code span whose content is a file path: a link around
/// the code. Other code spans are left to the default code syntax.
class _FilePathCodeSyntax extends md.InlineSyntax {
  _FilePathCodeSyntax()
    : super(r'(?<!`)`([^`\n]+)`(?!`)', startCharacter: 0x60);

  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    final match = pattern.matchAsPrefix(
      parser.source,
      startMatchPos ?? parser.pos,
    );
    if (match == null || parseFileReference(match[1]!) == null) return false;
    return super.tryMatch(parser, startMatchPos);
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final text = match[1]!.trim();
    final code = parser.encodeHtml ? _escape(text) : text;
    parser.addNode(
      md.Element('a', [md.Element.text('code', code)])
        ..attributes['href'] = filePathHref(text),
    );
    return true;
  }
}

/// A bare file path in prose ([filePathPattern]): a link with the path as
/// its text.
class _FilePathTextSyntax extends md.InlineSyntax {
  _FilePathTextSyntax() : super(filePathPattern.pattern);

  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    final match = pattern.matchAsPrefix(
      parser.source,
      startMatchPos ?? parser.pos,
    );
    if (match == null || parseFileReference(match[0]!) == null) return false;
    return super.tryMatch(parser, startMatchPos);
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final text = match[0]!;
    parser.addNode(
      md.Element('a', [md.Text(parser.encodeHtml ? _escape(text) : text)])
        ..attributes['href'] = filePathHref(text),
    );
    return true;
  }
}

String _escape(String text) =>
    const HtmlEscape(HtmlEscapeMode(escapeLtGt: true, escapeQuot: true))
        .convert(text);
