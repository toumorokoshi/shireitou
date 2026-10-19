/// Light and dark themes in the layout of the reference UI (AV-004,
/// AV-090), in the colour scheme the user picks (AV-097): flat greys,
/// no elevation or Material tints, hairline borders, small radii, and a
/// compact density and 13 px body text on desktop. Extra tokens are in
/// [AppColors].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'contrast.dart';
import 'palettes.dart';

export 'app_colors.dart';
export 'palettes.dart' show AppPalette;

/// The corner radius of buttons, fields, cards and menus.
const appRadius = 6.0;

/// Whether [platform] is a desktop OS (also for the web on a desktop).
bool isDesktopPlatform(TargetPlatform platform) => switch (platform) {
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => true,
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => false,
};

/// The color scheme of [palette] in [brightness]: its accent, with the
/// surfaces, text and outlines replaced by its greys.
ColorScheme appColorScheme(
  Brightness brightness, {
  AppPalette palette = AppPalette.graphite,
}) {
  final s = paletteSurfaces(palette, brightness);
  final tokens = AppColors.forPalette(palette, brightness);
  return ColorScheme.fromSeed(
    seedColor: s.accent,
    brightness: brightness,
  ).copyWith(
    primary: s.accent,
    onPrimary: onColor(s.accent),
    surface: s.background,
    onSurface: s.text,
    onSurfaceVariant: tokens.mutedText,
    surfaceContainerLowest: s.background,
    surfaceContainerLow: tokens.sidebarBackground,
    surfaceContainer: tokens.raisedSurface,
    surfaceContainerHigh: tokens.hoverFill,
    surfaceContainerHighest: tokens.bubbleFill,
    secondaryContainer: tokens.selectedFill,
    onSecondaryContainer: s.text,
    outline: s.outline,
    outlineVariant: tokens.hairline,
    error: tokens.statusColors.error,
    surfaceTint: Colors.transparent,
  );
}

/// White or near-black, whichever reads better on [fill].
Color onColor(Color fill) =>
    contrastRatio(Colors.white, fill) >= contrastRatio(_onLight, fill)
    ? Colors.white
    : _onLight;

const _onLight = Color(0xFF141414);

/// [base] with 13 px body text and 14 px titles, for desktop.
TextTheme _compactText(TextTheme base) => base.copyWith(
  bodyLarge: base.bodyLarge?.copyWith(fontSize: 14),
  bodyMedium: base.bodyMedium?.copyWith(fontSize: 13),
  bodySmall: base.bodySmall?.copyWith(fontSize: 12),
  titleMedium: base.titleMedium?.copyWith(fontSize: 14),
  titleSmall: base.titleSmall?.copyWith(fontSize: 13),
  labelLarge: base.labelLarge?.copyWith(fontSize: 13),
  labelMedium: base.labelMedium?.copyWith(fontSize: 12),
);

/// Builds the app theme for [brightness] in [palette] on [platform] (the
/// running platform by default). The font is the platform's system font.
ThemeData buildTheme(
  Brightness brightness, {
  AppPalette palette = AppPalette.graphite,
  TargetPlatform? platform,
}) {
  final target = platform ?? defaultTargetPlatform;
  final desktop = isDesktopPlatform(target);
  final scheme = appColorScheme(brightness, palette: palette);
  final tokens = AppColors.forPalette(palette, brightness);
  final radius = BorderRadius.circular(appRadius);
  final hairline = BorderSide(color: tokens.hairline);
  final base = ThemeData(colorScheme: scheme, platform: target);
  return base.copyWith(
    visualDensity: desktop ? VisualDensity.compact : VisualDensity.standard,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    dividerColor: tokens.hairline,
    hoverColor: tokens.hoverFill,
    textTheme: desktop ? _compactText(base.textTheme) : base.textTheme,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.titleBarBackground,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: hairline),
    ),
    cardTheme: CardThemeData(
      color: tokens.raisedSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius, side: hairline),
    ),
    dividerTheme: DividerThemeData(
      color: tokens.hairline,
      thickness: 1,
      space: 1,
    ),
    // Toolbar and row icons are muted in the reference; text and
    // status colours stand out instead.
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: tokens.mutedText),
    ),
    popupMenuTheme: PopupMenuThemeData(
      iconColor: tokens.mutedText,
      color: tokens.raisedSurface,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius, side: hairline),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(tokens.raisedSurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(2),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: radius, side: hairline),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.raisedSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(appRadius * 2),
        side: hairline,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.raisedSurface,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: tokens.sidebarBackground,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.sidebarBackground,
      surfaceTintColor: Colors.transparent,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.raisedSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.fromBorderSide(hairline),
      ),
      textStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.raisedSurface,
      contentTextStyle: TextStyle(color: scheme.onSurface),
      actionTextColor: scheme.primary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius, side: hairline),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: desktop,
      hintStyle: TextStyle(color: tokens.mutedText),
      border: OutlineInputBorder(borderRadius: radius, borderSide: hairline),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: hairline,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary),
      ),
    ),
    chipTheme: ChipThemeData(
      side: hairline,
      shape: RoundedRectangleBorder(borderRadius: radius),
      backgroundColor: Colors.transparent,
      selectedColor: tokens.selectedFill,
      checkmarkColor: scheme.onSurface,
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: scheme.onSurface,
      iconColor: tokens.mutedText,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: hairline,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 0,
      highlightElevation: 0,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(scheme.outline),
      radius: const Radius.circular(appRadius),
    ),
  );
}
