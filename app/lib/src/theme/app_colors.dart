/// The colour tokens of the reference UI (AV-090) that `ColorScheme` has
/// no slot for, as a `ThemeExtension` so widgets read them from
/// `Theme.of(context)`.
library;

import 'package:flutter/material.dart';

/// Colours for session states (status dots, connection icons).
@immutable
class StatusColors {
  /// Creates the status colours.
  const StatusColors({
    required this.running,
    required this.attention,
    required this.done,
    required this.error,
    required this.idle,
  });

  /// A turn in progress.
  final Color running;

  /// Waiting on the user (input needed, an approval).
  final Color attention;

  /// Finished, or a connected host.
  final Color done;

  /// Failed, or a lost connection.
  final Color error;

  /// Nothing happening.
  final Color idle;

  /// Interpolates every colour between [a] and [b] by [t].
  static StatusColors lerp(StatusColors a, StatusColors b, double t) =>
      StatusColors(
        running: Color.lerp(a.running, b.running, t)!,
        attention: Color.lerp(a.attention, b.attention, t)!,
        done: Color.lerp(a.done, b.done, t)!,
        error: Color.lerp(a.error, b.error, t)!,
        idle: Color.lerp(a.idle, b.idle, t)!,
      );
}

/// The app's extra colour tokens. Read them with [AppColors.of], which
/// falls back to values derived from the `ColorScheme` when a theme
/// without the extension is in use (some widget tests).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Creates the tokens.
  const AppColors({
    required this.sidebarBackground,
    required this.titleBarBackground,
    required this.raisedSurface,
    required this.hairline,
    required this.mutedText,
    required this.bubbleFill,
    required this.selectedFill,
    required this.hoverFill,
    required this.statusColors,
  });

  /// The sidebar (session list) background.
  final Color sidebarBackground;

  /// The title bar background.
  final Color titleBarBackground;

  /// Boxes that sit on the background: the composer, menus, hover cards.
  final Color raisedSurface;

  /// One-pixel borders and dividers.
  final Color hairline;

  /// Secondary text: metadata lines, timestamps, placeholders.
  final Color mutedText;

  /// The fill behind the user's messages.
  final Color bubbleFill;

  /// The fill of the selected sidebar row.
  final Color selectedFill;

  /// The fill of a hovered row or button.
  final Color hoverFill;

  /// Colours for session states.
  final StatusColors statusColors;

  /// The dark tokens, sampled from `design/reference/agents-window.png`.
  static const dark = AppColors(
    sidebarBackground: Color(0xFF121314),
    titleBarBackground: Color(0xFF121314),
    raisedSurface: Color(0xFF202122),
    hairline: Color(0xFF2A2B2C),
    mutedText: Color(0xFF8C8C8C),
    bubbleFill: Color(0xFF292A2B),
    selectedFill: Color(0xFF2C2D2E),
    hoverFill: Color(0xFF252626),
    statusColors: StatusColors(
      running: Color(0xFF3794FF),
      attention: Color(0xFFCCA700),
      done: Color(0xFF3FB950),
      error: Color(0xFFF14C4C),
      idle: Color(0xFF6E6E6E),
    ),
  );

  /// The light tokens, mirroring [dark].
  static const light = AppColors(
    sidebarBackground: Color(0xFFF7F7F8),
    titleBarBackground: Color(0xFFF7F7F8),
    raisedSurface: Color(0xFFFFFFFF),
    hairline: Color(0xFFE4E4E6),
    mutedText: Color(0xFF6E6E73),
    bubbleFill: Color(0xFFF0F0F2),
    selectedFill: Color(0xFFE6E6E9),
    hoverFill: Color(0xFFEFEFF1),
    statusColors: StatusColors(
      running: Color(0xFF0066CC),
      attention: Color(0xFFB58200),
      done: Color(0xFF1A7F37),
      error: Color(0xFFCF222E),
      idle: Color(0xFF8C8C8C),
    ),
  );

  /// The tokens for [brightness].
  static AppColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Tokens derived from [scheme], for themes without the extension.
  static AppColors fromScheme(ColorScheme scheme) => AppColors(
    sidebarBackground: scheme.surfaceContainerLow,
    titleBarBackground: scheme.surfaceContainerLow,
    raisedSurface: scheme.surfaceContainer,
    hairline: scheme.outlineVariant,
    mutedText: scheme.onSurfaceVariant,
    bubbleFill: scheme.surfaceContainerHighest,
    selectedFill: scheme.secondaryContainer,
    hoverFill: scheme.surfaceContainerHigh,
    statusColors: forBrightness(scheme.brightness).statusColors,
  );

  /// The tokens of the theme around [context].
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ?? fromScheme(theme.colorScheme);
  }

  @override
  AppColors copyWith({
    Color? sidebarBackground,
    Color? titleBarBackground,
    Color? raisedSurface,
    Color? hairline,
    Color? mutedText,
    Color? bubbleFill,
    Color? selectedFill,
    Color? hoverFill,
    StatusColors? statusColors,
  }) => AppColors(
    sidebarBackground: sidebarBackground ?? this.sidebarBackground,
    titleBarBackground: titleBarBackground ?? this.titleBarBackground,
    raisedSurface: raisedSurface ?? this.raisedSurface,
    hairline: hairline ?? this.hairline,
    mutedText: mutedText ?? this.mutedText,
    bubbleFill: bubbleFill ?? this.bubbleFill,
    selectedFill: selectedFill ?? this.selectedFill,
    hoverFill: hoverFill ?? this.hoverFill,
    statusColors: statusColors ?? this.statusColors,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      sidebarBackground: mix(sidebarBackground, other.sidebarBackground),
      titleBarBackground: mix(titleBarBackground, other.titleBarBackground),
      raisedSurface: mix(raisedSurface, other.raisedSurface),
      hairline: mix(hairline, other.hairline),
      mutedText: mix(mutedText, other.mutedText),
      bubbleFill: mix(bubbleFill, other.bubbleFill),
      selectedFill: mix(selectedFill, other.selectedFill),
      hoverFill: mix(hoverFill, other.hoverFill),
      statusColors: StatusColors.lerp(statusColors, other.statusColors, t),
    );
  }
}
