/// Wire types for the AHP root channel and session catalogue, modeled on
/// protocol 1.0.0 (`@microsoft/agent-host-protocol@1.0.0`, `types/`).
///
/// Only the fields shireitou reads are modeled. Structures the client passes
/// through without interpreting (config schemas, protected resources,
/// terminals) are kept as raw JSON maps.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'session_status.dart';

part 'wire.freezed.dart';
part 'wire.g.dart';

/// A JSON object as decoded from the wire.
typedef JsonMap = Map<String, Object?>;

/// `Implementation`: the name and version of a client or server.
@freezed
abstract class Implementation with _$Implementation {
  /// Creates an [Implementation].
  const factory Implementation({
    /// Machine-readable name, e.g. `pi-agent-host-protocol`.
    required String name,

    /// Version string.
    String? version,

    /// Human-readable title.
    String? title,
  }) = _Implementation;

  /// Decodes an [Implementation] from JSON.
  factory Implementation.fromJson(JsonMap json) =>
      _$ImplementationFromJson(json);
}

/// `ProjectInfo`: the server-owned project a session belongs to.
@freezed
abstract class ProjectInfo with _$ProjectInfo {
  /// Creates a [ProjectInfo].
  const factory ProjectInfo({
    /// Project URI.
    required String uri,

    /// Human-readable project name.
    required String displayName,
  }) = _ProjectInfo;

  /// Decodes a [ProjectInfo] from JSON.
  factory ProjectInfo.fromJson(JsonMap json) => _$ProjectInfoFromJson(json);
}

/// `ChangesSummary`: aggregate file-change counts for a session.
@freezed
abstract class ChangesSummary with _$ChangesSummary {
  /// Creates a [ChangesSummary].
  const factory ChangesSummary({
    /// Total inserted lines across all changed files.
    int? additions,

    /// Total deleted lines across all changed files.
    int? deletions,

    /// Number of files that have changes.
    int? files,
  }) = _ChangesSummary;

  /// Decodes a [ChangesSummary] from JSON.
  factory ChangesSummary.fromJson(JsonMap json) =>
      _$ChangesSummaryFromJson(json);
}

/// `ChatSummary`: a chat entry in a session's catalogue entry or in
/// `SessionState.chats`.
@freezed
abstract class SessionChatSummary with _$SessionChatSummary {
  /// Creates a [SessionChatSummary].
  const factory SessionChatSummary({
    /// Canonical chat URI.
    required String resource,

    /// Human-readable chat title.
    required String title,

    /// `full`, `readOnly` or `hidden`; absent means `full`.
    String? interactivity,

    /// Chat status bits; absent means unknown.
    @SessionStatusConverter() SessionStatus? status,

    /// What the chat is doing.
    String? activity,

    /// Last modification time (ISO 8601).
    String? modifiedAt,
  }) = _SessionChatSummary;

  /// Decodes a [SessionChatSummary] from JSON.
  factory SessionChatSummary.fromJson(JsonMap json) =>
      _$SessionChatSummaryFromJson(json);
}

