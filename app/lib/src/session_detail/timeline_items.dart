/// Pure view logic for the session timeline (AV-061 to AV-067, AV-095).
library;

import 'dart:collection';
import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';

import 'todo_list.dart';

/// One row of the timeline.
sealed class TimelineItem {
  const TimelineItem();

  /// A key that stays the same while the row exists, also when the turn
  /// finishes or older turns are paged in (so row state such as an
  /// expanded card follows the row).
  String get key;
}

/// The user's message that started turn [turnId].
class UserMessageItem extends TimelineItem {
  /// Creates a [UserMessageItem].
  const UserMessageItem(this.turnId, this.message, {this.startedAt});

  /// Turn ID.
  final String turnId;

  /// The message.
  final Message message;

  /// ISO 8601 timestamp at which the turn started, when the host sent it.
  final String? startedAt;

  @override
  String get key => '$turnId/message';
}

/// A response part of turn [turnId].
class ResponsePartItem extends TimelineItem {
  /// Creates a [ResponsePartItem]; [index] is the part's position in the
  /// turn, for parts without an ID.
  const ResponsePartItem(
    this.turnId,
    this.part, {
    required this.active,
    this.index = 0,
  });

  /// Turn ID.
  final String turnId;

  /// The part.
  final ResponsePart part;

  /// Whether the turn is still running (parts may still stream).
  final bool active;

  /// The part's position in its turn.
  final int index;

  @override
  String get key => '$turnId/${partKey(part) ?? '#$index'}';
}

/// Consecutive similar tool calls of turn [turnId], shown as one
/// expandable row (AV-064).
class ToolCallGroupItem extends TimelineItem {
  /// Creates a [ToolCallGroupItem].
  const ToolCallGroupItem(this.turnId, this.calls, {required this.active});

  /// Turn ID.
  final String turnId;

  /// The calls, in order (at least two, all with the same tool name).
  final List<ToolCallState> calls;

  /// Whether the turn is still running.
  final bool active;

  @override
  String get key => '$turnId/group/${calls.first.toolCallId}';
}

/// The steps of turn [turnId] (AV-095): its tool calls, reasoning and the
/// replies between them, collapsed into one "Completed N steps in T" row
/// that expands to [steps]. Calls that wait on the user, todo lists,
/// subagents, input requests and errors are not steps: they stay rows of
/// their own, so they are never hidden.
class StepsItem extends TimelineItem {
  /// Creates a [StepsItem].
  const StepsItem(
    this.turnId,
    this.steps, {
    required this.count,
    required this.active,
    this.duration,
    this.working = false,
    this.activity,
  });

  /// Turn ID.
  final String turnId;

  /// The rows shown when expanded: [ResponsePartItem]s and
  /// [ToolCallGroupItem]s, in order.
  final List<TimelineItem> steps;

  /// How many response parts the steps hold (each call of a group counts).
  final int count;

  /// Whether the turn is still running.
  final bool active;

  /// The finished turn's duration in milliseconds, when the host sent it.
  final int? duration;

  /// Whether the chat is working ([isChatWorking]): the row then shows
  /// the typing indicator in place of a [WorkingItem] (AV-072).
  final bool working;

  /// What the agent is doing now while [working], or null.
  final String? activity;

  @override
  String get key => '$turnId/steps';
}

/// The footer of a finished turn: how it ended, duration and usage.
class TurnFooterItem extends TimelineItem {
  /// Creates a [TurnFooterItem].
  const TurnFooterItem(this.turn);

  /// The finished turn.
  final Turn turn;

  @override
  String get key => '${turn.id}/footer';
}

/// The oldest row while the host holds older turns back
/// (`turnsNextCursor`, AV-068): building it pages them in.
class LoadOlderItem extends TimelineItem {
  /// Creates a [LoadOlderItem] for [cursor].
  const LoadOlderItem(this.cursor);

  /// The chat's `turnsNextCursor`.
  final String cursor;

