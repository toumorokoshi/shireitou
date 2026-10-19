/// The colour tokens of the reference UI (AV-090) that `ColorScheme` has
/// no slot for, as a `ThemeExtension` so widgets read them from
/// `Theme.of(context)`.
library;

import 'package:flutter/material.dart';
import 'package:xterm/ui.dart' show TerminalTheme;

import 'palettes.dart';

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
  /// background (VS Code's `diffEditor.insertedLineBackground`).
  final Color diffAddedFill;

  /// The translucent fill of a removed diff line (VS Code's
  /// `diffEditor.removedLineBackground`).
  final Color diffRemovedFill;

  /// Line numbers and +/− markers in a diff's gutter (VS Code's
  /// `editorLineNumber.foreground`).
  final Color diffGutterText;

  /// The colours of terminals: the AHP terminal preview and the SSH
  /// terminal. VS Code's integrated terminal palette on the sidebar's
  /// background, as xterm.dart's [TerminalTheme] so the SSH terminal
  /// uses it as is.
  final TerminalTheme terminal;

  /// The dark tokens of the default palette.
  static final dark = forPalette(AppPalette.graphite, Brightness.dark);

  /// The light tokens of the default palette, mirroring [dark].
  static final light = forPalette(AppPalette.graphite, Brightness.light);

  /// The tokens of [palette] in [brightness]: its surfaces and accent,
  /// with the status, diff and terminal colours shared by every palette.
  static AppColors forPalette(AppPalette palette, Brightness brightness) =>
      _byPalette.putIfAbsent((
        palette,
        brightness,
      ), () => _build(palette, brightness));

  static final _byPalette = <(AppPalette, Brightness), AppColors>{};

  static AppColors _build(AppPalette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final s = paletteSurfaces(palette, brightness);
    final status = dark ? _darkStatus : _lightStatus;
    return AppColors(
      sidebarBackground: s.sidebar,
      titleBarBackground: s.sidebar,
      raisedSurface: s.raised,
      hairline: s.hairline,
      mutedText: s.mutedText,
      bubbleFill: s.bubble,
      selectedFill: s.selected,
      hoverFill: s.hover,
      statusColors: StatusColors(
        running: s.accent,
        attention: status.attention,
        done: status.done,
        error: status.error,
        idle: status.idle,
      ),
      diffAddedFill: const Color(0x339BB955),
      diffRemovedFill: const Color(0x33FF0000),
      diffGutterText: dark ? const Color(0xFF8A8A8A) : const Color(0xFF237893),
      terminal: terminalOn(
        dark ? _darkTerminal : _lightTerminal,
        background: s.sidebar,
        foreground: s.text,
      ),
    );
  }

  /// The tokens for [brightness] in the default palette.
  static AppColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

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
      // xterm.dart's theme has no lerp; a terminal switches at halfway.
      terminal: t < 0.5 ? terminal : other.terminal,
    );
  }
}

const _darkStatus = StatusColors(
  running: Color(0xFF3794FF),
  attention: Color(0xFFCCA700),
  done: Color(0xFF3FB950),
  error: Color(0xFFF65F5F),
  idle: Color(0xFF858585),
);

const _lightStatus = StatusColors(
  running: Color(0xFF0066CC),
  attention: Color(0xFF9A6700),
  done: Color(0xFF1A7F37),
  error: Color(0xFFCF222E),
  idle: Color(0xFF757575),
);

/// VS Code's dark terminal palette; [AppColors.forPalette] replaces the
/// background and foreground.
const _darkTerminal = TerminalTheme(
  cursor: Color(0xAAAEAFAD),
  selection: Color(0x99264F78),
  foreground: Color(0xFFCCCCCC),
  background: Color(0xFF121314),
  black: Color(0xFF000000),
  red: Color(0xFFCD3131),
  green: Color(0xFF0DBC79),
  yellow: Color(0xFFE5E510),
  blue: Color(0xFF2472C8),
  magenta: Color(0xFFBC3FBC),
  cyan: Color(0xFF11A8CD),
  white: Color(0xFFE5E5E5),
  brightBlack: Color(0xFF666666),
  brightRed: Color(0xFFF14C4C),
  brightGreen: Color(0xFF23D18B),
  brightYellow: Color(0xFFF5F543),
  brightBlue: Color(0xFF3B8EEA),
  brightMagenta: Color(0xFFD670D6),
  brightCyan: Color(0xFF29B8DB),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: Color(0xFF000000),
);

/// VS Code's light terminal palette.
const _lightTerminal = TerminalTheme(
  cursor: Color(0x99333333),
  selection: Color(0x99ADD6FF),
  foreground: Color(0xFF333333),
  background: Color(0xFFF7F7F8),
  black: Color(0xFF000000),
  red: Color(0xFFCD3131),
  green: Color(0xFF107C10),
  yellow: Color(0xFF949800),
  blue: Color(0xFF0451A5),
  magenta: Color(0xFFBC05BC),
  cyan: Color(0xFF0598BC),
  white: Color(0xFF555555),
  brightBlack: Color(0xFF666666),
  brightRed: Color(0xFFCD3131),
  brightGreen: Color(0xFF14CE14),
  brightYellow: Color(0xFFB5BA00),
  brightBlue: Color(0xFF0451A5),
  brightMagenta: Color(0xFFBC05BC),
  brightCyan: Color(0xFF0598BC),
  brightWhite: Color(0xFFA5A5A5),
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: Color(0xFF000000),
);
