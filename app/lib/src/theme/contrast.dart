/// WCAG 2.x contrast ratios, used by the tests that check the theme's
/// tokens (AV-141: WCAG AA contrast).
library;

import 'dart:ui';

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
