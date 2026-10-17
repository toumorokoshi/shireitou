/// The state of a new-session draft (AV-040), kept in memory while the
/// user looks at other sessions.
library;

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
