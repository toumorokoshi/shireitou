/// Session list filters (AV-022).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/open_hosts.dart';

import 'status_badges.dart';

/// Which sessions the list shows.
enum SessionFilter {
  /// Sessions that are not archived (the default).
  active('Active'),

  /// Non-archived sessions that need input, failed, or are unread.
  attention('Needs attention'),

  /// Non-archived sessions whose agent finished: nothing running, no
  /// input needed and no error.
  done('Done'),

  /// Archived sessions only.
  archived('Archived'),

  /// Every session.
  all('All');

  const SessionFilter(this.label);

  /// Text shown on the filter chip.
  final String label;
}

/// Whether [status] passes [filter]. Checks are bitwise (AHP-026).
bool matchesFilter(SessionStatus status, SessionFilter filter) =>
    switch (filter) {
      SessionFilter.active => !status.isArchivedFlag,
      SessionFilter.attention =>
        !status.isArchivedFlag && needsAttention(status),
      SessionFilter.done => !status.isArchivedFlag && isDone(status),
      SessionFilter.archived => status.isArchivedFlag,
      SessionFilter.all => true,
    };

/// The sessions in [sessions] that pass [filter].
Iterable<SessionSummary> filterSessions(
  Iterable<SessionSummary> sessions,
  SessionFilter filter,
) => sessions.where((s) => matchesFilter(s.status, filter));

/// Whether the agent is finished with a session: idle (not running, not
/// waiting for input) and not failed. Read state does not matter.
bool isDone(SessionStatus status) =>
    !status.isInProgress && !status.isInputNeeded && !status.isError;

/// How many non-archived [sessions] need attention (AV-120).
int attentionCount(Iterable<SessionSummary> sessions) => sessions
    .where((s) => matchesFilter(s.status, SessionFilter.attention))
    .length;

/// The attention count over every live host's sessions (AV-120).
final attentionCountProvider = Provider<int>(
  (ref) => attentionCount([
    for (final s in ref.watch(allSessionsProvider)) s.summary,
  ]),
);

/// The window (or browser tab) title: the app name, prefixed with the
/// attention count when there is one, like "(3) shireitou".
String windowTitle(int attention) =>
    attention > 0 ? '($attention) shireitou' : 'shireitou';
