/// What the negotiated protocol version supports, and how the client
/// degrades when a host negotiates `0.9.0` instead of `1.0.0`.
///
/// The lists below come from diffing the TypeScript sources of
/// `@microsoft/agent-host-protocol@0.9.0` and `@1.0.0` (see
/// `specs/agent-host-protocol-client.md`, "0.9.0 compatibility"). The
/// protocol's own `ACTION_INTRODUCED_IN` registry dates some of these
/// actions `0.9.0` or `0.10.0`, but none of them is in the 0.9.0 release,
/// so the release diff is what counts.
library;

/// Compares two `MAJOR.MINOR.PATCH` versions: negative when [a] < [b],
/// zero when equal, positive when [a] > [b]. Missing or non-numeric parts
/// count as 0.
int compareProtocolVersions(String a, String b) {
  List<int> parse(String v) => [
    for (final part in v.split('.')) int.tryParse(part) ?? 0,
    0,
    0,
  ].take(3).toList();
  final (x, y) = (parse(a), parse(b));
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i] - y[i];
  }
  return 0;
}

/// The first release with every 1.0.0 addition.
const protocolVersion100 = '1.0.0';

/// Action types in protocol 1.0.0 that 0.9.0 does not have.
const actionsAddedIn100 = <String>{
  'chat/backgroundWorkSet',
  'chat/backgroundWorkRemoved',
  'chat/canvasesChanged',
  'chat/changesetsChanged',
  'chat/isArchivedChanged',
  'chat/isReadChanged',
  'chat/movableChanged',
  'canvas/stateChanged',
  'session/chatsReordered',
  'session/mcpServerBackgroundRequested',
};

/// Commands in protocol 1.0.0 that 0.9.0 does not have.
const commandsAddedIn100 = <String>{'moveChat'};

/// The protocol version that introduced the action [type], as far as this
/// client knows: `1.0.0` for [actionsAddedIn100], else `0.9.0` (the oldest
/// version the client offers).
String actionIntroducedIn(String type) =>
    actionsAddedIn100.contains(type) ? protocolVersion100 : '0.9.0';

/// Whether [version] knows the action [type]. A null [version] (not yet
/// negotiated) is treated as the target version, which knows every action.
bool isActionKnownToVersion(String type, String? version) =>
    version == null ||
    compareProtocolVersions(actionIntroducedIn(type), version) <= 0;

/// A 1.0.0 feature that a client must not rely on when an older version
/// is negotiated. [label] is short user-facing text.
enum ProtocolFeature {
  /// `SessionSummary.chats` and `SessionSummary.defaultChat`: the chat list
  /// without subscribing to the session.
  sessionSummaryChats('chat list in the session catalogue'),

  /// `SessionChatSummary.status`/`changes` and `chat/isReadChanged`: per-chat
  /// read state and change counts.
  chatReadState('read state per chat'),

  /// `chat/isArchivedChanged`: archiving one chat without its session.
  chatArchive('archiving single chats'),

  /// `ChatState.backgroundWork` and `chat/backgroundWork*`: background
  /// shells and subagents.
  backgroundWork('background shells and subagents'),

  /// `ChatState.changesets`/`changes`, `ChatSummary.changes` and
  /// `chat/changesetsChanged`: changesets and change counts per chat.
  chatChangesets('changes per chat'),

  /// `moveChat`, `ChatState.movable` and `chat/movableChanged`.
  moveChat('moving chats between sessions'),

  /// `session/chatsReordered`: reordering a session's chats.
  reorderChats('reordering chats'),

  /// `ChatState.canvases`, `chat/canvasesChanged` and the canvas channel.
  canvases('canvases'),

  /// `McpServerStartingState.blocking` and
  /// `session/mcpServerBackgroundRequested`.
  mcpBackgroundStartup('backgrounding a blocking MCP server start'),

  /// `AuthenticateParams.expiresIn`: token lifetimes.
  tokenExpiry('token expiry in authenticate'),

  /// `ChangesetStatus.recomputing`.
  changesetRecomputing('changeset recomputing status'),

  /// `ConfigPropertySchema.minItems` / `maxItems`.
  configArrayBounds('array size limits in config forms'),

  /// Automation `disableConditions`, `runCount` and `customizations`.
  automationLimits('automation run limits and plugins');

  const ProtocolFeature(this.label);

  /// Short user-facing description.
  final String label;

  /// The protocol version that introduced the feature.
  String get introducedIn => protocolVersion100;
}

/// Whether [version] supports [feature]. A null [version] is treated as the
/// target version.
bool supportsFeature(String? version, ProtocolFeature feature) =>
    version == null ||
    compareProtocolVersions(feature.introducedIn, version) <= 0;

/// The features [version] lacks, in declaration order; empty for 1.0.0 and
/// later (and for a version not negotiated yet).
List<ProtocolFeature> unavailableFeatures(String? version) => [
  for (final feature in ProtocolFeature.values)
    if (!supportsFeature(version, feature)) feature,
];

/// Thrown by `AhpClient.dispatch` for an action the negotiated protocol
/// version does not know (the host would reject or misread it).
class UnsupportedActionError extends StateError {
  /// Creates an [UnsupportedActionError] for [type] under [version].
  UnsupportedActionError(this.type, this.version)
    : super(
        '$type needs protocol ${actionIntroducedIn(type)}; '
        'the host negotiated $version',
      );

  /// The action type.
  final String type;

  /// The negotiated protocol version.
  final String version;
}
