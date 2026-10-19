/// The user's appearance choice (AV-097): light, dark or the system's
/// setting, and the colour scheme, kept with the app's prefs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';
import 'palettes.dart';

/// Light, dark or the system's setting, and the colour scheme.
typedef Appearance = ({ThemeMode mode, AppPalette palette});

/// The appearance before the user picks one: the system's setting in
/// [AppPalette.graphite].
const defaultAppearance = (
  mode: ThemeMode.system,
  palette: AppPalette.graphite,
);

/// The [PrefsStore] keys.
const themeModeKey = 'theme_mode';
const paletteKey = 'color_scheme';

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
    state = (
      mode: themeModeByName(await prefs.read(themeModeKey)),
      palette: AppPalette.byName(await prefs.read(paletteKey)),
    );
  }

  /// Switches to [mode] and saves it.
  Future<void> setMode(ThemeMode mode) async {
    await _loading;
    state = (mode: mode, palette: state.palette);
    await ref.read(prefsStoreProvider).write(themeModeKey, mode.name);
  }

  /// Switches to [palette] and saves it.
  Future<void> setPalette(AppPalette palette) async {
    await _loading;
    state = (mode: state.mode, palette: palette);
    await ref.read(prefsStoreProvider).write(paletteKey, palette.name);
  }
}

/// The user's appearance.
final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);

/// The "Appearance" submenu (AV-097): the mode, then the colour schemes,
/// each with a swatch of its accent.
class AppearanceMenu extends ConsumerWidget {
  /// Creates the submenu.
  const AppearanceMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final brightness = Theme.of(context).brightness;
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
        for (final palette in AppPalette.values)
          RadioMenuButton<AppPalette>(
            value: palette,
            groupValue: appearance.palette,
            onChanged: (palette) => notifier.setPalette(palette!),
            trailingIcon: Icon(
              Icons.circle,
              size: 12,
              color: palette.accent(brightness),
            ),
            child: Text(palette.label),
          ),
      ],
      child: const Text('Appearance'),
    );
  }
}
