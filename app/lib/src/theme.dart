/// Light and dark themes (AV-004).
library;

import 'package:flutter/material.dart';

/// Seed color for the Material 3 color scheme.
const _seed = Color(0xFF3F51B5);

/// Builds the app theme for [brightness].
ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  visualDensity: VisualDensity.standard,
);
