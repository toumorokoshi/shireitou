/// The session list (inbox) grouped into working-directory folders.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../hosts/open_hosts.dart';
import 'folder_grouping.dart';
import 'relative_time.dart';
import 'session_tree.dart';
import 'status_badges.dart';

/// What a session row's menu, swipe and multi-select can do (AV-024,
/// AV-028, AV-029). Each callback gets the session.
@immutable
class SessionRowActions {
  /// Creates the row actions.
  const SessionRowActions({
    required this.onArchive,
    required this.onMarkRead,
    required this.onSelect,
    this.onPin,
    this.onCompare,
  });

  /// Archives the session (true) or unarchives it (false).
  final void Function(SessionRef session, bool archived) onArchive;

  /// Marks the session read (true) or unread (false).
  final void Function(SessionRef session, bool read) onMarkRead;

  /// Starts multi-select with the session selected, or toggles it while
  /// selecting.
  final ValueChanged<SessionRef> onSelect;

  /// Pins the session (true) or unpins it (false, AV-028); not offered
  /// when null.
  final void Function(SessionRef session, bool pinned)? onPin;

  /// Opens the comparison of the session's parallel runs (AV-045); only
  /// offered for sessions with a run label.
  final ValueChanged<SessionRef>? onCompare;
}

/// Shows the sidebar [tree] (AV-012, AV-025): each host with its status,
/// Retry and Remove when it is not connected, then its workspace folders
/// and their session rows, and "Add host…" last. Hosts and folders
/// collapse; tapping a host narrows the list to it (or back to every
/// host). Rows have a menu (right-click or long-press) to archive, mark
/// read or unread, pin or unpin, and select; swiping a row to the left
/// archives (or unarchives) it. While [selection] is set, rows show
/// checkboxes and tapping toggles them. [dense] rows are thin, for
/// pointers; otherwise rows keep touch-sized targets.
class SessionListView extends StatelessWidget {
  /// Creates a [SessionListView].
  const SessionListView({
    super.key,
    required this.tree,
    required this.onSelect,
    this.collapsed = const {},
    this.onToggle,
    this.selected,
    this.selectedHost,
    this.onSelectHost,
    this.onAddHost,
    this.onRetry,
    this.onRemove,
    this.onNewSession,
    this.now,
    this.actions,
    this.selection,
    this.runLabels = const {},
    this.pinned = const {},
    this.dense = true,
  });

  /// The hosts with their folders, already grouped and sorted.
  final List<HostNode> tree;

  /// Ids of the collapsed hosts and folders ([sidebarRows]).
  final Set<String> collapsed;

  /// Collapses or expands the host or folder with an id; they do not
  /// collapse when null.
  final ValueChanged<String>? onToggle;

  /// The selected session, highlighted in the list.
  final SessionRef? selected;

  /// Called with a session when its row is tapped.
  final ValueChanged<SessionRef> onSelect;

  /// The host the list is narrowed to, highlighted; null for every host.
  final String? selectedHost;

  /// Narrows the list to a host, or to every host (null); host rows do
  /// nothing on tap when null.
  final ValueChanged<String?>? onSelectHost;

  /// Opens the page that connects another host; no "Add host…" row when
  /// null.
  final VoidCallback? onAddHost;

  /// Connects a failed host again, by key.
  final ValueChanged<String>? onRetry;

  /// Closes a host that is not connected, by key.
  final ValueChanged<String>? onRemove;

  /// Starts a session in a folder (the header's "+" button); no button
  /// when null.
  final ValueChanged<FolderGroup>? onNewSession;

  /// Clock for relative times; defaults to `DateTime.now()`.
  final DateTime? now;

  /// Row menu, swipe and multi-select; none when null.
  final SessionRowActions? actions;

  /// The sessions picked for a bulk action, or null when not selecting.
  final Set<SessionRef>? selection;

  /// Labels of sessions started as parallel runs ("Run 2 of 3",
  /// AV-045), by session.
  final Map<SessionRef, String> runLabels;

  /// The pinned sessions (AV-028), shown with a pin marker.
  final Set<SessionRef> pinned;

  /// Whether rows are thin ([denseHeaderHeight], [denseSessionHeight])
  /// rather than [kMinInteractiveDimension] high.
  final bool dense;