  @override
  String get key => 'older/$cursor';
}

/// The last row while the chat is working (and not waiting on the user):
/// a typing indicator with the chat's current [activity], if any.
class WorkingItem extends TimelineItem {
  /// Creates a [WorkingItem].
  const WorkingItem({this.activity});

  /// What the agent is doing now (`activity`), or null.
  final String? activity;

  @override
  String get key => 'working';
}

/// Whether [chat] is working: a turn is running ([SessionStatus]
/// `InProgress` bit, or an active turn) and it does not wait on the user
/// (`InputNeeded`), whose approval or question is shown instead.
bool isChatWorking(ChatState chat) =>
    (chat.status.isInProgress || chat.activeTurn != null) &&
    !chat.status.isInputNeeded;

/// The screen reader label of the working indicator: "Agent is working",
/// with [activity] when there is one.
String workingLabel(String? activity) =>
    activity == null ? 'Agent is working' : 'Agent is working: $activity';

/// The opacity of typing dot [dot] (0 to 2) at animation progress [t]
/// (0 to 1): each dot pulses from 0.3 to 1 and back, a third of a cycle
/// after the one before it.
double typingDotOpacity(int dot, double t) {
  final phase = (t - dot / 3) % 1;
  final pulse = 1 - (2 * phase - 1).abs();
  return 0.3 + 0.7 * pulse;
}

/// A steering or queued message waiting to be delivered (AV-081).
class PendingMessageItem {
  /// Creates a [PendingMessageItem].
  const PendingMessageItem(this.kind, this.pending);

  /// Steering or queued.
  final PendingMessageKind kind;

  /// The message.
  final PendingMessage pending;
}

/// A stable identifier of [part] within its turn, when it has one.
String? partKey(ResponsePart part) => switch (part) {
  MarkdownResponsePart(:final id) || ReasoningResponsePart(:final id) => id,
  ToolCallResponsePart(:final toolCall) => 'tool/${toolCall.toolCallId}',
  InputRequestResponsePart(:final request) => 'input/${request.id}',
  _ => null,
};

/// Whether [part] is worth a row: empty markdown and reasoning parts (which
/// pi opens before streaming into them) are hidden.
bool _visible(ResponsePart part) => switch (part) {
  MarkdownResponsePart(:final content) ||
  ReasoningResponsePart(:final content) => content.trim().isNotEmpty,
  _ => true,
};

/// Whether [toolCall] can be folded into a group: it does not wait on the
/// user, is not a todo list (AV-070) and has no inline preview (terminal,
/// diff or subagent) that the group would hide.
bool _groupable(ToolCallState toolCall) =>
    !toolCall.isBlocking &&
    !isTodoTool(toolCall.toolName) &&
    toolCall is! ToolCallStateUnknown &&
    !(toolCall.content ?? const <ToolResultContent>[]).any(
      (c) =>
          c is ToolResultTerminalContent ||
          c is ToolResultFileEditContent ||
          c is ToolResultSubagentContent,
    );

/// The rows of one turn's [parts]: visible parts, with runs of two or more
/// consecutive groupable calls of the same tool folded into a
/// [ToolCallGroupItem] (AV-064).
List<TimelineItem> partItems(
  String turnId,
  List<ResponsePart> parts, {
  required bool active,
}) => _partItems(turnId, parts.indexed, active: active);

