/// The session list (inbox) grouped into working-directory folders.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../hosts/open_hosts.dart';
import 'folder_grouping.dart';
import 'relative_time.dart';
import 'status_badges.dart';

/// What a session row's menu, swipe and multi-select can do (AV-024,
/// AV-029). Each callback gets the session.
@immutable
class SessionRowActions {
  /// Creates the row actions.
  const SessionRowActions({
    required this.onArchive,
    required this.onMarkRead,
    required this.onSelect,
  });

  /// Archives the session (true) or unarchives it (false).
  final void Function(SessionRef session, bool archived) onArchive;

  /// Marks the session read (true) or unread (false).
  final void Function(SessionRef session, bool read) onMarkRead;

  /// Starts multi-select with the session selected, or toggles it while
  /// selecting.
  final ValueChanged<SessionRef> onSelect;
}

/// Shows [groups] as collapsible folders of session rows. Rows have a
/// menu (right-click or long-press) to archive, mark read or unread, and
/// select; swiping a row to the left archives (or unarchives) it. While
/// [selection] is set, rows show checkboxes and tapping toggles them.
class SessionListView extends StatelessWidget {
  /// Creates a [SessionListView].
  const SessionListView({
    super.key,
    required this.groups,
    required this.onSelect,
    this.selected,
    this.onNewSession,
    this.hostLabels = const {},
    this.now,
    this.actions,
    this.selection,
    this.emptyText = 'No sessions on this host yet.',
  });

  /// Folders to show, already grouped and sorted.
  final List<FolderGroup> groups;

  /// The selected session, highlighted in the list.
  final SessionRef? selected;

  /// Called with a session when its row is tapped.
  final ValueChanged<SessionRef> onSelect;

  /// Starts a session in a folder (the header's "+" button); no button
  /// when null.
  final ValueChanged<FolderGroup>? onNewSession;

  /// Host labels by host key, shown on folder headers when sessions of
  /// more than one host are listed (AV-012).
  final Map<String, String> hostLabels;

  /// Clock for relative times; defaults to `DateTime.now()`.
  final DateTime? now;

  /// Row menu, swipe and multi-select; none when null.
  final SessionRowActions? actions;

  /// The sessions picked for a bulk action, or null when not selecting.
  final Set<SessionRef>? selection;

  /// Shown when there are no [groups].
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(child: Text(emptyText, textAlign: TextAlign.center));
    }
    final clock = now ?? DateTime.now();
    final selection = this.selection;
    return ListView(
      children: [
        for (final group in groups)
          ExpansionTile(
            key: PageStorageKey(group.id),
            initiallyExpanded: true,
            leading: const Icon(Icons.folder_outlined),
            title: Text(group.label),
            subtitle: switch (folderDetails(
              group,
              hostLabels.length > 1 ? hostLabels[group.host] : null,
            )) {
              '' => null,
              final details => Text(
                details,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            },
            trailing: _FolderCounts(
              group: group,
              onNewSession: onNewSession == null
                  ? null
                  : () => onNewSession!(group),
            ),
            children: [
              for (final session in group.sessions)
                _SessionRow(
                  key: ValueKey((group.host, session.resource)),
                  session: session,
                  ref: (host: group.host, session: session.resource),
                  now: clock,
                  selected:
                      selected == (host: group.host, session: session.resource),
                  checked: selection?.contains((
                    host: group.host,
                    session: session.resource,
                  )),
                  actions: actions,
                  onOpen: onSelect,
                ),
            ],
          ),
      ],
    );
  }
}

/// A [SessionTile] with the row menu, swipe to archive and multi-select.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    super.key,
    required this.session,
    required this.ref,
    required this.now,
    required this.selected,
    required this.checked,
    required this.actions,
    required this.onOpen,
  });

  final SessionSummary session;
  final SessionRef ref;
  final DateTime now;
  final bool selected;

  /// Whether the row is picked; null when not selecting.
  final bool? checked;
  final SessionRowActions? actions;
  final ValueChanged<SessionRef> onOpen;

  bool get _archived => session.status.isArchivedFlag;
  bool get _read => session.status.isReadFlag;

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final actions = this.actions!;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: () => actions.onArchive(ref, !_archived),
          child: Text(_archived ? 'Unarchive' : 'Archive'),
        ),
        PopupMenuItem(
          value: () => actions.onMarkRead(ref, !_read),
          child: Text(_read ? 'Mark unread' : 'Mark read'),
        ),
        PopupMenuItem(
          value: () => actions.onSelect(ref),
          child: Text(checked == null ? 'Select' : 'Toggle selection'),
        ),
      ],
    );
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final actions = this.actions;
    final checked = this.checked;
    final tile = SessionTile(
      session: session,
      now: now,
      selected: selected || (checked ?? false),
      leading: checked == null
          ? null
          : Checkbox(value: checked, onChanged: (_) => actions?.onSelect(ref)),
      onTap: checked == null ? () => onOpen(ref) : () => actions?.onSelect(ref),
    );
    if (actions == null) return tile;
    final archiveLabel = _archived ? 'Unarchive' : 'Archive';
    final row = Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: archiveLabel): () =>
            actions.onArchive(ref, !_archived),
        CustomSemanticsAction(label: _read ? 'Mark unread' : 'Mark read'): () =>
            actions.onMarkRead(ref, !_read),
      },
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            _showMenu(context, details.globalPosition),
        onLongPressStart: (details) =>
            _showMenu(context, details.globalPosition),
        child: tile,
      ),
    );
    if (checked != null) return row;
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(('swipe', ref)),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: scheme.secondaryContainer,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  archiveLabel,
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
      // The row stays; the host's catalogue update moves it out of the
      // filter (or not), so nothing is removed before the host agrees.
      confirmDismiss: (_) async {
        actions.onArchive(ref, !_archived);
        return false;
      },
      child: row,
    );
  }
}

/// The line under a folder's name: its host (when several are listed),
/// repository and branch when the host reports them, and its full path.
String folderDetails(FolderGroup group, String? hostLabel) => [
  ?hostLabel,
  ?group.repo,
  if (group.branch case final branch?) '⎇ $branch',
  if (group.path.isNotEmpty) group.path,
].join(' · ');

class _FolderCounts extends StatelessWidget {
  const _FolderCounts({required this.group, this.onNewSession});

  final FolderGroup group;
  final VoidCallback? onNewSession;

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
        if (onNewSession != null)
          IconButton(
            tooltip: 'New session in ${group.label}',
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
            onPressed: onNewSession,
          ),
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
    this.leading,
  });

  /// The session to show.
  final SessionSummary session;

  /// Clock for the relative modified time.
  final DateTime now;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Whether the row is highlighted.
  final bool selected;

  /// Shown before the title (the multi-select checkbox).
  final Widget? leading;

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
      leading: leading,
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