  Widget _row(
    BuildContext context,
    SidebarRow row,
    DateTime clock,
  ) => switch (row) {
    HostRow(:final node, :final collapsed) => _HostHeader(
      key: ValueKey(('host', node.host.key)),
      node: node,
      collapsed: collapsed,
      dense: dense,
      selected: selectedHost == node.host.key,
      onTap: onSelectHost == null
          ? null
          : () => onSelectHost!(
              selectedHost == node.host.key ? null : node.host.key,
            ),
      onToggle: onToggle == null ? null : () => onToggle!(hostNodeId(node)),
      onRetry: onRetry == null ? null : () => onRetry!(node.host.key),
      onRemove: onRemove == null ? null : () => onRemove!(node.host.key),
    ),
    FolderRow(:final group, :final collapsed) => _FolderHeader(
      key: ValueKey(('folder', group.id)),
      group: group,
      collapsed: collapsed,
      dense: dense,
      onToggle: onToggle == null ? null : () => onToggle!(group.id),
      onNewSession: onNewSession == null ? null : () => onNewSession!(group),
    ),
    EmptyRow(:final host, :final text) => Padding(
      key: ValueKey(('empty', host)),
      padding: EdgeInsetsDirectional.fromSTEB(
        _indent(1),
        dense ? 6 : 12,
        8,
        dense ? 6 : 12,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
    SessionItem(:final session, :final ref) => _SessionRow(
      key: ValueKey(('session', ref)),
      session: session,
      ref: ref,
      now: clock,
      dense: dense,
      selected: selected == ref,
      checked: selection?.contains(ref),
      pinned: pinned.contains(ref),
      actions: actions,
      onOpen: onSelect,
      runLabel: runLabels[ref],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final rows = sidebarRows(tree, collapsed);
    final addHost = onAddHost;
    return ListView.builder(
      itemCount: rows.length + (addHost == null ? 0 : 1),
      itemBuilder: (context, index) => index < rows.length
          ? _row(context, rows[index], clock)
          : _TreeRow(
              key: const ValueKey('add-host'),
              depth: 0,
              height: dense ? denseHeaderHeight : kMinInteractiveDimension,
              onTap: addHost,
              leading: Icon(Icons.add_link, size: _iconSize(dense)),
              title: Text('Add host…', style: _titleStyle(context, dense)),
            ),
    );
  }
}

/// Height of a host or folder row in a dense sidebar.
const denseHeaderHeight = 28.0;

/// Height of a session row in a dense sidebar.
const denseSessionHeight = 32.0;

/// Start padding of a row at tree [depth] (0 hosts, 1 folders, 2
/// sessions).
double _indent(int depth) => 8.0 + 14.0 * depth;

double _iconSize(bool dense) => dense ? 16 : 20;

TextStyle? _titleStyle(BuildContext context, bool dense) =>
    Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontSize: dense ? 13 : 14, height: 1.2);

TextStyle? _detailStyle(BuildContext context, bool dense) =>
    (dense
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.bodySmall)
        ?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.2,
        );

/// One sidebar row: [leading], [title] (with [subtitle] under it) and
/// [trailing] in a row at least [height] high, indented by [depth], with
/// button semantics when [onTap] is set (as a [ListTile] has).
class _TreeRow extends StatelessWidget {
  const _TreeRow({
    super.key,
    required this.depth,
    required this.height,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.expanded,
  });

  /// Tree depth: 0 hosts, 1 folders, 2 sessions.
  final int depth;

  /// Minimum row height.
  final double height;

  /// Shown first.
  final Widget? leading;

  /// The main line.
  final Widget title;

  /// The line under [title], if any.
  final Widget? subtitle;

  /// Shown at the end.
  final Widget? trailing;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  /// Whether the row is highlighted.
  final bool selected;

