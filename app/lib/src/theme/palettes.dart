/// The colour schemes the user picks from (AV-097): each is a grey ramp,
/// optionally tinted towards a hue, and an accent, in a light and a dark
/// variant. [paletteColors] turns one into the theme's tokens.
library;

import 'package:flutter/material.dart';
import 'package:xterm/ui.dart' show TerminalTheme;

/// A colour scheme. [graphite], neutral greys, is the default.
enum AppPalette {
  /// Neutral greys with a steel-blue accent.
  graphite(
    'Graphite',
    hue: 0,
    tint: 0,
    dark: Color(0xFF7AA7E0),
    light: Color(0xFF2F64A8),
  ),

  /// Cool blue-grey surfaces with a blue accent.
  slate(
    'Slate',
    hue: 215,
    tint: 0.14,
    dark: Color(0xFF5AAEFF),
    light: Color(0xFF0A5DB8),
  ),

  /// Green-grey surfaces with a green accent.
  moss(
    'Moss',
    hue: 140,
    tint: 0.08,
    dark: Color(0xFF5CC28A),
    light: Color(0xFF1E7A47),
  ),

  /// Violet-grey surfaces with a violet accent.
  dusk(
    'Dusk',
    hue: 265,
    tint: 0.12,
    dark: Color(0xFFB59CFF),
    light: Color(0xFF6A44C8),
  ),

  /// Warm brown-grey surfaces with an orange accent.
  ember(
    'Ember',
    hue: 28,
    tint: 0.10,
    dark: Color(0xFFF0A060),
    light: Color(0xFFA14E14),
  );

  const AppPalette(
    this.label, {
    required this.hue,
    required this.tint,
    required this.dark,
    required this.light,
  });

  /// The name shown in the menu.
  final String label;

  /// The hue (0 to 360) the greys lean towards.
  final double hue;

  /// The saturation (0 to 1) of the greys; 0 is neutral.
  final double tint;

  /// The accent in the dark variant.
  final Color dark;

  /// The accent in the light variant.
  final Color light;

  /// The accent for [brightness].
  Color accent(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The palette named [name], or [graphite] when there is none.
  static AppPalette byName(String? name) =>
      values.where((p) => p.name == name).firstOrNull ?? graphite;
}

/// The surfaces and text of a palette variant: the main pane, the
/// sidebar, raised boxes, fills, borders and text.
typedef PaletteSurfaces = ({
  Color background,
  Color sidebar,
  Color raised,
  Color hover,
  Color bubble,
  Color selected,
  Color hairline,
  Color outline,
  Color mutedText,
  Color text,
  Color accent,
});

/// The grey levels (0 to 255) of each surface, by brightness. Slightly
/// lighter and more neutral than VS Code's near-black greys.
const _darkLevels = (
  background: 0x1C,
  sidebar: 0x16,
  raised: 0x23,
  hover: 0x27,
  bubble: 0x2A,
  selected: 0x30,
  hairline: 0x2E,
  outline: 0x42,
  mutedText: 0x9E,
  text: 0xD0,
);
const _lightLevels = (
  background: 0xF6,
  sidebar: 0xF0,
  raised: 0xFB,
  hover: 0xE8,
  bubble: 0xEC,
  selected: 0xE2,
  hairline: 0xDC,
  outline: 0xC4,
  mutedText: 0x5C,
  text: 0x1E,
);

/// The grey at [level] (0 to 255) tinted towards [palette]'s hue.
Color _grey(AppPalette palette, int level) =>
    HSLColor.fromAHSL(1, palette.hue, palette.tint, level / 255).toColor();

/// The surfaces of [palette] in [brightness].
PaletteSurfaces paletteSurfaces(AppPalette palette, Brightness brightness) {
  final l = brightness == Brightness.dark ? _darkLevels : _lightLevels;
  Color grey(int level) => _grey(palette, level);
  return (
    background: grey(l.background),
    sidebar: grey(l.sidebar),
    raised: grey(l.raised),
    hover: grey(l.hover),
    bubble: grey(l.bubble),
    selected: grey(l.selected),
    hairline: grey(l.hairline),
    outline: grey(l.outline),
    mutedText: grey(l.mutedText),
    text: grey(l.text),
    accent: palette.accent(brightness),
  );
}

/// [base] with [background] and [foreground] replaced; the ANSI colours
/// are kept.
TerminalTheme terminalOn(
  TerminalTheme base, {
  required Color background,
  required Color foreground,
}) => TerminalTheme(
  cursor: base.cursor,
  selection: base.selection,
  foreground: foreground,
  background: background,
  black: base.black,
  red: base.red,
  green: base.green,
  yellow: base.yellow,
  blue: base.blue,
  magenta: base.magenta,
  cyan: base.cyan,
  white: base.white,
  brightBlack: base.brightBlack,
  brightRed: base.brightRed,
  brightGreen: base.brightGreen,
  brightYellow: base.brightYellow,
  brightBlue: base.brightBlue,
  brightMagenta: base.brightMagenta,
  brightCyan: base.brightCyan,
  brightWhite: base.brightWhite,
  searchHitBackground: base.searchHitBackground,
  searchHitBackgroundCurrent: base.searchHitBackgroundCurrent,
  searchHitForeground: base.searchHitForeground,
);
