/// The state of a new-session draft (AV-040), kept in memory while the
/// user looks at other sessions.
library;

import 'package:ahp_client/ahp_client.dart';

import '../hosts/open_hosts.dart';
import '../session_list/folder_grouping.dart';

/// Where a draft was opened: the host and folder that "New session" (the
/// button, a folder's "+", the shortcut or the menu) preselected; null
/// for the defaults.
typedef NewSessionTarget = ({String? host, String? directory});

/// What the user picked and typed in a draft: the [host], the agent
/// ([provider]), the working [directory] as typed, and the [prompt].
typedef NewSessionDraft = ({
  String? host,
  String? provider,
  String directory,
  String prompt,
});

/// The working directory a draft starts with: [directory] (a URI or
/// path) or else the host's [defaultDirectory], as a path; empty when
/// neither is known.
String initialDirectoryText(String? directory, String? defaultDirectory) =>
    switch (directory ?? defaultDirectory) {
      final uri? => normalizeFolderKey(uri),
      null => '',
    };

/// [drafts] with [draft] saved for [target]; a draft with nothing typed
/// is dropped, so "New session" there starts afresh.
Map<NewSessionTarget, NewSessionDraft> withDraft(
  Map<NewSessionTarget, NewSessionDraft> drafts,
  NewSessionTarget target,
  NewSessionDraft draft,
) => {
  for (final MapEntry(:key, :value) in drafts.entries)
    if (key != target) key: value,
  if (draft.prompt.trim().isNotEmpty) target: draft,
};

/// What starting a draft came to: the [started] sessions (the first is
/// opened) and a message per run that did not start.
typedef StartOutcome = ({List<SessionRef> started, List<String> failures});

/// A draft sent to the host that the host is still creating (AV-040):
/// listed atop the sidebar and shown in the session pane from the moment
/// the prompt is sent until the session exists. [id] tells starts apart;
/// [draft] is put back for [target] when the start fails.
typedef StartingSession = ({
  int id,
  NewSessionTarget target,
  NewSessionDraft draft,
  Message message,
});

/// Longest [startingTitle], in characters.
const startingTitleLength = 60;

/// The title of a session being started: the first non-blank line of
/// [prompt], shortened with an ellipsis past [startingTitleLength]; the
/// host titles the session once it exists.
String startingTitle(String prompt) {
  final line = prompt
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.isNotEmpty, orElse: () => '');
  if (line.isEmpty) return 'Session';
  return line.length <= startingTitleLength
      ? line
      : '${line.substring(0, startingTitleLength - 1).trimRight()}…';
}
