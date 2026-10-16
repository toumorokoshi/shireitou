/// Pure reducer for chat channels (AHP-021, AHP-025), ported from
/// `chatReducer` in `@microsoft/agent-host-protocol@1.0.0`
/// (`types/channels-chat/reducer.ts`).
library;

import 'chat_wire.dart';
import 'session_status.dart';
import 'wire.dart';

/// The activity bits of [SessionStatus] (`Idle` to `InputNeeded`).
const _activityMask = (1 << 5) - 1;

/// Statuses of a tool call that block the turn on the user.
const _blockingToolStatuses = {
  ToolCallStatus.pendingConfirmation,
  ToolCallStatus.pendingResultConfirmation,
  ToolCallStatus.authRequired,
};

/// Applies [action] to [state], mirroring the protocol's `chatReducer`.
///
/// Actions for another turn than the active one, and actions this client
/// does not model, leave [state] unchanged.
ChatState reduceChat(ChatState state, ChatAction action) => switch (action) {
  ChatTurnStarted() => _turnStarted(state, action),
  ChatDelta(:final turnId, :final partId, :final content) => _updatePart(
    state,
    turnId,
    partId,
    (part) => switch (part) {
      MarkdownPart() => part.copyWith(content: part.content + content),
      _ => part,
    },
  ),
  ChatReasoning(:final turnId, :final partId, :final content) => _updatePart(
    state,
    turnId,
    partId,
    (part) => switch (part) {
      ReasoningPart() => part.copyWith(content: part.content + content),
      _ => part,
    },
  ),
  ChatResponsePart(:final turnId, :final part) =>
    _isActive(state, turnId) && part is! ErrorPart
        ? _withParts(state, [...state.activeTurn!.responseParts, part])
        : state,
  ChatTurnComplete(:final turnId, :final duration) => _endTurn(
    state,
    turnId,
    TurnState.complete,
    duration,
  ),
  ChatTurnCancelled(:final turnId, :final duration) => _endTurn(
    state,
    turnId,
    TurnState.cancelled,
    duration,
  ),
  ChatError(:final turnId, :final duration, :final part) => _endTurn(
    state,
    turnId,
    TurnState.error,
    duration,
    terminalStatus: SessionStatus.error,
    errorPart: part,
  ),
  ChatTurnResume(:final turnId) => _turnResume(state, turnId),
  ChatActivityChanged(:final activity) => state.copyWith(activity: activity),
  ChatToolCallStart() =>
    _isActive(state, action.turnId)
        ? _withParts(state, [
            ...state.activeTurn!.responseParts,
            ResponsePart.toolCall(
              toolCall: ToolCall(
                toolCallId: action.toolCallId,
                toolName: action.toolName,
                displayName: action.displayName,
                intention: action.intention,
                contributor: action.contributor,
                meta: action.meta,
                status: ToolCallStatus.streaming,
              ),
            ),
          ])
        : state,
  ChatToolCallDelta() => _updateToolCall(
    state,
    action.turnId,
    action.toolCallId,
    (tc) => tc.status != ToolCallStatus.streaming
        ? tc
        : tc.copyWith(
            meta: action.meta ?? tc.meta,
            partialInput: action.content == null
                ? tc.partialInput
                : (tc.partialInput ?? '') + action.content!,
            invocationMessage: action.invocationMessage ?? tc.invocationMessage,
          ),
  ),
  ChatToolCallReady() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallReady(tc, action),
    ),
  ),
  ChatToolCallConfirmed() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallConfirmed(tc, action),
    ),
  ),
  ChatToolCallComplete() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallComplete(tc, action),
    ),
  ),
  ChatToolCallResultConfirmed() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => tc.status != ToolCallStatus.pendingResultConfirmation
          ? tc
          : action.approved
          ? tc.copyWith(
              status: ToolCallStatus.completed,
              meta: action.meta ?? tc.meta,
            )
          : _base(tc, action.meta).copyWith(
              status: ToolCallStatus.cancelled,
              invocationMessage: tc.invocationMessage,
              toolInput: tc.toolInput,
              reason: 'result-denied',
              selectedOption: tc.selectedOption,
            ),
    ),
  ),
  ChatToolCallContentChanged() => _updateToolCall(
    state,
    action.turnId,
    action.toolCallId,
    (tc) => tc.status != ToolCallStatus.running
        ? tc
        : tc.copyWith(meta: action.meta ?? tc.meta, content: action.content),
  ),
  ChatUsage(:final turnId, :final usage) =>
    _isActive(state, turnId)
        ? state.copyWith(activeTurn: state.activeTurn!.copyWith(usage: usage))
        : state,
  ChatTruncated(:final turnId) => _truncated(state, turnId),
  ChatTurnsLoaded(:final turns, :final turnsNextCursor) => () {
    final existing = {for (final t in state.turns) t.id};
    return state.copyWith(
      turns: [
        for (final t in turns)
          if (!existing.contains(t.id)) t,
        ...state.turns,
      ],
      turnsNextCursor: turnsNextCursor,
    );
  }(),
  ChatInputRequested(:final request) => _inputRequested(state, request),
  ChatInputAnswerChanged() => _updateOpenInputRequest(state, action.requestId, (
    part,
  ) {
    final answers = {...?part.request.answers};
    if (action.answer == null) {
      answers.remove(action.questionId);
    } else {
      answers[action.questionId] = action.answer!;
    }
    return part.copyWith(
      request: part.request.copyWith(answers: answers.isEmpty ? null : answers),
    );
  }),
  ChatInputCompleted() => () {
    final next = _updateOpenInputRequest(state, action.requestId, (part) {
      final answers = {...?part.request.answers, ...?action.answers};
      return part.copyWith(
        request: part.request.copyWith(
          answers: answers.isEmpty ? null : answers,
        ),
        response: action.response,
      );
    });
    return identical(next, state)
        ? state
        : next.copyWith(status: _summaryStatus(next));
  }(),
  ChatPendingMessageSet(:final kind, :final id, :final message) =>
    kind == 'steering'
        ? state.copyWith(
            steeringMessage: PendingMessage(id: id, message: message),
          )
        : state.copyWith(
            queuedMessages: _upsertQueued(
              state.queuedMessages ?? const [],
              PendingMessage(id: id, message: message),
            ),
          ),
  ChatPendingMessageRemoved(:final kind, :final id) => _pendingRemoved(
    state,
    kind,
    id,
  ),
  ChatIsReadChanged(:final isRead) => state.copyWith(
    status: state.status.withFlag(SessionStatus.isRead, enabled: isRead),
  ),
  ChatIsArchivedChanged(:final isArchived) => state.copyWith(
    status: state.status.withFlag(
      SessionStatus.isArchived,
      enabled: isArchived,
    ),
  ),
  ChatUnknownAction() => state,
};

