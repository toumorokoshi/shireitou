/// Syntax highlight themes for `re_highlight` (AV-061, AV-101): each
/// colour theme (AV-097) supplies [SyntaxColors], mapped from its Base16
/// colours in `themes.dart`.
library;

import 'package:flutter/painting.dart';

/// The colours of one theme, by the role a highlight.js scope plays.
typedef SyntaxColors = ({
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

/// A `re_highlight` theme (highlight.js scope to style) from [c]. It has
/// no `root` entry: code takes its base colour from the app's text.
Map<String, TextStyle> syntaxTheme(SyntaxColors c) {
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
