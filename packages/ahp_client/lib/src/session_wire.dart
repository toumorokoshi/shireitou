/// Wire types for the AHP session channel (AHP-024), modeled on protocol
/// 1.0.0 (`types/channels-session/` in `@microsoft/agent-host-protocol@1.0.0`).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_wire.dart';
import 'session_status.dart';
import 'wire.dart';

part 'session_wire.freezed.dart';
part 'session_wire.g.dart';

/// `SessionState`: the state of one session channel.
@freezed
abstract class SessionState with _$SessionState {
  /// Creates a [SessionState].
  const factory SessionState({
    /// Agent provider ID.
    required String provider,

    /// Session title.
    required String title,

    /// Session status bitset. pi keeps the live status on the default chat
    /// and the catalogue summary instead.
    @SessionStatusConverter() required SessionStatus status,

    /// `creating`, `ready` or `failed`.
    required String lifecycle,

    /// Ordered chat catalogue.
    @Default(<SessionChatSummary>[]) List<SessionChatSummary> chats,

    /// Clients that contribute tools (passed through).
    @Default(<JsonMap>[]) List<JsonMap> activeClients,

    /// Why creation failed (`failed` only).
    ErrorInfo? creationError,

    /// What the session is doing.
    String? activity,

    /// Server-owned project.
    ProjectInfo? project,

    /// Working directory URIs; the first is the primary one.
    List<String>? workingDirectories,

    /// Chat that receives input when none is selected.
    String? defaultChat,

    /// Session config schema and values (passed through).
    JsonMap? config,

    /// Session-level input requests (passed through).
    List<JsonMap>? inputNeeded,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _SessionState;

  /// Decodes a [SessionState] from JSON.
  factory SessionState.fromJson(JsonMap json) => _$SessionStateFromJson(json);
}

/// The chat a session sends input to: `defaultChat`, else the first chat.
String? defaultChatOf(SessionState state) =>
    state.defaultChat ?? state.chats.firstOrNull?.resource;

/// Session-channel actions (`SessionAction` in protocol 1.0.0).
///
/// Actions this client does not reduce (customizations, MCP servers,
/// changesets, server tools, working directories) decode as
/// [SessionAction.unknown] and leave the state unchanged.
@Freezed(unionKey: 'type', fallbackUnion: 'unknown')
sealed class SessionAction with _$SessionAction {
  /// `session/ready`: creation finished.
  @FreezedUnionValue('session/ready')
  const factory SessionAction.ready() = SessionReady;

  /// `session/creationFailed`: creation failed.
  @FreezedUnionValue('session/creationFailed')
  const factory SessionAction.creationFailed({
    /// The error.
    required ErrorInfo error,
  }) = SessionCreationFailed;

  /// `session/chatAdded`: adds or replaces a chat.
  @FreezedUnionValue('session/chatAdded')
  const factory SessionAction.chatAdded({
    /// The chat.
    required SessionChatSummary summary,
  }) = SessionChatAdded;

  /// `session/chatRemoved`: removes a chat.
  @FreezedUnionValue('session/chatRemoved')
  const factory SessionAction.chatRemoved({
    /// Chat URI.
    required String chat,
  }) = SessionChatRemoved;

  /// `session/chatUpdated`: merges a partial `ChatSummary`.
  @FreezedUnionValue('session/chatUpdated')
  const factory SessionAction.chatUpdated({
    /// Chat URI.
    required String chat,

    /// Changed fields.
    required JsonMap changes,
  }) = SessionChatUpdated;

  /// `session/defaultChatChanged`: changes the default chat.
  @FreezedUnionValue('session/defaultChatChanged')
  const factory SessionAction.defaultChatChanged({
    /// The new default chat.
    String? defaultChat,
  }) = SessionDefaultChatChanged;

  /// `session/titleChanged`: renames the session.
  @FreezedUnionValue('session/titleChanged')
  const factory SessionAction.titleChanged({
    /// The new title.
    required String title,
  }) = SessionTitleChanged;

  /// `session/isReadChanged`: sets or clears `IsRead` (AHP-043).
  @FreezedUnionValue('session/isReadChanged')
  const factory SessionAction.isReadChanged({
    /// Whether the session is read.
    required bool isRead,
  }) = SessionIsReadChanged;

  /// `session/isArchivedChanged`: sets or clears `IsArchived` (AHP-043).
  @FreezedUnionValue('session/isArchivedChanged')
  const factory SessionAction.isArchivedChanged({
    /// Whether the session is archived.
    required bool isArchived,
  }) = SessionIsArchivedChanged;

  /// `session/activityChanged`: updates the activity text.
  @FreezedUnionValue('session/activityChanged')
  const factory SessionAction.activityChanged({
    /// New activity, or null when idle.
    String? activity,
  }) = SessionActivityChanged;

  /// `session/configChanged`: merges (or replaces) config values.
  @FreezedUnionValue('session/configChanged')
  const factory SessionAction.configChanged({
    /// The changed values.
    required JsonMap config,

    /// Replace all values instead of merging.
    bool? replace,
  }) = SessionConfigChanged;

  /// An action this client version does not reduce.
  const factory SessionAction.unknown({
    /// The action's `type`.
    required String type,
  }) = SessionUnknownAction;

  /// Decodes a [SessionAction] from JSON.
  factory SessionAction.fromJson(JsonMap json) => _$SessionActionFromJson(json);
}