/// [partItems] over parts paired with their index in the turn, which keys
/// the parts without an ID.
List<TimelineItem> _partItems(
  String turnId,
  Iterable<(int, ResponsePart)> parts, {
  required bool active,
}) {
  final items = <TimelineItem>[];
  final run = <(int, ToolCallState)>[];
  void flush() {
    if (run.length >= 2) {
      items.add(
        ToolCallGroupItem(turnId, [
          for (final (_, c) in run) c,
        ], active: active),
      );
    } else {
      for (final (index, call) in run) {
        items.add(
          ResponsePartItem(
            turnId,
            ToolCallResponsePart(toolCall: call),
            active: active,
            index: index,
          ),
        );
      }
    }
    run.clear();
  }

  for (final (index, part) in parts) {
    if (!_visible(part)) continue;
    if (part is ToolCallResponsePart && _groupable(part.toolCall)) {
      if (run.isNotEmpty && run.first.$2.toolName != part.toolCall.toolName) {
        flush();
      }
      run.add((index, part.toolCall));
      continue;
    }
    flush();
    items.add(ResponsePartItem(turnId, part, active: active, index: index));
  }
  flush();
  return items;
}

/// Whether [part] is a step that folds into the turn's [StepsItem]
/// (AV-095): reasoning, and tool calls that do not wait on the user and
/// are not todo lists (AV-070) or subagents (AV-069), which stay in view.
bool isStep(ResponsePart part) => switch (part) {
  ReasoningResponsePart() => true,
  ToolCallResponsePart(:final toolCall) =>
    !toolCall.isBlocking &&
        !isTodoTool(toolCall.toolName) &&
        !(toolCall.content ?? const <ToolResultContent>[]).any(
          (c) => c is ToolResultSubagentContent,
        ),
  _ => false,
};

/// The rows of one turn's [parts] with its steps collapsed (AV-095): the
/// visible parts before the first step, a [StepsItem] holding every step
/// and the markdown between steps, then the remaining parts in order
/// (calls that need attention, input requests, errors and the reply after
/// the last step). Without steps, the same rows as [partItems].
/// [working] and [activity] go to the [StepsItem] (see
/// [StepsItem.working]).
List<TimelineItem> turnPartItems(
  String turnId,
  List<ResponsePart> parts, {
  required bool active,
  int? duration,
  bool working = false,
  String? activity,
}) {
  final visible = [
    for (final entry in parts.indexed)
      if (_visible(entry.$2)) entry,
  ];
  final first = visible.indexWhere((e) => isStep(e.$2));
  if (first < 0) return _partItems(turnId, visible, active: active);
  final last = visible.lastIndexWhere((e) => isStep(e.$2));
  final folded = [
    for (final entry in visible.sublist(first, last + 1))
      if (isStep(entry.$2) || entry.$2 is MarkdownResponsePart) entry,
  ];
  return [
    ..._partItems(turnId, visible.sublist(0, first), active: active),
    StepsItem(
      turnId,
      _partItems(turnId, folded, active: active),
      count: folded.length,
      active: active,
      duration: duration,
      working: working,
      activity: activity,
    ),
    ..._partItems(turnId, [
      for (final entry in visible.sublist(first, last + 1))
        if (!isStep(entry.$2) && entry.$2 is! MarkdownResponsePart) entry,
      ...visible.sublist(last + 1),
    ], active: active),
  ];
}

/// The number of tool calls among [steps] that failed (each call of a
/// group counts).
int failedSteps(List<TimelineItem> steps) => [
  for (final step in steps)
    ...switch (step) {
      ToolCallGroupItem(:final calls) => calls,
      ResponsePartItem(part: ToolCallResponsePart(:final toolCall)) => [
        toolCall,
      ],
      _ => const <ToolCallState>[],
    },
].where((c) => c is ToolCallCompletedState && !c.success).length;