/// [reduceChat] over a raw JSON action, for [ChannelMirror]s.
ChatState reduceChatJson(ChatState state, JsonMap action) =>
    reduceChat(state, ChatAction.fromJson(action));

bool _isActive(ChatState state, String turnId) =>
    state.activeTurn?.id == turnId;

ChatState _withParts(ChatState state, List<ResponsePart> parts) => state
    .copyWith(activeTurn: state.activeTurn!.copyWith(responseParts: parts));

bool _hasBlockingToolCall(ChatState state) =>
    state.activeTurn?.responseParts.any(
      (part) =>
          part is ToolCallPart &&
          _blockingToolStatuses.contains(part.toolCall.status),
    ) ??
    false;

bool _hasOpenInputRequest(ChatState state) =>
    state.activeTurn?.responseParts.any(
      (part) => part is InputRequestPart && part.response == null,
    ) ??
    false;

/// The status with its activity bits recomputed from the active turn, or
/// set to [terminalStatus] when given.
SessionStatus _summaryStatus(ChatState state, [SessionStatus? terminalStatus]) {
  final activity =
      terminalStatus ??
      (_hasOpenInputRequest(state) || _hasBlockingToolCall(state)
          ? SessionStatus.inputNeeded
          : state.activeTurn != null
          ? SessionStatus.inProgress
          : SessionStatus.idle);
  return SessionStatus((state.status.bits & ~_activityMask) | activity.bits);
}

