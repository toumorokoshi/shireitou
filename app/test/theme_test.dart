import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/theme/app_theme.dart';
import 'package:shireitou/src/theme/contrast.dart';
import 'package:shireitou/src/theme/appearance.dart';
import 'package:shireitou/src/theme/themes.dart';

void main() {
  group('buildTheme', () {
    test('the dark theme uses the graphite greys and the tokens', () {
      final theme = buildTheme(
        defaultTheme(Brightness.dark),
        platform: TargetPlatform.macOS,
      );
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
        defaultTheme(Brightness.light),
        platform: TargetPlatform.macOS,
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>(), AppColors.light);
      expect(theme.colorScheme.surfaceTint, Colors.transparent);
    });

    test('desktop is compact with 13 px body text; mobile is not', () {
      final dark = defaultTheme(Brightness.dark);
      final desktop = buildTheme(dark, platform: TargetPlatform.linux);
      final mobile = buildTheme(dark, platform: TargetPlatform.iOS);
      expect(desktop.visualDensity, VisualDensity.compact);
      expect(desktop.textTheme.bodyMedium?.fontSize, 13);
      expect(mobile.visualDensity, VisualDensity.standard);
      expect(mobile.textTheme.bodyMedium?.fontSize, isNot(13));
    });
  });

  group('themes', () {
    ThemeSpec theme(String id) => allThemes.firstWhere((t) => t.id == id);

    test('Graphite is the neutral grey default', () {
      for (final brightness in Brightness.values) {
        final graphite = defaultTheme(brightness);
        expect(graphite.name, 'Graphite');
        final bg = graphite.base(0x00);
        expect(bg.r, bg.g);
        expect(bg.g, bg.b);
      }
    });

    test('the popular editor themes are there, light and dark', () {
      for (final id in [
        'dracula',
        'one-dark',
        'github-dark',
        'catppuccin-mocha',
        'tokyo-night',
        'gruvbox-dark',
        'nord',
        'kanagawa',
        'rose-pine',
        'nightfox',
        'doom-one',
        'zenburn',
        'solarized-dark',
        'modus-vivendi',
      ]) {
        expect(theme(id).brightness, Brightness.dark, reason: id);
      }
      for (final id in [
        'one-light',
        'github-light',
        'catppuccin-latte',
        'solarized-light',
        'gruvbox-light',
        'modus-operandi',
      ]) {
        expect(theme(id).brightness, Brightness.light, reason: id);
      }
    });

    test("a theme's background, accent and syntax come from its palette", () {
      final dracula = theme('dracula');
      final built = buildTheme(dracula, platform: TargetPlatform.macOS);
      final tokens = built.extension<AppColors>()!;
      expect(built.brightness, Brightness.dark);
      expect(built.scaffoldBackgroundColor, const Color(0xFF282A36));
      expect(built.colorScheme.primary, const Color(0xFFBD93F9));
      expect(tokens.statusColors.running, built.colorScheme.primary);
      expect(tokens.syntax['string']?.color, const Color(0xFF50FA7B));
      expect(tokens.terminal.red, const Color(0xFFFF5555));
      expect(tokens.terminal.brightRed, const Color(0xFFFF6E6E));
      expect(tokens.terminal.background, tokens.sidebarBackground);
      expect(AppColors.forTheme(dracula), same(tokens));
    });

    test('Base16 schemes fall back to the normal colours for bright ANSI', () {
      final nord = theme('nord');
      expect(nord.base(0x12), nord.base(0x08));
      expect(nord.base(0x16), nord.base(0x0D));
    });

    test('a dim comment colour is raised to 4.5:1', () {
      final dracula = theme('dracula');
      final comment = themeColors(dracula).syntax.comment;
      expect(comment, isNot(dracula.base(0x03)));
      expect(
        contrastRatio(comment, themeColors(dracula).bubble),
        greaterThanOrEqualTo(textContrast),
      );
    });

    test('themeById falls back to the default of the brightness', () {
      expect(themeById('dracula', Brightness.dark).id, 'dracula');
      expect(
        themeById('dracula', Brightness.light),
        defaultTheme(Brightness.light),
      );
      expect(themeById(null, Brightness.dark), defaultTheme(Brightness.dark));
    });

    test('themesFor lists the default first, then by name', () {
      final names = themesFor(Brightness.dark).skip(1).map((t) => t.name);
      expect(
        names.toList(),
        [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      );
      expect(
        themesFor(Brightness.light)
            .every((t) => t.brightness == Brightness.light),
        isTrue,
      );
    });

    test('onColor picks the more readable text colour', () {
      expect(onColor(const Color(0xFF1E3A8A)), Colors.white);
      expect(onColor(const Color(0xFFF0E68C)), Colors.black);
    });
  });

  group('appearance', () {
    ThemeSpec theme(String id) => allThemes.firstWhere((t) => t.id == id);

    test('starts at the default and loads the saved choice', () async {
      final container = ProviderContainer(
        overrides: [
          prefsStoreProvider.overrideWithValue(
            MemoryPrefsStore({
              themeModeKey: 'dark',
              darkThemeKey: 'nord',
              lightThemeKey: 'solarized-light',
            }),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(appearanceProvider), defaultAppearance);
      await pumpEventQueue();
      final appearance = container.read(appearanceProvider);
      expect(appearance.mode, ThemeMode.dark);
      expect(appearance.dark.id, 'nord');
      expect(appearance.light.id, 'solarized-light');
    });

    test(
      'unknown or mismatched saved themes fall back to the defaults',
      () async {
        final container = ProviderContainer(
          overrides: [
            prefsStoreProvider.overrideWithValue(
              MemoryPrefsStore({
                darkThemeKey: 'solarized-light',
                lightThemeKey: 'gone',
              }),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(appearanceProvider, (_, _) {});
        await pumpEventQueue();
        expect(container.read(appearanceProvider), defaultAppearance);
        expect(themeModeByName('sepia'), ThemeMode.system);
      },
    );

    test('picking a theme of the other brightness switches the mode', () {
      final picked = withTheme(
        defaultAppearance,
        theme('catppuccin-latte'),
        Brightness.dark,
      );
      expect(picked.mode, ThemeMode.light);
      expect(picked.light.id, 'catppuccin-latte');
      expect(picked.dark, defaultAppearance.dark);
      final same = withTheme(
        defaultAppearance,
        theme('dracula'),
        Brightness.dark,
      );
      expect(same.mode, ThemeMode.system);
      expect(same.dark.id, 'dracula');
    });

    test('saves the mode and the themes', () async {
      final prefs = MemoryPrefsStore();
      final container = ProviderContainer(
        overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(appearanceProvider.notifier);
      await notifier.setMode(ThemeMode.dark);
      await notifier.setTheme(theme('kanagawa'), Brightness.dark);
      expect(container.read(appearanceProvider).dark.id, 'kanagawa');
      expect(prefs.values, {
        themeModeKey: 'dark',
        darkThemeKey: 'kanagawa',
        lightThemeKey: 'graphite-light',
      });
    });

    testWidgets('the Appearance menu picks a dark theme', (tester) async {
      final prefs = MemoryPrefsStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [prefsStoreProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: buildTheme(defaultTheme(Brightness.dark)),
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
      await tester.tap(find.text('Dark theme · Graphite'));
      await tester.pumpAndSettle();
      expect(find.byType(ThemeSwatch), findsWidgets);
      await tester.tap(find.text('Dracula'));
      await tester.pumpAndSettle();
      expect(prefs.values[darkThemeKey], 'dracula');
      expect(prefs.values[themeModeKey], 'system');
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
