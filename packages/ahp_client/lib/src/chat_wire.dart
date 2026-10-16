/// Wire types for the AHP chat channel (`ahp-chat:` URIs, AHP-025), modeled
/// on protocol 1.0.0 (`types/channels-chat/` in
/// `@microsoft/agent-host-protocol@1.0.0`).
///
/// The protocol's seven `ToolCallState` variants are flattened into one
/// [ToolCall] class keyed by [ToolCall.status]; fields that do not apply to a
/// status are null. Structures the client only displays (tool result content,
/// input answers, risk assessments, file edits) are kept as raw JSON maps.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'session_status.dart';
import 'wire.dart';

part 'chat_wire.freezed.dart';
part 'chat_wire.g.dart';

/// Returns the text of a `StringOrMarkdown` value (`string` or
/// `{ markdown: string }`), or null when [value] is neither.
String? stringOrMarkdownText(Object? value) => switch (value) {
  final String text => text,
  {'markdown': final String markdown} => markdown,
  _ => null,
};

/// `ModelSelection`: a model chosen for a message.
@freezed
abstract class ModelSelection with _$ModelSelection {
  /// Creates a [ModelSelection].
  const factory ModelSelection({
    /// Model ID from `SessionModelInfo.id`.
    required String id,

    /// Per-model config values, e.g. `{thinkingLevel: 'low'}`.
    JsonMap? config,
  }) = _ModelSelection;

  /// Decodes a [ModelSelection] from JSON.
  factory ModelSelection.fromJson(JsonMap json) =>
      _$ModelSelectionFromJson(json);
}

/// `MessageOrigin`: who wrote a message.
@freezed
abstract class MessageOrigin with _$MessageOrigin {
  /// Creates a [MessageOrigin].
  const factory MessageOrigin({
    /// `user`, `agent`, `tool`, `automation` or `systemNotification`.
    required String kind,
  }) = _MessageOrigin;

  /// Decodes a [MessageOrigin] from JSON.
  factory MessageOrigin.fromJson(JsonMap json) => _$MessageOriginFromJson(json);
}