/// `SessionSummary`: one entry of the root-channel session catalogue.
///
/// Surfaced by `listSessions`, `root/sessionAdded` and (as a partial)
/// `root/sessionSummaryChanged`.
@freezed
abstract class SessionSummary with _$SessionSummary {
  /// Creates a [SessionSummary].
  const factory SessionSummary({
    /// Session URI. Treat as opaque: hosts may use `ahp-session:/<id>` or
    /// their own scheme (pi uses `pi:/<id>`).
    required String resource,

    /// Agent provider ID.
    required String provider,

    /// Session title.
    required String title,

    /// Session status bitset.
    @SessionStatusConverter() required SessionStatus status,

    /// Creation timestamp (ISO 8601).
    required String createdAt,

    /// Last modification timestamp (ISO 8601).
    required String modifiedAt,

    /// What the session is currently doing, e.g. `Running npm test`.
    String? activity,

    /// Server-owned project.
    ProjectInfo? project,

    /// Working directory URIs; the first is the primary one.
    List<String>? workingDirectories,

    /// Aggregate file-change counts.
    ChangesSummary? changes,

    /// Ordered chat catalogue.
    List<SessionChatSummary>? chats,

    /// Chat that receives input when none is selected.
    String? defaultChat,

    /// Server-defined presentation metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _SessionSummary;

  /// Decodes a [SessionSummary] from JSON.
  factory SessionSummary.fromJson(JsonMap json) =>
      _$SessionSummaryFromJson(json);
}

/// `SessionModelInfo`: a model offered by an agent.
@freezed
abstract class SessionModelInfo with _$SessionModelInfo {
  /// Creates a [SessionModelInfo].
  const factory SessionModelInfo({
    /// Model ID.
    required String id,

    /// Provider that serves the model.
    required String provider,

    /// Human-readable model name.
    required String name,

    /// Context window size in tokens.
    int? maxContextWindow,

    /// Whether the model accepts images.
    bool? supportsVision,

    /// `enabled`, `disabled` or `unconfigured`.
    String? policyState,

    /// Per-model config schema (passed through).
    JsonMap? configSchema,
  }) = _SessionModelInfo;

  /// Decodes a [SessionModelInfo] from JSON.
  factory SessionModelInfo.fromJson(JsonMap json) =>
      _$SessionModelInfoFromJson(json);
}

/// `AgentInfo`: an agent a host offers.
@freezed
abstract class AgentInfo with _$AgentInfo {
  /// Creates an [AgentInfo].
  const factory AgentInfo({
    /// Agent provider ID, used as `createSession.provider`.
    required String provider,

    /// Human-readable agent name.
    required String displayName,

    /// Agent description.
    required String description,

    /// Models the agent offers.
    @Default(<SessionModelInfo>[]) List<SessionModelInfo> models,

    /// RFC 9728 protected resources the agent needs tokens for.
    List<JsonMap>? protectedResources,

    /// Agent capabilities (passed through).
    JsonMap? capabilities,
  }) = _AgentInfo;

  /// Decodes an [AgentInfo] from JSON.
  factory AgentInfo.fromJson(JsonMap json) => _$AgentInfoFromJson(json);
}

/// `RootConfigState`: host-level configuration.
@freezed
abstract class RootConfigState with _$RootConfigState {
  /// Creates a [RootConfigState].
  const factory RootConfigState({
    /// JSON Schema for the values.
    required JsonMap schema,

    /// Current config values.
    required JsonMap values,
  }) = _RootConfigState;

  /// Decodes a [RootConfigState] from JSON.
  factory RootConfigState.fromJson(JsonMap json) =>
      _$RootConfigStateFromJson(json);
}

/// `RootState`: the state of the `ahp-root://` channel.
@freezed
abstract class RootState with _$RootState {
  /// Creates a [RootState].
  const factory RootState({
    /// Agents the host offers.
    @Default(<AgentInfo>[]) List<AgentInfo> agents,

    /// Number of sessions with a running turn.
    int? activeSessions,

    /// Host terminals (passed through).
    List<JsonMap>? terminals,

    /// Host configuration.
    RootConfigState? config,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _RootState;

  /// Decodes a [RootState] from JSON.
  factory RootState.fromJson(JsonMap json) => _$RootStateFromJson(json);
}

/// `Snapshot`: the state of one channel at `fromSeq`.
@freezed
abstract class Snapshot with _$Snapshot {
  /// Creates a [Snapshot].
  const factory Snapshot({
    /// The channel URI.
    required String resource,

    /// The channel state; decode it according to the channel kind.
    required JsonMap state,

    /// Server sequence the snapshot was taken at.
    required int fromSeq,
  }) = _Snapshot;

  /// Decodes a [Snapshot] from JSON.
  factory Snapshot.fromJson(JsonMap json) => _$SnapshotFromJson(json);
}

/// `InitializeResult`: the host's answer to `initialize`.
@freezed
abstract class InitializeResult with _$InitializeResult {
  /// Creates an [InitializeResult].
  const factory InitializeResult({
    /// The negotiated protocol version.
    required String protocolVersion,

    /// The host's current server sequence.
    required int serverSeq,

    /// Snapshots for `initialSubscriptions`.
    @Default(<Snapshot>[]) List<Snapshot> snapshots,

    /// Host name and version.
    Implementation? serverInfo,

    /// Default working directory URI for new sessions.
    String? defaultDirectory,

    /// Characters that trigger `completions` in the composer.
    List<String>? completionTriggerCharacters,

    /// Prefix that marks a composer message as a terminal command.
    String? terminalCommandPrefix,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _InitializeResult;

  /// Decodes an [InitializeResult] from JSON.
  factory InitializeResult.fromJson(JsonMap json) =>
      _$InitializeResultFromJson(json);
}

/// `ListSessionsResult`: one page of the session catalogue.
@freezed
abstract class ListSessionsResult with _$ListSessionsResult {
  /// Creates a [ListSessionsResult].
  const factory ListSessionsResult({
    /// The sessions on this page.
    required List<SessionSummary> items,

    /// Cursor for the next page; absent on the last page.
    String? nextCursor,
  }) = _ListSessionsResult;

  /// Decodes a [ListSessionsResult] from JSON.
  factory ListSessionsResult.fromJson(JsonMap json) =>
      _$ListSessionsResultFromJson(json);
}

/// `ActionOrigin`: the client and client sequence that dispatched an action.
@freezed
abstract class ActionOrigin with _$ActionOrigin {
  /// Creates an [ActionOrigin].
  const factory ActionOrigin({
    /// The dispatching client's ID.
    required String clientId,

    /// The client's sequence number for the action.
    required int clientSeq,
  }) = _ActionOrigin;

  /// Decodes an [ActionOrigin] from JSON.
  factory ActionOrigin.fromJson(JsonMap json) => _$ActionOriginFromJson(json);
}

/// `ActionEnvelope`: one ordered action on a channel.
@freezed
abstract class ActionEnvelope with _$ActionEnvelope {
  /// Creates an [ActionEnvelope].
  const factory ActionEnvelope({
    /// Channel URI the action belongs to.
    required String channel,

    /// The raw action; its `type` field selects the variant.
    required JsonMap action,

    /// The host's sequence number for this action.
    required int serverSeq,

    /// Who dispatched it; absent for host-originated actions.
    ActionOrigin? origin,

    /// Set when the host rejected a client-dispatched action.
    String? rejectionReason,
  }) = _ActionEnvelope;

  /// Decodes an [ActionEnvelope] from JSON.
  factory ActionEnvelope.fromJson(JsonMap json) =>
      _$ActionEnvelopeFromJson(json);
}

/// `ReconnectResult`: either replayed actions or fresh snapshots.
@Freezed(unionKey: 'type')
sealed class ReconnectResult with _$ReconnectResult {
  /// The host replayed the actions since `lastSeenServerSeq`.
  const factory ReconnectResult.replay({
    /// Actions to apply, in order.
    required List<ActionEnvelope> actions,

    /// Requested channels the host no longer has.
    @Default(<String>[]) List<String> missing,
  }) = ReconnectReplay;

  /// The gap was too large; the host sent fresh snapshots.
  const factory ReconnectResult.snapshot({
    /// Snapshots for the requested subscriptions.
    required List<Snapshot> snapshots,
  }) = ReconnectSnapshot;

  /// Decodes a [ReconnectResult] from JSON.
  factory ReconnectResult.fromJson(JsonMap json) =>
      _$ReconnectResultFromJson(json);
}

/// Root-channel actions (`RootAction` in protocol 1.0.0).
@Freezed(unionKey: 'type', fallbackUnion: 'unknown')
sealed class RootAction with _$RootAction {
  /// `root/agentsChanged`: replaces the agent list.
  @FreezedUnionValue('root/agentsChanged')
  const factory RootAction.agentsChanged({
    /// The new agent list.
    required List<AgentInfo> agents,
  }) = RootAgentsChanged;

  /// `root/activeSessionsChanged`: updates the active-session count.
  @FreezedUnionValue('root/activeSessionsChanged')
  const factory RootAction.activeSessionsChanged({
    /// Number of sessions with a running turn.
    required int activeSessions,
  }) = RootActiveSessionsChanged;

  /// `root/terminalsChanged`: replaces the terminal list.
  @FreezedUnionValue('root/terminalsChanged')
  const factory RootAction.terminalsChanged({
    /// The new terminal list (passed through).
    required List<JsonMap> terminals,
  }) = RootTerminalsChanged;

  /// `root/configChanged`: merges (or replaces) config values.
  @FreezedUnionValue('root/configChanged')
  const factory RootAction.configChanged({
    /// The changed values.
    required JsonMap config,

    /// Replace all values instead of merging.
    bool? replace,
  }) = RootConfigChanged;

  /// An action this client version does not know; ignored by reducers.
  const factory RootAction.unknown({
    /// The action's `type`.
    required String type,
  }) = RootUnknownAction;

  /// Decodes a [RootAction] from JSON.
  factory RootAction.fromJson(JsonMap json) => _$RootActionFromJson(json);
}
