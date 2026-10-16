/// What the generator does beyond a mechanical schema translation: schema
/// fixes, names, and fields kept as raw JSON. Every entry is a deliberate
/// decision; see `DESIGN-DECISION-LOG.md` (2026-10-16, "Wire type
/// generation").
library;

import 'model.dart';

/// A union built from the members of another union whose discriminator
/// starts with [prefix] (the protocol's TypeScript `RootAction`,
/// `SessionAction`, ... types, which the schemas do not export).
final class SyntheticUnion {
  /// Creates a [SyntheticUnion].
  const SyntheticUnion(this.name, this.from, this.prefix, this.doc);

  /// The union's Dart name.
  final String name;

  /// The union whose members are filtered.
  final String from;

  /// Discriminator prefix, e.g. `root/`.
  final String prefix;

  /// Doc comment text.
  final String doc;
}

/// A correction to the upstream schemas, applied before generation.
///
/// [apply] must throw when the defect it fixes is gone, so upgrading the
/// schemas forces a review of every patch.
final class SchemaPatch {
  /// Creates a [SchemaPatch].
  const SchemaPatch(this.description, this.apply);

  /// What is wrong upstream.
  final String description;

  /// Fixes the merged `$defs` in place.
  final void Function(Map<String, Map<String, Object?>> defs) apply;
}

/// Generator settings.
final class GeneratorConfig {
  /// Creates a [GeneratorConfig].
  const GeneratorConfig({
    required this.protocolVersion,
    this.sources = const [
      'state',
      'actions',
      'commands',
      'notifications',
      'errors',
    ],
    this.skip = const {},
    this.fieldTypes = const {},
    this.fieldRenames = const {},
    this.typeRenames = const {},
    this.wrapperNames = const {},
    this.numFields = const {},
    this.syntheticUnions = const [],
    this.patches = const [],
    this.statusType = 'SessionStatus',
    this.statusImport = '../session_status.dart',
  });

  /// The protocol version the schemas describe.
  final String protocolVersion;

  /// Schema file stems (`<stem>.schema.json`), in priority order: a `$def`
  /// in several files is generated once, into the first file's part.
  final List<String> sources;

  /// `$defs` not generated, with the reason.
  final Map<String, String> skip;

  /// Field types that replace the schema's, keyed `Owner.jsonName`.
  final Map<String, TypeRef> fieldTypes;

  /// Dart names for JSON property names that are reserved words.
  final Map<String, String> fieldRenames;

  /// Dart names for generated declarations, keyed by the derived name.
  final Map<String, String> typeRenames;

  /// Names of primitive and untagged object members of unions, keyed
  /// `Union.string` / `Union.object`.
  final Map<String, String> wrapperNames;

  /// Number properties that may be fractional (`num`); every other
  /// `number` is an `int`.
  final Set<String> numFields;

  /// Unions built from other unions.
  final List<SyntheticUnion> syntheticUnions;

  /// Fixes to the upstream schemas.
  final List<SchemaPatch> patches;

  /// The `$def` mapped to the client's `SessionStatus` extension type.
  final String statusType;

  /// Import (relative to the output directory) that defines
  /// `SessionStatus`.
  final String statusImport;
}

Map<String, Object?> _properties(
  Map<String, Map<String, Object?>> defs,
  String def,
) => (defs[def]!['properties']! as Map).cast<String, Object?>();

void _setApprovedConst(
  Map<String, Map<String, Object?>> defs,
  String def,
  bool value,
) {
  final properties = _properties(defs, def);
  final approved = (properties['approved']! as Map).cast<String, Object?>();
  if (approved.containsKey('const') || approved.containsKey('type')) {
    throw StateError('$def.approved is typed upstream now; drop the patch');
  }
  properties['approved'] = {...approved, 'const': value};
}

