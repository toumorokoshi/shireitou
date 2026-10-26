/// Selected rich text as HTML for the clipboard: links, bold, italic and
/// code spans, read from the spans' styles.
library;

import 'dart:convert';

import 'package:flutter/painting.dart';

/// A stretch of text with one formatting.
typedef HtmlRun = ({
  String text,
  String? href,
  bool bold,
  bool italic,
  bool code,
});

/// The runs of [root]'s plain text (placeholders count one character)
/// between [start] and [end], with adjacent runs of the same formatting
/// merged. [hrefOf] gives the URL of a span's link; a span's children
/// share its link.
List<HtmlRun> spanRuns(
  InlineSpan root,
  int start,
  int end, {
  String? Function(TextSpan span)? hrefOf,
}) {
  final runs = <HtmlRun>[];
  var offset = 0;
  void add(String text, TextStyle style, String? href) {
    final from = (start - offset).clamp(0, text.length);
    final to = (end - offset).clamp(0, text.length);
    offset += text.length;
    if (from >= to) return;
    final run = (
      text: text.substring(from, to),
      href: href,
      bold: (style.fontWeight?.value ?? 400) >= 600,
      italic: style.fontStyle == FontStyle.italic,
      code: style.fontFamily == 'monospace',
    );
    if (runs.isNotEmpty && _sameFormat(runs.last, run)) {
      final last = runs.removeLast();
      runs.add((
        text: last.text + run.text,
        href: run.href,
        bold: run.bold,
        italic: run.italic,
        code: run.code,
      ));
    } else {
      runs.add(run);
    }
  }

  void walk(InlineSpan span, TextStyle style, String? href) {
    switch (span) {
      case TextSpan(:final text, :final children):
        final merged = style.merge(span.style);
        final link = hrefOf?.call(span) ?? href;
        if (text != null) add(text, merged, link);
        for (final child in children ?? const <InlineSpan>[]) {
          walk(child, merged, link);
        }
      case PlaceholderSpan():
        offset += 1;
      default:
        offset += span.toPlainText(includeSemanticsLabels: false).length;
    }
  }

  walk(root, const TextStyle(), null);
  return runs;
}

bool _sameFormat(HtmlRun a, HtmlRun b) =>
    a.href == b.href &&
    a.bold == b.bold &&
    a.italic == b.italic &&
    a.code == b.code;

const _attribute = HtmlEscape(HtmlEscapeMode.attribute);
const _element = HtmlEscape(HtmlEscapeMode.element);

/// [text] escaped for HTML, with line breaks as `<br>`.
String htmlText(String text) =>
    htmlEscape.convert(text).replaceAll('\n', '<br>');

/// [runs] as an HTML fragment.
String runsHtml(Iterable<HtmlRun> runs) => runs.map((run) {
  var html = htmlText(run.text);
  if (run.code) html = '<code>$html</code>';
  if (run.italic) html = '<i>$html</i>';
  if (run.bold) html = '<b>$html</b>';
  if (run.href case final href?) {
    html = '<a href="${_attribute.convert(href)}">$html</a>';
  }
  return html;
}).join();

/// [text] as a preformatted HTML block, for selected code.
String preHtml(String text) => '<pre>${_element.convert(text)}</pre>';
