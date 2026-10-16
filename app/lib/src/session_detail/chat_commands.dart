/// Pure builders for the chat actions the session view dispatches
/// (AV-080 to AV-084, AHP-041 to AHP-043).
library;

import 'package:ahp_client/ahp_client.dart';

/// The action that sends [text] (AV-080).
///
/// With no turn running it starts a turn. While a turn runs it queues the
/// message, or with [steer] delivers it to the agent at its next step.
/// [id] is the new turn or pending-message ID.
JsonMap sendMessageAction(
  ChatState chat, {
  required String text,
  required String id,
  required DateTime now,
  bool steer = false,
  ModelSelection? model,
}) {
  final message = userMessage(text, model: model);
  final StateAction action = chat.activeTurn == null
      ? ChatTurnStartedAction(
          turnId: id,
          startedAt: now.toUtc().toIso8601String(),
          message: message,
        )
      : ChatPendingMessageSetAction(
          kind: steer ? PendingMessageKind.steering : PendingMessageKind.queued,
          id: id,
          message: message,
        );
  return action.toJson();
}

/// The action that cancels the running turn (AV-082), or null when idle.
JsonMap? stopAction(ChatState chat, DateTime now) {
  final active = chat.activeTurn;
  if (active == null) return null;
  final started = DateTime.tryParse(active.startedAt);
  final duration = started == null ? 0 : now.difference(started).inMilliseconds;
  return ChatTurnCancelledAction(
    turnId: active.id,
    duration: duration < 0 ? 0 : duration,
  ).toJson();
}

/// The action that approves or denies [toolCall] in [turnId] (AV-083).
///
/// Waiting results (`pending-result-confirmation`) get
/// `chat/toolCallResultConfirmed`; calls waiting to run get
/// `chat/toolCallConfirmed`, with [option] when the host offered choices.
JsonMap confirmToolCallAction(
  String turnId,
  ToolCallState toolCall, {
  required bool approve,
  ConfirmationOption? option,
}) {
  final StateAction action = switch (toolCall) {
    ToolCallPendingResultConfirmationState() =>
      ChatToolCallResultConfirmedAction(
        turnId: turnId,
        toolCallId: toolCall.toolCallId,
        approved: approve,
      ),
    _ when approve => ChatToolCallApprovedAction(
      turnId: turnId,
      toolCallId: toolCall.toolCallId,
      confirmed: ToolCallConfirmationReason.userAction,
      selectedOptionId: option?.id,
    ),
    _ => ChatToolCallDeniedAction(
      turnId: turnId,
      toolCallId: toolCall.toolCallId,
      reason: ToolCallCancellationReason.denied,
      selectedOptionId: option?.id,
    ),
  };
  return action.toJson();
}

/// A submitted answer for [question] with [value] (AV-084), or null when
/// [value] is empty.
///
/// [value] is a `String` for text, number and single-select questions (the
/// option ID), a `bool` for boolean ones, and a `Set<String>` of option IDs
/// for multi-select ones.
ChatInputAnswer? inputAnswer(ChatInputQuestion question, Object? value) {
  final ChatInputAnswerValue? answerValue = switch ((question, value)) {
    (ChatInputBooleanQuestion(), final bool b) => ChatInputBooleanAnswerValue(
      value: b,
    ),
    (ChatInputNumberQuestion(), final String s) => switch (num.tryParse(s)) {
      final n? => ChatInputNumberAnswerValue(value: n),
      null => null,
    },
    (ChatInputSingleSelectQuestion(), final String s) when s.isNotEmpty =>
      ChatInputSelectedAnswerValue(value: s),
    (ChatInputMultiSelectQuestion(), final Set<String> ids)
        when ids.isNotEmpty =>
      ChatInputSelectedManyAnswerValue(value: ids.toList()),
    (ChatInputTextQuestion(), final String s) when s.isNotEmpty =>
      ChatInputTextAnswerValue(value: s),
    _ => null,
  };
  return answerValue == null
      ? null
      : ChatInputAnswered(state: 'submitted', value: answerValue);
}

/// The action that answers (or declines) input request [request] (AV-084).
/// [values] maps question IDs to values as [inputAnswer] takes them.
JsonMap inputCompletedAction(
  ChatInputRequest request, {
  required bool accept,
  Map<String, Object?> values = const {},
}) {
  final answers = <String, ChatInputAnswer>{
    for (final question in request.questions ?? const <ChatInputQuestion>[])
      question.id: ?inputAnswer(question, values[question.id]),
  };
  return ChatInputCompletedAction(
    requestId: request.id,
    response: accept
        ? ChatInputResponseKind.accept
        : ChatInputResponseKind.decline,
    answers: accept && answers.isNotEmpty ? answers : null,
  ).toJson();
}

/// Whether every required question of [request] has an answer in [values].
bool inputComplete(ChatInputRequest request, Map<String, Object?> values) =>
    (request.questions ?? const <ChatInputQuestion>[]).every(
      (q) => !(q.required ?? false) || inputAnswer(q, values[q.id]) != null,
    );

/// The action that gives up on [toolCall] in [turnId] while it waits for
/// MCP sign-in (AHP-062): a failed `chat/toolCallComplete`, the only
/// completion the protocol allows from `auth-required`.
JsonMap cancelAuthAction(String turnId, ToolCallState toolCall) =>
    ChatToolCallCompleteAction(
      turnId: turnId,
      toolCallId: toolCall.toolCallId,
      result: const ToolCallResult(
        success: false,
        pastTenseMessage: PlainString('Sign-in cancelled'),
        error: ToolCallError(message: 'The user cancelled the sign-in.'),
      ),
    ).toJson();
