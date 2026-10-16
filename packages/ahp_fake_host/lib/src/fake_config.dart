/// Pure pieces of the fake host's agent, model and session settings, and
/// its in-memory filesystem: what `resolveSessionConfig`,
/// `sessionConfigCompletions` and `resourceList` answer.
library;

import 'package:ahp_client/ahp_client.dart';

/// The model with a `thinkingLevel` option in its `configSchema`.
const scriptedModel = 'scripted';

/// A model without options.
const fastModel = 'scripted-fast';

/// The models the fake agent offers. Like VS Code's and pi's agents, the
/// per-model option is `thinkingLevel` (AV-041).
const fakeModels = [
  SessionModelInfo(
    id: scriptedModel,
    provider: 'fake',
    name: 'Scripted',
    configSchema: ConfigSchema(
      properties: {
        'thinkingLevel': ConfigPropertySchema(
          type: ConfigPropertySchemaType.string,
          title: 'Thinking',
          description: 'How much the model reasons before answering',
          defaultValue: 'medium',
          enumValues: ['low', 'medium', 'high'],
          enumLabels: ['Low', 'Medium', 'High'],
        ),
      },
    ),
  ),
  SessionModelInfo(id: fastModel, provider: 'fake', name: 'Scripted (fast)'),
];

/// The session setting that picks the agent's mode, as VS Code's agent
/// host names it; it may change after the session starts.
const modeProperty = 'mode';

/// The session setting that picks a branch; its values come from
/// `sessionConfigCompletions` and it is fixed once the session starts.
const branchProperty = 'branch';

/// The branches `sessionConfigCompletions` offers.
const fakeBranches = ['main', 'feature/login', 'fix/crash'];

/// Whether [path] is inside the fake repository at [repository].
bool inRepository(String path, String repository) =>
    path == repository || path.startsWith('$repository/');

/// The session settings the fake agent takes in [workingDirectory]: a mode
/// always, and a branch when the folder is inside [repository].
SessionConfigSchema sessionConfigSchema(
  String? workingDirectory,
  String repository,
) => SessionConfigSchema(
  properties: {
    modeProperty: const SessionConfigPropertySchema(
      type: SessionConfigPropertySchemaType.string,
      title: 'Mode',
      defaultValue: 'interactive',
      enumValues: ['interactive', 'plan', 'autopilot'],
      enumLabels: ['Interactive', 'Plan', 'Autopilot'],
      enumDescriptions: [
        'Asks before acting',
        'Plans first, then builds',
        'Works on its own',
      ],
      sessionMutable: true,
    ),
    if (workingDirectory != null &&
        inRepository(pathOfUri(workingDirectory), repository))
      branchProperty: const SessionConfigPropertySchema(
        type: SessionConfigPropertySchemaType.string,
        title: 'Branch',
        defaultValue: 'main',
        enumValues: ['main'],
        enumDynamic: true,
      ),
  },
);

/// [config] with the schema's defaults filled in and unknown keys dropped.
JsonMap resolvedConfigValues(SessionConfigSchema schema, JsonMap? config) => {
  for (final MapEntry(:key, value: property) in schema.properties.entries)
    key: ?(config?[key] ?? property.defaultValue),
};

/// The branches matching [query] (case-insensitive substring).
List<SessionConfigValueItem> branchCompletions(String? query) => [
  for (final branch in fakeBranches)
    if (query == null ||
        branch.toLowerCase().contains(query.trim().toLowerCase()))
      SessionConfigValueItem(value: branch, label: branch),
];

/// The path of a `file:` URI, or [uri] itself when it is a plain path.
String pathOfUri(String uri) {
  final parsed = Uri.tryParse(uri);
  final path = parsed != null && parsed.scheme == 'file'
      ? Uri.decodeComponent(parsed.path)
      : uri;
  return path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
}

/// The folders of the fake filesystem around [root] (the default
/// directory, a repository) plus one folder outside it.
Set<String> fakeDirectories(String root) => {
  '/',
  ..._ancestors(root),
  root,
  '$root/packages',
  '$root/packages/api',
  '$root/packages/web',
  '/srv',
  '/srv/scratch',
};

/// The files of the fake filesystem around [root].
Set<String> fakeFiles(String root) => {
  '$root/README.md',
  '$root/packages/api/main.dart',
};

Iterable<String> _ancestors(String path) sync* {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  for (var i = 1; i < segments.length; i++) {
    yield '/${segments.take(i).join('/')}';
  }
}

/// The entries directly inside [directory], folders first, by name; null
/// when [directory] is not a folder of [directories].
List<DirectoryEntry>? listFakeDirectory(
  String directory,
  Set<String> directories,
  Set<String> files,
) {
  if (!directories.contains(directory)) return null;
  String? childName(String path) {
    final prefix = directory == '/' ? '/' : '$directory/';
    if (path == directory || !path.startsWith(prefix)) return null;
    final rest = path.substring(prefix.length);
    return rest.isEmpty || rest.contains('/') ? null : rest;
  }

  List<String> names(Set<String> paths) =>
      [for (final p in paths) ?childName(p)]..sort();
  return [
    for (final name in names(directories))
      DirectoryEntry(name: name, type: DirectoryEntryType.directory),
    for (final name in names(files))
      DirectoryEntry(name: name, type: DirectoryEntryType.file),
  ];
}

/// The reply of the `settings` flow: the model, its options and the
/// session's settings the turn ran with.
String settingsReply(ModelSelection? model, JsonMap? sessionConfig) {
  final options = model?.config ?? const {};
  final settings = sessionConfig ?? const {};
  return [
    'Model: ${model?.id ?? 'default'}',
    for (final MapEntry(:key, :value) in options.entries) '$key: $value',
    for (final MapEntry(:key, :value) in settings.entries) '$key: $value',
  ].join('\n\n');
}
