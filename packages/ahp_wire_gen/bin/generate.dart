/// Generates the ahp_client wire types from the AHP JSON Schemas.
///
/// Usage: `dart run ahp_wire_gen:generate <schema-dir> <output-dir>`.
/// Writes one Dart library (plus parts) into `<output-dir>`, replacing the
/// previously generated files there. Run `dart format` on the output
/// afterwards; `just codegen` does both.
library;

import 'dart:convert';
import 'dart:io';

import 'package:ahp_wire_gen/ahp_wire_gen.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: generate <schema-dir> <output-dir>');
    exit(64);
  }
  final [schemaDir, outputDir] = args;
  final config = protocol100Config;
  final schemas = {
    for (final stem in config.sources)
      stem: (jsonDecode(
        File('$schemaDir/$stem.schema.json').readAsStringSync(),
      ) as Map).cast<String, Object?>(),
  };
  final files = generate(schemas, config);
  final out = Directory(outputDir)..createSync(recursive: true);
  for (final stale in out.listSync().whereType<File>()) {
    if (stale.path.split(Platform.pathSeparator).last.startsWith(libraryStem)) {
      stale.deleteSync();
    }
  }
  for (final MapEntry(:key, :value) in files.entries) {
    File('${out.path}/$key').writeAsStringSync(value);
  }
  stdout.writeln('Wrote ${files.length} files to ${out.path}');
}
