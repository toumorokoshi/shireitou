/// One colour theme of the Appearance menu (AV-097), as a Base24 palette.
library;

import 'package:flutter/material.dart';

/// A colour theme: its id (kept in prefs), its name in the menu, whether
/// it is light or dark, and its 24 Base24 colours, `base00` to `base17`.
/// Base16 schemes are padded to 24 by `tool/gen_themes.dart`.
///
/// `base00` is the background, `base01` the darker or lighter background,
/// `base02` the selection, `base03` comments, `base04` muted text, `base05`
/// text, `base06` and `base07` brighter text, `base08` to `base0F` red,
/// orange, yellow, green, cyan, blue, purple and brown, and `base10` to
/// `base17` the darker backgrounds and bright ANSI colours (see
/// <https://github.com/tinted-theming/base24/blob/main/styling.md>).
@immutable
class ThemeSpec {
  /// Creates a theme.
  const ThemeSpec({
    required this.id,
    required this.name,
    required this.brightness,
    required this.colors,
  });

  /// The id kept in prefs.
  final String id;

  /// The name shown in the menu.
  final String name;

  /// Whether it is a light or a dark theme.
  final Brightness brightness;

  /// The 24 colours as ARGB values.
  final List<int> colors;

  /// The colour `base<index in hex>`, such as `base(0x0D)` for the blue.
  Color base(int index) => Color(colors[index]);

  @override
  String toString() => 'ThemeSpec($id)';
}
