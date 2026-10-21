/// Pure builders for the chat actions the session view dispatches
/// (AV-080 to AV-084, AHP-041 to AHP-043).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';

/// The actions that send [text] (AV-080).
///
/// With no turn running they start a turn. While a turn runs they queue
/// the message, or with [sendNow] stop the turn and start one with it
/// (see [runNowActions]). [id] is the new turn or pending-message ID;
/// [attachments] go with the message (accepted completions, AV-044).
List<JsonMap> sendMessageActions(
  ChatState chat, {
  required String text,
  required String id,
  required DateTime now,
  bool sendNow = false,
  ModelSelection? model,
  List<MessageAttachment>? attachments,
}) {
  final message = userMessage(text, model: model, attachments: attachments);
  if (chat.activeTurn != null && !sendNow) {
    return [
      ChatPendingMessageSetAction(
        kind: PendingMessageKind.queued,
        id: id,
        message: message,
      ).toJson(),
    ];
  }
  return runNowActions(chat, message, id: id, now: now);
}

/// The actions that run [message] as turn [id] at once (AV-080): cancel
/// the running turn, if any, then start the new one.
///
/// Steering would wait for the agent's next step, which is after the whole
/// reply when the agent only writes text. The cancel names the turn, so if
/// another turn started in the meantime the host rejects both actions
/// instead of stopping the wrong turn.
List<JsonMap> runNowActions(
  ChatState chat,
  Message message, {
  required String id,
  required DateTime now,
}) => [
  ?stopAction(chat, now),
  ChatTurnStartedAction(
    turnId: id,
    startedAt: now.toUtc().toIso8601String(),
    message: message,
  ).toJson(),
];

/// The turn whose message can be edited to restart from it (AV-088): the
/// running turn, else the latest. Null when there is none, its message is
/// not the user's, or it is the oldest loaded turn while older ones are not
/// loaded (truncating before it would drop them too).
String? editableTurnId(ChatState chat) {
  final (id, message, earlier) = switch (chat.activeTurn) {
    final active? => (active.id, active.message, chat.turns.length),
    null when chat.turns.isNotEmpty => (
      chat.turns.last.id,
      chat.turns.last.message,
      chat.turns.length - 1,
    ),
    null => (null, null, 0),
  };
  if (id == null || message?.origin.kind != MessageKind.user) return null;
  if (earlier == 0 && chat.turnsNextCursor != null) return null;
  return id;
}

/// The actions that restart [chat] from turn [turnId] with [text] in place
/// of its message (AV-088): `chat/truncated` back to the turn before it
/// (which also ends it if it is running), then `chat/turnStarted` [id]
/// with the edited message, keeping the original's model and attachments.
/// Null when [text] is blank or [turnId] is not [editableTurnId].
List<JsonMap>? restartActions(
  ChatState chat, {
  required String turnId,
  required String text,
  required String id,
  required DateTime now,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || editableTurnId(chat) != turnId) return null;
  final running = chat.activeTurn?.id == turnId;
  final kept = running
      ? chat.turns
      : chat.turns.sublist(0, chat.turns.length - 1);
  final original = running ? chat.activeTurn!.message : chat.turns.last.message;
  return [
    ChatTruncatedAction(turnId: kept.lastOrNull?.id).toJson(),
    ChatTurnStartedAction(
      turnId: id,
      startedAt: now.toUtc().toIso8601String(),
      message: original.copyWith(text: trimmed),
    ).toJson(),
  ];
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
/// `chat/toolCallConfirmed`, with [option] when the host offered choices
/// and [editedInput] (see [editedToolInput]) when the user changed an
/// `editable` call's input. A denial chosen from a host's "skip" option
/// (an ID or label that says so) is sent as `skipped`.
JsonMap confirmToolCallAction(
  String turnId,
  ToolCallState toolCall, {
  required bool approve,
  ConfirmationOption? option,
  String? editedInput,
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
      editedToolInput: editedInput,
    ),
    _ => ChatToolCallDeniedAction(
      turnId: turnId,
      toolCallId: toolCall.toolCallId,
      reason: option != null && _isSkip(option)
          ? ToolCallCancellationReason.skipped
          : ToolCallCancellationReason.denied,
      selectedOptionId: option?.id,
    ),
  };
  return action.toJson();
}

bool _isSkip(ConfirmationOption option) =>
    '${option.id} ${option.label}'.toLowerCase().contains('skip');

/// [input] for reading: indented when it is JSON.
String prettyToolInput(String input) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(input));
  } on FormatException {
    return input;
  }
}

