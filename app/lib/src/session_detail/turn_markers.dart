/// Pure logic of the turn rail beside the timeline (AV-074): one marker
/// per user turn, the turn in view, the turn a step away, and where the
/// dots go.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import 'timeline_items.dart';

/// How a turn ended, or that it still runs; the rail draws each
/// differently.
enum TurnMarkerState {
  /// Finished normally.
  done,

  /// Cancelled by the user.
  cancelled,

  /// Ended in an error.
  error,

  /// Still running (the chat's active turn).
  running,
}

/// One user turn of the timeline.
class TurnMarker {
  /// Creates a [TurnMarker].
  const TurnMarker({
    required this.turnId,
    required this.text,
    required this.state,
    required this.row,
  });

  /// Turn ID.
  final String turnId;

  /// The first line of the user's message.
  final String text;

  /// How the turn ended, or that it still runs.
  final TurnMarkerState state;

  /// The index of the turn's [UserMessageItem] in [TimelineRows], oldest
  /// first.
  final int row;
}

/// The first non-empty line of [text], cut to [max] characters with an
/// ellipsis.
String firstLine(String text, {int max = 80}) {
  final line = text
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.isNotEmpty, orElse: () => '');
  return line.length <= max ? line : '${line.substring(0, max - 1)}…';
}

TurnMarkerState _markerState(TurnState state) => switch (state) {
  TurnState.cancelled => TurnMarkerState.cancelled,
  TurnState.error => TurnMarkerState.error,
  TurnState.complete || TurnState.$unknown => TurnMarkerState.done,
};

/// The markers of [chat]'s loaded turns, oldest first, each with its row
/// in [rows] (`timelineItems(chat)`). Turns the host still holds back
/// (`turnsNextCursor`) have none until they are paged in.
List<TurnMarker> turnMarkers(ChatState chat, TimelineRows rows) => [
  for (final turn in chat.turns)
    if (rows.indexOfKey(UserMessageItem(turn.id, turn.message).key)
        case final row?)
      TurnMarker(
        turnId: turn.id,
        text: firstLine(turn.message.text),
        state: _markerState(turn.state),
        row: row,
      ),
  if (chat.activeTurn case final active?)
    if (rows.indexOfKey(UserMessageItem(active.id, active.message).key)
        case final row?)
      TurnMarker(
        turnId: active.id,
        text: firstLine(active.message.text),
        state: TurnMarkerState.running,
        row: row,
      ),
];

/// The screen reader label of marker [index] (0-based) of [markers]:
/// "Turn 3: Fix the tests", and how it ended when it did not finish
/// normally.
String turnMarkerLabel(List<TurnMarker> markers, int index) {
  final marker = markers[index];
  final suffix = switch (marker.state) {
    TurnMarkerState.done => '',
    TurnMarkerState.cancelled => ' (cancelled)',
    TurnMarkerState.error => ' (failed)',
    TurnMarkerState.running => ' (running)',
  };
  return 'Turn ${index + 1}: ${marker.text}$suffix';
}

/// The index of the turn in view: the newest of [markers] whose message
/// is at or above [topRow], the oldest row on screen. Null when there
/// are no markers; 0 while only rows before the first turn show.
int? currentTurn(List<TurnMarker> markers, int topRow) {
  if (markers.isEmpty) return null;
  final above = markers.lastIndexWhere((m) => m.row <= topRow);
  return above < 0 ? 0 : above;
}

/// The index of the marker to go to from [topRow], the oldest row on
/// screen: for [delta] < 0 the newest turn whose message starts above it,
/// else the oldest turn whose message starts below it. Null when there is
/// none (for a step back, older turns may still need paging in).
int? steppedTurn(List<TurnMarker> markers, int topRow, int delta) {
  final index = delta < 0
      ? markers.lastIndexWhere((m) => m.row < topRow)
      : markers.indexWhere((m) => m.row > topRow);
  return index < 0 ? null : index;
}

/// Where [count] dots go on a rail [height] high: [spacing] between dot
/// centres (from [maxSpacing] down to [minSpacing], compressed to fit),
/// and whether the rail [scrolls] because even [minSpacing] does not fit.
({double spacing, bool scrolls}) turnRailLayout(
  int count,
  double height, {
  double minSpacing = 4,
  double maxSpacing = 24,
}) {
  if (count == 0) return (spacing: maxSpacing, scrolls: false);
  final fit = height / count;
  return (
    spacing: fit.clamp(minSpacing, maxSpacing),
    scrolls: fit < minSpacing,
  );
}

/// The index of the dot at [dy] along a rail of [count] dots [spacing]
/// apart (for scrubbing), clamped to the dots.
int turnAtOffset(double dy, double spacing, int count) =>
    (dy / spacing).floor().clamp(0, count - 1);

/// The scroll offset that centres dot [index] on a scrolling rail of
/// [count] dots [spacing] apart, [height] high.
double turnRailScrollOffset(
  int index,
  int count,
  double spacing,
  double height,
) {
  final max = count * spacing - height;
  if (max <= 0) return 0;
  return ((index + 0.5) * spacing - height / 2).clamp(0, max);
}

/// How close to the timeline's right edge, in logical pixels, the pointer
/// reveals the rail.
const turnRailHoverZone = 64.0;

/// Whether a pointer at [dx] is within [turnRailHoverZone] of the right
/// edge of a timeline [width] wide.
bool nearRightEdge(double dx, double width) => dx >= width - turnRailHoverZone;

/// Whether [platform] is a phone or tablet one, where there is no hover.
bool isTouchPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.android ||
    platform == TargetPlatform.iOS ||
    platform == TargetPlatform.fuchsia;

/// Whether the rail shows (AV-074): always on [compact] layouts and for
/// [touch] input, else only while the pointer is near it ([hovered]).
bool turnRailVisible({
  required bool hovered,
  required bool touch,
  required bool compact,
}) => hovered || touch || compact;
