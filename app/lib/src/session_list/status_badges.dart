/// Status badges derived from the `SessionStatus` bitset (AV-021).
library;

import 'package:ahp_client/ahp_client.dart';

/// A badge shown on a session row.
enum SessionBadge {
  /// A turn is running.
  working('Working'),

  /// The agent is waiting for an approval or an answer.
  needsInput('Needs input'),

  /// The last turn failed.
  error('Error'),

  /// Nothing is running.
  idle('Idle'),

  /// The user has not read the latest changes.
  unread('Unread');

  const SessionBadge(this.label);

  /// Text shown in the badge.
  final String label;
}

/// The badges for [status]: one activity badge, plus [SessionBadge.unread]
/// when the `IsRead` flag is clear. Checks are bitwise, never equality.
List<SessionBadge> badgesFor(SessionStatus status) => [
  if (status.isInputNeeded)
    SessionBadge.needsInput
  else if (status.isInProgress)
    SessionBadge.working
  else if (status.isError)
    SessionBadge.error
  else
    SessionBadge.idle,
  if (!status.isReadFlag) SessionBadge.unread,
];

/// Whether a session needs attention: input needed, error, or unread.
bool needsAttention(SessionStatus status) =>
    status.isInputNeeded || status.isError || !status.isReadFlag;
