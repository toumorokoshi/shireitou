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
  final action = chat.activeTurn == null
      ? ChatAction.turnStarted(
          turnId: id,
          startedAt: now.toUtc().toIso8601String(),
          message: message,
        )
      : ChatAction.pendingMessageSet(
          kind: steer ? 'steering' : 'queued',
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
  return ChatAction.turnCancelled(
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
  ToolCall toolCall, {
  required bool approve,
  ConfirmationOption? option,
}) {
  final action = toolCall.status == ToolCallStatus.pendingResultConfirmation
      ? ChatAction.toolCallResultConfirmed(
          turnId: turnId,
          toolCallId: toolCall.toolCallId,
          approved: approve,
        )
      : ChatAction.toolCallConfirmed(
          turnId: turnId,
          toolCallId: toolCall.toolCallId,
          approved: approve,
          confirmed: approve ? 'user-action' : null,
          reason: approve ? null : 'denied',
          selectedOptionId: option?.id,
        );
  return action.toJson();
}

/// A submitted `ChatInputAnswer` for [question] with [value] (AV-084), or
/// null when [value] is empty.
///
/// [value] is a `String` for text, number and single-select questions (the
/// option ID), a `bool` for boolean ones, and a `Set<String>` of option IDs
/// for multi-select ones.
JsonMap? inputAnswer(ChatInputQuestion question, Object? value) {
  final JsonMap? answerValue = switch ((question.kind, value)) {
    ('boolean', final bool b) => {'kind': 'boolean', 'value': b},
    ('number' || 'integer', final String s) => switch (num.tryParse(s)) {
      final n? => {'kind': 'number', 'value': n},
      null => null,
    },
    ('single-select', final String s) when s.isNotEmpty => {
      'kind': 'selected',
      'value': s,
    },
    ('multi-select', final Set<String> ids) when ids.isNotEmpty => {
      'kind': 'selected-many',
      'value': ids.toList(),
    },
    ('text', final String s) when s.isNotEmpty => {'kind': 'text', 'value': s},
    _ => null,
  };
  return answerValue == null
      ? null
      : {'state': 'submitted', 'value': answerValue};
}

/// The action that answers (or declines) input request [request] (AV-084).
/// [values] maps question IDs to values as [inputAnswer] takes them.
JsonMap inputCompletedAction(
  ChatInputRequest request, {
  required bool accept,
  Map<String, Object?> values = const {},
}) {
  final answers = <String, JsonMap>{
    for (final question in request.questions ?? const <ChatInputQuestion>[])
      question.id: ?inputAnswer(question, values[question.id]),
  };
  return ChatAction.inputCompleted(
    requestId: request.id,
    response: accept ? 'accept' : 'decline',
    answers: accept && answers.isNotEmpty ? answers : null,
  ).toJson();
}

/// Whether every required question of [request] has an answer in [values].
bool inputComplete(ChatInputRequest request, Map<String, Object?> values) =>
    (request.questions ?? const <ChatInputQuestion>[]).every(
      (q) => !(q.required ?? false) || inputAnswer(q, values[q.id]) != null,
    );
