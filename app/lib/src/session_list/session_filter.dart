/// Session list filters (AV-022).
library;

import 'package:ahp_client/ahp_client.dart';

import 'status_badges.dart';

/// Which sessions the list shows.
enum SessionFilter {
  /// Sessions that are not archived (the default).
  active('Active'),

  /// Non-archived sessions that need input, failed, or are unread.
  attention('Needs attention'),

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
      SessionFilter.archived => status.isArchivedFlag,
      SessionFilter.all => true,
    };

/// The sessions in [sessions] that pass [filter].
Iterable<SessionSummary> filterSessions(
  Iterable<SessionSummary> sessions,
  SessionFilter filter,
) => sessions.where((s) => matchesFilter(s.status, filter));
