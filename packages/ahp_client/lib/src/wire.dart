/// Wire types of the Agent Host Protocol 1.0.0, and helpers over them.
///
/// The types are generated from the protocol's JSON Schemas into
/// `generated/` by `packages/ahp_wire_gen` (run `just codegen`; never edit
/// the output). This file only adds hand-written helpers.
library;

import 'generated/ahp_types.dart';

export 'generated/ahp_types.dart';

/// The text of a [StringOrMarkdown], plain or markdown.
extension StringOrMarkdownText on StringOrMarkdown {
  /// The text, without telling plain text and markdown apart.
  String get text => switch (this) {
    PlainString(:final value) => value,
    MarkdownString(:final markdown) => markdown,
  };
}

/// Builds a user [Message] with [text], optionally for [model].
Message userMessage(String text, {ModelSelection? model}) => Message(
  text: text,
  origin: const MessageOrigin(kind: MessageKind.user),
  model: model,
);

/// The chat a session sends input to: `defaultChat`, else the first chat.
String? defaultChatOf(SessionState state) =>
    state.defaultChat ?? state.chats.firstOrNull?.resource;

/// Fields that only some [ToolCallState] variants have.
extension ToolCallStateFields on ToolCallState {
  /// The tool input, once the call has left `streaming`.
  ToolInput? get toolInput => switch (this) {
    ToolCallPendingConfirmationState(:final toolInput) ||
    ToolCallRunningState(:final toolInput) ||
    ToolCallAuthRequiredState(:final toolInput) ||
    ToolCallPendingResultConfirmationState(:final toolInput) ||
    ToolCallCompletedState(:final toolInput) ||
    ToolCallCancelledState(:final toolInput) => toolInput,
    ToolCallStreamingState() || ToolCallStateUnknown() => null,
  };

  /// The option the user chose when confirming the call.
  ConfirmationOption? get selectedOption => switch (this) {
    ToolCallRunningState(:final selectedOption) ||
    ToolCallAuthRequiredState(:final selectedOption) ||
    ToolCallPendingResultConfirmationState(:final selectedOption) ||
    ToolCallCompletedState(:final selectedOption) ||
    ToolCallCancelledState(:final selectedOption) => selectedOption,
    ToolCallStreamingState() ||
    ToolCallPendingConfirmationState() ||
    ToolCallStateUnknown() => null,
  };

  /// How the call was confirmed, once it ran.
  ToolCallConfirmationReason? get confirmed => switch (this) {
    ToolCallRunningState(:final confirmed) ||
    ToolCallAuthRequiredState(:final confirmed) ||
    ToolCallPendingResultConfirmationState(:final confirmed) ||
    ToolCallCompletedState(:final confirmed) => confirmed,
    ToolCallStreamingState() ||
    ToolCallPendingConfirmationState() ||
    ToolCallCancelledState() ||
    ToolCallStateUnknown() => null,
  };

  /// Result or live output content.
  List<ToolResultContent>? get content => switch (this) {
    ToolCallRunningState(:final content) ||
    ToolCallAuthRequiredState(:final content) ||
    ToolCallPendingResultConfirmationState(:final content) ||
    ToolCallCompletedState(:final content) => content,
    ToolCallStreamingState() ||
    ToolCallPendingConfirmationState() ||
    ToolCallCancelledState() ||
    ToolCallStateUnknown() => null,
  };

  /// Whether the call waits on the user: confirmation, result
  /// confirmation, or authentication.
  bool get isBlocking => switch (this) {
    ToolCallPendingConfirmationState() ||
    ToolCallPendingResultConfirmationState() ||
    ToolCallAuthRequiredState() => true,
    _ => false,
  };

  /// Whether the call has finished (completed or cancelled).
  bool get isFinished =>
      this is ToolCallCompletedState || this is ToolCallCancelledState;
}
