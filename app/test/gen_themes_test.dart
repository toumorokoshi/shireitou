/// The generated theme table matches themes/manifest.yaml and its scheme
/// files (AV-097), so a stale `themes.g.dart` fails here: run
/// `just themes`.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/theme/themes.dart';
import 'package:yaml/yaml.dart';

import '../tool/gen_themes.dart';

void main() {
  final manifest =
      loadYaml(File('themes/manifest.yaml').readAsStringSync()) as YamlMap;
  final entries = (manifest['themes'] as YamlMap).map(
    (id, entry) => MapEntry(id as String, entry as YamlMap),
  );
  YamlMap scheme(YamlMap entry) =>
      loadYaml(File('themes/${schemePath(entry)}').readAsStringSync())
          as YamlMap;

  test('every manifest theme is generated, in order', () {
    expect(allThemes.map((t) => t.id), entries.keys);
  });

  test('names, variants and colours match the scheme files', () {
    for (final (index, MapEntry(key: id, value: entry))
        in entries.entries.indexed) {
      final source = scheme(entry);
      final theme = allThemes[index];
      expect(theme.name, entry['name'] ?? source['name'], reason: id);
      expect(
        theme.brightness,
        source['variant'] == 'dark' ? Brightness.dark : Brightness.light,
        reason: id,
      );
      expect(
        theme.colors,
        base24Colors(source['palette'] as YamlMap),
        reason: id,
      );
    }
  });

  test('a Base16 palette is padded to Base24', () {
    final colors = base24Colors(
      YamlMap.wrap({
        for (var i = 0; i < 16; i++)
          'base${i.toRadixString(16).padLeft(2, '0').toUpperCase()}':
              '#0000${i.toRadixString(16).padLeft(2, '0')}',
      }),
    );
    expect(colors, hasLength(24));
    expect(colors[0x10], colors[0x00]);
    expect(colors[0x12], colors[0x08]);
    expect(colors[0x17], colors[0x0E]);
  });
}