ChatState _refreshStatus(ChatState state) {
  final status = _summaryStatus(state);
  return status == state.status ? state : state.copyWith(status: status);
}

ChatState _unread(ChatState state) => state.copyWith(
  status: _summaryStatus(state).withFlag(SessionStatus.isRead, enabled: false),
);

ChatState _turnStarted(ChatState state, ChatTurnStarted action) {
  final queuedId = action.queuedMessageId;
  final queued = [
    for (final m in state.queuedMessages ?? const <PendingMessage>[])
      if (m.id != queuedId) m,
  ];
  final next = state.copyWith(
    activeTurn: ActiveTurn(
      id: action.turnId,
      startedAt: action.startedAt,
      message: action.message,
      responseParts: const [],
    ),
    modifiedAt: action.startedAt,
    steeringMessage: queuedId != null && state.steeringMessage?.id == queuedId
        ? null
        : state.steeringMessage,
    queuedMessages: queuedId == null || state.queuedMessages == null
        ? state.queuedMessages
        : queued.isEmpty
        ? null
        : queued,
  );
  return _unread(next);
}

ChatState _endTurn(
  ChatState state,
  String turnId,
  TurnState turnState,
  int duration, {
  SessionStatus? terminalStatus,
  ResponsePart? errorPart,
}) {
  final active = state.activeTurn;
  if (active == null || active.id != turnId) return state;
  final parts = [
    for (final part in active.responseParts)
      switch (part) {
        ToolCallPart(:final toolCall)
            when toolCall.status != ToolCallStatus.completed &&
                toolCall.status != ToolCallStatus.cancelled =>
          ResponsePart.toolCall(
            toolCall: _base(toolCall, null).copyWith(
              status: ToolCallStatus.cancelled,
              invocationMessage: toolCall.status == ToolCallStatus.streaming
                  ? (toolCall.invocationMessage ?? '')
                  : toolCall.invocationMessage,
              toolInput: toolCall.status == ToolCallStatus.streaming
                  ? null
                  : toolCall.toolInput,
              reason: 'skipped',
            ),
          ),
        _ => part,
      },
    ?errorPart,
  ];
  final clamped = duration < 0 ? 0 : duration;
  final next = state.copyWith(
    turns: [
      ...state.turns,
      Turn(
        id: active.id,
        startedAt: active.startedAt,
        duration: clamped,
        message: active.message,
        responseParts: parts,
        usage: active.usage,
        state: turnState,
      ),
    ],
    activeTurn: null,
    modifiedAt: _addMilliseconds(active.startedAt, clamped) ?? state.modifiedAt,
  );
  return next.copyWith(status: _summaryStatus(next, terminalStatus));
}

String? _addMilliseconds(String timestamp, int milliseconds) =>
    DateTime.tryParse(timestamp)
        ?.toUtc()
        .add(Duration(milliseconds: milliseconds))
        .toIso8601String();

ChatState _turnResume(ChatState state, String turnId) {
  if (state.activeTurn != null || state.turns.isEmpty) return state;
  final turn = state.turns.last;
  final last = turn.responseParts.lastOrNull;
  if (turn.id != turnId ||
      turn.state != TurnState.error ||
      last is! ErrorPart ||
      last.resumable != true) {
    return state;
  }
  return _unread(
    state.copyWith(
      turns: state.turns.sublist(0, state.turns.length - 1),
      activeTurn: ActiveTurn(
        id: turn.id,
        startedAt: turn.startedAt ?? state.modifiedAt,
        message: turn.message,
        responseParts: turn.responseParts,
        usage: turn.usage,
      ),
    ),
  );
}

