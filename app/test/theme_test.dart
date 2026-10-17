import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/theme/app_theme.dart';

void main() {
  group('buildTheme', () {
    test('the dark theme uses the reference greys and the tokens', () {
      final theme = buildTheme(Brightness.dark, platform: TargetPlatform.macOS);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF191A1B));
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
