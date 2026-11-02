/// Converts rich text HTML (such as that copied from Google Docs, web pages,
/// or rich text editors) into clean Markdown.
library;

import 'dart:math';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Converts an HTML string [html] into Markdown.
///
/// Returns an empty string if [html] is empty or whitespace-only.
String htmlToMarkdown(String html) {
  final trimmed = html.trim();
  if (trimmed.isEmpty) return '';

  final fragment = html_parser.parseFragment(trimmed);
  final buffer = StringBuffer();
  final context = _ConversionContext();

  for (final node in fragment.nodes) {
    _walk(node, buffer, context);
  }

  return _normalizeOutput(buffer.toString());
}

/// Parsing context tracking list nesting, ordered list counters, etc.
class _ConversionContext {
  final Map<Object, int> orderedCounters = {};
  bool inPre = false;
  bool inTable = false;
  bool inBlockquote = false;
}

void _walk(dom.Node node, StringBuffer out, _ConversionContext context) {
  if (node is dom.Text) {
    if (context.inPre) {
      out.write(node.text);
      return;
    }

    if (node.text.trim().isEmpty) {
      final parent = node.parentNode;
      if (parent is dom.DocumentFragment || parent is dom.Document) {
        return;
      }
      final prev = _previousSibling(node);
      final next = _nextSibling(node);
      if (_isBlockNode(prev) ||
          _isBlockNode(next) ||
          (prev == null && _isBlockNode(parent)) ||
          (next == null && _isBlockNode(parent))) {
        return;
      }
    }

    var text = node.text.replaceAll('\u00A0', ' ');
    text = text.replaceAll(RegExp(r'\s*\n\s*'), ' ');
    out.write(text);
    return;
  }

  if (node is! dom.Element) return;

  final element = node;
  final tag = element.localName?.toLowerCase() ?? '';

  // Skip script, style, head, and comments.
  if (tag == 'script' || tag == 'style' || tag == 'head' || tag == 'meta') {
    return;
  }

  switch (tag) {
    case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
      _renderHeading(element, out, context);
    case 'p':
      _renderParagraph(element, out, context);
    case 'div' || 'article' || 'section' || 'header' || 'footer':
      _renderBlock(element, out, context);
    case 'ul' || 'ol':
      _renderList(element, out, context);
    case 'li':
      _renderListItem(element, out, context);
    case 'blockquote':
      _renderBlockquote(element, out, context);
    case 'pre':
      _renderPre(element, out, context);
    case 'table':
      _renderTable(element, out, context);
    case 'hr':
      _ensureTrailingNewlines(out, 2);
      out.write('---\n\n');
    case 'br':
      out.write('\n');
    case 'a':
      _renderLink(element, out, context);
    case 'img':
      _renderImage(element, out);
    case 'b' || 'strong':
      _renderInlineFormatting(element, out, context, marker: '**');
    case 'i' || 'em':
      _renderInlineFormatting(element, out, context, marker: '*');
    case 's' || 'del' || 'strike':
      _renderInlineFormatting(element, out, context, marker: '~~');
    case 'code':
      if (context.inPre) {
        _walkChildren(element, out, context);
      } else {
        _renderInlineFormatting(element, out, context, marker: '`');
      }
    default:
      // Generic elements (span, font, etc.): check style rules for bold,
      // italic, code, strikethrough, or just walk children.
      _renderStyledElement(element, out, context);
  }
}

void _walkChildren(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  for (final child in element.nodes) {
    _walk(child, out, context);
  }
}

void _renderHeading(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  final tag = element.localName?.toLowerCase() ?? '';
  final level = int.tryParse(tag.replaceFirst('h', '')) ?? 1;
  final prefix = '#' * level;

  _ensureTrailingNewlines(out, 2);
  out.write('$prefix ');
  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  out.write(sub.toString().trim());
  out.write('\n\n');
}

void _renderParagraph(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  // If inside a list item, blockquote, or table, avoid leading double newlines.
  if (_isInside(element, 'li') || context.inBlockquote || context.inTable) {
    _walkChildren(element, out, context);
    out.write('\n');
    return;
  }

  _ensureTrailingNewlines(out, 2);
  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  final text = sub.toString().trim();
  if (text.isNotEmpty) {
    out.write(text);
    out.write('\n\n');
  }
}