/// `Message`: the input that starts a turn.
@freezed
abstract class Message with _$Message {
  /// Creates a [Message].
  const factory Message({
    /// Message text.
    required String text,

    /// Who wrote it.
    required MessageOrigin origin,

    /// Attachments (passed through).
    List<JsonMap>? attachments,

    /// Model to run the turn with; absent means the host's default.
    ModelSelection? model,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _Message;

  /// Decodes a [Message] from JSON.
  factory Message.fromJson(JsonMap json) => _$MessageFromJson(json);
}

/// Builds a user [Message] with [text], optionally for [model].
Message userMessage(String text, {ModelSelection? model}) => Message(
  text: text,
  origin: const MessageOrigin(kind: 'user'),
  model: model,
);

/// `UsageInfo`: token usage for a turn.
@freezed
abstract class UsageInfo with _$UsageInfo {
  /// Creates a [UsageInfo].
  const factory UsageInfo({
    /// Input tokens.
    int? inputTokens,

    /// Output tokens.
    int? outputTokens,

    /// Model that served the turn.
    String? model,

    /// Input tokens read from the prompt cache.
    int? cacheReadTokens,
  }) = _UsageInfo;

  /// Decodes a [UsageInfo] from JSON.
  factory UsageInfo.fromJson(JsonMap json) => _$UsageInfoFromJson(json);
}

/// `ErrorInfo`: an error reported by the host.
@freezed
abstract class ErrorInfo with _$ErrorInfo {
  /// Creates an [ErrorInfo].
  const factory ErrorInfo({
    /// Error category, e.g. `model`.
    required String errorType,

    /// Human-readable message.
    required String message,

    /// Stack trace, when the host sends one.
    String? stack,
  }) = _ErrorInfo;

  /// Decodes an [ErrorInfo] from JSON.
  factory ErrorInfo.fromJson(JsonMap json) => _$ErrorInfoFromJson(json);
}

/// `ToolCallStatus`: the lifecycle state of a tool call.
enum ToolCallStatus {
  /// The model is still streaming the tool's input.
  @JsonValue('streaming')
  streaming,

  /// The tool waits for the user to approve or deny it.
  @JsonValue('pending-confirmation')
  pendingConfirmation,

  /// The tool is running.
  @JsonValue('running')
  running,

  /// An MCP tool needs the user to authenticate.
  @JsonValue('auth-required')
  authRequired,

  /// The tool finished and its result waits for the user's approval.
  @JsonValue('pending-result-confirmation')
  pendingResultConfirmation,

  /// The tool finished.
  @JsonValue('completed')
  completed,

  /// The tool was denied, skipped or its result was rejected.
  @JsonValue('cancelled')
  cancelled,

  /// A status this client version does not know.
  unknown,
}

/// `ConfirmationOption`: a host-provided approve/deny choice.
@freezed
abstract class ConfirmationOption with _$ConfirmationOption {
  /// Creates a [ConfirmationOption].
  const factory ConfirmationOption({
    /// Option ID, sent back as `selectedOptionId`.
    required String id,

    /// Button label.
    required String label,

    /// `approve` or `deny`.
    required String kind,

    /// Options with the same group are shown together.
    int? group,
  }) = _ConfirmationOption;

  /// Decodes a [ConfirmationOption] from JSON.
  factory ConfirmationOption.fromJson(JsonMap json) =>
      _$ConfirmationOptionFromJson(json);
}

/// `ToolCallState`, flattened: one tool call in a turn.
@freezed
abstract class ToolCall with _$ToolCall {
  /// Creates a [ToolCall].
  const factory ToolCall({
    /// Tool call ID, unique within the turn.
    required String toolCallId,

    /// Machine-readable tool name, e.g. `bash`.
    required String toolName,

    /// Human-readable tool name, e.g. `Bash`.
    required String displayName,

    /// Lifecycle status; selects which other fields apply.
    @JsonKey(unknownEnumValue: ToolCallStatus.unknown)
    required ToolCallStatus status,

    /// Why the model is calling the tool.
    String? intention,

    /// Who runs the tool (client or MCP server), passed through.
    JsonMap? contributor,

    /// Input JSON streamed so far (`streaming` only).
    String? partialInput,

    /// `StringOrMarkdown` describing the call, e.g. "Running `ls`".
    Object? invocationMessage,

    /// Tool input: a JSON string or a `ContentRef` map.
    Object? toolInput,

    /// `StringOrMarkdown` title for the approval prompt.
    Object? confirmationTitle,

    /// Risk assessment for the approval prompt (passed through).
    JsonMap? riskAssessment,

    /// File edits the call would make (passed through).
    JsonMap? edits,

    /// Whether the user may edit [toolInput] before approving.
    bool? editable,

    /// Host-provided approve/deny choices.
    List<ConfirmationOption>? options,

    /// How the call was confirmed: `not-needed`, `user-action` or `setting`.
    String? confirmed,

    /// The option the user chose.
    ConfirmationOption? selectedOption,

    /// Result content (text, terminals, file edits, ...), passed through.
    List<JsonMap>? content,

    /// Whether the tool succeeded (finished statuses only).
    bool? success,

    /// `StringOrMarkdown` past-tense summary, e.g. "Ran `ls`".
    Object? pastTenseMessage,

    /// Structured result (passed through).
    JsonMap? structuredContent,

    /// Tool error: `{message, code?}`.
    JsonMap? error,

    /// Authentication the tool needs (`auth-required` only).
    JsonMap? auth,

    /// Why the call was cancelled: `denied`, `skipped` or `result-denied`.
    String? reason,

    /// `StringOrMarkdown` explanation of the cancellation.
    Object? reasonMessage,

    /// A message the user sent instead of approving.
    Message? userSuggestion,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _ToolCall;

  /// Decodes a [ToolCall] from JSON.
  factory ToolCall.fromJson(JsonMap json) => _$ToolCallFromJson(json);
}

/// `ChatInputOption`: one choice of a select question.
@freezed
abstract class ChatInputOption with _$ChatInputOption {
  /// Creates a [ChatInputOption].
  const factory ChatInputOption({
    /// Option ID, sent back in the answer.
    required String id,

    /// Option label.
    required String label,

    /// Longer description.
    String? description,

    /// Whether this is the suggested choice.
    bool? recommended,
  }) = _ChatInputOption;

  /// Decodes a [ChatInputOption] from JSON.
  factory ChatInputOption.fromJson(JsonMap json) =>
      _$ChatInputOptionFromJson(json);
}

/// `ChatInputQuestion`, flattened: one question of an input request.
@freezed
abstract class ChatInputQuestion with _$ChatInputQuestion {
  /// Creates a [ChatInputQuestion].
  const factory ChatInputQuestion({
    /// Question ID; the key of its answer.
    required String id,

    /// `text`, `number`, `integer`, `boolean`, `single-select` or
    /// `multi-select`.
    required String kind,

    /// Question text.
    required String message,

    /// Short title.
    String? title,

    /// Whether an answer is required.
    bool? required,

    /// Choices for select questions.
    List<ChatInputOption>? options,

    /// Whether select questions also accept free text.
    bool? allowFreeformInput,

    /// Text format hint, e.g. `email` (text questions).
    String? format,

    /// Minimum length, value or selection count.
    num? min,

    /// Maximum length, value or selection count.
    num? max,

    /// Default answer (string, number or boolean).
    Object? defaultValue,
  }) = _ChatInputQuestion;

  /// Decodes a [ChatInputQuestion] from JSON.
  factory ChatInputQuestion.fromJson(JsonMap json) =>
      _$ChatInputQuestionFromJson(json);
}

/// `ChatInputRequest`: an elicitation the agent is waiting on (AHP-042).
@freezed
abstract class ChatInputRequest with _$ChatInputRequest {
  /// Creates a [ChatInputRequest].
  const factory ChatInputRequest({
    /// Request ID.
    required String id,

    /// Text shown above the questions.
    String? message,

    /// A URL the user should open instead of answering questions.
    String? url,

    /// The questions to answer.
    List<ChatInputQuestion>? questions,

    /// Draft or submitted answers keyed by question ID (`ChatInputAnswer`).
    Map<String, JsonMap>? answers,
  }) = _ChatInputRequest;

  /// Decodes a [ChatInputRequest] from JSON.
  factory ChatInputRequest.fromJson(JsonMap json) =>
      _$ChatInputRequestFromJson(json);
}

/// `ResponsePart`: one piece of a turn's response.
@Freezed(unionKey: 'kind', fallbackUnion: 'unknown')
sealed class ResponsePart with _$ResponsePart {
  /// Markdown text, extended by `chat/delta`.
  const factory ResponsePart.markdown({
    /// Part ID, addressed by `chat/delta`.
    required String id,

    /// Markdown text so far.
    required String content,
  }) = MarkdownPart;

  /// Model reasoning, extended by `chat/reasoning`.
  const factory ResponsePart.reasoning({
    /// Part ID, addressed by `chat/reasoning`.
    required String id,

    /// Reasoning text so far.
    required String content,
  }) = ReasoningPart;

  /// A tool call.
  const factory ResponsePart.toolCall({
    /// The tool call's state.
    required ToolCall toolCall,
  }) = ToolCallPart;

  /// An input request (elicitation).
  const factory ResponsePart.inputRequest({
    /// The request.
    required ChatInputRequest request,

    /// `accept`, `decline` or `cancel` once answered.
    String? response,
  }) = InputRequestPart;

  /// A turn error.
  const factory ResponsePart.error({
    /// The error.
    required ErrorInfo error,

    /// Whether `chat/turnResume` can continue the turn.
    bool? resumable,
  }) = ErrorPart;

  /// A system notification shown inline.
  const factory ResponsePart.systemNotification({
    /// `StringOrMarkdown` content.
    Object? content,
  }) = SystemNotificationPart;

  /// A reference to content (file, image, ...).
  const factory ResponsePart.contentRef({
    /// Content URI.
    required String uri,

    /// MIME type.
    String? contentType,
  }) = ContentRefPart;

  /// A part kind this client version does not know.
  const factory ResponsePart.unknown({
    /// The part's `kind`.
    required String kind,
  }) = UnknownPart;

  /// Decodes a [ResponsePart] from JSON.
  factory ResponsePart.fromJson(JsonMap json) => _$ResponsePartFromJson(json);
}

/// `TurnState`: how a finished turn ended.
enum TurnState {
  /// Finished normally.
  @JsonValue('complete')
  complete,

  /// Cancelled by the user.
  @JsonValue('cancelled')
  cancelled,

  /// Ended with an error.
  @JsonValue('error')
  error,
}

/// `Turn`: a finished request/response pair.
@freezed
abstract class Turn with _$Turn {
  /// Creates a [Turn].
  const factory Turn({
    /// Turn ID.
    required String id,

    /// The message that started the turn.
    required Message message,

    /// Response parts in order.
    required List<ResponsePart> responseParts,

    /// How the turn ended.
    required TurnState state,

    /// Start time (ISO 8601).
    String? startedAt,

    /// Duration in milliseconds.
    int? duration,

    /// Token usage.
    UsageInfo? usage,
  }) = _Turn;

  /// Decodes a [Turn] from JSON.
  factory Turn.fromJson(JsonMap json) => _$TurnFromJson(json);
}

/// `ActiveTurn`: the turn that is running.
@freezed
abstract class ActiveTurn with _$ActiveTurn {
  /// Creates an [ActiveTurn].
  const factory ActiveTurn({
    /// Turn ID.
    required String id,

    /// Start time (ISO 8601).
    required String startedAt,

    /// The message that started the turn.
    required Message message,

    /// Response parts so far.
    required List<ResponsePart> responseParts,

    /// Token usage so far.
    UsageInfo? usage,
  }) = _ActiveTurn;

  /// Decodes an [ActiveTurn] from JSON.
  factory ActiveTurn.fromJson(JsonMap json) => _$ActiveTurnFromJson(json);
}

/// `PendingMessage`: a steering or queued message.
@freezed
abstract class PendingMessage with _$PendingMessage {
  /// Creates a [PendingMessage].
  const factory PendingMessage({
    /// Pending message ID.
    required String id,

    /// The message.
    required Message message,
  }) = _PendingMessage;

  /// Decodes a [PendingMessage] from JSON.
  factory PendingMessage.fromJson(JsonMap json) =>
      _$PendingMessageFromJson(json);
}

/// `ChatState`: the state of one chat channel.
@freezed
abstract class ChatState with _$ChatState {
  /// Creates a [ChatState].
  const factory ChatState({
    /// Chat URI.
    required String resource,

    /// Chat title.
    required String title,

    /// Chat status bitset.
    @SessionStatusConverter() required SessionStatus status,

    /// Last modification time (ISO 8601).
    required String modifiedAt,

    /// Finished turns, oldest first.
    @Default(<Turn>[]) List<Turn> turns,

    /// What the chat is doing, e.g. `Running ls`.
    String? activity,

    /// The running turn.
    ActiveTurn? activeTurn,

    /// Cursor for `fetchTurns`; absent when all turns are loaded.
    String? turnsNextCursor,

    /// A message delivered to the agent at its next step.
    PendingMessage? steeringMessage,

    /// Messages that start turns after the current one, in order.
    List<PendingMessage>? queuedMessages,

    /// Working directory URIs.
    List<String>? workingDirectories,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = _ChatState;

  /// Decodes a [ChatState] from JSON.
  factory ChatState.fromJson(JsonMap json) => _$ChatStateFromJson(json);
}

/// Chat-channel actions (`ChatAction` in protocol 1.0.0).
///
/// Actions this client does not reduce (background work, changesets,
/// canvases, MCP auth, working directories) decode as
/// [ChatAction.unknown] and leave the state unchanged.
@Freezed(unionKey: 'type', fallbackUnion: 'unknown')
sealed class ChatAction with _$ChatAction {
  /// `chat/turnStarted`: starts a turn. Dispatched by clients to send a
  /// message (AHP-041).
  @FreezedUnionValue('chat/turnStarted')
  const factory ChatAction.turnStarted({
    /// New turn ID (client-chosen when dispatched by a client).
    required String turnId,

    /// Start time (ISO 8601).
    required String startedAt,

    /// The message.
    required Message message,

    /// The pending message this turn consumes, if any.
    String? queuedMessageId,
  }) = ChatTurnStarted;

  /// `chat/delta`: appends to a markdown part.
  @FreezedUnionValue('chat/delta')
  const factory ChatAction.delta({
    /// Turn ID.
    required String turnId,

    /// Markdown part ID.
    required String partId,

    /// Text to append.
    required String content,
  }) = ChatDelta;

  /// `chat/reasoning`: appends to a reasoning part.
  @FreezedUnionValue('chat/reasoning')
  const factory ChatAction.reasoning({
    /// Turn ID.
    required String turnId,

    /// Reasoning part ID.
    required String partId,

    /// Text to append.
    required String content,
  }) = ChatReasoning;

  /// `chat/responsePart`: adds a response part.
  @FreezedUnionValue('chat/responsePart')
  const factory ChatAction.responsePart({
    /// Turn ID.
    required String turnId,

    /// The new part.
    required ResponsePart part,
  }) = ChatResponsePart;

  /// `chat/toolCallStart`: adds a streaming tool call.
  @FreezedUnionValue('chat/toolCallStart')
  const factory ChatAction.toolCallStart({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// Tool name.
    required String toolName,

    /// Tool display name.
    required String displayName,

    /// Why the model is calling the tool.
    String? intention,

    /// Who runs the tool (passed through).
    JsonMap? contributor,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallStart;

  /// `chat/toolCallDelta`: streams tool input.
  @FreezedUnionValue('chat/toolCallDelta')
  const factory ChatAction.toolCallDelta({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// Input JSON to append.
    String? content,

    /// Updated `StringOrMarkdown` invocation message.
    Object? invocationMessage,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallDelta;

  /// `chat/toolCallReady`: input is complete; the call runs or waits for
  /// confirmation.
  @FreezedUnionValue('chat/toolCallReady')
  const factory ChatAction.toolCallReady({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// `StringOrMarkdown` invocation message.
    required Object invocationMessage,

    /// Tool input.
    Object? toolInput,

    /// Why the model is calling the tool.
    String? intention,

    /// Who runs the tool (passed through).
    JsonMap? contributor,

    /// `StringOrMarkdown` approval title.
    Object? confirmationTitle,

    /// Risk assessment (passed through).
    JsonMap? riskAssessment,

    /// File edits (passed through).
    JsonMap? edits,

    /// Whether the input is editable before approval.
    bool? editable,

    /// Set when no confirmation is needed; the call starts running.
    String? confirmed,

    /// Approve/deny choices.
    List<ConfirmationOption>? options,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallReady;

  /// `chat/toolCallConfirmed`: the user approved or denied a tool call
  /// (AHP-041).
  @FreezedUnionValue('chat/toolCallConfirmed')
  const factory ChatAction.toolCallConfirmed({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// Whether the call was approved.
    required bool approved,

    /// When approved: `user-action` or `setting`.
    String? confirmed,

    /// When denied: `denied` or `skipped`.
    String? reason,

    /// Replacement input, when approved with edits.
    String? editedToolInput,

    /// The chosen host-provided option.
    String? selectedOptionId,

    /// `StringOrMarkdown` explanation of a denial.
    Object? reasonMessage,

    /// A message to send instead, when denied.
    Message? userSuggestion,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallConfirmed;

  /// `chat/toolCallComplete`: the tool finished.
  @FreezedUnionValue('chat/toolCallComplete')
  const factory ChatAction.toolCallComplete({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// `ToolCallResult`: `success`, `pastTenseMessage`, `content`, ...
    required JsonMap result,

    /// Whether the result waits for the user's approval.
    bool? requiresResultConfirmation,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallComplete;

  /// `chat/toolCallResultConfirmed`: the user approved or rejected a
  /// result.
  @FreezedUnionValue('chat/toolCallResultConfirmed')
  const factory ChatAction.toolCallResultConfirmed({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// Whether the result was approved.
    required bool approved,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallResultConfirmed;

  /// `chat/toolCallContentChanged`: live output of a running tool.
  @FreezedUnionValue('chat/toolCallContentChanged')
  const factory ChatAction.toolCallContentChanged({
    /// Turn ID.
    required String turnId,

    /// Tool call ID.
    required String toolCallId,

    /// The tool's content so far.
    required List<JsonMap> content,

    /// Server-defined metadata.
    @JsonKey(name: '_meta') JsonMap? meta,
  }) = ChatToolCallContentChanged;

  /// `chat/turnComplete`: the turn finished.
  @FreezedUnionValue('chat/turnComplete')
  const factory ChatAction.turnComplete({
    /// Turn ID.
    required String turnId,

    /// Duration in milliseconds.
    required int duration,
  }) = ChatTurnComplete;

  /// `chat/turnCancelled`: the turn was cancelled. Dispatched by clients to
  /// stop a turn (AV-082).
  @FreezedUnionValue('chat/turnCancelled')
  const factory ChatAction.turnCancelled({
    /// Turn ID.
    required String turnId,

    /// Duration in milliseconds.
    required int duration,
  }) = ChatTurnCancelled;

  /// `chat/error`: the turn failed.
  @FreezedUnionValue('chat/error')
  const factory ChatAction.error({
    /// Turn ID.
    required String turnId,

    /// Duration in milliseconds.
    required int duration,

    /// The [ErrorPart] appended to the turn.
    required ResponsePart part,
  }) = ChatError;

  /// `chat/turnResume`: continues a turn that ended with a resumable error.
  @FreezedUnionValue('chat/turnResume')
  const factory ChatAction.turnResume({
    /// Turn ID.
    required String turnId,
  }) = ChatTurnResume;

  /// `chat/activityChanged`: updates the activity text.
  @FreezedUnionValue('chat/activityChanged')
  const factory ChatAction.activityChanged({
    /// New activity, or null when idle.
    String? activity,
  }) = ChatActivityChanged;

  /// `chat/usage`: updates the active turn's token usage.
  @FreezedUnionValue('chat/usage')
  const factory ChatAction.usage({
    /// Turn ID.
    required String turnId,

    /// Usage so far.
    required UsageInfo usage,
  }) = ChatUsage;

  /// `chat/truncated`: drops turns after [turnId] (all turns when null).
  @FreezedUnionValue('chat/truncated')
  const factory ChatAction.truncated({
    /// Last turn to keep.
    String? turnId,
  }) = ChatTruncated;

  /// `chat/turnsLoaded`: older turns paged in by `fetchTurns`.
  @FreezedUnionValue('chat/turnsLoaded')
  const factory ChatAction.turnsLoaded({
    /// Older turns, oldest first.
    required List<Turn> turns,

    /// Cursor for the next page.
    String? turnsNextCursor,
  }) = ChatTurnsLoaded;

  /// `chat/pendingMessageSet`: adds or replaces a steering or queued
  /// message (AV-080).
  @FreezedUnionValue('chat/pendingMessageSet')
  const factory ChatAction.pendingMessageSet({
    /// `steering` or `queued`.
    required String kind,

    /// Pending message ID.
    required String id,

    /// The message.
    required Message message,
  }) = ChatPendingMessageSet;

  /// `chat/pendingMessageRemoved`: removes a steering or queued message.
  @FreezedUnionValue('chat/pendingMessageRemoved')
  const factory ChatAction.pendingMessageRemoved({
    /// `steering` or `queued`.
    required String kind,

    /// Pending message ID.
    required String id,
  }) = ChatPendingMessageRemoved;

  /// `chat/isReadChanged`: sets or clears the `IsRead` flag.
  @FreezedUnionValue('chat/isReadChanged')
  const factory ChatAction.isReadChanged({
    /// Whether the chat is read.
    required bool isRead,
  }) = ChatIsReadChanged;

  /// `chat/isArchivedChanged`: sets or clears the `IsArchived` flag.
  @FreezedUnionValue('chat/isArchivedChanged')
  const factory ChatAction.isArchivedChanged({
    /// Whether the chat is archived.
    required bool isArchived,
  }) = ChatIsArchivedChanged;

  /// `chat/inputRequested`: adds or replaces an input request.
  @FreezedUnionValue('chat/inputRequested')
  const factory ChatAction.inputRequested({
    /// The request.
    required ChatInputRequest request,
  }) = ChatInputRequested;

  /// `chat/inputAnswerChanged`: updates a draft answer.
  @FreezedUnionValue('chat/inputAnswerChanged')
  const factory ChatAction.inputAnswerChanged({
    /// Request ID.
    required String requestId,

    /// Question ID.
    required String questionId,

    /// The answer (`ChatInputAnswer`), or null to clear it.
    JsonMap? answer,
  }) = ChatInputAnswerChanged;

  /// `chat/inputCompleted`: answers an input request (AHP-042).
  @FreezedUnionValue('chat/inputCompleted')
  const factory ChatAction.inputCompleted({
    /// Request ID.
    required String requestId,

    /// `accept`, `decline` or `cancel`.
    required String response,

    /// Final answers keyed by question ID.
    Map<String, JsonMap>? answers,
  }) = ChatInputCompleted;

  /// An action this client version does not reduce.
  const factory ChatAction.unknown({
    /// The action's `type`.
    required String type,
  }) = ChatUnknownAction;

  /// Decodes a [ChatAction] from JSON.
  factory ChatAction.fromJson(JsonMap json) => _$ChatActionFromJson(json);
}