/// "1m 47s", "12s" or "1h 3m": a turn's [ms] for the steps line.
String formatStepsDuration(int ms) {
  final seconds = (ms / 1000).round();
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ${seconds % 60}s';
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

/// The steps line of [item] (AV-095): "Working… 3 steps" while the turn
/// runs, else "Completed 3 steps in 1m 47s" (without the time when the
/// host did not send the duration), and how many calls failed.
String stepsSummary(StepsItem item) {
  final steps = '${item.count} ${item.count == 1 ? 'step' : 'steps'}';
  final failed = failedSteps(item.steps);
  return [
    if (item.active)
      'Working… $steps'
    else
      [
        'Completed $steps',
        if (item.duration case final ms?) 'in ${formatStepsDuration(ms)}',
      ].join(' '),
    if (failed > 0) '$failed failed',
  ].join(' · ');
}

final _turnRows = Expando<List<TimelineItem>>('turn rows');

/// The rows of a finished [turn], computed once per turn object (turns are
/// immutable, so a turn the reducer did not touch keeps its rows).
List<TimelineItem> turnItems(Turn turn) =>
    _turnRows[turn] ??= List.unmodifiable([
      UserMessageItem(turn.id, turn.message, startedAt: turn.startedAt),
      ...turnPartItems(
        turn.id,
        turn.responseParts,
        active: false,
        duration: turn.duration,
      ),
      TurnFooterItem(turn),
    ]);

/// The rows of every finished turn, oldest first, and each row's index
/// by key.
typedef _Settled = ({List<TimelineItem> rows, Map<String, int> index});

final _settledRows = Expando<_Settled>('settled rows');

/// The rows of [turns], computed once per list: the chat reducer keeps the
/// same `turns` list while a turn streams, so deltas only rebuild the
/// active turn's rows.
_Settled _settled(List<Turn> turns) => _settledRows[turns] ??= () {
  final rows = List<TimelineItem>.unmodifiable([
    for (final turn in turns) ...turnItems(turn),
  ]);
  return (rows: rows, index: {for (final (i, row) in rows.indexed) row.key: i});
}();

/// The timeline of a chat: a [LoadOlderItem] while older turns are held
/// back, the finished turns' rows (shared between states), then the
/// active turn's rows. Indexable without copying the finished rows.
class TimelineRows with ListMixin<TimelineItem> {
  TimelineRows._(this._older, this._settled, this._live);

  final LoadOlderItem? _older;
  final _Settled _settled;
  final List<TimelineItem> _live;

  int get _offset => _older == null ? 0 : 1;

  @override
  int get length => _offset + _settled.rows.length + _live.length;

  @override
  set length(int _) => throw UnsupportedError('read-only');

  @override
  TimelineItem operator [](int index) {
    if (_older case final older? when index == 0) return older;
    final i = index - _offset;
    final settled = _settled.rows;
    return i < settled.length ? settled[i] : _live[i - settled.length];
  }

  @override
  void operator []=(int index, TimelineItem value) =>
      throw UnsupportedError('read-only');

  /// The index of the row with [key], or null when there is none.
  int? indexOfKey(String key) {
    if (_older?.key == key) return 0;
    if (_settled.index[key] case final i?) return _offset + i;
    final live = _live.indexWhere((item) => item.key == key);
    return live < 0 ? null : _offset + _settled.rows.length + live;
  }
}

/// Flattens [chat] into timeline rows, oldest first: a [LoadOlderItem]
/// when the host holds older turns back, each finished turn's message,
/// visible parts (steps collapsed, similar tool calls grouped) and footer,
/// then the active turn, then a [WorkingItem] while the chat is working
/// ([isChatWorking]) and the active turn has no [StepsItem] to show it.
/// Pending messages are not rows; see [pendingMessages].
TimelineRows timelineItems(ChatState chat) {
  final working = isChatWorking(chat);
  final activity = switch (chat.activity?.trim()) {
    final activity? when activity.isNotEmpty => activity,
    _ => null,
  };
  final live = [
    if (chat.activeTurn case final active?) ...[
      UserMessageItem(active.id, active.message, startedAt: active.startedAt),
      ...turnPartItems(
        active.id,
        active.responseParts,
        active: true,
        working: working,
        activity: activity,
      ),
    ],
  ];
  return TimelineRows._(
    switch (chat.turnsNextCursor) {
      final cursor? => LoadOlderItem(cursor),
      null => null,
    },
    _settled(chat.turns),
    [
      ...live,
      if (working && !live.any((item) => item is StepsItem))
        WorkingItem(activity: activity),
    ],
  );
}

/// The steering message, then the queued ones in order (AV-081).
List<PendingMessageItem> pendingMessages(ChatState chat) => [
  if (chat.steeringMessage case final steering?)
    PendingMessageItem(PendingMessageKind.steering, steering),
  for (final queued in chat.queuedMessages ?? const <PendingMessage>[])
    PendingMessageItem(PendingMessageKind.queued, queued),
];

/// A one-line summary of a group of [calls] of one tool (AV-064):
/// "Read · 3 calls".
String toolCallGroupSummary(List<ToolCallState> calls) =>
    '${calls.first.displayName} · ${calls.length} calls';

/// The status of a group: running while any call runs, else how many
/// failed or were cancelled.
String toolCallGroupStatus(List<ToolCallState> calls) {
  if (calls.any((c) => !c.isFinished)) return 'Running';
  final failed = calls
      .where((c) => c is ToolCallCompletedState && !c.success)
      .length;
  final cancelled = calls.whereType<ToolCallCancelledState>().length;
  return [
    if (failed > 0) '$failed failed',
    if (cancelled > 0) '$cancelled cancelled',
  ].join(', ').ifEmpty('Done');
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// A one-line summary of [toolCall] (AV-063): the past-tense message when
/// finished, else the invocation message, else the display name.
String toolCallSummary(ToolCallState toolCall) =>
    switch (toolCall) {
      ToolCallCompletedState(:final pastTenseMessage) ||
      ToolCallPendingResultConfirmationState(
        :final pastTenseMessage,
      ) => pastTenseMessage.text,
      _ => null,
    } ??
    toolCall.invocationMessage?.text ??
    toolCall.displayName;

/// A label for a tool call's status (AV-063).
String toolCallStatusLabel(ToolCallState toolCall) => switch (toolCall) {
  ToolCallStreamingState() => 'Preparing',
  ToolCallPendingConfirmationState() => 'Needs approval',
  ToolCallRunningState() => 'Running',
  ToolCallAuthRequiredState() => 'Sign-in required',
  ToolCallPendingResultConfirmationState() => 'Review result',
  ToolCallCompletedState() => 'Done',
  ToolCallCancelledState() => 'Cancelled',
  ToolCallStateUnknown() => 'Unknown',
};

/// The tool's input for display: the streamed or final input, with JSON
/// pretty-printed. Null when there is none.
String? toolCallInputText(ToolCallState toolCall) {
  final input = switch (toolCall.toolInput) {
    InlineToolInput(:final value) => value,
    ContentRef(:final uri) => uri,
    null => switch (toolCall) {
      ToolCallStreamingState(:final partialInput) => partialInput,
      _ => null,
    },
  };
  if (input == null || input.isEmpty) return null;
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(input));
  } on FormatException {
    return input;
  }
}

