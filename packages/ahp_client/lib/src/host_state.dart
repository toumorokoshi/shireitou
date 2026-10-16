/// The client's view of one host, and pure functions that advance it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'changeset_reducer.dart';
import 'channel_mirror.dart';
import 'chat_reducer.dart';
import 'protocol.dart';
import 'protocol_version.dart';
import 'root_reducer.dart';
import 'session_catalogue.dart';
import 'session_reducer.dart';
import 'terminal_reducer.dart';
import 'wire.dart';

part 'host_state.freezed.dart';

/// Connection state surfaced to the UI (AHP-005).
enum ConnectionStatus {
  /// Not connected and not trying to connect.
  disconnected,

  /// Opening the socket or running `initialize`.
  connecting,

  /// Initialized and receiving actions.
  connected,

  /// The socket dropped; retrying with backoff.
  reconnecting,

  /// Connecting failed with an error that retrying will not fix.
  failed,
}

/// Everything the client knows about one host.
@freezed
abstract class HostState with _$HostState {
  /// Creates a [HostState].
  const factory HostState({
    /// Connection status.
    @Default(ConnectionStatus.disconnected) ConnectionStatus status,

    /// Root channel state; null until the root snapshot arrives.
    RootState? root,

    /// Session catalogue keyed by session URI.
    @Default(emptyCatalogue) SessionCatalogue sessions,

    /// Highest `serverSeq` seen, used by `reconnect`.
    @Default(0) int serverSeq,

    /// Negotiated protocol version.
    String? protocolVersion,

    /// Host name and version.
    Implementation? serverInfo,

    /// Default working directory URI for new sessions.
    String? defaultDirectory,

    /// Last error, for display.
    String? error,

    /// Subscribed session channels, keyed by the URI they were subscribed
    /// with (AHP-024).
    @Default(<String, ChannelMirror<SessionState>>{})
    Map<String, ChannelMirror<SessionState>> sessionChannels,

    /// Subscribed chat channels, keyed by chat URI (AHP-025).
    @Default(<String, ChannelMirror<ChatState>>{})
    Map<String, ChannelMirror<ChatState>> chatChannels,

    /// Subscribed terminal channels, keyed by terminal URI (AHP-028).
    @Default(<String, ChannelMirror<TerminalState>>{})
    Map<String, ChannelMirror<TerminalState>> terminalChannels,

    /// Subscribed changeset channels, keyed by the expanded changeset URI
    /// (AHP-027).
    @Default(<String, ChannelMirror<ChangesetState>>{})
    Map<String, ChannelMirror<ChangesetState>> changesetChannels,

    /// Subscribed canvas channels, keyed by canvas URI (AHP-031, 1.0.0).
    @Default(<String, ChannelMirror<CanvasState>>{})
    Map<String, ChannelMirror<CanvasState>> canvasChannels,

    /// Channels the host could not resume after a reconnect (`missing` in
    /// the `reconnect` result, AHP-004), for example disposed sessions. They
    /// are no longer subscribed or mirrored. Subscribing again clears the
    /// entry.
    @Default(<String>{}) Set<String> missingChannels,
  }) = _HostState;
}

/// The kind of state a subscribed channel holds.
enum ChannelKind {
  /// `ahp-root://`.
  root,

  /// A session channel (`SessionState`).
  session,

  /// A chat channel (`ChatState`).
  chat,

  /// A terminal channel (`TerminalState`).
  terminal,

  /// A changeset channel (`ChangesetState`).
  changeset,

  /// A canvas channel (`CanvasState`).
  canvas,

  /// Any other channel; only `serverSeq` is tracked.
  other,
}

/// The mirrored channel kinds, each with its own map in [HostState].
const mirroredKinds = [
  ChannelKind.session,
  ChannelKind.chat,
  ChannelKind.terminal,
  ChannelKind.changeset,
  ChannelKind.canvas,
];

