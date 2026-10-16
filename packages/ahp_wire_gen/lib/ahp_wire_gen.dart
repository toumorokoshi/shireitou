/// Generates Dart wire types from the Agent Host Protocol JSON Schemas.
library;

import 'src/analyzer.dart';
import 'src/config.dart';
import 'src/emitter.dart';

export 'src/analyzer.dart'
    show UnsupportedSchemaError, WireModel, analyze, mergeDefs;
export 'src/config.dart';
export 'src/emitter.dart' show GeneratedFiles, emit, libraryStem;
export 'src/model.dart';

/// Analyzes [schemas] (schema file stem to decoded file) and emits the
/// Dart library for [config].
GeneratedFiles generate(
  Map<String, Map<String, Object?>> schemas,
  GeneratorConfig config,
) => emit(analyze(schemas, config), config);
