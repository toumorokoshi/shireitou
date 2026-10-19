/// The user's appearance choice (AV-097): light, dark or the system's
/// setting, and a colour theme for each, kept with the app's prefs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';
import 'themes.dart';

/// Light, dark or the system's setting, and the theme used when the app
/// is dark and when it is light.
typedef Appearance = ({ThemeMode mode, ThemeSpec dark, ThemeSpec light});

/// The appearance before the user picks one: the system's setting in
/// the default themes.
final defaultAppearance = (
  mode: ThemeMode.system,
  dark: defaultTheme(Brightness.dark),
  light: defaultTheme(Brightness.light),
);

/// The [PrefsStore] keys.
const themeModeKey = 'theme_mode';
const darkThemeKey = 'dark_theme';
const lightThemeKey = 'light_theme';

/// The mode named [name], or [ThemeMode.system] when there is none.
ThemeMode themeModeByName(String? name) =>
    ThemeMode.values.where((m) => m.name == name).firstOrNull ??
    ThemeMode.system;

/// The label of [mode] in the menu.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

/// [appearance] with [theme] picked while the app shows [shown]. A theme
/// of the other brightness also switches the mode to it, so the pick is
/// seen at once.
Appearance withTheme(Appearance appearance, ThemeSpec theme, Brightness shown) {
  final dark = theme.brightness == Brightness.dark;
  return (
    mode: theme.brightness == shown
        ? appearance.mode
        : dark
        ? ThemeMode.dark
        : ThemeMode.light,
    dark: dark ? theme : appearance.dark,
    light: dark ? appearance.light : theme,
  );
}

/// The appearance, kept with [prefsStoreProvider];
/// [defaultAppearance] until it loads.
class AppearanceNotifier extends Notifier<Appearance> {
  Future<void>? _loading;

  @override
  Appearance build() {
    _loading = _load();
    return defaultAppearance;
  }

  Future<void> _load() async {
    final prefs = ref.read(prefsStoreProvider);
    final mode = await prefs.read(themeModeKey);
    final dark = await prefs.read(darkThemeKey);
    final light = await prefs.read(lightThemeKey);
    if (!ref.mounted) return;
    state = (
      mode: themeModeByName(mode),
      dark: themeById(dark, Brightness.dark),
      light: themeById(light, Brightness.light),
    );
  }

  /// Switches to [mode] and saves it.
  Future<void> setMode(ThemeMode mode) async {
    await _loading;
    await _save((mode: mode, dark: state.dark, light: state.light));
  }

  /// Picks [theme] while the app shows [shown] ([withTheme]) and saves it.
  Future<void> setTheme(ThemeSpec theme, Brightness shown) async {
    await _loading;
    await _save(withTheme(state, theme, shown));
  }

  Future<void> _save(Appearance appearance) async {
    state = appearance;
    final prefs = ref.read(prefsStoreProvider);
    await prefs.write(themeModeKey, appearance.mode.name);
    await prefs.write(darkThemeKey, appearance.dark.id);
    await prefs.write(lightThemeKey, appearance.light.id);
  }
}

/// The user's appearance.
final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);

/// The "Appearance" submenu (AV-097): the mode, then a "Dark theme" and a
/// "Light theme" submenu listing the themes, each with a [ThemeSwatch].
class AppearanceMenu extends ConsumerWidget {
  /// Creates the submenu.
  const AppearanceMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final shown = Theme.of(context).brightness;
    Widget themes(String label, Brightness brightness, ThemeSpec picked) =>
        SubmenuButton(
          menuChildren: [
            for (final theme in themesFor(brightness))
              RadioMenuButton<String>(
                value: theme.id,
                groupValue: picked.id,
                onChanged: (_) => notifier.setTheme(theme, shown),
                trailingIcon: ThemeSwatch(theme),
                child: Text(theme.name),
              ),
          ],
          child: Text('$label · ${picked.name}'),
        );
    return SubmenuButton(
      leadingIcon: const Icon(Icons.palette_outlined),
      menuChildren: [
        for (final mode in ThemeMode.values)
          RadioMenuButton<ThemeMode>(
            value: mode,
            groupValue: appearance.mode,
            onChanged: (mode) => notifier.setMode(mode!),
            child: Text(themeModeLabel(mode)),
          ),
        const Divider(height: 8),
        themes('Dark theme', Brightness.dark, appearance.dark),
        themes('Light theme', Brightness.light, appearance.light),
      ],
      child: const Text('Appearance'),
    );
  }
}

/// A small preview of [theme]: its background with its blue, green, red
/// and purple.
class ThemeSwatch extends StatelessWidget {
  /// Creates the swatch.
  const ThemeSwatch(this.theme, {super.key});

  /// The theme shown.
  final ThemeSpec theme;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: theme.base(0x00),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: theme.base(0x02)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final index in const [0x0D, 0x0B, 0x08, 0x0E])
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.base(index),
              shape: BoxShape.circle,
            ),
          ),
      ],
    ),
  );
}
