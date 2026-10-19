/// WCAG 2.x contrast ratios, used by the tests that check the theme's
/// tokens (AV-141: WCAG AA contrast).
library;

import 'package:flutter/painting.dart';

/// WCAG AA's minimum contrast for body text.
const textContrast = 4.5;

/// WCAG AA's minimum contrast for large text and for non-text UI such
/// as status dots, icons and focus borders.
const uiContrast = 3.0;

/// The WCAG contrast ratio (1 to 21) of [foreground] drawn on
/// [background]. A translucent [foreground] is first composited onto
/// [background], since that is the colour the eye sees; [background]
/// must be opaque.
double contrastRatio(Color foreground, Color background) {
  final a = Color.alphaBlend(foreground, background).computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

/// [color], or the nearest colour of its hue that has [minimum] contrast
/// on every one of [backgrounds]: lighter on a dark theme ([dark]),
/// darker on a light one. Themes' own colours (comments, above all) are
/// often under WCAG AA, so they are moved only as far as needed.
Color readable(
  Color color,
  Iterable<Color> backgrounds, {
  required double minimum,
  required bool dark,
}) {
  bool passes(Color c) =>
      backgrounds.every((b) => contrastRatio(c, b) >= minimum);
  if (passes(color)) return color;
  final hsl = HSLColor.fromColor(color);
  for (var step = 1; step <= 100; step++) {
    final lightness = (hsl.lightness + (dark ? step : -step) / 100).clamp(
      0.0,
      1.0,
    );
    final candidate = hsl.withLightness(lightness).toColor();
    if (passes(candidate)) return candidate;
    if (lightness == 0 || lightness == 1) break;
  }
  return dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
}