/// The mirrors of [kind] in [state] (empty for unmirrored kinds).
Map<String, ChannelMirror<Object>> mirrorsOf(
  HostState state,
  ChannelKind kind,
) => switch (kind) {
  ChannelKind.session => state.sessionChannels,
  ChannelKind.chat => state.chatChannels,
  ChannelKind.terminal => state.terminalChannels,
  ChannelKind.changeset => state.changesetChannels,
  ChannelKind.canvas => state.canvasChannels,
  ChannelKind.root || ChannelKind.other => const {},
};

/// The kind of [channel] in [state], from the maps it is held in.
ChannelKind channelKindOf(HostState state, String channel) =>
    channel == rootChannel
    ? ChannelKind.root
    : mirroredKinds.firstWhere(
        (kind) => mirrorsOf(state, kind).containsKey(channel),
        orElse: () => ChannelKind.other,
      );

/// Changes one [ChannelMirror], whatever its state type.
typedef MirrorUpdate = ChannelMirror<S> Function<S>(
  ChannelMirror<S> mirror,
  JsonReducer<S> reduce,
);

/// Applies [update] to the mirror of [channel] (of [kind], by default the
/// kind it has in [state]). Unmirrored channels leave [state] unchanged.
HostState updateMirror(
  HostState state,
  String channel,
  MirrorUpdate update, [
  ChannelKind? kind,
]) {
  Map<String, ChannelMirror<S>> put<S>(
    Map<String, ChannelMirror<S>> mirrors,
    JsonReducer<S> reduce,
  ) => switch (mirrors[channel]) {
    final mirror? => Map.unmodifiable({
      ...mirrors,
      channel: update(mirror, reduce),
    }),
    null => mirrors,
  };
  return switch (kind ?? channelKindOf(state, channel)) {
    ChannelKind.session => state.copyWith(
      sessionChannels: put(state.sessionChannels, reduceSessionJson),
    ),
    ChannelKind.chat => state.copyWith(
      chatChannels: put(state.chatChannels, reduceChatJson),
    ),
    ChannelKind.terminal => state.copyWith(
      terminalChannels: put(state.terminalChannels, reduceTerminalJson),
    ),
    ChannelKind.changeset => state.copyWith(
      changesetChannels: put(state.changesetChannels, reduceChangesetJson),
    ),
    ChannelKind.canvas => state.copyWith(
      canvasChannels: put(state.canvasChannels, reduceCanvasJson),
    ),
    ChannelKind.root || ChannelKind.other => state,
  };
}

/// Applies a [snapshot] of a channel of [kind] (by default, the kind
/// [snapshot]'s channel already has in [state]).
HostState applySnapshot(
  HostState state,
  Snapshot snapshot, [
  ChannelKind? kind,
]) {
  final seq = snapshot.fromSeq > state.serverSeq
      ? snapshot.fromSeq
      : state.serverSeq;
  final resource = snapshot.resource;
  final next = state.copyWith(
    serverSeq: seq,
    missingChannels: state.missingChannels.contains(resource)
        ? Set.unmodifiable({...state.missingChannels}..remove(resource))
        : state.missingChannels,
  );
  Map<String, ChannelMirror<S>> put<S>(
    Map<String, ChannelMirror<S>> mirrors,
    S Function(JsonMap json) decode,
  ) => Map.unmodifiable({
    ...mirrors,
    resource: ChannelMirror.snapshot(decode(snapshot.state)),
  });
  return switch (kind ?? channelKindOf(state, resource)) {
    ChannelKind.root => next.copyWith(root: RootState.fromJson(snapshot.state)),
    ChannelKind.session => next.copyWith(
      sessionChannels: put(state.sessionChannels, SessionState.fromJson),
    ),
    ChannelKind.chat => next.copyWith(
      chatChannels: put(state.chatChannels, ChatState.fromJson),
    ),
    ChannelKind.terminal => next.copyWith(
      terminalChannels: put(state.terminalChannels, TerminalState.fromJson),
    ),
    ChannelKind.changeset => next.copyWith(
      changesetChannels: put(state.changesetChannels, ChangesetState.fromJson),
    ),
    ChannelKind.canvas => next.copyWith(
      canvasChannels: put(state.canvasChannels, CanvasState.fromJson),
    ),
    ChannelKind.other => next,
  };
}

