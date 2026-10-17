/// The back and forward history of opened sessions (AV-091): a list of
/// visited sessions and the index of the open one, changed by pure
/// functions.
library;

import '../hosts/open_hosts.dart';

/// How many visited sessions the history keeps; older ones are dropped
/// so the list does not grow for the life of the app.
const sessionHistoryLimit = 100;

/// The visited sessions, oldest first, and the index of the current one
/// (-1 when empty).
typedef SessionHistory = ({List<SessionRef> entries, int index});

/// An empty history.
const SessionHistory emptySessionHistory = (entries: [], index: -1);

/// [history] after opening [session]: the entries after the current one
/// are dropped and [session] is added, unless it is already current.
SessionHistory visitedSession(SessionHistory history, SessionRef session) {
  final (:entries, :index) = history;
  if (index >= 0 && entries[index] == session) return history;
  final kept = [...entries.take(index + 1), session];
  final trimmed = kept.length > sessionHistoryLimit
      ? kept.sublist(kept.length - sessionHistoryLimit)
      : kept;
  return (entries: trimmed, index: trimmed.length - 1);
}

/// Whether there is an entry before the current one.
bool canGoBack(SessionHistory history) => history.index > 0;

/// Whether there is an entry after the current one.
bool canGoForward(SessionHistory history) =>
    history.index < history.entries.length - 1;

/// [history] moved [delta] entries (negative goes back), clamped to its
/// ends.
SessionHistory steppedHistory(SessionHistory history, int delta) {
  if (history.entries.isEmpty) return history;
  final index = (history.index + delta).clamp(0, history.entries.length - 1);
  return (entries: history.entries, index: index);
}

/// The current entry of [history], or null when it is empty.
SessionRef? currentSession(SessionHistory history) =>
    history.index < 0 ? null : history.entries[history.index];
