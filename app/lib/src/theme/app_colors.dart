/// The colour tokens of the reference UI (AV-090) that `ColorScheme` has
/// no slot for, as a `ThemeExtension` so widgets read them from
/// `Theme.of(context)`.
library;

import 'package:flutter/material.dart';
import 'package:xterm/ui.dart' show TerminalTheme;

import 'highlight_themes.dart';
import 'themes.dart';

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
    required this.diffAddedFill,
    required this.diffRemovedFill,
    required this.diffGutterText,
    required this.terminal,
    required this.syntax,
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

  /// The translucent fill of an added diff line, drawn over the diff's
  /// background (the theme's green).
  final Color diffAddedFill;

  /// The translucent fill of a removed diff line (the theme's red).
  final Color diffRemovedFill;

  /// Line numbers and +/− markers in a diff's gutter.
  final Color diffGutterText;

  /// The colours of the AHP terminal preview: the theme's ANSI colours on
  /// the sidebar's background, as xterm.dart's [TerminalTheme].
  final TerminalTheme terminal;

  /// The code highlighting theme (highlight.js scope to style).
  final Map<String, TextStyle> syntax;

  /// The dark tokens of the default theme.
  static final dark = forBrightness(Brightness.dark);

  /// The light tokens of the default theme, mirroring [dark].
  static final light = forBrightness(Brightness.light);

  /// The tokens of [theme] (built once per theme).
  static AppColors forTheme(ThemeSpec theme) =>
      _byTheme.putIfAbsent(theme.id, () => _build(theme));

  static final _byTheme = <String, AppColors>{};

  static AppColors _build(ThemeSpec theme) {
    final c = themeColors(theme);
    return AppColors(
      sidebarBackground: c.sidebar,
      titleBarBackground: c.sidebar,
      raisedSurface: c.raised,
      hairline: c.hairline,
      mutedText: c.mutedText,
      bubbleFill: c.bubble,
      selectedFill: c.selected,
      hoverFill: c.hover,
      statusColors: StatusColors(
        running: c.accent,
        attention: c.attention,
        done: c.done,
        error: c.error,
        idle: c.idle,
      ),
      diffAddedFill: c.diffAddedFill,
      diffRemovedFill: c.diffRemovedFill,
      diffGutterText: c.diffGutter,
      terminal: terminalTheme(theme, background: c.sidebar, foreground: c.text),
      syntax: syntaxTheme(c.syntax),
    );
  }

  /// The tokens of the default theme for [brightness].
  static AppColors forBrightness(Brightness brightness) =>
      forTheme(defaultTheme(brightness));

  /// Tokens derived from [scheme], for themes without the extension.
  static AppColors fromScheme(ColorScheme scheme) {
    final tokens = forBrightness(scheme.brightness);
    return AppColors(
      sidebarBackground: scheme.surfaceContainerLow,
      titleBarBackground: scheme.surfaceContainerLow,
      raisedSurface: scheme.surfaceContainer,
      hairline: scheme.outlineVariant,
      mutedText: scheme.onSurfaceVariant,
      bubbleFill: scheme.surfaceContainerHighest,
      selectedFill: scheme.secondaryContainer,
      hoverFill: scheme.surfaceContainerHigh,
      statusColors: tokens.statusColors,
      diffAddedFill: tokens.diffAddedFill,
      diffRemovedFill: tokens.diffRemovedFill,
      diffGutterText: tokens.diffGutterText,
      terminal: tokens.terminal,
      syntax: tokens.syntax,
    );
  }

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
    Color? diffAddedFill,
    Color? diffRemovedFill,
    Color? diffGutterText,
    TerminalTheme? terminal,
    Map<String, TextStyle>? syntax,
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
    diffAddedFill: diffAddedFill ?? this.diffAddedFill,
    diffRemovedFill: diffRemovedFill ?? this.diffRemovedFill,
    diffGutterText: diffGutterText ?? this.diffGutterText,
    terminal: terminal ?? this.terminal,
    syntax: syntax ?? this.syntax,
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
      diffAddedFill: mix(diffAddedFill, other.diffAddedFill),
      diffRemovedFill: mix(diffRemovedFill, other.diffRemovedFill),
      diffGutterText: mix(diffGutterText, other.diffGutterText),
      // xterm.dart's theme and text styles of code switch at halfway.
      terminal: t < 0.5 ? terminal : other.terminal,
      syntax: t < 0.5 ? syntax : other.syntax,
    );
  }
}

/// The terminal colours of [theme] (Base24's ANSI mapping) on
/// [background] with [foreground] text.
TerminalTheme terminalTheme(
  ThemeSpec theme, {
  required Color background,
  required Color foreground,
}) {
  Color c(int index) => theme.base(index);
  return TerminalTheme(
    cursor: foreground,
    selection: c(0x02).withAlpha(0x99),
    foreground: foreground,
    background: background,
    black: c(0x01),
    red: c(0x08),
    green: c(0x0B),
    yellow: c(0x0A),
    blue: c(0x0D),
    magenta: c(0x0E),
    cyan: c(0x0C),
    white: c(0x05),
    brightBlack: c(0x03),
    brightRed: c(0x12),
    brightGreen: c(0x14),
    brightYellow: c(0x13),
    brightBlue: c(0x16),
    brightMagenta: c(0x17),
    brightCyan: c(0x15),
    brightWhite: c(0x07),
    searchHitBackground: const Color(0xFFFFFF2B),
    searchHitBackgroundCurrent: const Color(0xFF31FF26),
    searchHitForeground: const Color(0xFF000000),
  );
}