/// Replaces the first part of the active turn whose ID (or tool call ID) is
/// [partId].
ChatState _updatePart(
  ChatState state,
  String turnId,
  String partId,
  ResponsePart Function(ResponsePart part) update,
) {
  if (!_isActive(state, turnId)) return state;
  final parts = state.activeTurn!.responseParts;
  final index = parts.indexWhere((part) => _partId(part) == partId);
  if (index < 0) return state;
  return _withParts(state, [...parts]..[index] = update(parts[index]));
}

String? _partId(ResponsePart part) => switch (part) {
  MarkdownPart(:final id) || ReasoningPart(:final id) => id,
  ToolCallPart(:final toolCall) => toolCall.toolCallId,
  _ => null,
};

ChatState _updateToolCall(
  ChatState state,
  String turnId,
  String toolCallId,
  ToolCall Function(ToolCall toolCall) update,
) {
  if (!_isActive(state, turnId)) return state;
  var found = false;
  final parts = [
    for (final part in state.activeTurn!.responseParts)
      switch (part) {
        ToolCallPart(:final toolCall) when toolCall.toolCallId == toolCallId =>
          () {
            final updated = update(toolCall);
            if (identical(updated, toolCall)) return part;
            found = true;
            return ResponsePart.toolCall(toolCall: updated);
          }(),
        _ => part,
      },
  ];
  return found ? _withParts(state, parts) : state;
}

/// The fields every tool call status keeps (`tcBase` in the protocol).
ToolCall _base(ToolCall tc, JsonMap? meta) => ToolCall(
  toolCallId: tc.toolCallId,
  toolName: tc.toolName,
  displayName: tc.displayName,
  intention: tc.intention,
  contributor: tc.contributor,
  meta: meta ?? tc.meta,
  status: tc.status,
);

ToolCall _toolCallReady(ToolCall tc, ChatToolCallReady action) {
  if (tc.status != ToolCallStatus.streaming &&
      tc.status != ToolCallStatus.running &&
      tc.status != ToolCallStatus.pendingConfirmation) {
    return tc;
  }
  final base = _base(tc, action.meta).copyWith(
    contributor: _refineContributor(tc.contributor, action.contributor),
    intention: action.intention ?? tc.intention,
    invocationMessage: action.invocationMessage,
    toolInput:
        action.toolInput ??
        (tc.status == ToolCallStatus.streaming ? null : tc.toolInput),
  );
  if (action.confirmed != null) {
    return base.copyWith(
      status: ToolCallStatus.running,
      confirmed: action.confirmed,
    );
  }
  final pending = tc.status == ToolCallStatus.pendingConfirmation ? tc : null;
  return base.copyWith(
    status: ToolCallStatus.pendingConfirmation,
    confirmationTitle: action.confirmationTitle ?? pending?.confirmationTitle,
    riskAssessment: action.riskAssessment ?? pending?.riskAssessment,
    edits: action.edits ?? pending?.edits,
    editable: action.editable ?? pending?.editable,
    options: action.options ?? pending?.options,
  );
}

/// A client-run tool call keeps its contributor; MCP contributors may be
/// refined (`refineToolCallContributor` in the protocol).
JsonMap? _refineContributor(JsonMap? current, JsonMap? next) {
  if (next == null) return current;
  if (current?['kind'] == 'client') {
    return next['kind'] == 'client' && next['clientId'] == current!['clientId']
        ? next
        : current;
  }
  return next['kind'] == 'client' ? current : next;
}

ToolCall _toolCallConfirmed(ToolCall tc, ChatToolCallConfirmed action) {
  if (tc.status != ToolCallStatus.pendingConfirmation) return tc;
  final selected = tc.options
      ?.where((o) => o.id == action.selectedOptionId)
      .firstOrNull;
  final base = _base(
    tc,
    action.meta,
  ).copyWith(invocationMessage: tc.invocationMessage, selectedOption: selected);
  if (action.approved) {
    return base.copyWith(
      status: ToolCallStatus.running,
      toolInput: action.editedToolInput != null && tc.toolInput is String
          ? action.editedToolInput
          : tc.toolInput,
      confirmed: action.confirmed,
    );
  }
  return base.copyWith(
    status: ToolCallStatus.cancelled,
    toolInput: tc.toolInput,
    reason: action.reason,
    reasonMessage: action.reasonMessage,
    userSuggestion: action.userSuggestion,
  );
}

