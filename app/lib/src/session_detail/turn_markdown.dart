/// A turn's reply as markdown for the clipboard (AV-071), modelled on VS
/// Code's chat "Copy" action (`AbstractResponse.toString` and
/// `toPortableMarkdown`).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:markdown/markdown.dart' as md;

import 'timeline_items.dart';

/// The reply of [turn] as markdown, one paragraph per part: markdown parts
/// as written, each tool call's summary (and its error when it failed),
/// errors and notes. Reasoning, input requests and unknown parts are left
/// out. Links that only resolve on the host (absolute paths, `file:` and
/// other non-web schemes) become their label as inline code
/// ([portableMarkdown]).
String turnMarkdown(Turn turn) => portableMarkdown(
  [for (final part in turn.responseParts) ?_partMarkdown(part)]
      .where((block) => block.isNotEmpty)
      .join('\n\n'),
);

/// [markdown] (GitHub flavored) rendered as an HTML fragment, for the
/// clipboard's rich copy of [turnMarkdown].
String markdownHtml(String markdown) =>
    md.markdownToHtml(markdown, extensionSet: md.ExtensionSet.gitHubFlavored);

String? _partMarkdown(ResponsePart part) => switch (part) {
  MarkdownResponsePart(:final content) => content.trim(),
  ToolCallResponsePart(:final toolCall) => [
    toolCallSummary(toolCall),
    ?_toolCallError(toolCall),
  ].join('\n'),
  ErrorResponsePart(:final error) => error.message,
  SystemNotificationResponsePart(:final content) => content.text,
  ResourceResponsePart(:final uri) => _resourceMarkdown(uri),
  ReasoningResponsePart() ||
  InputRequestResponsePart() ||
  ResponsePartUnknown() => null,
};

String? _toolCallError(ToolCallState toolCall) => switch (toolCall) {
  ToolCallCompletedState(:final error?, success: false) => error.message,
  ToolCallCompletedState(success: false) => 'Failed',
  ToolCallCancelledState() => 'Cancelled',
  _ => null,
};

String _resourceMarkdown(String uri) => isPortableLinkTarget(uri)
    ? uri
    : inlineCode(
        uri
            .split(RegExp(r'[/\\]'))
            .lastWhere((s) => s.isNotEmpty, orElse: () => uri),
      );

/// Whether [target] still resolves when pasted into another application:
/// an `http`, `https` or `mailto` URL.
bool isPortableLinkTarget(String target) =>
    RegExp(r'^(https?|mailto):', caseSensitive: false).hasMatch(target.trim());

/// Whether a link to [target] is worth keeping in shared markdown: a
/// portable URL ([isPortableLinkTarget]), or a relative target such as
/// `#section` or `docs/a.md`, which names no machine.
bool isPortableMarkdownTarget(String target) {
  final t = target.trim();
  return isPortableLinkTarget(t) ||
      (t.isNotEmpty &&
          !RegExp(r'^[a-z][a-z0-9.+-]*:', caseSensitive: false).hasMatch(t) &&
          !RegExp(r'^(?:[/\\]|[a-z]:[/\\])', caseSensitive: false).hasMatch(t));
}

/// [text] as an inline code span, fenced with one more backtick than its
/// longest run of backticks.
String inlineCode(String text) {
  final longest = RegExp('`+')
      .allMatches(text)
      .fold(0, (n, m) => m.end - m.start > n ? m.end - m.start : n);
  final fence = '`' * (longest + 1);
  final padded = text.startsWith('`') || text.endsWith('`') ? ' $text ' : text;
  return '$fence$padded$fence';
}

final _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})');
final _codeSpan = RegExp(r'(`+)[\s\S]*?\1');
final _link = RegExp(
  r'''(!?)\[((?:\\.|[^\[\]\\])*)\]\(\s*(<[^>]*>|[^\s)]*)(?:\s+(?:"[^"]*"|'[^']*'))?\s*\)''',
);

/// [markdown] with inline links and images whose target is not portable
/// ([isPortableMarkdownTarget]) replaced by their label (or alt text) as
/// inline code, and dropped when the label is empty. Fenced code blocks
/// and code spans are left alone.
String portableMarkdown(String markdown) {
  final out = StringBuffer();
  String? openFence;
  final prose = StringBuffer();
  void flushProse() {
    out.write(_rewriteProse(prose.toString()));
    prose.clear();
  }

  for (final line in markdown.split('\n').indexed) {
    final (i, text) = line;
    final sep = i == 0 ? '' : '\n';
    final fence = _fence.firstMatch(text)?.group(1);
    if (openFence == null && fence != null) {
      flushProse();
      openFence = fence;
      out.write('$sep$text');
    } else if (openFence != null) {
      if (fence != null &&
          fence[0] == openFence[0] &&
          fence.length >= openFence.length &&
          text.trim() == fence) {
        openFence = null;
      }
      out.write('$sep$text');
    } else {
      prose.write('$sep$text');
    }
  }
  flushProse();
  return out.toString();
}

/// Rewrites the links of [text] outside its code spans.
String _rewriteProse(String text) {
  final out = StringBuffer();
  var at = 0;
  for (final span in _codeSpan.allMatches(text)) {
    out
      ..write(_rewriteLinks(text.substring(at, span.start)))
      ..write(span[0]);
    at = span.end;
  }
  out.write(_rewriteLinks(text.substring(at)));
  return out.toString();
}

String _rewriteLinks(String text) => text.replaceAllMapped(_link, (m) {
  var target = m[3]!;
  if (target.startsWith('<')) target = target.substring(1, target.length - 1);
  if (isPortableMarkdownTarget(target)) return m[0]!;
  final label = m[2]!.replaceAllMapped(RegExp(r'\\(.)'), (e) => e[1]!).trim();
  return label.isEmpty ? '' : inlineCode(label);
});