/// Drops the mirror of [channel] after its last observer unsubscribed.
HostState removeChannel(HostState state, String channel) {
  Map<String, ChannelMirror<S>> drop<S>(Map<String, ChannelMirror<S>> m) =>
      m.containsKey(channel) ? Map.unmodifiable({...m}..remove(channel)) : m;
  return state.copyWith(
    sessionChannels: drop(state.sessionChannels),
    chatChannels: drop(state.chatChannels),
    terminalChannels: drop(state.terminalChannels),
    changesetChannels: drop(state.changesetChannels),
    canvasChannels: drop(state.canvasChannels),
  );
}

/// Applies an action this client dispatched on [channel] before the host
/// confirms it (AHP-022). Channels without a mirror are unchanged.
HostState applyDispatchedAction(
  HostState state,
  String channel,
  PendingAction action,
) => updateMirror(
  state,
  channel,
  <S>(mirror, reduce) => applyPendingAction(mirror, action, reduce),
);

/// Applies the `initialize` result: version, server info and snapshots.
HostState applyInitializeResult(HostState state, InitializeResult result) =>
    result.snapshots.fold(
      state.copyWith(
        protocolVersion: result.protocolVersion,
        serverInfo: result.serverInfo,
        defaultDirectory: result.defaultDirectory,
        serverSeq: result.serverSeq,
        error: null,
      ),
      (state, snapshot) => applySnapshot(state, snapshot),
    );

/// Applies an `action` notification received by the client [clientId].
///
/// Root-channel actions go through [reduceRoot]. Actions on mirrored channels
/// advance their [ChannelMirror] (reconciling this client's write-ahead
/// actions). Rejected root actions, unmirrored channels and actions the
/// negotiated protocol version does not know (see [isActionKnownToVersion])
/// only advance `serverSeq`.
HostState applyEnvelope(
  HostState state,
  ActionEnvelope envelope, {
  required String clientId,
}) {
  final seq = envelope.serverSeq > state.serverSeq
      ? envelope.serverSeq
      : state.serverSeq;
  final next = state.copyWith(serverSeq: seq);
  final channel = envelope.channel;
  final type = envelope.action['type'];
  if (type is String && !isActionKnownToVersion(type, state.protocolVersion)) {
    return next;
  }
  return switch (channelKindOf(state, channel)) {
    ChannelKind.root => switch (state.root) {
      final root? when envelope.rejectionReason == null => next.copyWith(
        root: reduceRoot(root, RootAction.fromJson(envelope.action)),
      ),
      _ => next,
    },
    ChannelKind.other => next,
    _ => updateMirror(
      next,
      channel,
      <S>(mirror, reduce) =>
          applyHostEnvelope(mirror, envelope, reduce, clientId: clientId),
    ),
  };
}

/// Applies a `reconnect` result (AHP-004) for the client [clientId].
///
/// A replay applies the missed actions (which echo or reject this client's
/// pending actions), then drops the `missing` channels (see
/// [applyMissingChannels]). A snapshot result replaces the mirrors it
/// covers and drops the ones it leaves out (see [unresumedChannels]).
/// Pending actions still left afterwards are not cleared here; see
/// [clearAllPendingActions].
HostState applyReconnectResult(
  HostState state,
  ReconnectResult result, {
  required String clientId,
}) => applyMissingChannels(switch (result) {
  ReconnectReplayResult(:final actions) => actions.fold(
    state,
    (state, envelope) => applyEnvelope(state, envelope, clientId: clientId),
  ),
  ReconnectSnapshotResult(:final snapshots) => snapshots.fold(
    state,
    (state, snapshot) => applySnapshot(state, snapshot),
  ),
  // The client runs `initialize` again instead.
  ReconnectResultUnknown() => state,
}, missingAfterReconnect(state, result));

