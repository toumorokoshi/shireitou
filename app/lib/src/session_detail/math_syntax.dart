/// Markdown syntaxes for TeX math in replies (AV-078): display math in
/// `$$…$$` or `\[…\]` (its own lines, or inline in a paragraph) and
/// inline math in `\(…\)` or `$…$`. Each becomes a `math` element whose
/// text is the TeX, with `display` set for display math and `source`
/// holding the text as written.
library;

import 'package:markdown/markdown.dart' as md;

/// The markdown tag of a math element.
const mathTag = 'math';

/// Block syntaxes for display math on its own lines.
final List<md.BlockSyntax> mathBlockSyntaxes = [_MathBlockSyntax()];

/// Inline syntaxes for math within a paragraph.
final List<md.InlineSyntax> mathInlineSyntaxes = [_MathInlineSyntax()];

md.Element _math(String tex, {required bool display, required String source}) =>
    md.Element.text(mathTag, tex.trim())
      ..attributes['display'] = '$display'
      ..attributes['source'] = source;

const _closers = {r'$$': r'$$', r'\[': r'\]'};

/// A line that opens display math: `$$` or `\[`, then the rest of the line.
final _opener = RegExp(r'^ {0,3}(\$\$|\\\[)(.*)$');

/// The TeX of the display math opened on the current line: the lines up to
/// the one ending with the closer, or null when no line before the next
/// blank line closes it. The opening line alone is either just the opener
/// or a whole `$$…$$`.
List<String>? _displayLines(md.BlockParser parser) {
  final match = _opener.firstMatch(parser.current.content);
  if (match == null) return null;
  final close = _closers[match[1]]!;
  final first = match[2]!.trim();
  if (first.isNotEmpty) {
    return first.length > close.length && first.endsWith(close)
        ? [first.substring(0, first.length - close.length)]
        : null;
  }
  final lines = <String>[];
  for (var ahead = 1; ; ahead++) {
    final line = parser.peek(ahead)?.content;
    if (line == null || line.trim().isEmpty) return null;
    final end = line.trimRight();
    if (end.endsWith(close)) {
      return [...lines, end.substring(0, end.length - close.length)];
    }
    lines.add(line);
  }
}

class _MathBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => _opener;

  @override
  bool canParse(md.BlockParser parser) => _displayLines(parser) != null;

  @override
  md.Node parse(md.BlockParser parser) {
    final lines = _displayLines(parser)!;
    final oneLine = _opener
        .firstMatch(parser.current.content)![2]!
        .trim()
        .isNotEmpty;
    final written = <String>[];
    for (var i = oneLine ? 1 : lines.length + 1; i > 0; i--) {
      written.add(parser.current.content);
      parser.advance();
    }
    return md.Element('p', [
      _math(lines.join('\n'), display: true, source: written.join('\n')),
    ]);
  }
}

/// `$$…$$`, `\[…\]`, `\(…\)`, then `$…$`. A `$…$` follows Pandoc's rule so
/// prices stay text: no space after the opening `$`, none before the
/// closing one, and no digit after it.
final _inlineMath = RegExp(
  r'\$\$([^$]+?)\$\$'
  r'|\\\[([\s\S]+?)\\\]'
  r'|\\\(([\s\S]+?)\\\)'
  r'|\$(?![\s$])((?:\\.|[^\\$\n])*?[^\s\\])\$(?!\d)',
);

class _MathInlineSyntax extends md.InlineSyntax {
  _MathInlineSyntax() : super(_inlineMath.pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final display = match[1] ?? match[2];
    parser.addNode(
      _math(
        display ?? match[3] ?? match[4]!,
        display: display != null,
        source: match[0]!,
      ),
    );
    return true;
  }
}
