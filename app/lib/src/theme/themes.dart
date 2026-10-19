/// The colour themes of the Appearance menu (AV-097) and how a theme's
/// Base24 colours become the app's colours. The themes are generated
/// from `themes/manifest.yaml` (see docs/themes.md).
library;

import 'package:flutter/material.dart';

import 'contrast.dart';
import 'generated/themes.g.dart';
import 'highlight_themes.dart';
import 'theme_spec.dart';

export 'theme_spec.dart';

/// Every theme.
const List<ThemeSpec> allThemes = generatedThemes;

/// The id of the default theme for each brightness.
const defaultThemeIds = {
  Brightness.dark: 'graphite-dark',
  Brightness.light: 'graphite-light',
};

/// The themes of [brightness] for the menu: the default first, then by
/// name.
List<ThemeSpec> themesFor(Brightness brightness) {
  final themes = allThemes.where((t) => t.brightness == brightness).toList();
  final first = defaultThemeIds[brightness];
  return themes..sort(
    (a, b) => a.id == first
        ? -1
        : b.id == first
        ? 1
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
}

/// The theme with [id] if it is a [brightness] theme, else that
/// brightness's default.
ThemeSpec themeById(String? id, Brightness brightness) =>
    allThemes
        .where((t) => t.id == id && t.brightness == brightness)
        .firstOrNull ??
    allThemes.firstWhere((t) => t.id == defaultThemeIds[brightness]);

/// The default theme for [brightness].
ThemeSpec defaultTheme(Brightness brightness) => themeById(null, brightness);

/// The colours the app draws with, derived from a theme.
typedef ThemeColors = ({
  Color background,
  Color sidebar,
  Color raised,
  Color hover,
  Color bubble,
  Color selected,
  Color hairline,
  Color outline,
  Color text,
  Color mutedText,
  Color accent,
  Color attention,
  Color done,
  Color error,
  Color idle,
  Color diffAddedFill,
  Color diffRemovedFill,
  Color diffGutter,
  SyntaxColors syntax,
});

/// The surfaces text, dots and icons are drawn on, in [c].
List<Color> drawingSurfaces(ThemeColors c) => [
  c.background,
  c.sidebar,
  c.raised,
  c.selected,
  c.hover,
  c.bubble,
];

/// The surfaces body text, links and error text are drawn on.
List<Color> textSurfaces(ThemeColors c) => [c.background, c.sidebar, c.raised];

/// The diff area (the sidebar's colour) and its added and removed lines.
List<Color> diffSurfaces(Color area, Color added, Color removed) => [
  area,
  Color.alphaBlend(added, area),
  Color.alphaBlend(removed, area),
];

/// The colours of [theme]: the surfaces mixed from its backgrounds and
/// selection, and its text, accent, status, diff and syntax colours,
/// each moved only as far as WCAG AA needs (4.5:1 for text, 3:1 for
/// dots, the gutter and syntax colours on diff lines) with [readable].
ThemeColors themeColors(ThemeSpec theme) =>
    _colors.putIfAbsent(theme.id, () => _derive(theme));

final _colors = <String, ThemeColors>{};

ThemeColors _derive(ThemeSpec theme) {
  final dark = theme.brightness == Brightness.dark;
  final bg = theme.base(0x00);
  final alt = theme.base(0x01);
  Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
  // A mid-tone selection (Zenburn's) leaves no text colour 4.5:1 on it,
  // so it is moved towards the background until the theme's text reads.
  final selection =
      [for (var t = 0.0; t < 1; t += 0.1) mix(theme.base(0x02), bg, t)]
          .firstWhere(
            (fill) => contrastRatio(theme.base(0x05), fill) >= textContrast,
            orElse: () => bg,
          );

  final sidebar = alt.computeLuminance() < bg.computeLuminance()
      ? alt
      : mix(bg, Colors.black, dark ? 0.25 : 0.05);
  final raised = dark ? mix(bg, selection, 0.25) : mix(bg, Colors.white, 0.5);
  final hover = mix(bg, selection, 0.45);
  final bubble = mix(bg, selection, 0.55);
  final surfaces = [bg, sidebar, raised, selection, hover, bubble];
  final text = [bg, sidebar, raised];
  final added = theme.base(0x0B).withAlpha(0x33);
  final removed = theme.base(0x08).withAlpha(0x33);
  final diff = diffSurfaces(sidebar, added, removed);
  final code = [bubble, sidebar];

  Color fix(Color c, Iterable<Color> on, double minimum) =>
      readable(c, on, minimum: minimum, dark: dark);
  Color dot(Color c) => fix(c, surfaces, uiContrast);
  Color syntax(int index) =>
      fix(fix(theme.base(index), code, textContrast), diff, uiContrast);

  final accent = dot(fix(theme.base(0x0D), text, textContrast));
  return (
    background: bg,
    sidebar: sidebar,
    raised: raised,
    hover: hover,
    bubble: bubble,
    selected: selection,
    hairline: fix(mix(bg, selection, 0.7), text, 1.1),
    outline: theme.base(0x03),
    text: fix(theme.base(0x05), [...surfaces, ...diff], textContrast),
    mutedText: fix(theme.base(0x04), surfaces, textContrast),
    accent: accent,
    attention: dot(theme.base(0x0A)),
    done: dot(theme.base(0x0B)),
    error: dot(fix(theme.base(0x08), text, textContrast)),
    idle: dot(theme.base(0x03)),
    diffAddedFill: added,
    diffRemovedFill: removed,
    diffGutter: fix(theme.base(0x03), diff, uiContrast),
    syntax: (
      keyword: syntax(0x0E),
      control: syntax(0x0E),
      string: syntax(0x0B),
      number: syntax(0x09),
      comment: syntax(0x03),
      function: syntax(0x0D),
      type: syntax(0x0A),
      variable: syntax(0x08),
      regexp: syntax(0x0C),
      tag: syntax(0x08),
      attribute: syntax(0x09),
      meta: syntax(0x0F),
      added: syntax(0x0B),
      removed: syntax(0x08),
    ),
  );
}
