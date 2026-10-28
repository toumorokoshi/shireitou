/// How long tool calls ran, as this client saw them (AHP-032). AHP carries
/// a producer-measured duration for turns (`chat/turnComplete`) and
/// terminal commands, but none for a tool call, and its timestamps come
/// from other clocks. So the client times the status changes it receives
/// with its own clock: an estimate, which includes network delays.
library;

import 'package:meta/meta.dart';

import 'host_state.dart';
import 'wire.dart';

/// The time one tool call spent `running`, as observed by this client.
@immutable
final class ToolCallTiming {
  /// Creates a [ToolCallTiming].
  const ToolCallTiming({this.ran, this.runningSince, this.partial = false});

  /// Time spent running in earlier, closed intervals; null until the call
  /// is first seen running. Waiting on approval or sign-in is not counted.
  final Duration? ran;

  /// When the current running interval began; null when not running.
  final DateTime? runningSince;

  /// Whether the call may have run while this client was not watching
  /// (first seen already running, or the connection or subscription was
  /// lost while it ran), so [elapsed] is a lower bound.
  final bool partial;

  /// Whether the call is running now.
  bool get running => runningSince != null;

  /// The time spent running up to [now]; null when it never ran.
  Duration? elapsed(DateTime now) => switch (runningSince) {
    final since? => (ran ?? Duration.zero) + now.difference(since),
    null => ran,
  };

  ToolCallTiming _started(DateTime now) => ToolCallTiming(
    ran: ran ?? Duration.zero,
    runningSince: now,
    partial: partial,
  );

  ToolCallTiming _stopped(DateTime now, {bool lost = false}) =>
      ToolCallTiming(ran: elapsed(now), partial: partial || lost);

  @override
  bool operator ==(Object other) =>
      other is ToolCallTiming &&
      other.ran == ran &&
      other.runningSince == runningSince &&
      other.partial == partial;

  @override
  int get hashCode => Object.hash(ran, runningSince, partial);

  @override
  String toString() =>
      'ToolCallTiming(ran: $ran, runningSince: $runningSince, '
      'partial: $partial)';
}

/// Tool call timings by chat URI, then `toolCallId`.
typedef ToolCallTimings = Map<String, Map<String, ToolCallTiming>>;

/// Advances [timings] to [state], observed at [now]. Call it with every
/// state the client publishes: each action arrives as its own state, so
/// every status change is seen when it happens. Returns [timings] itself
/// when nothing changed.
///
/// A call is timed from its first sighting before it finishes. Calls
/// first seen running are [ToolCallTiming.partial]; calls first seen
/// finished get no timing. While not connected, or once its chat is no
/// longer mirrored, a running call's interval is closed and marked
/// partial; it reopens if the call is still running when seen again.
ToolCallTimings observeToolCalls(
  ToolCallTimings timings,
  HostState state,
  DateTime now,
) {
  final connected = state.status == ConnectionStatus.connected;
  final chats = {...timings.keys, if (connected) ...state.chatChannels.keys};
  ToolCallTimings? next;
  for (final chat in chats) {
    final mirror = connected ? state.chatChannels[chat] : null;
    final before = timings[chat] ?? const <String, ToolCallTiming>{};
    final after = _observeChat(
      before,
      _activeCalls(mirror?.state),
      now,
      watching: mirror != null,
    );
    if (identical(after, before)) continue;
    (next ??= {...timings})[chat] = after;
  }
  return next ?? timings;
}

Map<String, ToolCallTiming> _observeChat(
  Map<String, ToolCallTiming> before,
  Map<String, ToolCallState> calls,
  DateTime now, {
  required bool watching,
}) {
  Map<String, ToolCallTiming>? after;
  void put(String id, ToolCallTiming timing) =>
      (after ??= {...before})[id] = timing;
  for (final MapEntry(key: id, value: call) in calls.entries) {
    final previous = before[id];
    final timing = _observeCall(previous, call, now);
    if (timing != null && timing != previous) put(id, timing);
  }
  // Calls that left the active turn while running ended with it.
  for (final MapEntry(key: id, value: timing) in before.entries) {
    if (timing.running && !calls.containsKey(id)) {
      put(id, timing._stopped(now, lost: !watching));
    }
  }
  return after ?? before;
}

ToolCallTiming? _observeCall(
  ToolCallTiming? previous,
  ToolCallState call,
  DateTime now,
) {
  final running = call is ToolCallRunningState;
  if (previous == null) {
    return switch (call) {
      ToolCallStreamingState() ||
      ToolCallPendingConfirmationState() => const ToolCallTiming(),
      ToolCallRunningState() => ToolCallTiming(
        ran: Duration.zero,
        runningSince: now,
        partial: true,
      ),
      ToolCallAuthRequiredState() || ToolCallPendingResultConfirmationState() =>
        const ToolCallTiming(partial: true),
      _ => null,
    };
  }
  if (running && !previous.running) return previous._started(now);
  if (!running && previous.running) return previous._stopped(now);
  return previous;
}

/// The unfinished turn's tool calls by id; finished turns hold only
/// finished calls.
Map<String, ToolCallState> _activeCalls(ChatState? chat) => {
  for (final part in chat?.activeTurn?.responseParts ?? const [])
    if (part case ToolCallResponsePart(:final toolCall))
      toolCall.toolCallId: toolCall,
};
