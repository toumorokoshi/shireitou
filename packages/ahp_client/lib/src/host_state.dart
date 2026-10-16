/// The client's view of one host, and pure functions that advance it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'protocol.dart';
import 'root_reducer.dart';
import 'session_catalogue.dart';
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
  }) = _HostState;
}

/// Applies a channel [snapshot]. Only the root channel is held in
/// [HostState]; other channels are left to their own observers.
HostState applySnapshot(HostState state, Snapshot snapshot) {
  final seq = snapshot.fromSeq > state.serverSeq
      ? snapshot.fromSeq
      : state.serverSeq;
  if (snapshot.resource != rootChannel) return state.copyWith(serverSeq: seq);
  return state.copyWith(
    root: RootState.fromJson(snapshot.state),
    serverSeq: seq,
  );
}

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
      applySnapshot,
    );

/// Applies an `action` notification. Root-channel actions go through
/// [reduceRoot]; rejected actions and other channels only advance
/// `serverSeq`.
HostState applyEnvelope(HostState state, ActionEnvelope envelope) {
  final seq = envelope.serverSeq > state.serverSeq
      ? envelope.serverSeq
      : state.serverSeq;
  final root = state.root;
  if (envelope.channel != rootChannel ||
      envelope.rejectionReason != null ||
      root == null) {
    return state.copyWith(serverSeq: seq);
  }
  return state.copyWith(
    root: reduceRoot(root, RootAction.fromJson(envelope.action)),
    serverSeq: seq,
  );
}

/// Applies a `reconnect` result (AHP-004).
HostState applyReconnectResult(HostState state, ReconnectResult result) =>
    switch (result) {
      ReconnectReplay(:final actions) => actions.fold(state, applyEnvelope),
      ReconnectSnapshot(:final snapshots) => snapshots.fold(
        state,
        applySnapshot,
      ),
    };