  /// Whether a collapsible row is expanded; null when it does not
  /// collapse.
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: onTap != null,
          selected: selected,
          expanded: expanded,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: _indent(depth),
                end: 4,
              ),
              child: Row(
                children: [
                  if (leading case final leading?) ...[
                    leading,
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: subtitle == null
                        ? title
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [title, subtitle],
                          ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small icon button for sidebar rows: 24 px in a dense sidebar, touch
/// sized otherwise.
class _RowButton extends StatelessWidget {
  const _RowButton({
    required this.tooltip,
    required this.icon,
    required this.dense,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool dense;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon, size: _iconSize(dense)),
    visualDensity: VisualDensity.compact,
    padding: dense ? EdgeInsets.zero : null,
    constraints: dense
        ? const BoxConstraints.tightFor(width: 24, height: 24)
        : null,
    onPressed: onPressed,
  );
}

/// A host's row: collapse toggle, status dot, label, status when not
/// connected, session and attention counts, and Retry and Remove for a
/// host that is not connected (AV-010 to AV-012).
class _HostHeader extends StatelessWidget {
  const _HostHeader({
    super.key,
    required this.node,
    required this.collapsed,
    required this.dense,
    required this.selected,
    this.onTap,
    this.onToggle,
    this.onRetry,
    this.onRemove,
  });

  final HostNode node;
  final bool collapsed;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final host = node.host;
    final scheme = Theme.of(context).colorScheme;
    final idle =
        host.status == ConnectionStatus.failed ||
        host.status == ConnectionStatus.disconnected;
    final onToggle = this.onToggle;
    return _TreeRow(
      depth: 0,
      height: dense ? denseHeaderHeight : kMinInteractiveDimension,
      selected: selected,
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onToggle != null)
            _RowButton(
              tooltip: '${collapsed ? 'Expand' : 'Collapse'} ${host.label}',
              icon: collapsed ? Icons.chevron_right : Icons.expand_more,
              dense: dense,
              onPressed: onToggle,
            ),
          const SizedBox(width: 2),
          Icon(
            Icons.circle,
            size: 10,
            // Other states are spelled out beside the label.
            semanticLabel: host.status == ConnectionStatus.connected
                ? hostStatusText(host)
                : null,
            color: switch (host.status) {
              ConnectionStatus.connected => Colors.green,
              ConnectionStatus.failed => scheme.error,
              _ => scheme.outline,
            },
          ),
        ],
      ),
      title: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              host.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(
                context,
                dense,
              )?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (host.status != ConnectionStatus.connected) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Tooltip(
                excludeFromSemantics: true,
                message: hostStatusText(host),
                child: Text(
                  hostStatusText(host),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _detailStyle(context, dense)?.copyWith(
                    color: host.status == ConnectionStatus.failed
                        ? scheme.error
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (host.live)
            _Counts(
              count: node.sessionCount,
              attention: node.attentionCount,
              dense: dense,
            ),
          if (idle && onRetry != null)
            _RowButton(
              tooltip: 'Retry ${host.label}',
              icon: Icons.refresh,
              dense: dense,
              onPressed: onRetry!,
            ),
          if (idle && onRemove != null)
            _RowButton(
              tooltip: 'Remove ${host.label}',
              icon: Icons.close,
              dense: dense,
              onPressed: onRemove!,
            ),
        ],
      ),
    );
  }
}

/// A workspace folder's row (AV-025): collapse marker, name, details
/// ([folderDetails]), counts and the "+" button.
class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    super.key,
    required this.group,
    required this.collapsed,
    required this.dense,
    this.onToggle,
    this.onNewSession,
  });

  final FolderGroup group;
  final bool collapsed;
  final bool dense;
  final VoidCallback? onToggle;
  final VoidCallback? onNewSession;

  @override
  Widget build(BuildContext context) {
    final details = folderDetails(group);
    final onNewSession = this.onNewSession;
    return _TreeRow(
      depth: 1,
      height: dense ? denseHeaderHeight : kMinInteractiveDimension,
      onTap: onToggle,
      expanded: onToggle == null ? null : !collapsed,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            collapsed ? Icons.chevron_right : Icons.expand_more,
            size: _iconSize(dense),
          ),
          Icon(Icons.folder_outlined, size: _iconSize(dense)),
        ],
      ),
      title: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(
                context,
                dense,
              )?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Tooltip(
                excludeFromSemantics: true,
                message: details,
                child: Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _detailStyle(context, dense),
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Counts(
            count: group.sessions.length,
            attention: group.attentionCount,
            dense: dense,
          ),
          if (onNewSession != null)
            _RowButton(
              tooltip: 'New session in ${group.label}',
              icon: Icons.add,
              dense: dense,
              onPressed: onNewSession,
            ),
        ],
      ),
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
    required this.dense,
    required this.selected,
    required this.checked,
    required this.pinned,
    required this.actions,
    required this.onOpen,
    this.runLabel,
  });

  final SessionSummary session;
  final String? runLabel;
  final SessionRef ref;
  final DateTime now;
  final bool dense;
  final bool selected;

  /// Whether the row is picked; null when not selecting.
  final bool? checked;
  final bool pinned;
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
        if (actions.onPin case final onPin?)
          PopupMenuItem(
            value: () => onPin(ref, !pinned),
            child: Text(pinLabel(pinned: pinned)),
          ),
        PopupMenuItem(
          value: () => actions.onSelect(ref),
          child: Text(checked == null ? 'Select' : 'Toggle selection'),
        ),
        if (actions.onCompare case final onCompare? when runLabel != null)
          PopupMenuItem(
            value: () => onCompare(ref),
            child: const Text('Compare runs'),
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
      runLabel: runLabel,
      pinned: pinned,
      dense: dense,
      selected: selected || (checked ?? false),
      leading: checked == null
          ? null
          : Checkbox(
              value: checked,
              visualDensity: dense ? VisualDensity.compact : null,
              materialTapTargetSize: dense
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              onChanged: (_) => actions?.onSelect(ref),
            ),
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
        if (actions.onPin case final onPin?)
          CustomSemanticsAction(label: pinLabel(pinned: pinned)): () =>
              onPin(ref, !pinned),
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

/// The pin action's label for a session that is [pinned] or not
/// (AV-028).
String pinLabel({required bool pinned}) => pinned ? 'Unpin' : 'Pin to top';

/// The line beside a folder's name: its repository and branch when the
/// host reports them, and its full path. The host is the folder's parent
/// in the sidebar tree, so it is not repeated.
String folderDetails(FolderGroup group) => [
  ?group.repo,
  if (group.branch case final branch?) '⎇ $branch',
  if (group.path.isNotEmpty) group.path,
].join(' · ');

/// A session [count] and, when [attention] is above zero, a badge with
/// the number that need attention.
class _Counts extends StatelessWidget {
  const _Counts({
    required this.count,
    required this.attention,
    required this.dense,
  });

  final int count;
  final int attention;
  final bool dense;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: _detailStyle(context, dense)),
        if (attention > 0) ...[
          const SizedBox(width: 8),
          Badge(
            label: Text('$attention'),
            child: Icon(Icons.notifications_outlined, size: _iconSize(dense)),
          ),
        ],
      ],
    ),
  );
}

