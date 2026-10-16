/// The client's view of one host, and pure functions that advance it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'channel_mirror.dart';
import 'chat_reducer.dart';
import 'chat_wire.dart';
import 'protocol.dart';
import 'root_reducer.dart';
import 'session_catalogue.dart';
import 'session_reducer.dart';
import 'session_wire.dart';
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

  /// Any other channel; only `serverSeq` is tracked.
  other,
}

/// The kind of [channel] in [state], from the maps it is held in.
ChannelKind channelKindOf(HostState state, String channel) =>
    channel == rootChannel
    ? ChannelKind.root
    : state.sessionChannels.containsKey(channel)
    ? ChannelKind.session
    : state.chatChannels.containsKey(channel)
    ? ChannelKind.chat
    : ChannelKind.other;

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
  final next = state.copyWith(serverSeq: seq);
  final resource = snapshot.resource;
  return switch (kind ?? channelKindOf(state, resource)) {
    ChannelKind.root => next.copyWith(root: RootState.fromJson(snapshot.state)),
    ChannelKind.session => next.copyWith(
      sessionChannels: Map.unmodifiable({
        ...state.sessionChannels,
        resource: ChannelMirror.snapshot(SessionState.fromJson(snapshot.state)),
      }),
    ),
    ChannelKind.chat => next.copyWith(
      chatChannels: Map.unmodifiable({
        ...state.chatChannels,
        resource: ChannelMirror.snapshot(ChatState.fromJson(snapshot.state)),
      }),
    ),
    ChannelKind.other => next,
  };
}

/// Drops the mirror of [channel] after its last observer unsubscribed.
HostState removeChannel(HostState state, String channel) => state.copyWith(
  sessionChannels: Map.unmodifiable(
    {...state.sessionChannels}..remove(channel),
  ),
  chatChannels: Map.unmodifiable({...state.chatChannels}..remove(channel)),
);

/// Applies an action this client dispatched on [channel] before the host
/// confirms it (AHP-022). Channels without a mirror are unchanged.
HostState applyDispatchedAction(
  HostState state,
  String channel,
  PendingAction action,
) => switch (channelKindOf(state, channel)) {
  ChannelKind.session => state.copyWith(
    sessionChannels: Map.unmodifiable({
      ...state.sessionChannels,
      channel: applyPendingAction(
        state.sessionChannels[channel]!,
        action,
        reduceSessionJson,
      ),
    }),
  ),
  ChannelKind.chat => state.copyWith(
    chatChannels: Map.unmodifiable({
      ...state.chatChannels,
      channel: applyPendingAction(
        state.chatChannels[channel]!,
        action,
        reduceChatJson,
      ),
    }),
  ),
  ChannelKind.root || ChannelKind.other => state,
};

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
/// Root-channel actions go through [reduceRoot]. Session and chat actions
/// advance their [ChannelMirror] (reconciling this client's write-ahead
/// actions). Rejected root actions and unmirrored channels only advance
/// `serverSeq`.
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
  return switch (channelKindOf(state, channel)) {
    ChannelKind.root => switch (state.root) {
      final root? when envelope.rejectionReason == null => next.copyWith(
        root: reduceRoot(root, RootAction.fromJson(envelope.action)),
      ),
      _ => next,
    },
    ChannelKind.session => next.copyWith(
      sessionChannels: Map.unmodifiable({
        ...state.sessionChannels,
        channel: applyHostEnvelope(
          state.sessionChannels[channel]!,
          envelope,
          reduceSessionJson,
          clientId: clientId,
        ),
      }),
    ),
    ChannelKind.chat => next.copyWith(
      chatChannels: Map.unmodifiable({
        ...state.chatChannels,
        channel: applyHostEnvelope(
          state.chatChannels[channel]!,
          envelope,
          reduceChatJson,
          clientId: clientId,
        ),
      }),
    ),
    ChannelKind.other => next,
  };
}

/// Applies a `reconnect` result (AHP-004) for the client [clientId].
HostState applyReconnectResult(
  HostState state,
  ReconnectResult result, {
  required String clientId,
}) => switch (result) {
  ReconnectReplay(:final actions) => actions.fold(
    state,
    (state, envelope) => applyEnvelope(state, envelope, clientId: clientId),
  ),
  ReconnectSnapshot(:final snapshots) => snapshots.fold(
    state,
    (state, snapshot) => applySnapshot(state, snapshot),
  ),
};
