import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/theme/app_theme.dart';
import 'package:shireitou/src/theme/appearance.dart';
import 'package:shireitou/src/theme/palettes.dart';

void main() {
  group('buildTheme', () {
    test('the dark theme uses the graphite greys and the tokens', () {
      final theme = buildTheme(Brightness.dark, platform: TargetPlatform.macOS);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF1C1C1C));
      expect(theme.extension<AppColors>(), AppColors.dark);
      expect(theme.colorScheme.surfaceTint, Colors.transparent);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.dividerTheme.color, AppColors.dark.hairline);
    });

    test('the light theme mirrors it', () {
      final theme = buildTheme(
        Brightness.light,
        platform: TargetPlatform.macOS,
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>(), AppColors.light);
      expect(theme.colorScheme.surfaceTint, Colors.transparent);
    });

    test('desktop is compact with 13 px body text; mobile is not', () {
      final desktop = buildTheme(
        Brightness.dark,
        platform: TargetPlatform.linux,
      );
      final mobile = buildTheme(Brightness.dark, platform: TargetPlatform.iOS);
      expect(desktop.visualDensity, VisualDensity.compact);
      expect(desktop.textTheme.bodyMedium?.fontSize, 13);
      expect(mobile.visualDensity, VisualDensity.standard);
      expect(mobile.textTheme.bodyMedium?.fontSize, isNot(13));
    });
  });

  group('palettes', () {
    test('graphite is neutral grey; the others are tinted', () {
      for (final brightness in Brightness.values) {
        final graphite = paletteSurfaces(AppPalette.graphite, brightness);
        final bg = graphite.background;
        expect(bg.r, bg.g);
        expect(bg.g, bg.b);
        for (final palette in AppPalette.values.skip(1)) {
          final tinted = paletteSurfaces(palette, brightness).background;
          expect(tinted, isNot(bg), reason: palette.name);
        }
      }
    });

    test('a palette sets the accent, the running dot and the tokens', () {
      final theme = buildTheme(
        Brightness.dark,
        palette: AppPalette.moss,
        platform: TargetPlatform.macOS,
      );
      final tokens = theme.extension<AppColors>()!;
      expect(theme.colorScheme.primary, AppPalette.moss.dark);
      expect(tokens.statusColors.running, AppPalette.moss.dark);
      expect(tokens, AppColors.forPalette(AppPalette.moss, Brightness.dark));
      expect(tokens.terminal.background, tokens.sidebarBackground);
    });

    test('byName falls back to graphite', () {
      expect(AppPalette.byName('dusk'), AppPalette.dusk);
      expect(AppPalette.byName('nope'), AppPalette.graphite);
      expect(AppPalette.byName(null), AppPalette.graphite);
    });

    test('onColor picks the more readable text colour', () {
      expect(onColor(const Color(0xFF1E3A8A)), Colors.white);
      expect(onColor(const Color(0xFFF0E68C)), isNot(Colors.white));
    });
  });

  group('appearance', () {
    test('starts at the default and loads the saved choice', () async {
      final container = ProviderContainer(
        overrides: [
          prefsStoreProvider.overrideWithValue(
            MemoryPrefsStore({themeModeKey: 'dark', paletteKey: 'ember'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(appearanceProvider), defaultAppearance);
      await pumpEventQueue();
      expect(container.read(appearanceProvider), (
        mode: ThemeMode.dark,
        palette: AppPalette.ember,
      ));
    });

    test('saves the mode and the palette', () async {
      final prefs = MemoryPrefsStore();
      final container = ProviderContainer(
        overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(appearanceProvider.notifier);
      await notifier.setMode(ThemeMode.light);
      await notifier.setPalette(AppPalette.slate);
      expect(container.read(appearanceProvider), (
        mode: ThemeMode.light,
        palette: AppPalette.slate,
      ));
      expect(prefs.values, {themeModeKey: 'light', paletteKey: 'slate'});
    });

    test('unknown saved values fall back to the defaults', () {
      expect(themeModeByName('sepia'), ThemeMode.system);
      expect(themeModeByName(null), ThemeMode.system);
    });

    testWidgets('the Appearance menu switches the palette', (tester) async {
      final prefs = MemoryPrefsStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [prefsStoreProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: MenuAnchor(
                menuChildren: const [AppearanceMenu()],
                builder: (context, controller, _) => TextButton(
                  onPressed: controller.open,
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.text('System'), findsOneWidget);
      await tester.tap(find.text('Dusk'));
      await tester.pumpAndSettle();
      expect(prefs.values[paletteKey], 'dusk');
    });
  });

  test('isDesktopPlatform', () {
    expect(isDesktopPlatform(TargetPlatform.macOS), isTrue);
    expect(isDesktopPlatform(TargetPlatform.windows), isTrue);
    expect(isDesktopPlatform(TargetPlatform.android), isFalse);
  });

  testWidgets('AppColors.of falls back to the color scheme', (tester) async {
    late AppColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Builder(
          builder: (context) {
            colors = AppColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final scheme = ThemeData().colorScheme;
    expect(colors.hairline, scheme.outlineVariant);
    expect(colors.mutedText, scheme.onSurfaceVariant);
  });

  test('AppColors.lerp blends the tokens', () {
    final mid = AppColors.dark.lerp(AppColors.light, 0.5);
    expect(
      mid.hairline,
      Color.lerp(AppColors.dark.hairline, AppColors.light.hairline, 0.5),
    );
    expect(AppColors.dark.lerp(null, 0.5), AppColors.dark);
  });
}
