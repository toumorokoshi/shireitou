/// Groups sessions into one folder per working directory (AV-025).
///
/// See `specs/agents-view.md`, "Worktree grouping".
library;

import 'package:ahp_client/ahp_client.dart';

import 'status_badges.dart';

/// Label of the group for sessions with no working directory or project.
const noFolderLabel = 'No folder';

/// One collapsible folder in the session list.
class FolderGroup {
  /// Creates a [FolderGroup].
  const FolderGroup({
    required this.key,
    required this.label,
    required this.path,
    required this.sessions,
  });

  /// Normalized folder path, or null for the "No folder" group.
  final String? key;

  /// Folder name (last path segment), or [noFolderLabel].
  final String label;

  /// Full folder path shown under the label; empty for "No folder".
  final String path;

  /// Sessions in this folder, most recently modified first.
  final List<SessionSummary> sessions;

  /// Number of sessions that need attention (input, error or unread).
  int get attentionCount =>
      sessions.where((s) => needsAttention(s.status)).length;
}

/// Normalizes a working-directory or project URI into a folder key:
/// `file://` URIs are decoded to a path and a trailing slash is removed.
String normalizeFolderKey(String uri) {
  final parsed = Uri.tryParse(uri);
  final path = parsed != null && parsed.scheme == 'file'
      ? Uri.decodeComponent(parsed.path)
      : uri;
  return path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
}

/// The folder key of [summary]: its first working directory, else its
/// project URI, else null.
String? folderKeyOf(SessionSummary summary) {
  final directory = summary.workingDirectories?.firstOrNull;
  final uri = directory ?? summary.project?.uri;
  return uri == null ? null : normalizeFolderKey(uri);
}

/// The last path segment of [key], used as the folder label.
String folderLabelOf(String key) {
  final segments = key.split('/').where((s) => s.isNotEmpty);
  return segments.isEmpty ? key : segments.last;
}

int _byModifiedDesc(SessionSummary a, SessionSummary b) =>
    b.modifiedAt.compareTo(a.modifiedAt);

/// Groups [sessions] by exact working directory. Worktrees of one repository
/// stay separate folders. Folders are sorted by their most recently modified
/// session, and the "No folder" group (if any) sorts the same way.
List<FolderGroup> groupSessionsByFolder(Iterable<SessionSummary> sessions) {
  final byKey = <String?, List<SessionSummary>>{};
  for (final session in sessions) {
    (byKey[folderKeyOf(session)] ??= []).add(session);
  }
  final groups = [
    for (final MapEntry(:key, :value) in byKey.entries)
      FolderGroup(
        key: key,
        label: key == null ? noFolderLabel : folderLabelOf(key),
        path: key ?? '',
        sessions: [...value]..sort(_byModifiedDesc),
      ),
  ];
  return groups
    ..sort((a, b) => _byModifiedDesc(a.sessions.first, b.sessions.first));
}
