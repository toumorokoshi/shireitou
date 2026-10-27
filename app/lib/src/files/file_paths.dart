/// File paths in agent output (AV-106): recognising them in prose, code
/// spans and link targets, and resolving them against the session's
/// working directory to a `file:` URI the host reads with `resourceRead`.
library;

import 'package:path/path.dart' as p;

/// A file named in a reply: its [path] as written (relative to the
/// session's working directory, or absolute), and the [line] (1-based)
/// and [endLine] it points at, if any.
typedef FileReference = ({String path, int? line, int? endLine});

/// The link target the app gives the paths it finds in prose and code
/// spans ([findFileReferences]), so a tap opens the file and a copy keeps
/// the text rather than a link.
const filePathHrefPrefix = 'shireitou-file:';

/// The href of a link to [path] (the text as written) found in a reply.
String filePathHref(String path) => '$filePathHrefPrefix$path';

/// File extensions that make a bare name (no `/`) a file, such as
/// `README.md`; with a `/` any extension does.
const _knownExtensions = {
  'bash',
  'bat',
  'c',
  'cc',
  'cfg',
  'cjs',
  'conf',
  'cpp',
  'cs',
  'css',
  'csv',
  'dart',
  'env',
  'go',
  'gradle',
  'h',
  'hpp',
  'html',
  'ini',
  'ipynb',
  'java',
  'js',
  'json',
  'jsonc',
  'jsx',
  'kt',
  'kts',
  'less',
  'lock',
  'lua',
  'md',
  'mdx',
  'mjs',
  'mk',
  'php',
  'pl',
  'plist',
  'proto',
  'ps1',
  'py',
  'r',
  'rb',
  'rs',
  'rst',
  'sass',
  'scala',
  'scss',
  'sh',
  'sql',
  'svelte',
  'svg',
  'swift',
  'tf',
  'toml',
  'ts',
  'tsx',
  'txt',
  'vue',
  'xml',
  'yaml',
  'yml',
  'zig',
  'zsh',
};

/// Names of files without an extension.
const _knownNames = {
  'BUILD',
  'CODEOWNERS',
  'Dockerfile',
  'Gemfile',
  'Justfile',
  'LICENSE',
  'Makefile',
  'Procfile',
  'README',
  'Rakefile',
  'WORKSPACE',
  'justfile',
  'makefile',
  '.editorconfig',
  '.env',
  '.gitattributes',
  '.gitignore',
  '.npmrc',
  '.prettierrc',
};

final _pathShape = RegExp(r'^(?:\.{1,2}/|/)?[\w@+.\-]+(?:/[\w@+.\-]+)*$');
final _extension = RegExp(r'^[\w@+\-][\w@+.\-]*\.([A-Za-z][A-Za-z0-9_]{0,9})$');
final _dotfile = RegExp(r'^\.[A-Za-z][\w.\-]*$');
final _domain = RegExp(
  r'^(?:www\.|[\w\-]+(?:\.[\w\-]+)*\.(?:com|org|net|io|dev|ai|co|edu|gov|app)$)',
  caseSensitive: false,
);

/// Whether [path] (no line suffix) looks like a file: a name with an
/// extension, a dotfile or a well-known name such as `Makefile`, after
/// optional folders. A bare name needs a [_knownExtensions] extension,
/// so `e.g.`, `v1.2` and `foo.bar` are not files; a leading domain
/// (`github.com/…`) is a URL, not a path.
bool looksLikeFilePath(String path) {
  if (!_pathShape.hasMatch(path)) return false;
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return false;
  final name = segments.last;
  if (name == '.' || name == '..') return false;
  final nested = path.contains('/');
  if (nested && _domain.hasMatch(segments.first)) return false;
  if (_knownNames.contains(name)) return true;
  return switch (_extension.firstMatch(name)?.group(1)) {
    final ext? => nested || _knownExtensions.contains(ext.toLowerCase()),
    null => nested && _dotfile.hasMatch(name),
  };
}

final _lineSuffix = RegExp(
  r'^(.+?)(?::(\d+)(?:-(\d+)|:\d+)?|#L(\d+)(?:-L?(\d+))?)$',
);