void _renderBlock(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  final text = sub.toString().trim();
  if (text.isNotEmpty) {
    out.write(text);
    _ensureTrailingNewlines(out, 1);
  }
}

void _renderList(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  if (!_isInside(element.parent, 'li') &&
      !_isInside(element.parent, 'ul') &&
      !_isInside(element.parent, 'ol')) {
    _ensureTrailingNewlines(out, 2);
  }

  _walkChildren(element, out, context);

  if (!_isInside(element.parent, 'li') &&
      !_isInside(element.parent, 'ul') &&
      !_isInside(element.parent, 'ol')) {
    _ensureTrailingNewlines(out, 2);
  }
}

void _renderListItem(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  final depth = _listItemDepth(element);
  final indent = '  ' * depth;

  final isOrdered =
      element.parent?.localName?.toLowerCase() == 'ol' ||
      _hasOrderedClass(element);

  String prefix;
  final checkbox = element.querySelector('input[type="checkbox"]');
  final ariaChecked = element.attributes['aria-checked'];
  final isTask = checkbox != null || ariaChecked != null;

  if (isTask) {
    final checked =
        checkbox?.attributes.containsKey('checked') == true ||
        ariaChecked == 'true';
    prefix = checked ? '$indent- [x] ' : '$indent- [ ] ';
  } else if (isOrdered) {
    final Object listKey = element.parent?.localName?.toLowerCase() == 'ol'
        ? element.parent!
        : 'flat_$depth';
    final counter = (context.orderedCounters[listKey] ?? 0) + 1;
    context.orderedCounters[listKey] = counter;
    prefix = '$indent$counter. ';
  } else {
    prefix = '$indent- ';
  }

  // Separate non-list children (item text/spans/paragraphs) from nested lists.
  final itemChildren = <dom.Node>[];
  final nestedLists = <dom.Element>[];

  for (final child in element.nodes) {
    if (child is dom.Element &&
        (child.localName?.toLowerCase() == 'ul' ||
            child.localName?.toLowerCase() == 'ol')) {
      nestedLists.add(child);
    } else {
      itemChildren.add(child);
    }
  }

  final sub = StringBuffer();
  for (final child in itemChildren) {
    _walk(child, sub, context);
  }
  var itemText = sub.toString().trim();
  itemText = _stripLeadingBullet(itemText);

  _ensureTrailingNewlines(out, 1);
  out.write(prefix);

  final lines = itemText.split('\n');
  var first = true;
  for (final line in lines) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) continue;
    if (first) {
      out.write(trimmedLine);
      first = false;
    } else {
      out.write('\n$indent  $trimmedLine');
    }
  }
  out.write('\n');

  // Render nested lists directly.
  for (final list in nestedLists) {
    _renderList(list, out, context);
  }
}

void _renderBlockquote(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  _ensureTrailingNewlines(out, 2);
  final wasInBlockquote = context.inBlockquote;
  context.inBlockquote = true;

  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  context.inBlockquote = wasInBlockquote;

  final raw = sub.toString().trim();
  final lines = raw.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    out.write('> $trimmed\n');
  }
  out.write('\n');
}

void _renderPre(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  _ensureTrailingNewlines(out, 2);
  final wasInPre = context.inPre;
  context.inPre = true;

  // Check language from class (e.g. language-dart)
  var lang = '';
  final codeEl = element.querySelector('code');
  final target = codeEl ?? element;
  final cls = target.className;
  final match = RegExp(r'(?:language|lang)-(\w+)').firstMatch(cls);
  if (match != null) {
    lang = match.group(1) ?? '';
  }

  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  context.inPre = wasInPre;

  final codeText = sub.toString().trimRight();
  out.write('```$lang\n$codeText\n```\n\n');
}

void _renderTable(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  _ensureTrailingNewlines(out, 2);
  final wasInTable = context.inTable;
  context.inTable = true;

  final rows = <List<String>>[];
  for (final tr in element.querySelectorAll('tr')) {
    final cells = <String>[];
    for (final cell in tr.children) {
      final tag = cell.localName?.toLowerCase();
      if (tag == 'td' || tag == 'th') {
        final sub = StringBuffer();
        _walkChildren(cell, sub, context);
        // Replace internal newlines in table cells with <br>
        var cellText = sub.toString().trim().replaceAll('\n', '<br>');
        cellText = cellText.replaceAll('|', '\\|');
        cells.add(cellText);
      }
    }
    if (cells.isNotEmpty) {
      rows.add(cells);
    }
  }

  context.inTable = wasInTable;
  if (rows.isEmpty) return;

  final colCount = rows.map((r) => r.length).reduce(max);
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    while (row.length < colCount) {
      row.add('');
    }
    out.write('| ${row.join(' | ')} |\n');
    if (r == 0) {
      final sep = List.filled(colCount, '---');
      out.write('| ${sep.join(' | ')} |\n');
    }
  }
  out.write('\n');
}

