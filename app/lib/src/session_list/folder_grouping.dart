/// Groups sessions into one folder per working directory (AV-025).
///
/// See `specs/agents-view.md`, "Worktree grouping".
library;

import 'package:ahp_client/ahp_client.dart';

import '../hosts/open_hosts.dart';
import 'session_query.dart';
import 'status_badges.dart';

/// Label of the group for sessions with no working directory or project.
const noFolderLabel = 'No folder';

/// One collapsible folder in the session list: one working directory on
/// one host.
class FolderGroup {
  /// Creates a [FolderGroup].
  const FolderGroup({
    required this.key,
    required this.label,
    required this.path,
    required this.sessions,
    this.host = '',
    this.repo,
    this.branch,
    this.project,
  });

  /// The host key the folder is on (AV-012); empty for a single host.
  final String host;

  /// Normalized folder path, or null for the "No folder" group.
  final String? key;

  /// Folder name (last path segment), or [noFolderLabel].
  final String label;

  /// Full folder path shown under the label; empty for "No folder".
  final String path;

  /// The repository's name when the host reports one
  /// ([worktreeInfoOf]).
  final String? repo;

  /// The checked-out branch when the host reports one.
  final String? branch;

  /// The name of the folder's project when the host reports one
  /// ([projectNameOf]), shown in brackets after [label]
  /// ([workspaceLabel]).
  final String? project;

  /// Sessions in this folder, most recently modified first.
  final List<SessionSummary> sessions;

  /// Identifies the folder across hosts.
  String get id => '$host|${key ?? ''}';

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

/// The `_meta` key under which VS Code's agent host reports a session's git
/// state (`branchName`, …). It is a VS Code convention, not part of AHP.
const gitMetaKey = 'git';

/// The repository and branch a host reports for [summary]'s folder.
///
/// AHP has no git fields. VS Code's agent host sets `project` to the
/// repository root (named by `displayName`) and puts the branch in
/// `_meta.git.branchName`; pi reports neither. The repository is only
/// named when it is not the folder itself (a worktree or a subfolder).
({String? repo, String? branch}) worktreeInfoOf(SessionSummary summary) {
  final project = summary.project;
  final folder = folderKeyOf(summary);
  final repo =
      project == null ||
          project.displayName.isEmpty ||
          normalizeFolderKey(project.uri) == folder
      ? null
      : project.displayName;
  final git = summary.meta?[gitMetaKey];
  final branch = git is Map ? git['branchName'] : null;
  return (
    repo: repo,
    branch: branch is String && branch.isNotEmpty ? branch : null,
  );
}

/// The name of [summary]'s project (`SessionSummary.project`'s
/// `displayName`), or null when the host reports none.
String? projectNameOf(SessionSummary summary) => switch (summary.project) {
  ProjectInfo(:final displayName) when displayName.isNotEmpty => displayName,
  _ => null,
};

/// A workspace's label as the reference UI writes it, "folder [project]"
/// (AV-092), or just [folder] when there is no [project].
String workspaceLabel(String folder, String? project) =>
    project == null ? folder : '$folder [$project]';

int _byModifiedDesc(SessionSummary a, SessionSummary b) =>
    b.modifiedAt.compareTo(a.modifiedAt);

/// Groups the sessions of one host by exact working directory. See
/// [groupHostSessions].
List<FolderGroup> groupSessionsByFolder(
  Iterable<SessionSummary> sessions, {
  String host = '',
  SessionSort sort = SessionSort.recent,
}) => groupHostSessions([
  for (final s in sessions) HostSession(host, s),
], sort: sort);

/// Groups [sessions] by host and exact working directory (AV-025): the
/// same path on two hosts is two folders, and worktrees of one repository
/// stay separate folders. Sessions in a folder are ordered by [sort], and
/// folders by their first session (by default the most recently modified
/// one); the "No folder" groups sort the same way (AV-026). Pinned
/// sessions (AV-028) are left out by the caller (`splitPinned`). A
/// folder's repository and branch come from its most recent session.
List<FolderGroup> groupHostSessions(
  Iterable<HostSession> sessions, {
  SessionSort sort = SessionSort.recent,
}) {
  int compare(SessionSummary a, SessionSummary b) =>
      compareSessions(sort, a, b);
  final byKey = <(String, String?), List<SessionSummary>>{};
  for (final HostSession(:host, :summary) in sessions) {
    (byKey[(host, folderKeyOf(summary))] ??= []).add(summary);
  }
  final groups = [
    for (final MapEntry(key: (host, key), :value) in byKey.entries)
      () {
        final sorted = [...value]..sort(compare);
        final latest = [...value]..sort(_byModifiedDesc);
        final (:repo, :branch) = worktreeInfoOf(latest.first);
        return FolderGroup(
          host: host,
          key: key,
          label: key == null ? noFolderLabel : folderLabelOf(key),
          path: key ?? '',
          sessions: sorted,
          repo: repo,
          branch: branch,
          project: projectNameOf(latest.first),
        );
      }(),
  ];
  return groups..sort((a, b) => compare(a.sessions.first, b.sessions.first));
}

/// The folders of [host]'s sessions, most recently used first, for the
/// composer's suggestions (AV-043).
List<String> recentFolders(
  Iterable<HostSession> sessions,
  String host, {
  int max = 6,
}) {
  final summaries = [
    for (final s in sessions)
      if (s.host == host) s.summary,
  ]..sort(_byModifiedDesc);
  final folders = <String>{
    for (final s in summaries)
      if (s.workingDirectories?.firstOrNull case final d?)
        normalizeFolderKey(d),
  };
  return folders.take(max).toList();
}
