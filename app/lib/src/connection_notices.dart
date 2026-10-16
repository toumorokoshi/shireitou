/// User-facing text for connection events: undone actions (AHP-022) and
/// protocol compatibility mode (0.9.0 hosts).
library;

import 'package:ahp_client/ahp_client.dart';

/// A short description of a dispatched action, from its `type`.
String describeActionType(JsonMap action) => switch (action['type']) {
  'chat/turnStarted' => 'Your message',
  'chat/pendingMessageSet' => 'Your queued message',
  'chat/pendingMessageRemoved' => 'Removing the queued message',
  'chat/turnCancelled' => 'Stop',
  'chat/toolCallConfirmed' ||
  'chat/toolCallResultConfirmed' => 'Your tool approval',
  'chat/inputCompleted' => 'Your answer',
  'session/isReadChanged' => 'Marking the session read or unread',
  'session/isArchivedChanged' => 'Archiving',
  final String type => type,
  _ => 'That action',
};

/// The snackbar text for an undone action.
String describeActionFailure(ActionFailure failure) {
  final what = describeActionType(failure.action);
  return switch (failure.kind) {
    ActionFailureKind.rejected =>
      'The host rejected that (${failure.reason ?? 'no reason given'}). '
          '$what was undone.',
    ActionFailureKind.timedOut =>
      'The host did not confirm that in time. $what was undone; '
          'try again.',
    ActionFailureKind.connectionLost =>
      'The connection dropped before the host confirmed that. $what may '
          'not have gone through; check and try again.',
  };
}

/// Text explaining what is unavailable because the host negotiated an
/// older protocol [version], or null when nothing is.
String? compatibilityNotice(String? version) {
  final missing = unavailableFeatures(version);
  if (missing.isEmpty) return null;
  return 'This host speaks AHP $version, an older protocol version than '
      '$targetProtocolVersion. Not available: '
      '${missing.map((f) => f.label).join(', ')}.';
}