/// The configuration for protocol 1.0.0.
final protocol100Config = GeneratorConfig(
  protocolVersion: '1.0.0',
  skip: const {
    'AhpErrorDetailsMap':
        'a TypeScript mapped type keyed by error-code expressions; the '
        '*ErrorData types it maps to are generated',
    'ProtocolNotification':
        'notifications are told apart by their JSON-RPC method, which is '
        'not in the params; the *Params types are generated',
  },
  fieldTypes: const {
    // Decoded by the client according to the channel kind; the schema's
    // oneOf has no discriminator.
    'Snapshot.state': JsonMapType(),
    // Write-ahead keeps actions as JSON; reducers decode them with the
    // channel's action union.
    'ActionEnvelope.action': JsonMapType(),
    // `Partial<ChatSummary>` / `Partial<SessionSummary>`: hosts clear a
    // field with an explicit null (pi sends `activity: null`), which a typed
    // class cannot tell from an omitted field. Merge the JSON instead.
    'SessionChatUpdatedAction.changes': JsonMapType(),
    'SessionSummaryChangedParams.changes': JsonMapType(),
    // The same values as the `ToolCallCancellationReason` enum, inlined.
    'ChatToolCallDeniedAction.reason': NamedType('ToolCallCancellationReason'),
  },
  fieldRenames: const {'default': 'defaultValue', 'enum': 'enumValues'},
  typeRenames: const {
    // Clash with Flutter's `Icon` widget and dart:ui's text types.
    'Icon': 'AhpIcon',
    'TextPosition': 'AhpTextPosition',
    'TextRange': 'AhpTextRange',
    'TextSelection': 'AhpTextSelection',
    'ToolCallResultError': 'ToolCallError',
    'ResourceWatchStateExcludes': 'ResourceWatchFilter',
    'ToolDefinitionInputSchema': 'ToolSchema',
    'AhpMcpUiHostCapabilitiesServerTools': 'McpUiListChangedCapability',
    'ResourceWatchChangedActionChanges': 'ResourceWatchChanges',
  },
  wrapperNames: const {
    'StringOrMarkdown.string': 'PlainString',
    'StringOrMarkdown.object': 'MarkdownString',
    'ToolInput.string': 'InlineToolInput',
  },
  numFields: const {
    'min',
    'max',
    'value',
    'defaultValue',
    'safety',
    'progress',
    'total',
  },
  syntheticUnions: const [
    SyntheticUnion(
      'RootAction',
      'StateAction',
      'root/',
      'Root channel actions.',
    ),
    SyntheticUnion(
      'SessionAction',
      'StateAction',
      'session/',
      'Session channel actions.',
    ),
    SyntheticUnion(
      'TerminalAction',
      'StateAction',
      'terminal/',
      'Terminal channel actions.',
    ),
    SyntheticUnion(
      'ChangesetAction',
      'StateAction',
      'changeset/',
      'Changeset channel actions.',
    ),
    SyntheticUnion(
      'AnnotationsAction',
      'StateAction',
      'annotations/',
      'Annotations channel actions.',
    ),
    SyntheticUnion(
      'AutomationAction',
      'StateAction',
      'automation/',
      'Automation channel actions.',
    ),
    SyntheticUnion(
      'AutomationRunAction',
      'StateAction',
      'automationRun/',
      'Automation run channel actions.',
    ),
  ],
  patches: [
    SchemaPatch('StateAction lists an empty `#/\$defs/` reference.', (defs) {
      final oneOf = (defs['StateAction']!['oneOf']! as List)
          .cast<Map<String, Object?>>();
      final before = oneOf.length;
      oneOf.removeWhere((m) => m[r'$ref'] == r'#/$defs/');
      if (oneOf.length == before) {
        throw StateError('StateAction has no empty reference; drop the patch');
      }
    }),
    SchemaPatch(
      'ChatToolCallApprovedAction/DeniedAction.approved lost their `true` / '
      '`false` literal types, so chat/toolCallConfirmed has no discriminator.',
      (defs) {
        _setApprovedConst(defs, 'ChatToolCallApprovedAction', true);
        _setApprovedConst(defs, 'ChatToolCallDeniedAction', false);
      },
    ),
  ],
);