/// One session row: title, then provider, modified time, change stats
/// and activity on a smaller second line, and status badges (AV-020,
/// AV-021).
class SessionTile extends StatelessWidget {
  /// Creates a [SessionTile].
  const SessionTile({
    super.key,
    required this.session,
    required this.now,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.runLabel,
    this.pinned = false,
    this.dense = true,
  });

  /// The session to show.
  final SessionSummary session;

  /// "Run 2 of 3" when the session is one of several parallel runs
  /// (AV-045).
  final String? runLabel;

  /// Whether the session is pinned (AV-028); a pin marker is shown
  /// before the title.
  final bool pinned;

  /// Clock for the relative modified time.
  final DateTime now;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Whether the row is highlighted.
  final bool selected;

  /// Shown before the title (the multi-select checkbox).
  final Widget? leading;

  /// Whether the row is thin ([denseSessionHeight]) rather than touch
  /// sized.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final modified = DateTime.tryParse(session.modifiedAt);
    final changes = session.changes;
    final details = [
      ?runLabel,
      session.provider,
      if (modified != null) formatRelativeTime(modified, now),
      if (changes != null)
        '+${changes.additions ?? 0} −${changes.deletions ?? 0}'
            '${changes.files == null ? '' : ' (${changes.files} files)'}',
      ?session.activity,
    ];
    final badges = badgesFor(session.status);
    return _TreeRow(
      depth: 2,
      height: dense ? denseSessionHeight : kMinInteractiveDimension,
      selected: selected,
      onTap: onTap,
      leading: leading,
      title: Row(
        children: [
          if (pinned) ...[
            Icon(
              Icons.push_pin,
              size: dense ? 12 : 14,
              semanticLabel: 'Pinned',
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(context, dense)?.copyWith(
                fontWeight: session.status.isReadFlag ? null : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        details.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _detailStyle(context, dense),
      ),
      trailing: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
        child: Wrap(
          spacing: 4,
          children: [for (final badge in badges) StatusBadgeChip(badge: badge)],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