/// The tool's text output: text content and the error, joined. Terminal
/// output, file edits and subagents have their own previews
/// ([toolCallPreviews]). Null when there is none.
String? toolCallOutputText(ToolCallState toolCall) {
  final error = switch (toolCall) {
    ToolCallCompletedState(:final error) ||
    ToolCallPendingResultConfirmationState(:final error) => error,
    _ => null,
  };
  final texts = [
    for (final content in toolCall.content ?? const <ToolResultContent>[])
      switch (content) {
        ToolResultTextContent(:final text) => text,
        // Shown by their own previews.
        ToolResultTerminalContent() ||
        ToolResultFileEditContent() ||
        ToolResultSubagentContent() => '',
        _ => '[${content.type}]',
      },
    ?error?.message,
  ].where((text) => text.isNotEmpty);
  return texts.isEmpty ? null : texts.join('\n');
}

/// "1,234": [value] with thousands separators.
String _grouped(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// A footer line for [turn] (AV-067): end state, duration and tokens.
String turnFooterText(Turn turn) {
  final usage = turn.usage;
  return [
    switch (turn.state) {
      TurnState.complete => 'Done',
      TurnState.cancelled => 'Cancelled',
      TurnState.error => 'Failed',
      TurnState.$unknown => 'Ended',
    },
    if (turn.duration case final ms?) formatStepsDuration(ms),
    if (usage?.inputTokens case final tokens?) '${_grouped(tokens)} in',
    if (usage?.outputTokens case final tokens?) '${_grouped(tokens)} out',
    ?usage?.model,
  ].join(' · ');
}

typedef _Usage = ({int input, int output});

final _turnsUsage = Expando<_Usage>('turns usage');

/// Total input and output tokens over [chat]'s turns (AV-067). The
/// finished turns' total is computed once per `turns` list.
({int input, int output}) sessionUsage(ChatState chat) {
  final settled = _turnsUsage[chat.turns] ??= chat.turns.fold<_Usage>(
    (input: 0, output: 0),
    (sum, t) => (
      input: sum.input + (t.usage?.inputTokens ?? 0),
      output: sum.output + (t.usage?.outputTokens ?? 0),
    ),
  );
  final active = chat.activeTurn?.usage;
  return (
    input: settled.input + (active?.inputTokens ?? 0),
    output: settled.output + (active?.outputTokens ?? 0),
  );
}

/// The model of the last turn: what the host reported, else what the
/// message asked for.
String? lastModelOf(ChatState chat) {
  if (chat.activeTurn case final a?) {
    if (a.usage?.model ?? a.message.model?.id case final model?) return model;
  }
  for (final turn in chat.turns.reversed) {
    if (turn.usage?.model ?? turn.message.model?.id case final model?) {
      return model;
    }
  }
  return null;
}

/// The model the user last asked for in [chat] (`Message.model`, with its
/// options), to keep using it for follow-ups; null when every message used
/// the host's default.
ModelSelection? lastModelSelection(ChatState chat) {
  if (chat.activeTurn?.message.model case final model?) return model;
  for (final turn in chat.turns.reversed) {
    if (turn.message.model case final model?) return model;
  }
  return null;
}

/// The inline previews of [toolCall] (AV-065, AV-069): terminals, file
/// edits (also those awaiting confirmation) and subagent chats.
List<ToolResultContent> toolCallPreviews(ToolCallState toolCall) => [
  for (final content in toolCall.content ?? const <ToolResultContent>[])
    if (content is ToolResultTerminalContent ||
        content is ToolResultFileEditContent ||
        content is ToolResultSubagentContent)
      content,
  if (toolCall case ToolCallPendingConfirmationState(:final edits?))
    for (final edit in edits.items)
      ToolResultFileEditContent(
        before: edit.before,
        after: edit.after,
        diff: edit.diff,
      ),
];

/// [options] split into runs of the same `group`, in the host's order,
/// so a divider can go between groups (AV-083).
List<List<ConfirmationOption>> confirmationOptionGroups(
  List<ConfirmationOption> options,
) {
  final groups = <List<ConfirmationOption>>[];
  for (final option in options) {
    if (groups.isNotEmpty && groups.last.last.group == option.group) {
      groups.last.add(option);
    } else {
      groups.add([option]);
    }
  }
  return groups;
}

/// How risky a judged tool call is, from its safety score.
enum RiskLevel {
  /// Safety of 0.7 or more.
  low('Low risk'),

  /// Safety from 0.4 to 0.7.
  medium('Medium risk'),

  /// Safety under 0.4.
  high('High risk');

  const RiskLevel(this.label);

  /// The label shown.
  final String label;
}

/// The [RiskLevel] of a judge's [safety] score (0 unsafe, 1 safe).
RiskLevel riskLevel(num safety) => safety >= 0.7
    ? RiskLevel.low
    : safety >= 0.4
    ? RiskLevel.medium
    : RiskLevel.high;