ToolCall _toolCallComplete(ToolCall tc, ChatToolCallComplete action) {
  final status = tc.status;
  if (status != ToolCallStatus.running &&
      status != ToolCallStatus.pendingConfirmation &&
      status != ToolCallStatus.authRequired) {
    return tc;
  }
  final result = action.result;
  final success = result['success'] as bool?;
  if (status == ToolCallStatus.authRequired && (success ?? false)) return tc;
  final confirmedBefore =
      status == ToolCallStatus.running || status == ToolCallStatus.authRequired;
  final error = result['error'];
  final content = result['content'];
  final structured = result['structuredContent'];
  return _base(tc, action.meta).copyWith(
    status:
        action.requiresResultConfirmation == true &&
            status != ToolCallStatus.authRequired
        ? ToolCallStatus.pendingResultConfirmation
        : ToolCallStatus.completed,
    invocationMessage: tc.invocationMessage,
    toolInput: tc.toolInput,
    confirmed: confirmedBefore ? tc.confirmed : 'not-needed',
    selectedOption: confirmedBefore ? tc.selectedOption : null,
    content: content is List
        ? content.cast<JsonMap>()
        : (status == ToolCallStatus.authRequired ? tc.content : null),
    success: success,
    pastTenseMessage: result['pastTenseMessage'],
    structuredContent: structured is JsonMap ? structured : null,
    error: error is JsonMap ? error : null,
  );
}

ChatState _truncated(ChatState state, String? turnId) {
  final List<Turn> turns;
  if (turnId == null) {
    turns = const [];
  } else {
    final index = state.turns.indexWhere((t) => t.id == turnId);
    if (index < 0) return state;
    turns = state.turns.sublist(0, index + 1);
  }
  final next = state.copyWith(
    turns: turns,
    activeTurn: null,
    turnsNextCursor: turnId == null ? null : state.turnsNextCursor,
  );
  return next.copyWith(status: _summaryStatus(next));
}

ChatState _inputRequested(ChatState state, ChatInputRequest request) {
  final active = state.activeTurn;
  if (active == null) return state;
  final parts = [...active.responseParts];
  final index = _openInputRequestIndex(parts, request.id);
  if (index < 0) {
    parts.add(ResponsePart.inputRequest(request: request));
  } else {
    final existing = parts[index] as InputRequestPart;
    parts[index] = ResponsePart.inputRequest(
      request: request.copyWith(
        answers: request.answers ?? existing.request.answers,
      ),
    );
  }
  return _unread(_withParts(state, parts));
}

int _openInputRequestIndex(List<ResponsePart> parts, String requestId) =>
    parts.indexWhere(
      (part) =>
          part is InputRequestPart &&
          part.response == null &&
          part.request.id == requestId,
    );

ChatState _updateOpenInputRequest(
  ChatState state,
  String requestId,
  InputRequestPart Function(InputRequestPart part) update,
) {
  final active = state.activeTurn;
  if (active == null) return state;
  final index = _openInputRequestIndex(active.responseParts, requestId);
  if (index < 0) return state;
  final parts = [...active.responseParts];
  parts[index] = update(parts[index] as InputRequestPart);
  return _withParts(state, parts);
}

List<PendingMessage> _upsertQueued(
  List<PendingMessage> queued,
  PendingMessage entry,
) => queued.any((m) => m.id == entry.id)
    ? [for (final m in queued) m.id == entry.id ? entry : m]
    : [...queued, entry];

ChatState _pendingRemoved(ChatState state, String kind, String id) {
  if (kind == 'steering') {
    return state.steeringMessage?.id == id
        ? state.copyWith(steeringMessage: null)
        : state;
  }
  final queued = state.queuedMessages;
  if (queued == null) return state;
  final filtered = [
    for (final m in queued)
      if (m.id != id) m,
  ];
  if (filtered.length == queued.length) return state;
  return state.copyWith(queuedMessages: filtered.isEmpty ? null : filtered);
}
