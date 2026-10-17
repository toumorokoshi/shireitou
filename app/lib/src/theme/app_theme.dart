/// Light and dark themes that match the reference UI (AV-004, AV-090):
/// flat greys, no elevation or Material tints, hairline borders, small
/// radii, and a compact density and 13 px body text on desktop. Extra
/// tokens are in [AppColors].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

/// The corner radius of buttons, fields, cards and menus.
const appRadius = 6.0;

/// The main pane background, the text colour and the accent, by
/// brightness.
const _dark = (
  background: Color(0xFF191A1B),
  text: Color(0xFFCCCCCC),
  accent: Color(0xFF3794FF),
);
const _light = (
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  accent: Color(0xFF0066CC),
);

/// Whether [platform] is a desktop OS (also for the web on a desktop).
bool isDesktopPlatform(TargetPlatform platform) => switch (platform) {
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => true,
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => false,
};

/// The color scheme for [brightness]: the accent from the reference
/// with the surfaces, text and outlines replaced by its greys.
ColorScheme appColorScheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = dark ? _dark : _light;
  final tokens = AppColors.forBrightness(brightness);
  return ColorScheme.fromSeed(
    seedColor: base.accent,
    brightness: brightness,
  ).copyWith(
    primary: base.accent,
    onPrimary: Colors.white,
    surface: base.background,
    onSurface: base.text,
    onSurfaceVariant: tokens.mutedText,
    surfaceContainerLowest: base.background,
    surfaceContainerLow: tokens.sidebarBackground,
    surfaceContainer: tokens.raisedSurface,
    surfaceContainerHigh: tokens.hoverFill,
    surfaceContainerHighest: tokens.bubbleFill,
    secondaryContainer: tokens.selectedFill,
    onSecondaryContainer: base.text,
    outline: dark ? const Color(0xFF3C3C3C) : const Color(0xFFCDCDD1),
    outlineVariant: tokens.hairline,
    error: tokens.statusColors.error,
    surfaceTint: Colors.transparent,
  );
}

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

/// Builds the app theme for [brightness] on [platform] (the running
/// platform by default). The font is the platform's system font.
ThemeData buildTheme(Brightness brightness, {TargetPlatform? platform}) {
  final target = platform ?? defaultTargetPlatform;
  final desktop = isDesktopPlatform(target);
  final scheme = appColorScheme(brightness);
  final tokens = AppColors.forBrightness(brightness);
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
    popupMenuTheme: PopupMenuThemeData(
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