void _renderLink(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  var href = element.attributes['href']?.trim() ?? '';
  // Decode Google Docs redirection URLs: https://www.google.com/url?q=TARGET&...
  if (href.contains('google.com/url?') && href.contains('q=')) {
    try {
      final uri = Uri.parse(href);
      final realUrl = uri.queryParameters['q'];
      if (realUrl != null && realUrl.isNotEmpty) {
        href = realUrl;
      }
    } catch (_) {}
  }

  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  final text = sub.toString().trim();

  if (href.isEmpty) {
    out.write(text);
  } else if (text.isEmpty || text == href) {
    out.write('<$href>');
  } else {
    out.write('[$text]($href)');
  }
}

void _renderImage(dom.Element element, StringBuffer out) {
  final src = element.attributes['src']?.trim() ?? '';
  final alt = element.attributes['alt']?.trim() ?? '';
  if (src.isNotEmpty) {
    out.write('![$alt]($src)');
  }
}

void _renderInlineFormatting(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context, {
  required String marker,
}) {
  // If wrapper tag like Google Docs docs-internal-guid with normal font weight, do not format.
  if (_isDocsInternalWrapper(element)) {
    _walkChildren(element, out, context);
    return;
  }

  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  final raw = sub.toString();
  if (raw.isEmpty) return;

  out.write(_wrapInline(raw, marker));
}

void _renderStyledElement(
  dom.Element element,
  StringBuffer out,
  _ConversionContext context,
) {
  if (_isDocsInternalWrapper(element)) {
    _walkChildren(element, out, context);
    return;
  }

  final style = _parseCssStyle(element.attributes['style']);
  final bold = _styleIsBold(style);
  final italic = _styleIsItalic(style);
  final strikethrough = _styleIsStrikethrough(style);
  final code = _styleIsCode(style) && !context.inPre;

  final sub = StringBuffer();
  _walkChildren(element, sub, context);
  var text = sub.toString();
  if (text.isEmpty) return;

  if (code) text = _wrapInline(text, '`');
  if (strikethrough) text = _wrapInline(text, '~~');
  if (italic) text = _wrapInline(text, '*');
  if (bold) text = _wrapInline(text, '**');

  out.write(text);
}

bool _isDocsInternalWrapper(dom.Element element) {
  if (element.id.startsWith('docs-internal-guid')) return true;
  final style = _parseCssStyle(element.attributes['style']);
  final fw = style['font-weight']?.toLowerCase();
  if (element.localName?.toLowerCase() == 'b' &&
      (fw == 'normal' || fw == '400')) {
    return true;
  }
  return false;
}

Map<String, String> _parseCssStyle(String? style) {
  if (style == null || style.trim().isEmpty) return const {};
  final result = <String, String>{};
  for (final rule in style.split(';')) {
    final colon = rule.indexOf(':');
    if (colon == -1) continue;
    final property = rule.substring(0, colon).trim().toLowerCase();
    final value = rule.substring(colon + 1).trim();
    if (property.isNotEmpty) {
      result[property] = value;
    }
  }
  return result;
}

bool _styleIsBold(Map<String, String> style) {
  final fw = style['font-weight']?.toLowerCase();
  if (fw == null) return false;
  if (fw == 'bold' || fw == 'bolder') return true;
  final num = int.tryParse(fw);
  return num != null && num >= 600;
}

bool _styleIsItalic(Map<String, String> style) {
  final fs = style['font-style']?.toLowerCase();
  return fs == 'italic' || fs == 'oblique';
}

bool _styleIsStrikethrough(Map<String, String> style) {
  final td = style['text-decoration']?.toLowerCase() ?? '';
  return td.contains('line-through');
}

bool _styleIsCode(Map<String, String> style) {
  final ff = style['font-family']?.toLowerCase() ?? '';
  return ff.contains('consolas') ||
      ff.contains('courier') ||
      ff.contains('menlo') ||
      ff.contains('monaco') ||
      ff.contains('roboto mono') ||
      ff.contains('monospace');
}