/// What to send as `editedToolInput` after the user changed [original]
/// to [edited]: compact JSON when the input is JSON, the text otherwise,
/// and null when nothing changed (whitespace in JSON does not count).
String? editedToolInput(String original, String edited) {
  try {
    final before = jsonDecode(original);
    final after = jsonDecode(edited);
    return jsonEncode(before) == jsonEncode(after) ? null : jsonEncode(after);
  } on FormatException {
    return edited == original ? null : edited;
  }
}

/// Why [edited] cannot replace [original]: a JSON input must stay JSON
/// (tools validate it against their schema); null when it can.
String? toolInputEditError(String original, String edited) {
  try {
    jsonDecode(original);
  } on FormatException {
    return null;
  }
  try {
    jsonDecode(edited);
    return null;
  } on FormatException catch (error) {
    return 'Not valid JSON: ${error.message}';
  }
}

/// A submitted answer for [question] with [value] (AV-084), or null when
/// [value] is empty.
///
/// [value] is a `String` for text, number and single-select questions (the
/// option ID), a `bool` for boolean ones, and a `Set<String>` of option IDs
/// for multi-select ones. [freeform] is text typed for a select question
/// that allows free-form input (`allowFreeformInput`, for example
/// feedback on a plan, AV-046): it goes with the selection as
/// `freeformValues`, or alone as a text answer when nothing is selected
/// (as VS Code's agent host reads plan review answers).
ChatInputAnswer? inputAnswer(
  ChatInputQuestion question,
  Object? value, {
  String? freeform,
  bool draft = false,
}) {
  final text = freeform?.trim() ?? '';
  final extra = text.isEmpty ? null : [text];
  final ChatInputAnswerValue? answerValue = switch ((question, value)) {
    (ChatInputBooleanQuestion(), final bool b) => ChatInputBooleanAnswerValue(
      value: b,
    ),
    (ChatInputNumberQuestion(), final String s) => switch (num.tryParse(s)) {
      final n? => ChatInputNumberAnswerValue(value: n),
      null => null,
    },
    (ChatInputSingleSelectQuestion(), final String s) when s.isNotEmpty =>
      ChatInputSelectedAnswerValue(value: s, freeformValues: extra),
    (ChatInputMultiSelectQuestion(), final Set<String> ids)
        when ids.isNotEmpty =>
      ChatInputSelectedManyAnswerValue(
        value: ids.toList(),
        freeformValues: extra,
      ),
    (
      ChatInputSingleSelectQuestion(allowFreeformInput: true) ||
          ChatInputMultiSelectQuestion(allowFreeformInput: true),
      _,
    )
        when text.isNotEmpty =>
      ChatInputTextAnswerValue(value: text),
    (ChatInputTextQuestion(), final String s) when s.isNotEmpty =>
      ChatInputTextAnswerValue(value: s),
    _ => null,
  };
  return answerValue == null
      ? null
      : ChatInputAnswered(
          state: draft ? 'draft' : 'submitted',
          value: answerValue,
        );
}

/// The `chat/inputAnswerChanged` that syncs the draft of [question] in
/// [request] ([value] and [freeform] as [inputAnswer] takes them), so
/// other clients see it; an empty value clears the draft.
JsonMap inputAnswerChangedAction(
  ChatInputRequest request,
  ChatInputQuestion question,
  Object? value, {
  String? freeform,
}) => ChatInputAnswerChangedAction(
  requestId: request.id,
  questionId: question.id,
  answer: inputAnswer(question, value, freeform: freeform, draft: true),
).toJson();

/// [answer] (a draft or submitted answer the host holds) as the form's
/// value for [question], the inverse of [inputAnswer]; null when there is
/// nothing to show.
({Object? value, String? freeform})? answerFormValue(
  ChatInputQuestion question,
  ChatInputAnswer? answer,
) {
  if (answer is! ChatInputAnswered) return null;
  final allowsFreeform = switch (question) {
    ChatInputSingleSelectQuestion(:final allowFreeformInput) ||
    ChatInputMultiSelectQuestion(
      :final allowFreeformInput,
    ) => allowFreeformInput ?? false,
    _ => false,
  };
  return switch ((question, answer.value)) {
    (ChatInputBooleanQuestion(), ChatInputBooleanAnswerValue(:final value)) => (
      value: value,
      freeform: null,
    ),
    (ChatInputNumberQuestion(), ChatInputNumberAnswerValue(:final value)) => (
      value: '$value',
      freeform: null,
    ),
    (
      ChatInputSingleSelectQuestion(),
      ChatInputSelectedAnswerValue(:final value, :final freeformValues),
    ) =>
      (value: value, freeform: freeformValues?.join(' ')),
    (
      ChatInputMultiSelectQuestion(),
      ChatInputSelectedManyAnswerValue(:final value, :final freeformValues),
    ) =>
      (value: value.toSet(), freeform: freeformValues?.join(' ')),
    (ChatInputTextQuestion(), ChatInputTextAnswerValue(:final value)) => (
      value: value,
      freeform: null,
    ),
    (_, ChatInputTextAnswerValue(:final value)) when allowsFreeform => (
      value: question is ChatInputMultiSelectQuestion ? <String>{} : '',
      freeform: value,
    ),
    _ => null,
  };
}

