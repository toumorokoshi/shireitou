/// Pure helpers that turn JSON names into Dart identifiers and schema
/// descriptions into doc comments.
library;

/// Dart reserved words that cannot be used as identifiers.
const dartReservedWords = {
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'while',
  'with',
};

/// Splits [name] into words at `_`, `-`, `/`, `.`, spaces, and lower-to-upper
/// case changes.
List<String> words(String name) {
  final spaced = name
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp('[^A-Za-z0-9]+'), ' ')
      .trim();
  return spaced.isEmpty ? const [] : spaced.split(' ');
}

String _capitalize(String word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);

/// `foo_bar-baz` → `FooBarBaz`.
String pascalCase(String name) => words(name).map(_capitalize).join();

/// `foo_bar-baz` → `fooBarBaz`. A leading digit gets a `v` prefix.
String camelCase(String name) {
  final parts = words(name);
  if (parts.isEmpty) return 'value';
  final first = parts.first;
  final head = first == first.toUpperCase() && first.length > 1
      ? first.toLowerCase()
      : first[0].toLowerCase() + first.substring(1);
  final result = head + parts.skip(1).map(_capitalize).join();
  return RegExp('^[0-9]').hasMatch(result) ? 'v$result' : result;
}

/// The Dart field name for the JSON property [jsonName].
///
/// `_meta` becomes `meta`, snake_case becomes camelCase, and reserved words
/// take the name from [renames] or get a `Value` suffix.
String fieldName(String jsonName, {Map<String, String> renames = const {}}) {
  final renamed = renames[jsonName];
  if (renamed != null) return renamed;
  final name = camelCase(jsonName);
  return dartReservedWords.contains(name) ? '${name}Value' : name;
}

/// Converts a schema description into `///` doc comment lines, indented by
/// [indent]. TSDoc `{@link X}` becomes `[X]` when [isType] knows `X`, and
/// code otherwise; `{@link X | text}` becomes the text.
String docComment(
  String? description, {
  String indent = '',
  required String fallback,
  bool Function(String name)? isType,
}) {
  final text = (description == null || description.trim().isEmpty)
      ? fallback
      : description.trim();
  final linked = text.replaceAllMapped(
    RegExp(r'\{@link\s+([^}|]+?)\s*(?:\|\s*([^}]*?)\s*)?\}'),
    (m) {
      final target = m[1]!.trim();
      final label = m[2];
      if (label != null && label.isNotEmpty) return label;
      return (isType?.call(target) ?? false) ? '[$target]' : '`$target`';
    },
  );
  return linked
      .split('\n')
      .map(
        (line) => line.trimRight().isEmpty ? '$indent///' : '$indent/// $line',
      )
      .join('\n');
}
