/// Write-ahead state for one channel (AHP-022).
///
/// A [ChannelMirror] keeps the state confirmed by the host and the actions
/// this client dispatched that the host has not echoed yet. The visible
/// [ChannelMirror.state] is the confirmed state with the pending actions
/// replayed on top, so optimistic changes show immediately and are rolled
/// back when the host rejects them.
library;

import 'package:meta/meta.dart';

import 'wire.dart';

/// Applies a raw JSON action to a channel state.
typedef JsonReducer<S> = S Function(S state, JsonMap action);

/// An action this client dispatched and the host has not echoed yet.
typedef PendingAction = ({int clientSeq, JsonMap action});

/// Confirmed state, pending actions, and the visible state of one channel.
@immutable
class ChannelMirror<S> {
  const ChannelMirror._(this.confirmed, this.pending, this.state);

  /// A mirror of a fresh snapshot, with no pending actions.
  const ChannelMirror.snapshot(S state) : this._(state, const [], state);

  /// The state as of the last action the host sent.
  final S confirmed;

  /// Dispatched actions not yet echoed, in `clientSeq` order.
  final List<PendingAction> pending;

  /// [confirmed] with [pending] applied; what the UI shows.
  final S state;
}

/// Applies a client-dispatched [action] optimistically.
ChannelMirror<S> applyPendingAction<S>(
  ChannelMirror<S> mirror,
  PendingAction action,
  JsonReducer<S> reduce,
) => ChannelMirror._(
  mirror.confirmed,
  List.unmodifiable([...mirror.pending, action]),
  reduce(mirror.state, action.action),
);

/// Applies an action [envelope] from the host.
///
/// An echo of one of this client's actions (matching [clientId] and
/// `clientSeq`) removes it from the pending list. Accepted actions advance
/// the confirmed state; rejected ones (`rejectionReason`) do not, which
/// rolls the optimistic change back.
ChannelMirror<S> applyHostEnvelope<S>(
  ChannelMirror<S> mirror,
  ActionEnvelope envelope,
  JsonReducer<S> reduce, {
  required String clientId,
}) {
  final origin = envelope.origin;
  final pending = origin != null && origin.clientId == clientId
      ? [
          for (final p in mirror.pending)
            if (p.clientSeq != origin.clientSeq) p,
        ]
      : mirror.pending;
  final confirmed = envelope.rejectionReason == null
      ? reduce(mirror.confirmed, envelope.action)
      : mirror.confirmed;
  if (pending.isEmpty) return ChannelMirror._(confirmed, const [], confirmed);
  return ChannelMirror._(
    confirmed,
    List.unmodifiable(pending),
    pending.fold(confirmed, (state, p) => reduce(state, p.action)),
  );
}

/// Removes the pending action [clientSeq] without confirming it, which
/// rolls its optimistic change back. Unknown sequence numbers are a no-op.
ChannelMirror<S> dropPendingAction<S>(
  ChannelMirror<S> mirror,
  int clientSeq,
  JsonReducer<S> reduce,
) {
  if (!mirror.pending.any((p) => p.clientSeq == clientSeq)) return mirror;
  final pending = [
    for (final p in mirror.pending)
      if (p.clientSeq != clientSeq) p,
  ];
  return ChannelMirror._(
    mirror.confirmed,
    List.unmodifiable(pending),
    pending.fold(mirror.confirmed, (state, p) => reduce(state, p.action)),
  );
}

/// Drops every pending action, leaving the confirmed state. Used after a
/// reconnect, when the host has either echoed an action (in the replay) or
/// never received it.
ChannelMirror<S> clearPendingActions<S>(ChannelMirror<S> mirror) =>
    mirror.pending.isEmpty
    ? mirror
    : ChannelMirror._(mirror.confirmed, const [], mirror.confirmed);

/// Why a write-ahead action was undone.
enum ActionFailureKind {
  /// The host echoed it with a `rejectionReason`.
  rejected,

  /// The host did not echo it within the pending-action timeout.
  timedOut,

  /// The connection dropped before the host echoed it. After a replay the
  /// host never received it; after a snapshot (or a fresh `initialize`) it
  /// may have, and the snapshot shows the host's state either way.
  connectionLost,
}

/// A dispatched action that was rolled back, reported to observers.
@immutable
class ActionFailure {
  /// Creates an [ActionFailure].
  const ActionFailure({
    required this.channel,
    required this.clientSeq,
    required this.action,
    required this.kind,
    this.reason,
  });

  /// Channel the action was dispatched on.
  final String channel;

  /// The action's `clientSeq`.
  final int clientSeq;

  /// The action as dispatched.
  final JsonMap action;

  /// Why it was undone.
  final ActionFailureKind kind;

  /// The host's `rejectionReason`, for [ActionFailureKind.rejected].
  final String? reason;

  @override
  String toString() =>
      'ActionFailure($channel #$clientSeq ${action['type']}: ${kind.name}'
      '${reason == null ? '' : ' $reason'})';
}
