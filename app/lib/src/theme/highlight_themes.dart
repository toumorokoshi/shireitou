/// Syntax highlight themes for `re_highlight` (AV-061, AV-101) based on
/// VS Code's Dark+ and Light+ colours. A few colours are darkened or
/// lightened so code keeps 4.5:1 contrast on the code block and diff
/// backgrounds of every palette (`test/contrast_test.dart` checks this).
library;

import 'package:flutter/painting.dart';

/// The colours of one theme, by the role a highlight.js scope plays.
typedef _SyntaxColors = ({
  Color keyword,
  Color control,
  Color string,
  Color number,
  Color comment,
  Color function,
  Color type,
  Color variable,
  Color regexp,
  Color tag,
  Color attribute,
  Color meta,
  Color added,
  Color removed,
});

/// Dark+; the comment and regexp colours are lightened (Dark+ uses
/// #6A9955 and #D16969, under 4.5:1 on the code block fill).
const _dark = (
  keyword: Color(0xFF569CD6),
  control: Color(0xFFC586C0),
  string: Color(0xFFCE9178),
  number: Color(0xFFB5CEA8),
  comment: Color(0xFF73A65D),
  function: Color(0xFFDCDCAA),
  type: Color(0xFF4EC9B0),
  variable: Color(0xFF9CDCFE),
  regexp: Color(0xFFDC7C7C),
  tag: Color(0xFF569CD6),
  attribute: Color(0xFF9CDCFE),
  meta: Color(0xFF9B9B9B),
  added: Color(0xFFB5CEA8),
  removed: Color(0xFFCE9178),
);

/// Light+; the comment, number, type and attribute colours are darkened
/// (Light+ uses #008000, #098658, #267F99 and #E50000, under 4.5:1 on
/// the code block fill).
const _light = (
  keyword: Color(0xFF0000FF),
  control: Color(0xFFAF00DB),
  string: Color(0xFFA31515),
  number: Color(0xFF067350),
  comment: Color(0xFF007800),
  function: Color(0xFF795E26),
  type: Color(0xFF1F7189),
  variable: Color(0xFF001080),
  regexp: Color(0xFF811F3F),
  tag: Color(0xFF800000),
  attribute: Color(0xFFD00000),
  meta: Color(0xFF616161),
  added: Color(0xFF067350),
  removed: Color(0xFFA31515),
);

/// A `re_highlight` theme (highlight.js scope to style) from [c]. It has
/// no `root` entry: code takes its base colour from the app's text.
Map<String, TextStyle> _theme(_SyntaxColors c) {
  TextStyle color(Color color) => TextStyle(color: color);
  return {
    for (final scope in ['keyword', 'literal', 'symbol', 'built_in'])
      scope: color(c.keyword),
    'meta-keyword': color(c.control),
    'variable.language_': color(c.keyword),
    for (final scope in ['string', 'meta-string', 'char.escape_'])
      scope: color(c.string),
    'number': color(c.number),
    for (final scope in ['comment', 'quote', 'doctag']) scope: color(c.comment),
    for (final scope in ['title', 'title.function_', 'function'])
      scope: color(c.function),
    for (final scope in [
      'type',
      'class',
      'title.class_',
      'title.class_.inherited__',
    ])
      scope: color(c.type),
    for (final scope in ['variable', 'params', 'template-variable', 'property'])
      scope: color(c.variable),
    for (final scope in ['regexp', 'template-tag']) scope: color(c.regexp),
    for (final scope in ['tag', 'name', 'selector-tag', 'section'])
      scope: color(c.tag),
    for (final scope in [
      'attr',
      'attribute',
      'selector-attr',
      'selector-class',
      'selector-id',
      'selector-pseudo',
    ])
      scope: color(c.attribute),
    for (final scope in ['meta', 'bullet', 'link']) scope: color(c.meta),
    'addition': color(c.added),
    'deletion': color(c.removed),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
  };
}

/// VS Code's Dark+ highlight theme.
final Map<String, TextStyle> darkHighlightTheme = _theme(_dark);

/// VS Code's Light+ highlight theme.
final Map<String, TextStyle> lightHighlightTheme = _theme(_light);