/// The channels a `reconnect` [result] could not resume: the replay's
/// `missing` list, or the mirrored channels a snapshot result has no
/// snapshot for.
List<String> missingAfterReconnect(HostState state, ReconnectResult result) =>
    switch (result) {
      ReconnectReplayResult(:final missing) => missing,
      ReconnectSnapshotResult(:final snapshots) => unresumedChannels(
        state,
        snapshots,
      ),
      ReconnectResultUnknown() => const [],
    };

/// Mirrored channels that [snapshots] leave out. A host
/// may omit snapshots only for channels whose state has no fields, so a
/// session or chat without one could not be resumed (it was disposed, for
/// example). Used for `reconnect` snapshot results and the `initialize`
/// fallback, which carry no `missing` list.
List<String> unresumedChannels(HostState state, List<Snapshot> snapshots) {
  final covered = {for (final s in snapshots) s.resource};
  return [
    for (final kind in mirroredKinds)
      for (final channel in mirrorsOf(state, kind).keys)
        if (!covered.contains(channel)) channel,
  ];
}

/// Drops the mirrors of [missing] channels and records them in
/// [HostState.missingChannels] so observers can tell the user (AHP-004).
HostState applyMissingChannels(HostState state, List<String> missing) =>
    missing.isEmpty
    ? state
    : missing
          .fold(state, removeChannel)
          .copyWith(
            missingChannels: Set.unmodifiable({
              ...state.missingChannels,
              ...missing,
            }),
          );

/// Pending (dispatched, not yet echoed) actions of every mirrored channel,
/// keyed by channel.
Map<String, List<PendingAction>> pendingActionsOf(HostState state) => {
  for (final kind in mirroredKinds)
    for (final MapEntry(:key, :value) in mirrorsOf(state, kind).entries)
      if (value.pending.isNotEmpty) key: value.pending,
};

/// Rolls back the pending action [clientSeq] on [channel] because the host
/// did not echo it in time. Returns the failure, or null when the action
/// is no longer pending (it was echoed, rejected or cleared already).
({HostState state, ActionFailure? failure}) expirePendingAction(
  HostState state,
  String channel,
  int clientSeq,
) {
  final pending = pendingActionsOf(
    state,
  )[channel]?.where((p) => p.clientSeq == clientSeq).firstOrNull;
  if (pending == null) return (state: state, failure: null);
  final next = updateMirror(
    state,
    channel,
    <S>(mirror, reduce) => dropPendingAction(mirror, clientSeq, reduce),
  );
  return (
    state: next,
    failure: ActionFailure(
      channel: channel,
      clientSeq: clientSeq,
      action: pending.action,
      kind: ActionFailureKind.timedOut,
    ),
  );
}

/// Rolls back every pending action, as the write-ahead reconciliation
/// guide requires after a reconnect: the replay (or snapshot) already
/// carries every action the host accepted, so anything still pending was
/// lost. Returns one [ActionFailureKind.connectionLost] failure per action.
({HostState state, List<ActionFailure> failures}) clearAllPendingActions(
  HostState state,
) {
  final failures = [
    for (final MapEntry(key: channel, value: pending) in pendingActionsOf(
      state,
    ).entries)
      for (final p in pending)
        ActionFailure(
          channel: channel,
          clientSeq: p.clientSeq,
          action: p.action,
          kind: ActionFailureKind.connectionLost,
        ),
  ];
  if (failures.isEmpty) return (state: state, failures: const []);
  return (
    state: pendingActionsOf(state).keys.fold(
      state,
      (state, channel) => updateMirror(
        state,
        channel,
        <S>(mirror, _) => clearPendingActions(mirror),
      ),
    ),
    failures: failures,
  );
}

/// The failure to report for an echoed [envelope], when it rejects one of
/// [clientId]'s actions.
ActionFailure? rejectionOf(
  ActionEnvelope envelope, {
  required String clientId,
}) {
  final origin = envelope.origin;
  final reason = envelope.rejectionReason;
  if (origin == null || origin.clientId != clientId || reason == null) {
    return null;
  }
  return ActionFailure(
    channel: envelope.channel,
    clientSeq: origin.clientSeq,
    action: envelope.action,
    kind: ActionFailureKind.rejected,
    reason: reason,
  );
}
