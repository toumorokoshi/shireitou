/// The sidebar's sections (AV-012, AV-025, AV-028, AV-092): "Pinned",
/// "Chats" (sessions with no working directory), then one section per
/// workspace folder, each with its sessions, flattened into rows for a
/// lazily built list. Hosts are not a level: every open host's sessions
/// are merged into these sections.
///
/// See `specs/agents-view.md`, "Sidebar tree".
library;

import 'package:ahp_client/ahp_client.dart';

import '../hosts/open_hosts.dart';
import 'folder_grouping.dart';
import 'session_query.dart';
import 'status_badges.dart';

/// Shown in place of the sections when no host has sessions.
const noSessionsText = 'No sessions yet.';

/// Shown in place of the sections when every session is filtered out.
const noMatchText = 'No sessions match.';

/// The id of the "Pinned" section in the collapsed set. Folder ids
/// contain `|`, so it cannot clash with them.
const pinnedNodeId = 'pinned';

/// The id of the "Chats" section in the collapsed set.
const chatsNodeId = 'chats';

/// One row of the flattened sidebar.
sealed class SidebarRow {
  const SidebarRow();
}

/// The header of the "Pinned" (AV-028) or "Chats" section, which list
/// sessions of every host without grouping them by folder.
final class SectionRow extends SidebarRow {
  /// Creates a [SectionRow].
  const SectionRow(this.id, this.sessions, {required this.collapsed});

  /// [pinnedNodeId] or [chatsNodeId].
  final String id;

  /// The section's sessions, in the order shown.
  final List<HostSession> sessions;

  /// Whether the sessions are hidden.
  final bool collapsed;

  /// Whether any of the sessions needs attention ([needsAttention]).
  bool get hasAttention =>
      sessions.any((s) => needsAttention(s.summary.status));
}

/// A workspace folder's header (AV-025).
final class FolderRow extends SidebarRow {
  /// Creates a [FolderRow].
  const FolderRow(this.group, {required this.collapsed, this.hostLabel});

  /// The folder and its sessions.
  final FolderGroup group;

  /// Whether the folder's sessions are hidden.
  final bool collapsed;

  /// The label of the folder's host when several hosts are open; null
  /// otherwise.
  final String? hostLabel;
}

/// A session's row, in any section.
final class SessionItem extends SidebarRow {
  /// Creates a [SessionItem].
  const SessionItem(this.host, this.session, {required this.place});

  /// The host key the session is on.
  final String host;

  /// The session.
  final SessionSummary session;

  /// Where the session lives ([sessionPlace]), shown on its second line.
  final String place;

  /// The session's reference.
  SessionRef get ref => (host: host, session: session.resource);
}

/// The sessions of [sessions] with no working directory or project (the
/// "Chats" section), ordered by [sort].
List<HostSession> chatSessions(
  Iterable<HostSession> sessions, {
  SessionSort sort = SessionSort.recent,
}) => [
  for (final s in sessions)
    if (folderKeyOf(s.summary) == null) s,
]..sort((a, b) => compareSessions(sort, a.summary, b.summary));

/// Where a session lives, for its row's second line: its workspace
/// ([workspaceLabel]) and [hostLabel] (when given), joined by " · ".
/// Empty for a session with no folder and no [hostLabel].
String sessionPlace(SessionSummary summary, {String? hostLabel}) => [
  if (folderKeyOf(summary) case final key?)
    workspaceLabel(folderLabelOf(key), projectNameOf(summary)),
  ?hostLabel,
].join(' · ');

/// The labels of [hosts] by key when there is more than one host, so
/// rows and folders name their host; empty otherwise.
Map<String, String> hostLabelsOf(List<HostInfo> hosts) => {
  if (hosts.length > 1)
    for (final h in hosts) h.key: h.label,
};

/// The sidebar's rows: [pinned] as the "Pinned" section and [chats] as
/// the "Chats" section (each left out when empty), then each of
/// [folders] in order. The sessions of a section or folder whose id
/// ([pinnedNodeId], [chatsNodeId], [FolderGroup.id]) is in [collapsed]
/// are skipped. [hostLabels] ([hostLabelsOf]) name the host of rows and
/// folders.
List<SidebarRow> sidebarRows({
  required Set<String> collapsed,
  List<HostSession> pinned = const [],
  List<HostSession> chats = const [],
  List<FolderGroup> folders = const [],
  Map<String, String> hostLabels = const {},
}) {
  SessionItem item(String host, SessionSummary s) =>
      SessionItem(host, s, place: sessionPlace(s, hostLabel: hostLabels[host]));
  return [
    for (final (id, sessions) in [(pinnedNodeId, pinned), (chatsNodeId, chats)])
      if (sessions.isNotEmpty) ...[
        SectionRow(id, sessions, collapsed: collapsed.contains(id)),
        if (!collapsed.contains(id))
          for (final s in sessions) item(s.host, s.summary),
      ],
    for (final group in folders) ...[
      FolderRow(
        group,
        collapsed: collapsed.contains(group.id),
        hostLabel: hostLabels[group.host],
      ),
      if (!collapsed.contains(group.id))
        for (final s in group.sessions) item(group.host, s),
    ],
  ];
}

/// [collapsed] with [id] added, or removed when it is already in it.
Set<String> toggledNode(Set<String> collapsed, String id) =>
    collapsed.contains(id) ? ({...collapsed}..remove(id)) : {...collapsed, id};

/// [collapsed] without the section that lists [session]: "Pinned" when
/// it is in [pinned], "Chats" when it is in [chats], else its folder in
/// [groups], so the session's row is shown.
Set<String> revealSession(
  Set<String> collapsed,
  List<FolderGroup> groups,
  SessionRef session, {
  Iterable<SessionRef> pinned = const [],
  Iterable<SessionRef> chats = const [],
}) {
  if (pinned.contains(session)) return collapsed.difference({pinnedNodeId});
  if (chats.contains(session)) return collapsed.difference({chatsNodeId});
  final folder = groups
      .where(
        (g) =>
            g.host == session.host &&
            g.sessions.any((s) => s.resource == session.session),
      )
      .firstOrNull;
  return collapsed.difference({?folder?.id});
}

/// The app bar title for [hosts] when the list is narrowed to
/// [hostFilter]: that host's label, the only host's label, or
/// "All hosts".
String hostsTitle(List<HostInfo> hosts, String? hostFilter) =>
    switch ((hosts.where((h) => h.key == hostFilter).firstOrNull, hosts)) {
      (final host?, _) => host.label,
      (null, [final only]) => only.label,
      (null, []) => 'shireitou',
      _ => 'All hosts',
    };
