/// The session list (inbox) grouped into working-directory folders.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import 'folder_grouping.dart';
import 'relative_time.dart';
import 'status_badges.dart';

/// Shows [groups] as collapsible folders of session rows.
class SessionListView extends StatelessWidget {
  /// Creates a [SessionListView].
  const SessionListView({
    super.key,
    required this.groups,
    required this.onSelect,
    this.selected,
    this.now,
  });

  /// Folders to show, already grouped and sorted.
  final List<FolderGroup> groups;

  /// URI of the selected session, highlighted in the list.
  final String? selected;

  /// Called with a session's URI when its row is tapped.
  final ValueChanged<String> onSelect;

  /// Clock for relative times; defaults to `DateTime.now()`.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(child: Text('No sessions on this host yet.'));
    }
    final clock = now ?? DateTime.now();
    return ListView(
      children: [
        for (final group in groups)
          ExpansionTile(
            key: PageStorageKey(group.key ?? noFolderLabel),
            initiallyExpanded: true,
            leading: const Icon(Icons.folder_outlined),
            title: Text(group.label),
            subtitle: group.path.isEmpty
                ? null
                : Text(group.path, overflow: TextOverflow.ellipsis),
            trailing: _FolderCounts(group: group),
            children: [
              for (final session in group.sessions)
                SessionTile(
                  session: session,
                  now: clock,
                  selected: session.resource == selected,
                  onTap: () => onSelect(session.resource),
                ),
            ],
          ),
      ],
    );
  }
}

class _FolderCounts extends StatelessWidget {
  const _FolderCounts({required this.group});

  final FolderGroup group;

  @override
  Widget build(BuildContext context) {
    final attention = group.attentionCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${group.sessions.length}'),
        if (attention > 0) ...[
          const SizedBox(width: 8),
          Badge(
            label: Text('$attention'),
            child: const Icon(Icons.notifications_outlined, size: 20),
          ),
        ],
      ],
    );
  }
}

/// One session row: title, provider, modified time, change stats and
/// status badges (AV-020, AV-021).
class SessionTile extends StatelessWidget {
  /// Creates a [SessionTile].
  const SessionTile({
    super.key,
    required this.session,
    required this.now,
    required this.onTap,
    this.selected = false,
  });

  /// The session to show.
  final SessionSummary session;

  /// Clock for the relative modified time.
  final DateTime now;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Whether the row is highlighted.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final modified = DateTime.tryParse(session.modifiedAt);
    final changes = session.changes;
    final details = [
      session.provider,
      if (modified != null) formatRelativeTime(modified, now),
      if (changes != null)
        '+${changes.additions ?? 0} −${changes.deletions ?? 0}'
            '${changes.files == null ? '' : ' (${changes.files} files)'}',
      ?session.activity,
    ];
    return ListTile(
      selected: selected,
      onTap: onTap,
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: session.status.isReadFlag
            ? null
            : const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(details.join(' · '), maxLines: 1),
      trailing: Wrap(
        spacing: 4,
        children: [
          for (final badge in badgesFor(session.status))
            StatusBadgeChip(badge: badge),
        ],
      ),
    );
  }
}

/// A small colored label for one [SessionBadge].
class StatusBadgeChip extends StatelessWidget {
  /// Creates a [StatusBadgeChip].
  const StatusBadgeChip({super.key, required this.badge});

  /// The badge to show.
  final SessionBadge badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (badge) {
      SessionBadge.working => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      SessionBadge.needsInput => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      SessionBadge.error => (scheme.errorContainer, scheme.onErrorContainer),
      SessionBadge.idle => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      SessionBadge.unread => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badge.label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