String _wrapInline(String text, String marker) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return text;

  final start = text.indexOf(trimmed);
  final leading = text.substring(0, start);
  final trailing = text.substring(start + trimmed.length);

  return '$leading$marker$trimmed$marker$trailing';
}

String _stripLeadingBullet(String text) {
  var t = text.trimLeft();
  final bulletRegex = RegExp(r'^[\u2022\u25E6\u25AA\u25AB\u2023\u2219\*\-]\s*');
  final match = bulletRegex.firstMatch(t);
  if (match != null) {
    t = t.substring(match.end);
  }
  return t;
}

dom.Node? _previousSibling(dom.Node node) {
  final parent = node.parentNode;
  if (parent == null) return null;
  final index = parent.nodes.indexOf(node);
  return index > 0 ? parent.nodes[index - 1] : null;
}

dom.Node? _nextSibling(dom.Node node) {
  final parent = node.parentNode;
  if (parent == null) return null;
  final index = parent.nodes.indexOf(node);
  return (index >= 0 && index < parent.nodes.length - 1)
      ? parent.nodes[index + 1]
      : null;
}

bool _isBlockNode(dom.Node? node) {
  if (node is! dom.Element) return false;
  final tag = node.localName?.toLowerCase();
  return switch (tag) {
    'h1' ||
    'h2' ||
    'h3' ||
    'h4' ||
    'h5' ||
    'h6' ||
    'p' ||
    'div' ||
    'ul' ||
    'ol' ||
    'li' ||
    'blockquote' ||
    'pre' ||
    'table' ||
    'tbody' ||
    'thead' ||
    'tr' ||
    'td' ||
    'th' ||
    'hr' ||
    'section' ||
    'article' ||
    'header' ||
    'footer' => true,
    _ => false,
  };
}

bool _isInside(dom.Node? node, String tag) {
  var current = node;
  while (current != null) {
    if (current is dom.Element &&
        current.localName?.toLowerCase() == tag.toLowerCase()) {
      return true;
    }
    current = current.parent;
  }
  return false;
}

int _countAncestorLists(dom.Element el) {
  var count = 0;
  var current = el.parent;
  while (current != null) {
    final tag = current.localName?.toLowerCase();
    if (tag == 'ul' || tag == 'ol') {
      count++;
    }
    current = current.parent;
  }
  return count;
}

int _listItemDepth(dom.Element li) {
  // 1. Check aria-level (Google Docs sets aria-level="1", "2", ...)
  final aria = li.attributes['aria-level'];
  if (aria != null) {
    final parsed = int.tryParse(aria);
    if (parsed != null && parsed > 0) {
      return parsed - 1;
    }
  }

  // 2. Check lst-kix_...-(\d+) class
  final cls = li.className;
  final match = RegExp(r'lst-kix_[^\s"]+-(\d+)').firstMatch(cls);
  if (match != null) {
    final parsed = int.tryParse(match.group(1)!);
    if (parsed != null) return parsed;
  }

  // 3. Check CSS margin-left / padding-left
  final style = _parseCssStyle(li.attributes['style']);
  final margin = style['margin-left'] ?? style['padding-left'];
  if (margin != null) {
    final ptMatch = RegExp(r'(\d+(?:\.\d+)?)\s*pt').firstMatch(margin);
    if (ptMatch != null) {
      final pt = double.tryParse(ptMatch.group(1)!);
      if (pt != null && pt >= 36) {
        return (pt / 36).floor();
      }
    }
  }

  // 4. Fall back to DOM ancestor list count
  return max(0, _countAncestorLists(li) - 1);
}

bool _hasOrderedClass(dom.Element li) {
  final cls = li.className;
  return cls.contains('ordered') || cls.contains('decimal');
}

void _ensureTrailingNewlines(StringBuffer out, int count) {
  final str = out.toString();
  if (str.isEmpty) return;

  var existing = 0;
  for (var i = str.length - 1; i >= 0; i--) {
    if (str[i] == '\n') {
      existing++;
    } else {
      break;
    }
  }

  final needed = count - existing;
  for (var i = 0; i < needed; i++) {
    out.write('\n');
  }
}

String _normalizeOutput(String markdown) {
  var res = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  // Collapse 3 or more consecutive newlines into 2
  res = res.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return res.trim();
}