/// [text] split into its path and a `:12`, `:12:4` (column ignored),
/// `:12-20` or `#L12-L20` line suffix.
FileReference _splitLine(String text) {
  final m = _lineSuffix.firstMatch(text);
  if (m == null) return (path: text, line: null, endLine: null);
  int? number(int group) => switch (m.group(group)) {
    final String n => int.tryParse(n),
    null => null,
  };
  return (
    path: m.group(1)!,
    line: number(2) ?? number(4),
    endLine: number(3) ?? number(5),
  );
}

/// [text] (a whole token, such as the content of a code span) as a file
/// reference, or null when it does not look like a file path
/// ([looksLikeFilePath]).
FileReference? parseFileReference(String text) {
  final ref = _splitLine(text.trim());
  return looksLikeFilePath(ref.path) ? ref : null;
}

/// A file path in prose, where it starts and ends in the text.
typedef FileMatch = ({int start, int end, FileReference ref});

/// A path-like token: not inside a word, a URL (`://`) or a longer path,
/// and not ending in a period (the end of a sentence).
final filePathPattern = RegExp(
  r'(?<![\w/.~:@+\-\\])'
  r'(?:\.{1,2}/|/)?[\w@+.\-]*[\w@+\-](?:/[\w@+.\-]*[\w@+\-])*'
  r'(?::\d+(?:-\d+|:\d+)?|#L\d+(?:-L?\d+)?)?'
  r'(?![\w/@+\-]|:\d)',
);

/// The file paths in [text] ([parseFileReference]), in order.
List<FileMatch> findFileReferences(String text) => [
  for (final m in filePathPattern.allMatches(text))
    if (parseFileReference(m[0]!) case final ref?)
      (start: m.start, end: m.end, ref: ref),
];

final _scheme = RegExp(r'^([a-z][a-z0-9.+\-]*):', caseSensitive: false);
final _pathWithLine = RegExp(r'^[\w@+.\-/]+:\d+');

String _decoded(String text) {
  try {
    return Uri.decodeFull(text);
  } on ArgumentError {
    return text;
  }
}

/// The file a link target [href] points at: a path the app found
/// ([filePathHref]), a `file:` URI, or a relative or absolute path such
/// as `src/a.dart`, `../b.md#L3` or `/home/me/c.py:12`. Null for web and
/// other URLs, `#anchors` and queries.
FileReference? fileReferenceOfHref(String href) {
  final h = href.trim();
  if (h.startsWith(filePathHrefPrefix)) {
    return parseFileReference(h.substring(filePathHrefPrefix.length));
  }
  if (h.isEmpty || h.startsWith('#') || h.startsWith('?')) return null;
  if (h.startsWith('//')) return null;
  final scheme = _pathWithLine.hasMatch(h)
      ? null
      : _scheme.firstMatch(h)?.group(1)?.toLowerCase();
  if (scheme == 'file') {
    final uri = Uri.tryParse(h);
    if (uri == null || uri.path.isEmpty) return null;
    final line = _splitLine('x#${uri.fragment}');
    return (path: _decoded(uri.path), line: line.line, endLine: line.endLine);
  }
  if (scheme != null) return null;
  final ref = _splitLine(_decoded(h));
  return ref.path.isEmpty ? null : ref;
}

/// [path] as an absolute, normalized path: as it is when absolute, else
/// under [root] (the session's working directory). Null when [path] is
/// relative and there is no [root].
String? resolveFilePath(String path, {String? root}) {
  if (p.posix.isAbsolute(path)) return p.posix.normalize(path);
  if (root == null || !p.posix.isAbsolute(root)) return null;
  return p.posix.normalize(p.posix.join(root, path));
}

/// The `file:` URI of the absolute [path] on the host.
String fileUriOf(String path) => Uri.file(path, windows: false).toString();

/// [path] relative to [root] when it is inside it, else [path].
String filePathLabel(String path, {String? root}) =>
    root != null && p.posix.isWithin(root, path)
    ? p.posix.relative(path, from: root)
    : path;