/// The action that answers (or declines) input request [request] (AV-084).
/// [values] maps question IDs to values as [inputAnswer] takes them, and
/// [freeform] question IDs to free-form text.
JsonMap inputCompletedAction(
  ChatInputRequest request, {
  required bool accept,
  Map<String, Object?> values = const {},
  Map<String, String> freeform = const {},
}) {
  final answers = <String, ChatInputAnswer>{
    for (final question in request.questions ?? const <ChatInputQuestion>[])
      question.id: ?inputAnswer(
        question,
        values[question.id],
        freeform: freeform[question.id],
      ),
  };
  return ChatInputCompletedAction(
    requestId: request.id,
    response: accept
        ? ChatInputResponseKind.accept
        : ChatInputResponseKind.decline,
    answers: accept && answers.isNotEmpty ? answers : null,
  ).toJson();
}

/// Whether every required question of [request] has an answer in [values]
/// (or free-form text in [freeform]).
bool inputComplete(
  ChatInputRequest request,
  Map<String, Object?> values, {
  Map<String, String> freeform = const {},
}) => (request.questions ?? const <ChatInputQuestion>[]).every(
  (q) =>
      !(q.required ?? false) ||
      inputAnswer(q, values[q.id], freeform: freeform[q.id]) != null,
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

/// The action that replaces pending message [pending]'s text with [text]
/// (AV-081), keeping its other fields (model, attachments).
JsonMap editPendingAction(
  PendingMessageKind kind,
  PendingMessage pending,
  String text,
) => ChatPendingMessageSetAction(
  kind: kind,
  id: pending.id,
  message: pending.message.copyWith(text: text),
).toJson();

/// The action that removes pending message [id] (AV-081).
JsonMap removePendingAction(PendingMessageKind kind, String id) =>
    ChatPendingMessageRemovedAction(kind: kind, id: id).toJson();

/// The actions that send queued [pending] now (AV-081): remove it from the
/// queue, so the host does not also start it after the cancel, then run it
/// as turn [id] with its model and attachments (see [runNowActions]).
List<JsonMap> sendQueuedNowActions(
  ChatState chat,
  PendingMessage pending, {
  required String id,
  required DateTime now,
}) => [
  removePendingAction(PendingMessageKind.queued, pending.id),
  ...runNowActions(chat, pending.message, id: id, now: now),
];

/// The action that saves an inline edit of [pending] as [text] (AV-081):
/// an edit with the trimmed text, a removal when [text] is blank, or null
/// when nothing is sent, because [text] is unchanged or [pending] is null
/// (the host sent or removed the message while it was being edited, and
/// setting it again would queue it anew).
JsonMap? savePendingEditAction(
  PendingMessageKind kind,
  PendingMessage? pending,
  String text,
) {
  if (pending == null) return null;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return removePendingAction(kind, pending.id);
  if (trimmed == pending.message.text) return null;
  return editPendingAction(kind, pending, trimmed);
}

/// The action that moves the queued message at [from] to position [to]
/// (both indexes into [queued], [to] counted after the removal), or null
/// when nothing moves (AV-081).
JsonMap? reorderQueuedAction(List<PendingMessage> queued, int from, int to) {
  if (from == to || from < 0 || from >= queued.length) return null;
  final ids = [for (final m in queued) m.id];
  final moved = ids.removeAt(from);
  ids.insert(to.clamp(0, ids.length), moved);
  return ChatQueuedMessagesReorderedAction(order: ids).toJson();
}

/// The action that syncs the follow-up box's [text] as the chat's draft,
/// or clears it when [text] is blank (`chat/draftChanged`). [previous]
/// keeps the draft's other fields.
JsonMap draftAction(String text, {Message? previous}) => ChatDraftChangedAction(
  draft: text.trim().isEmpty
      ? null
      : (previous?.copyWith(text: text) ?? userMessage(text)),
).toJson();
