/// Pure logic for waiting on a new session (AHP-040): either the host
/// lists it in the catalogue, or its backend fails to start
/// (`session/creationFailed`).
library;

import 'host_state.dart';
import 'session_catalogue.dart';
import 'wire.dart';

/// How a `createSession` call turned out.
sealed class SessionCreationOutcome {
  const SessionCreationOutcome();
}

/// The session is listed under [resource] (the catalogue key).
final class SessionCreated extends SessionCreationOutcome {
  /// Creates a [SessionCreated].
  const SessionCreated(this.resource);

  /// The session's URI as the host lists it.
  final String resource;
}

/// The session's backend failed to start.
final class SessionCreationFailed extends SessionCreationOutcome {
  /// Creates a [SessionCreationFailed].
  const SessionCreationFailed(this.error);

  /// What the host reported (`SessionState.creationError`).
  final ErrorInfo? error;
}

/// The outcome for the session created as [created] in [state], or null
/// while it is still starting.
///
/// A mirrored session channel decides first: `lifecycle: failed` is a
/// failure (whether it came in the snapshot or as
/// `session/creationFailed`), and `creating` keeps waiting even when the
/// catalogue already lists the session. Otherwise the session is created
/// once the catalogue lists it ([resolveSessionResource]).
SessionCreationOutcome? creationOutcome(HostState state, String created) {
  final mirrored = state.sessionChannels[created]?.state;
  switch (mirrored?.lifecycle) {
    case SessionLifecycle.failed:
      return SessionCreationFailed(mirrored!.creationError);
    case SessionLifecycle.creating:
      return null;
    default:
      final listed = resolveSessionResource(state.sessions, created);
      return listed == null ? null : SessionCreated(listed);
  }
}

/// Thrown by `AhpClient.createSession` when the host reports that the
/// session's backend failed to start.
class SessionCreationFailedError implements Exception {
  /// Creates a [SessionCreationFailedError] for [session].
  const SessionCreationFailedError(this.session, this.error);

  /// The URI sent to `createSession`.
  final String session;

  /// The host's error details, if it sent any.
  final ErrorInfo? error;

  @override
  String toString() => switch (error) {
    final error? => 'The session could not start: ${error.message}',
    null => 'The session could not start.',
  };
}
