/// App-wide font size scaling (AV-140), persisted in [PrefsStore].
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';

/// The default font scale factor (100%).
const defaultFontScale = 1.0;

/// The minimum supported font scale factor (70%).
const minFontScale = 0.7;

/// The maximum supported font scale factor (200%).
const maxFontScale = 2.0;

/// The step added or subtracted per zoom command (10%).
const fontScaleStep = 0.1;

/// The [PrefsStore] key for the saved font scale factor.
const fontScaleKey = 'font_scale';

/// Clamps [scale] to `[minFontScale, maxFontScale]` and rounds to one decimal
/// place so repeated steps do not accumulate floating-point drift.
double clampFontScale(double scale) {
  if (!scale.isFinite) return defaultFontScale;
  final clamped = scale.clamp(minFontScale, maxFontScale);
  return (clamped * 10).round() / 10;
}

/// Returns [current] shifted by [steps] * [fontScaleStep], clamped.
double stepFontScale(double current, int steps) =>
    clampFontScale(current + steps * fontScaleStep);

/// Composes [base] with a multiplicative [factor].
TextScaler scaledTextScaler(TextScaler base, double factor) {
  final normalized = clampFontScale(factor);
  if ((normalized - 1.0).abs() < 1e-9) return base;
  if (base == TextScaler.noScaling) return TextScaler.linear(normalized);
  return _ScaledTextScaler(base, normalized);
}

final class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ScaledTextScaler &&
          base == other.base &&
          factor == other.factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// The user's font scale factor, kept with [prefsStoreProvider];
/// [defaultFontScale] until it loads.
class FontScaleNotifier extends Notifier<double> {
  Future<void>? _loading;

  @override
  double build() {
    _loading = _load();
    return defaultFontScale;
  }

  Future<void> _load() async {
    final raw = await ref.read(prefsStoreProvider).read(fontScaleKey);
    final parsed = raw == null ? null : double.tryParse(raw);
    if (!ref.mounted || parsed == null) return;
    state = clampFontScale(parsed);
  }

  /// Increases the font scale by one step and saves it.
  Future<void> increase() => setScale(stepFontScale(state, 1));

  /// Decreases the font scale by one step and saves it.
  Future<void> decrease() => setScale(stepFontScale(state, -1));

  /// Resets the font scale to [defaultFontScale] and saves it.
  Future<void> reset() => setScale(defaultFontScale);

  /// Sets the font scale to [scale] (clamped) and saves it.
  Future<void> setScale(double scale) async {
    await _loading;
    final next = clampFontScale(scale);
    if (next == state) return;
    state = next;
    await ref.read(prefsStoreProvider).write(fontScaleKey, '$next');
  }
}

/// The app-wide font scale factor.
final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);
