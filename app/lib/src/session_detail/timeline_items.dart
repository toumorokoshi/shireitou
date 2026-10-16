/// Pure view logic for the session timeline (AV-061 to AV-067).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';

/// One row of the timeline.
sealed class TimelineItem {
  const TimelineItem();
}

/// The user's message that started turn [turnId].
class UserMessageItem extends TimelineItem {
  /// Creates a [UserMessageItem].
  const UserMessageItem(this.turnId, this.message);

  /// Turn ID.
  final String turnId;

  /// The message.
  final Message message;
}

/// A response part of turn [turnId].
class ResponsePartItem extends TimelineItem {
  /// Creates a [ResponsePartItem].
  const ResponsePartItem(this.turnId, this.part, {required this.active});

  /// Turn ID.
  final String turnId;

  /// The part.
  final ResponsePart part;

  /// Whether the turn is still running (parts may still stream).
  final bool active;
}

/// The footer of a finished turn: how it ended, duration and usage.
class TurnFooterItem extends TimelineItem {
  /// Creates a [TurnFooterItem].
  const TurnFooterItem(this.turn);

  /// The finished turn.
  final Turn turn;
}

/// A steering or queued message waiting to be delivered (AV-081).
class PendingMessageItem extends TimelineItem {
  /// Creates a [PendingMessageItem].
  const PendingMessageItem(this.kind, this.pending);

  /// `steering` or `queued`.
  final String kind;

  /// The message.
  final PendingMessage pending;
}

/// Whether [part] is worth a row: empty markdown and reasoning parts (which
/// pi opens before streaming into them) are hidden.
bool _visible(ResponsePart part) => switch (part) {
  MarkdownPart(:final content) ||
  ReasoningPart(:final content) => content.trim().isNotEmpty,
  _ => true,
};

/// Flattens [chat] into timeline rows, oldest first: each turn's message,
/// its visible parts and a footer, then the active turn, then pending
/// messages.
List<TimelineItem> timelineItems(ChatState chat) => [
  for (final turn in chat.turns) ...[
    UserMessageItem(turn.id, turn.message),
    for (final part in turn.responseParts)
      if (_visible(part)) ResponsePartItem(turn.id, part, active: false),
    TurnFooterItem(turn),
  ],
  if (chat.activeTurn case final active?) ...[
    UserMessageItem(active.id, active.message),
    for (final part in active.responseParts)
      if (_visible(part)) ResponsePartItem(active.id, part, active: true),
  ],
  if (chat.steeringMessage case final steering?)
    PendingMessageItem('steering', steering),
  for (final queued in chat.queuedMessages ?? const <PendingMessage>[])
    PendingMessageItem('queued', queued),
];

/// A one-line summary of [toolCall] (AV-063): the past-tense message when
/// finished, else the invocation message, else the display name.
String toolCallSummary(ToolCall toolCall) =>
    stringOrMarkdownText(toolCall.pastTenseMessage) ??
    stringOrMarkdownText(toolCall.invocationMessage) ??
    toolCall.displayName;

/// A label for a tool call's status (AV-063).
String toolCallStatusLabel(ToolCallStatus status) => switch (status) {
  ToolCallStatus.streaming => 'Preparing',
  ToolCallStatus.pendingConfirmation => 'Needs approval',
  ToolCallStatus.running => 'Running',
  ToolCallStatus.authRequired => 'Sign-in required',
  ToolCallStatus.pendingResultConfirmation => 'Review result',
  ToolCallStatus.completed => 'Done',
  ToolCallStatus.cancelled => 'Cancelled',
  ToolCallStatus.unknown => 'Unknown',
};

/// The tool's input for display: the streamed or final input, with JSON
/// pretty-printed. Null when there is none.
String? toolCallInputText(ToolCall toolCall) {
  final input = switch (toolCall.toolInput) {
    final String text => text,
    {'uri': final String uri} => uri,
    _ => toolCall.partialInput,
  };
  if (input == null || input.isEmpty) return null;
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(input));
  } on FormatException {
    return input;
  }
}

/// The tool's text output: text content and terminal previews, joined.
/// Null when there is none.
String? toolCallOutputText(ToolCall toolCall) {
  final texts = [
    for (final content in toolCall.content ?? const <JsonMap>[])
      switch (content) {
        {'type': 'text', 'text': final String text} => text,
        {'type': 'terminal', 'result': {'preview': final String preview}} =>
          preview,
        {'type': final String type} => '[$type]',
        _ => '',
      },
    if (toolCall.error case {'message': final String message}) message,
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
    },
    if (turn.duration case final ms?) '${(ms / 1000).toStringAsFixed(1)} s',
    if (usage?.inputTokens case final tokens?) '${_grouped(tokens)} in',
    if (usage?.outputTokens case final tokens?) '${_grouped(tokens)} out',
    ?usage?.model,
  ].join(' · ');
}

/// Total input and output tokens over [chat]'s turns (AV-067).
({int input, int output}) sessionUsage(ChatState chat) {
  final usages = [
    for (final turn in chat.turns) ?turn.usage,
    ?chat.activeTurn?.usage,
  ];
  return (
    input: usages.fold(0, (sum, u) => sum + (u.inputTokens ?? 0)),
    output: usages.fold(0, (sum, u) => sum + (u.outputTokens ?? 0)),
  );
}

/// The model of the last turn: what the host reported, else what the
/// message asked for.
String? lastModelOf(ChatState chat) {
  final turns = [...chat.turns.map((t) => (t.usage, t.message))];
  if (chat.activeTurn case final a?) turns.add((a.usage, a.message));
  for (final (usage, message) in turns.reversed) {
    if (usage?.model ?? message.model?.id case final model?) return model;
  }
  return null;
}
