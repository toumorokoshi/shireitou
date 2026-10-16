/// Pure reducer for chat channels (AHP-021, AHP-025), ported from
/// `chatReducer` in `@microsoft/agent-host-protocol@1.0.0`
/// (`types/channels-chat/reducer.ts`).
library;

import 'session_status.dart';
import 'wire.dart';

/// The activity bits of [SessionStatus] (`Idle` to `InputNeeded`).
const _activityMask = (1 << 5) - 1;

/// Applies [action] to [state], mirroring the protocol's `chatReducer`.
///
/// Actions for another turn than the active one, and actions this client
/// does not model yet (background work, canvases, changesets, MCP auth,
/// working directories, drafts), leave [state] unchanged.
ChatState reduceChat(ChatState state, ChatAction action) => switch (action) {
  ChatTurnStartedAction() => _turnStarted(state, action),
  ChatDeltaAction(:final turnId, :final partId, :final content) => _updatePart(
    state,
    turnId,
    partId,
    (part) => switch (part) {
      MarkdownResponsePart() => part.copyWith(content: part.content + content),
      _ => part,
    },
  ),
  ChatReasoningAction(:final turnId, :final partId, :final content) =>
    _updatePart(
      state,
      turnId,
      partId,
      (part) => switch (part) {
        ReasoningResponsePart() => part.copyWith(
          content: part.content + content,
        ),
        _ => part,
      },
    ),
  ChatResponsePartAction(:final turnId, :final part) =>
    _isActive(state, turnId) && part is! ErrorResponsePart
        ? _withParts(state, [...state.activeTurn!.responseParts, part])
        : state,
  ChatTurnCompleteAction(:final turnId, :final duration) => _endTurn(
    state,
    turnId,
    TurnState.complete,
    duration,
  ),
  ChatTurnCancelledAction(:final turnId, :final duration) => _endTurn(
    state,
    turnId,
    TurnState.cancelled,
    duration,
  ),
  ChatErrorAction(:final turnId, :final duration, :final part) => _endTurn(
    state,
    turnId,
    TurnState.error,
    duration,
    terminalStatus: SessionStatus.error,
    errorPart: part,
  ),
  ChatTurnResumeAction(:final turnId) => _turnResume(state, turnId),
  ChatActivityChangedAction(:final activity) => state.copyWith(
    activity: activity,
  ),
  ChatToolCallStartAction() =>
    _isActive(state, action.turnId)
        ? _withParts(state, [
            ...state.activeTurn!.responseParts,
            ToolCallResponsePart(
              toolCall: ToolCallStreamingState(
                toolCallId: action.toolCallId,
                toolName: action.toolName,
                displayName: action.displayName,
                intention: action.intention,
                contributor: action.contributor,
                meta: action.meta,
              ),
            ),
          ])
        : state,
  ChatToolCallDeltaAction() => _updateToolCall(
    state,
    action.turnId,
    action.toolCallId,
    (tc) => switch (tc) {
      ToolCallStreamingState() => tc.copyWith(
        meta: action.meta ?? tc.meta,
        partialInput: action.content == null
            ? tc.partialInput
            : (tc.partialInput ?? '') + action.content!,
        invocationMessage: action.invocationMessage ?? tc.invocationMessage,
      ),
      _ => tc,
    },
  ),
  ChatToolCallReadyAction() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallReady(tc, action),
    ),
  ),
  ChatToolCallConfirmedAction() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallConfirmed(tc, action),
    ),
  ),
  ChatToolCallCompleteAction() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallComplete(tc, action),
    ),
  ),
  ChatToolCallResultConfirmedAction() => _refreshStatus(
    _updateToolCall(
      state,
      action.turnId,
      action.toolCallId,
      (tc) => _toolCallResultConfirmed(tc, action),
    ),
  ),
  ChatToolCallContentChangedAction() => _updateToolCall(
    state,
    action.turnId,
    action.toolCallId,
    (tc) => switch (tc) {
      ToolCallRunningState() => tc.copyWith(
        meta: action.meta ?? tc.meta,
        content: action.content,
      ),
      _ => tc,
    },
  ),
  ChatUsageAction(:final turnId, :final usage) =>
    _isActive(state, turnId)
        ? state.copyWith(activeTurn: state.activeTurn!.copyWith(usage: usage))
        : state,
  ChatTruncatedAction(:final turnId) => _truncated(state, turnId),
  ChatTurnsLoadedAction(:final turns, :final turnsNextCursor) => () {
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
  ChatInputRequestedAction(:final request) => _inputRequested(state, request),
  ChatInputAnswerChangedAction() => _updateOpenInputRequest(
    state,
    action.requestId,
    (part) {
      final answers = {...?part.request.answers};
      if (action.answer == null) {
        answers.remove(action.questionId);
      } else {
        answers[action.questionId] = action.answer!;
      }
      return part.copyWith(
        request: part.request.copyWith(
          answers: answers.isEmpty ? null : answers,
        ),
      );
    },
  ),
  ChatInputCompletedAction() => () {
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
  ChatPendingMessageSetAction(:final kind, :final id, :final message) =>
    kind == PendingMessageKind.steering
        ? state.copyWith(
            steeringMessage: PendingMessage(id: id, message: message),
          )
        : state.copyWith(
            queuedMessages: _upsertQueued(
              state.queuedMessages ?? const [],
              PendingMessage(id: id, message: message),
            ),
          ),
  ChatPendingMessageRemovedAction(:final kind, :final id) => _pendingRemoved(
    state,
    kind,
    id,
  ),
  ChatIsReadChangedAction(:final isRead) => state.copyWith(
    status: state.status.withFlag(SessionStatus.isRead, enabled: isRead),
  ),
  ChatIsArchivedChangedAction(:final isArchived) => state.copyWith(
    status: state.status.withFlag(
      SessionStatus.isArchived,
      enabled: isArchived,
    ),
  ),
  ChatToolCallAuthRequiredAction() ||
  ChatToolCallAuthResolvedAction() ||
  ChatBackgroundWorkSetAction() ||
  ChatBackgroundWorkRemovedAction() ||
  ChatMovableChangedAction() ||
  ChatChangesetsChangedAction() ||
  ChatCanvasesChangedAction() ||
  ChatWorkingDirectorySetAction() ||
  ChatWorkingDirectoryRemovedAction() ||
  ChatQueuedMessagesReorderedAction() ||
  ChatDraftChangedAction() ||
  ChatActionUnknown() => state,
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
      (part) => part is ToolCallResponsePart && part.toolCall.isBlocking,
    ) ??
    false;

bool _hasOpenInputRequest(ChatState state) =>
    state.activeTurn?.responseParts.any(
      (part) => part is InputRequestResponsePart && part.response == null,
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

ChatState _turnStarted(ChatState state, ChatTurnStartedAction action) {
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

/// A tool call forced into `cancelled` when its turn ends.
ToolCallState _skipped(ToolCallState tc) => switch (tc) {
  ToolCallCompletedState() ||
  ToolCallCancelledState() ||
  ToolCallStateUnknown() => tc,
  _ => ToolCallCancelledState(
    toolCallId: tc.toolCallId,
    toolName: tc.toolName,
    displayName: tc.displayName,
    intention: tc.intention,
    contributor: tc.contributor,
    meta: tc.meta,
    invocationMessage: tc.invocationMessage ?? const PlainString(''),
    toolInput: tc.toolInput,
    reason: ToolCallCancellationReason.skipped,
  ),
};

ChatState _endTurn(
  ChatState state,
  String turnId,
  TurnState turnState,
  int duration, {
  SessionStatus? terminalStatus,
  ErrorResponsePart? errorPart,
}) {
  final active = state.activeTurn;
  if (active == null || active.id != turnId) return state;
  final parts = <ResponsePart>[
    for (final part in active.responseParts)
      switch (part) {
        ToolCallResponsePart(:final toolCall)
            when !identical(_skipped(toolCall), toolCall) =>
          ToolCallResponsePart(toolCall: _skipped(toolCall)),
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
      last is! ErrorResponsePart ||
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
  MarkdownResponsePart(:final id) || ReasoningResponsePart(:final id) => id,
  ToolCallResponsePart(:final toolCall) => toolCall.toolCallId,
  _ => null,
};

ChatState _updateToolCall(
  ChatState state,
  String turnId,
  String toolCallId,
  ToolCallState Function(ToolCallState toolCall) update,
) {
  if (!_isActive(state, turnId)) return state;
  var found = false;
  final parts = [
    for (final part in state.activeTurn!.responseParts)
      switch (part) {
        ToolCallResponsePart(:final toolCall)
            when toolCall.toolCallId == toolCallId =>
          () {
            final updated = update(toolCall);
            if (identical(updated, toolCall)) return part;
            found = true;
            return ToolCallResponsePart(toolCall: updated);
          }(),
        _ => part,
      },
  ];
  return found ? _withParts(state, parts) : state;
}

ToolCallState _toolCallReady(ToolCallState tc, ChatToolCallReadyAction action) {
  if (tc is! ToolCallStreamingState &&
      tc is! ToolCallRunningState &&
      tc is! ToolCallPendingConfirmationState) {
    return tc;
  }
  final meta = action.meta ?? tc.meta;
  final contributor = _refineContributor(tc.contributor, action.contributor);
  final intention = action.intention ?? tc.intention;
  final toolInput = action.toolInput ?? tc.toolInput;
  final confirmed = action.confirmed;
  if (confirmed != null) {
    return ToolCallRunningState(
      toolCallId: tc.toolCallId,
      toolName: tc.toolName,
      displayName: tc.displayName,
      intention: intention,
      contributor: contributor,
      meta: meta,
      invocationMessage: action.invocationMessage,
      toolInput: toolInput,
      confirmed: confirmed,
    );
  }
  final pending = tc is ToolCallPendingConfirmationState ? tc : null;
  return ToolCallPendingConfirmationState(
    toolCallId: tc.toolCallId,
    toolName: tc.toolName,
    displayName: tc.displayName,
    intention: intention,
    contributor: contributor,
    meta: meta,
    invocationMessage: action.invocationMessage,
    toolInput: toolInput,
    confirmationTitle: action.confirmationTitle ?? pending?.confirmationTitle,
    riskAssessment: action.riskAssessment ?? pending?.riskAssessment,
    edits: action.edits ?? pending?.edits,
    editable: action.editable ?? pending?.editable,
    options: action.options ?? pending?.options,
  );
}

/// A client-run tool call keeps its contributor; MCP contributors may be
/// refined (`refineToolCallContributor` in the protocol).
ToolCallContributor? _refineContributor(
  ToolCallContributor? current,
  ToolCallContributor? next,
) {
  if (next == null) return current;
  if (current is ToolCallClientContributor) {
    return next is ToolCallClientContributor &&
            next.clientId == current.clientId
        ? next
        : current;
  }
  return next is ToolCallClientContributor ? current : next;
}

ToolCallState _toolCallConfirmed(
  ToolCallState tc,
  ChatToolCallConfirmedAction action,
) {
  if (tc is! ToolCallPendingConfirmationState) return tc;
  final selected = tc.options
      ?.where((o) => o.id == action.selectedOptionId)
      .firstOrNull;
  final meta = action.meta ?? tc.meta;
  return switch (action) {
    ChatToolCallApprovedAction(:final editedToolInput, :final confirmed) =>
      ToolCallRunningState(
        toolCallId: tc.toolCallId,
        toolName: tc.toolName,
        displayName: tc.displayName,
        intention: tc.intention,
        contributor: tc.contributor,
        meta: meta,
        invocationMessage: tc.invocationMessage,
        toolInput: editedToolInput != null && tc.toolInput is InlineToolInput
            ? InlineToolInput(editedToolInput)
            : tc.toolInput,
        confirmed: confirmed,
        selectedOption: selected,
      ),
    ChatToolCallDeniedAction() => ToolCallCancelledState(
      toolCallId: tc.toolCallId,
      toolName: tc.toolName,
      displayName: tc.displayName,
      intention: tc.intention,
      contributor: tc.contributor,
      meta: meta,
      invocationMessage: tc.invocationMessage,
      toolInput: tc.toolInput,
      reason: action.reason,
      reasonMessage: action.reasonMessage,
      userSuggestion: action.userSuggestion,
      selectedOption: selected,
    ),
  };
}

ToolCallState _toolCallComplete(
  ToolCallState tc,
  ChatToolCallCompleteAction action,
) {
  final authRequired = tc is ToolCallAuthRequiredState;
  if (tc is! ToolCallRunningState &&
      tc is! ToolCallPendingConfirmationState &&
      !authRequired) {
    return tc;
  }
  final result = action.result;
  if (authRequired && result.success) return tc;
  final confirmedBefore = tc is! ToolCallPendingConfirmationState;
  final confirmed = confirmedBefore
      ? tc.confirmed ?? ToolCallConfirmationReason.notNeeded
      : ToolCallConfirmationReason.notNeeded;
  final selectedOption = confirmedBefore ? tc.selectedOption : null;
  final content = result.content ?? (authRequired ? tc.content : null);
  final meta = action.meta ?? tc.meta;
  if (action.requiresResultConfirmation == true && !authRequired) {
    return ToolCallPendingResultConfirmationState(
      toolCallId: tc.toolCallId,
      toolName: tc.toolName,
      displayName: tc.displayName,
      intention: tc.intention,
      contributor: tc.contributor,
      meta: meta,
      invocationMessage: tc.invocationMessage!,
      toolInput: tc.toolInput,
      confirmed: confirmed,
      selectedOption: selectedOption,
      success: result.success,
      pastTenseMessage: result.pastTenseMessage,
      content: content,
      structuredContent: result.structuredContent,
      error: result.error,
    );
  }
  return ToolCallCompletedState(
    toolCallId: tc.toolCallId,
    toolName: tc.toolName,
    displayName: tc.displayName,
    intention: tc.intention,
    contributor: tc.contributor,
    meta: meta,
    invocationMessage: tc.invocationMessage!,
    toolInput: tc.toolInput,
    confirmed: confirmed,
    selectedOption: selectedOption,
    success: result.success,
    pastTenseMessage: result.pastTenseMessage,
    content: content,
    structuredContent: result.structuredContent,
    error: result.error,
  );
}

ToolCallState _toolCallResultConfirmed(
  ToolCallState tc,
  ChatToolCallResultConfirmedAction action,
) {
  if (tc is! ToolCallPendingResultConfirmationState) return tc;
  final meta = action.meta ?? tc.meta;
  return action.approved
      ? ToolCallCompletedState(
          toolCallId: tc.toolCallId,
          toolName: tc.toolName,
          displayName: tc.displayName,
          intention: tc.intention,
          contributor: tc.contributor,
          meta: meta,
          invocationMessage: tc.invocationMessage,
          toolInput: tc.toolInput,
          confirmed: tc.confirmed,
          selectedOption: tc.selectedOption,
          success: tc.success,
          pastTenseMessage: tc.pastTenseMessage,
          content: tc.content,
          structuredContent: tc.structuredContent,
          error: tc.error,
        )
      : ToolCallCancelledState(
          toolCallId: tc.toolCallId,
          toolName: tc.toolName,
          displayName: tc.displayName,
          intention: tc.intention,
          contributor: tc.contributor,
          meta: meta,
          invocationMessage: tc.invocationMessage,
          toolInput: tc.toolInput,
          reason: ToolCallCancellationReason.resultDenied,
          selectedOption: tc.selectedOption,
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
    parts.add(InputRequestResponsePart(request: request));
  } else {
    final existing = parts[index] as InputRequestResponsePart;
    parts[index] = InputRequestResponsePart(
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
          part is InputRequestResponsePart &&
          part.response == null &&
          part.request.id == requestId,
    );

ChatState _updateOpenInputRequest(
  ChatState state,
  String requestId,
  InputRequestResponsePart Function(InputRequestResponsePart part) update,
) {
  final active = state.activeTurn;
  if (active == null) return state;
  final index = _openInputRequestIndex(active.responseParts, requestId);
  if (index < 0) return state;
  final parts = [...active.responseParts];
  parts[index] = update(parts[index] as InputRequestResponsePart);
  return _withParts(state, parts);
}

List<PendingMessage> _upsertQueued(
  List<PendingMessage> queued,
  PendingMessage entry,
) => queued.any((m) => m.id == entry.id)
    ? [for (final m in queued) m.id == entry.id ? entry : m]
    : [...queued, entry];

ChatState _pendingRemoved(ChatState state, PendingMessageKind kind, String id) {
  if (kind == PendingMessageKind.steering) {
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
