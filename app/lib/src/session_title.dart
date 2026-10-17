/// Renaming a session (AV-073): the `session/titleChanged` action a client
/// dispatches, and which title to show while a rename is pending.
library;

import 'package:ahp_client/ahp_client.dart';

/// The `session/titleChanged` action that renames a session titled
/// [current] to [typed], or null when [typed] is empty or unchanged once
/// trimmed (nothing is sent).
JsonMap? renameAction(String current, String typed) {
  final title = typed.trim();
  if (title.isEmpty || title == current) return null;
  return SessionTitleChangedAction(title: title).toJson();
}

/// The title to show for a session: the session channel's (which carries
/// this client's pending rename), else the catalogue's, else the chat's.
String sessionTitleOf({
  SessionState? session,
  SessionSummary? summary,
  ChatState? chat,
}) =>
    [
      session?.title,
      summary?.title,
      chat?.title,
    ].firstWhere((t) => t != null && t.isNotEmpty, orElse: () => null) ??
    'Session';

/// [summary] with the title of the session's mirrored channel [session],
/// so a pending rename shows in the session list before the host updates
/// its catalogue.
SessionSummary withMirroredTitle(
  SessionSummary summary,
  SessionState? session,
) => switch (session?.title) {
  final title? when title.isNotEmpty && title != summary.title =>
    summary.copyWith(title: title),
  _ => summary,
};
