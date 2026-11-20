import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/theme/font_scale.dart';

import 'fake_connection.dart';

void main() {
  group('clampFontScale & stepFontScale', () {
    test('clamps to [minFontScale, maxFontScale] and rounds to 1 decimal', () {
      expect(clampFontScale(1.0), 1.0);
      expect(clampFontScale(0.2), minFontScale);
      expect(clampFontScale(5.0), maxFontScale);
      expect(clampFontScale(1.2000000000000002), 1.2);
      expect(clampFontScale(double.nan), defaultFontScale);
      expect(clampFontScale(double.infinity), defaultFontScale);
    });

    test('steps cleanly up and down without drift', () {
      var scale = defaultFontScale;
      scale = stepFontScale(scale, 1);
      expect(scale, 1.1);
      scale = stepFontScale(scale, 1);
      expect(scale, 1.2);
      scale = stepFontScale(scale, -1);
      expect(scale, 1.1);
      scale = stepFontScale(scale, -1);
      expect(scale, 1.0);
      scale = stepFontScale(minFontScale, -1);
      expect(scale, minFontScale);
      scale = stepFontScale(maxFontScale, 1);
      expect(scale, maxFontScale);
    });
  });

  group('scaledTextScaler', () {
    test('returns base when factor is 1.0', () {
      const base = TextScaler.linear(1.25);
      expect(scaledTextScaler(base, 1.0), same(base));
    });

    test('scales noScaling linearly and composes custom scalers', () {
      expect(scaledTextScaler(TextScaler.noScaling, 1.2).scale(10), 12);
      const custom = TextScaler.linear(1.5);
      final composed = scaledTextScaler(custom, 1.2);
      expect(composed.scale(10), closeTo(18, 1e-9));
      expect(scaledTextScaler(custom, 1.2), scaledTextScaler(custom, 1.2));
    });
  });

  group('FontScaleNotifier', () {
    test('loads saved scale and ignores invalid values', () async {
      final container = ProviderContainer(
        overrides: [
          prefsStoreProvider.overrideWithValue(
            MemoryPrefsStore({fontScaleKey: '1.3'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(fontScaleProvider), defaultFontScale);
      await pumpEventQueue();
      expect(container.read(fontScaleProvider), 1.3);

      final invalid = ProviderContainer(
        overrides: [
          prefsStoreProvider.overrideWithValue(
            MemoryPrefsStore({fontScaleKey: 'not-a-number'}),
          ),
        ],
      );
      addTearDown(invalid.dispose);
      invalid.listen(fontScaleProvider, (_, _) {});
      await pumpEventQueue();
      expect(invalid.read(fontScaleProvider), defaultFontScale);
    });

    test('increase, decrease, and reset persist to PrefsStore', () async {
      final prefs = MemoryPrefsStore();
      final container = ProviderContainer(
        overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(fontScaleProvider.notifier);

      await notifier.increase();
      expect(container.read(fontScaleProvider), 1.1);
      expect(prefs.values[fontScaleKey], '1.1');

      await notifier.decrease();
      await notifier.decrease();
      expect(container.read(fontScaleProvider), 0.9);
      expect(prefs.values[fontScaleKey], '0.9');

      await notifier.reset();
      expect(container.read(fontScaleProvider), defaultFontScale);
      expect(prefs.values[fontScaleKey], '1.0');
    });
  });

  group('font size shortcuts in ShireitouApp', () {
    Future<void> pressCombo(
      WidgetTester tester,
      List<LogicalKeyboardKey> modifiers,
      LogicalKeyboardKey key,
    ) async {
      for (final mod in modifiers) {
        await tester.sendKeyDownEvent(mod);
      }
      await tester.sendKeyEvent(key);
      for (final mod in modifiers.reversed) {
        await tester.sendKeyUpEvent(mod);
      }
      await tester.pump();
    }

    double currentScaledTen(WidgetTester tester) {
      final context = tester.element(find.byType(HomeScreen));
      return MediaQuery.textScalerOf(context).scale(10);
    }

    testWidgets(
      'Ctrl+= / Ctrl+Shift+= / Ctrl+- / Ctrl+0 scale font size on Linux/Windows',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final prefs = MemoryPrefsStore();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...hostOverrides(),
                prefsStoreProvider.overrideWithValue(prefs),
              ],
              child: const ShireitouApp(),
            ),
          );
          await tester.pump();

          expect(currentScaledTen(tester), closeTo(10, 1e-6));

          // Ctrl+=
          await pressCombo(tester, [
            LogicalKeyboardKey.controlLeft,
          ], LogicalKeyboardKey.equal);
          expect(currentScaledTen(tester), closeTo(11, 1e-6));

          // Ctrl+Shift+= (Ctrl +)
          await pressCombo(tester, [
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.shiftLeft,
          ], LogicalKeyboardKey.equal);
          expect(currentScaledTen(tester), closeTo(12, 1e-6));

          // Ctrl+Numpad+
          await pressCombo(tester, [
            LogicalKeyboardKey.controlLeft,
          ], LogicalKeyboardKey.numpadAdd);
          expect(currentScaledTen(tester), closeTo(13, 1e-6));

          // Ctrl+-
          await pressCombo(tester, [
            LogicalKeyboardKey.controlLeft,
          ], LogicalKeyboardKey.minus);
          expect(currentScaledTen(tester), closeTo(12, 1e-6));

          // Ctrl+0 resets
          await pressCombo(tester, [
            LogicalKeyboardKey.controlLeft,
          ], LogicalKeyboardKey.digit0);
          expect(currentScaledTen(tester), closeTo(10, 1e-6));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Cmd+Shift+= works on macOS even when the native menu bar owns Cmd+=',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final prefs = MemoryPrefsStore();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...hostOverrides(),
                prefsStoreProvider.overrideWithValue(prefs),
              ],
              child: const ShireitouApp(),
            ),
          );
          await tester.pump();

          expect(currentScaledTen(tester), closeTo(10, 1e-6));

          await pressCombo(tester, [
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.shiftLeft,
          ], LogicalKeyboardKey.equal);
          expect(currentScaledTen(tester), closeTo(11, 1e-6));
          expect(prefs.values[fontScaleKey], '1.1');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
