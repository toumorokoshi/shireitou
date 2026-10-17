/// The sidebar tree (AV-012, AV-025): every open host, its workspace
/// folders under it and each folder's sessions, flattened into rows for
/// a lazily built list.
///
/// See `specs/agents-view.md`, "Sidebar tree".
library;

import 'package:ahp_client/ahp_client.dart';

import '../hosts/open_hosts.dart';
import 'folder_grouping.dart';

/// Shown under a host that has no sessions.
const noSessionsText = 'No sessions on this host yet.';

/// Shown under a host whose sessions are all filtered out.
const noMatchText = 'No sessions match.';

/// One host in the sidebar with its folders.
class HostNode {
  /// Creates a [HostNode].
  const HostNode({required this.host, required this.folders, this.emptyText});

  /// The open host.
  final HostInfo host;

  /// The host's folders, in list order.
  final List<FolderGroup> folders;

  /// Shown under the host in place of folders ([noSessionsText] or
  /// [noMatchText]); null shows nothing.
  final String? emptyText;

  /// Number of sessions in [folders].
  int get sessionCount =>
      folders.fold(0, (count, folder) => count + folder.sessions.length);

  /// Number of sessions in [folders] that need attention.
  int get attentionCount =>
      folders.fold(0, (count, folder) => count + folder.attentionCount);
}

/// The sidebar tree: one node per host in [hosts] (in their order), each
/// holding its folders from [groups] (in their order, so a different
/// folder order only needs [groups] ordered first).
///
/// A live host with no folders gets an [HostNode.emptyText]:
/// [noMatchText] when it is in [hostsWithSessions] (its sessions are
/// filtered out), else [noSessionsText]. Hosts other than [hostFilter]
/// (when set) and hosts that are not live get none, since their sessions
/// are not listed.
List<HostNode> sessionTree(
  List<HostInfo> hosts,
  List<FolderGroup> groups, {
  Set<String> hostsWithSessions = const {},
  String? hostFilter,
}) => [
  for (final host in hosts)
    () {
      final folders = [
        for (final g in groups)
          if (g.host == host.key) g,
      ];
      final listed =
          host.live && (hostFilter == null || hostFilter == host.key);
      return HostNode(
        host: host,
        folders: folders,
        emptyText: !listed || folders.isNotEmpty
            ? null
            : hostsWithSessions.contains(host.key)
            ? noMatchText
            : noSessionsText,
      );
    }(),
];

/// One row of the flattened sidebar tree.
sealed class SidebarRow {
  const SidebarRow();
}

/// A host's row.
final class HostRow extends SidebarRow {
  /// Creates a [HostRow].
  const HostRow(this.node, {required this.collapsed});

  /// The host and its folders.
  final HostNode node;

  /// Whether the host's folders are hidden.
  final bool collapsed;
}

/// A workspace folder's row.
final class FolderRow extends SidebarRow {
  /// Creates a [FolderRow].
  const FolderRow(this.group, {required this.collapsed});

  /// The folder and its sessions.
  final FolderGroup group;

  /// Whether the folder's sessions are hidden.
  final bool collapsed;
}

/// A session's row.
final class SessionItem extends SidebarRow {
  /// Creates a [SessionItem].
  const SessionItem(this.group, this.session);

  /// The folder the session is in.
  final FolderGroup group;

  /// The session.
  final SessionSummary session;

  /// The session's reference.
  SessionRef get ref => (host: group.host, session: session.resource);
}

/// The text under a host with no folders ([HostNode.emptyText]).
final class EmptyRow extends SidebarRow {
  /// Creates an [EmptyRow].
  const EmptyRow(this.host, this.text);

  /// The host key.
  final String host;

  /// The text to show.
  final String text;
}

/// The id of a host's node in the collapsed set: its key.
String hostNodeId(HostNode node) => node.host.key;

/// [tree] as rows, skipping the children of the hosts and folders whose
/// ids ([hostNodeId], [FolderGroup.id]) are in [collapsed].
List<SidebarRow> sidebarRows(List<HostNode> tree, Set<String> collapsed) => [
  for (final node in tree) ...[
    HostRow(node, collapsed: collapsed.contains(hostNodeId(node))),
    if (!collapsed.contains(hostNodeId(node))) ...[
      if (node.emptyText case final text?) EmptyRow(node.host.key, text),
      for (final group in node.folders) ...[
        FolderRow(group, collapsed: collapsed.contains(group.id)),
        if (!collapsed.contains(group.id))
          for (final session in group.sessions) SessionItem(group, session),
      ],
    ],
  ],
];

/// [collapsed] with [id] added, or removed when it is already in it.
Set<String> toggledNode(Set<String> collapsed, String id) =>
    collapsed.contains(id) ? ({...collapsed}..remove(id)) : {...collapsed, id};

/// [collapsed] without the host and the folder of [session] in [groups],
/// so the session's row is shown.
Set<String> revealSession(
  Set<String> collapsed,
  List<FolderGroup> groups,
  SessionRef session,
) {
  final folder = groups
      .where(
        (g) =>
            g.host == session.host &&
            g.sessions.any((s) => s.resource == session.session),
      )
      .firstOrNull;
  return collapsed.difference({session.host, ?folder?.id});
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
