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
    this.onRename,
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

  /// Asks for a new title and renames the session (AV-073); not offered
  /// when null.
  final ValueChanged<SessionRef>? onRename;
}

/// Shows the sidebar: the [pinned] sessions in a "Pinned" section at the
/// top (AV-028), then the [tree] (AV-012, AV-025): each host with its status,
/// Retry and Remove when it is not connected, then its workspace folders
/// and their session rows, and "Add host…" last. Hosts and folders
/// collapse; tapping a host narrows the list to it (or back to every
/// host). Rows have a menu (right-click or long-press) to rename, archive,
/// mark read or unread, pin or unpin, and select; swiping a row to the left
/// archives (or unarchives) it. While [selection] is set, rows show
/// checkboxes and tapping toggles them. [dense] rows are thin, for
/// pointers; otherwise rows keep touch-sized targets. Folders are
/// dragged within their host to reorder them ([onMoveFolder]).
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
    this.onSshTerminal,
    this.onSshSettings,
    this.onNewSession,
    this.onMoveFolder,
    this.now,
    this.actions,
    this.selection,
    this.runLabels = const {},
    this.pinned = const [],
    this.dense = true,
  });

  /// The hosts with their folders, already grouped and sorted.
  final List<HostNode> tree;

  /// Ids of the collapsed "Pinned" section, hosts and folders
  /// ([sidebarRows]).
  final Set<String> collapsed;

  /// Collapses or expands the "Pinned" section, host or folder with an
  /// id; they do not collapse when null.
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

  /// Opens an SSH terminal to a host, by key (AV-014): "Open SSH
  /// terminal" in the host's menu; no menu item when null.
  final ValueChanged<String>? onSshTerminal;

  /// Edits a host's SSH settings, by key: "SSH settings…" in the host's
  /// menu; no menu item when null.
  final ValueChanged<String>? onSshSettings;

  /// Starts a session in a folder (the header's "+" button); no button
  /// when null.
  final ValueChanged<FolderGroup>? onNewSession;

  /// Moves `folders[from]` to index `to` of `folders`, one host's folders
  /// in list order: a folder row dragged onto another of its host (from
  /// the row with a pointer, after a long press on touch), or "Move up"
  /// and "Move down" in its menu and screen reader actions. Folders do
  /// not move when null.
  final void Function(List<FolderGroup> folders, int from, int to)?
  onMoveFolder;

  /// Clock for relative times; defaults to `DateTime.now()`.
  final DateTime? now;

  /// Row menu, swipe and multi-select; none when null.
  final SessionRowActions? actions;

  /// The sessions picked for a bulk action, or null when not selecting.
  final Set<SessionRef>? selection;

  /// Labels of sessions started as parallel runs ("Run 2 of 3",
  /// AV-045), by session.
  final Map<SessionRef, String> runLabels;

  /// The pinned sessions (AV-028), in the order shown in the "Pinned"
  /// section; not shown in their folders.
  final List<HostSession> pinned;

  /// Whether rows are thin ([denseHeaderHeight], [denseSessionHeight])
  /// rather than [kMinInteractiveDimension] high.
  final bool dense;

  Widget _row(
    BuildContext context,
    SidebarRow row,
    DateTime clock,
    Map<String, List<FolderGroup>> folders,
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
      onSshTerminal: onSshTerminal == null
          ? null
          : () => onSshTerminal!(node.host.key),
      onSshSettings: onSshSettings == null
          ? null
          : () => onSshSettings!(node.host.key),
    ),
    FolderRow(:final group, :final collapsed) => _FolderHeader(
      key: ValueKey(('folder', group.id)),
      group: group,
      collapsed: collapsed,
      dense: dense,
      onToggle: onToggle == null ? null : () => onToggle!(group.id),
      onNewSession: onNewSession == null ? null : () => onNewSession!(group),
      index: folders[group.host]!.indexOf(group),
      count: folders[group.host]!.length,
      onMove: onMoveFolder == null
          ? null
          : (from, to) => onMoveFolder!(folders[group.host]!, from, to),
    ),
    PinnedRow(:final sessions, :final collapsed, :final attentionCount) =>
      _PinnedHeader(
        key: const ValueKey('pinned'),
        count: sessions.length,
        attention: attentionCount,
        collapsed: collapsed,
        dense: dense,
        onToggle: onToggle == null ? null : () => onToggle!(pinnedNodeId),
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
    SessionItem(:final session, :final ref, :final place) => _SessionRow(
      key: ValueKey(('session', ref)),
      session: session,
      ref: ref,
      place: place,
      now: clock,
      dense: dense,
      selected: selected == ref,
      checked: selection?.contains(ref),
      pinned: place != null,
      actions: actions,
      onOpen: onSelect,
      runLabel: runLabels[ref],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final rows = sidebarRows(tree, collapsed, pinned: pinned);
    final folders = {for (final node in tree) node.host.key: node.folders};
    final addHost = onAddHost;
    return ListView.builder(
      itemCount: rows.length + (addHost == null ? 0 : 1),
      itemBuilder: (context, index) => index < rows.length
          ? _row(context, rows[index], clock, folders)
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

/// Start padding of a row at tree [depth] (0 hosts and the "Pinned"
/// section, 1 folders and pinned sessions, 2 sessions in folders).
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
    this.mouseCursor,
    this.semanticsActions,
  });

  /// Tree depth ([_indent]).
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

  /// The cursor over the row; the click cursor when null and [onTap] is
  /// set.
  final MouseCursor? mouseCursor;

  /// Screen reader actions on the row, by label.
  final Map<String, VoidCallback>? semanticsActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: mouseCursor,
        child: Semantics(
          button: onTap != null,
          selected: selected,
          expanded: expanded,
          customSemanticsActions: {
            for (final MapEntry(key: label, value: action)
                in (semanticsActions ?? const {}).entries)
              CustomSemanticsAction(label: label): action,
          },
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
/// connected, session and attention counts, Retry and Remove for a
/// host that is not connected (AV-010 to AV-012), and a menu with the
/// SSH terminal (AV-014).
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
    this.onSshTerminal,
    this.onSshSettings,
  });

  final HostNode node;
  final bool collapsed;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;
  final VoidCallback? onSshTerminal;
  final VoidCallback? onSshSettings;

  @override
  Widget build(BuildContext context) {
    final host = node.host;
    final onSshTerminal = this.onSshTerminal;
    final onSshSettings = this.onSshSettings;
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
          if (onSshTerminal != null || onSshSettings != null)
            PopupMenuButton<VoidCallback>(
              tooltip: '${host.label} actions',
              icon: Icon(Icons.more_vert, size: _iconSize(dense)),
              padding: dense ? EdgeInsets.zero : const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 200),
              style: dense
                  ? IconButton.styleFrom(
                      minimumSize: const Size(24, 24),
                      fixedSize: const Size(24, 24),
                    )
                  : null,
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                if (onSshTerminal != null)
                  PopupMenuItem(
                    value: onSshTerminal,
                    child: const Text('Open SSH terminal'),
                  ),
                if (onSshSettings != null)
                  PopupMenuItem(
                    value: onSshSettings,
                    child: const Text('SSH settings…'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The folder a folder row drag carries: its host and its index among the
/// host's folders.
@immutable
class _DraggedFolder {
  const _DraggedFolder(this.host, this.index);

  /// The host key of the folder.
  final String host;

  /// The folder's index among its host's folders.
  final int index;
}

/// A workspace folder's row (AV-025): collapse marker, name, details
/// ([folderDetails]), counts and the "+" button. With [onMove] it is
/// dragged onto another folder row of its host to take that folder's
/// place (from the row in a [dense] sidebar, with a grab cursor and a
/// handle on hover or focus; after a long press otherwise), and its
/// menu (right-click, the handle) and screen reader actions move it up
/// or down.
class _FolderHeader extends StatefulWidget {
  const _FolderHeader({
    super.key,
    required this.group,
    required this.collapsed,
    required this.dense,
    required this.index,
    required this.count,
    this.onToggle,
    this.onNewSession,
    this.onMove,
  });

  final FolderGroup group;
  final bool collapsed;
  final bool dense;

  /// The folder's index among its host's [count] folders.
  final int index;
  final int count;
  final VoidCallback? onToggle;
  final VoidCallback? onNewSession;

  /// Moves the folder at the first index among its host's folders to the
  /// second.
  final void Function(int from, int to)? onMove;

  @override
  State<_FolderHeader> createState() => _FolderHeaderState();
}

class _FolderHeaderState extends State<_FolderHeader> {
  bool _hovered = false;
  bool _focused = false;

  /// "Move up" and "Move down", where the folder can move that way.
  Map<String, VoidCallback> get _moves {
    final onMove = widget.onMove;
    final index = widget.index;
    return {
      if (onMove != null && index > 0)
        'Move up': () => onMove(index, index - 1),
      if (onMove != null && index < widget.count - 1)
        'Move down': () => onMove(index, index + 1),
    };
  }

  Future<void> _showMenu(Offset position) async {
    final moves = _moves;
    if (moves.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final MapEntry(key: label, value: move) in moves.entries)
          PopupMenuItem(value: move, child: Text(label)),
      ],
    );
    action?.call();
  }

  Widget _row(BuildContext context, {required bool interactive}) {
    final group = widget.group;
    final dense = widget.dense;
    final collapsed = widget.collapsed;
    final details = folderDetails(group);
    final onNewSession = widget.onNewSession;
    final movable = interactive && _moves.isNotEmpty;
    return _TreeRow(
      depth: 1,
      height: dense ? denseHeaderHeight : kMinInteractiveDimension,
      onTap: interactive ? widget.onToggle : null,
      mouseCursor: movable && dense ? SystemMouseCursors.grab : null,
      semanticsActions: movable ? _moves : null,
      expanded: widget.onToggle == null ? null : !collapsed,
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
          if (interactive && onNewSession != null)
            _RowButton(
              tooltip: 'New session in ${group.label}',
              icon: Icons.add,
              dense: dense,
              onPressed: onNewSession,
            ),
          if (movable && dense && (_hovered || _focused))
            Builder(
              builder: (context) => _RowButton(
                tooltip: 'Move ${group.label}',
                icon: Icons.drag_indicator,
                dense: dense,
                onPressed: () {
                  final box = context.findRenderObject()! as RenderBox;
                  _showMenu(
                    box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onMove = widget.onMove;
    final row = _row(context, interactive: true);
    if (onMove == null || widget.count < 2) return row;
    final data = _DraggedFolder(widget.group.host, widget.index);
    final dimmed = Opacity(opacity: 0.4, child: row);
    final interactiveRow = GestureDetector(
      onSecondaryTapUp: (details) => _showMenu(details.globalPosition),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: row,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final feedback = Material(
          elevation: 4,
          child: SizedBox(
            width: constraints.maxWidth,
            child: _row(context, interactive: false),
          ),
        );
        final draggable = widget.dense
            ? Draggable<_DraggedFolder>(
                data: data,
                feedback: feedback,
                childWhenDragging: dimmed,
                child: interactiveRow,
              )
            : LongPressDraggable<_DraggedFolder>(
                data: data,
                feedback: feedback,
                childWhenDragging: dimmed,
                child: interactiveRow,
              );
        return DragTarget<_DraggedFolder>(
          onWillAcceptWithDetails: (details) =>
              details.data.host == widget.group.host &&
              details.data.index != widget.index,
          onAcceptWithDetails: (details) =>
              onMove(details.data.index, widget.index),
          builder: (context, candidates, _) {
            final from = candidates.firstOrNull?.index;
            // The dragged folder takes this one's place: above it when it
            // comes from below, else below it.
            final side = BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            );
            return DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: from == null
                    ? null
                    : from > widget.index
                    ? Border(top: side)
                    : Border(bottom: side),
              ),
              child: draggable,
            );
          },
        );
      },
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
    this.place,
    this.runLabel,
  });

  final SessionSummary session;

  /// Where a pinned session lives ([pinnedPlace]); null in its folder.
  final String? place;
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
        if (actions.onRename case final onRename?)
          PopupMenuItem(
            value: () => onRename(ref),
            child: const Text('Rename…'),
          ),
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
      place: place,
      depth: place == null ? 2 : 1,
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
        if (actions.onRename case final onRename?)
          const CustomSemanticsAction(label: 'Rename'): () => onRename(ref),
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

/// The "Pinned" section's row (AV-028): collapse marker, pin icon,
/// "Pinned", and the session and attention counts. Tapping it collapses
/// or expands the section.
class _PinnedHeader extends StatelessWidget {
  const _PinnedHeader({
    super.key,
    required this.count,
    required this.attention,
    required this.collapsed,
    required this.dense,
    this.onToggle,
  });

  /// Number of pinned sessions shown.
  final int count;

  /// Number of them that need attention.
  final int attention;

  /// Whether the pinned sessions are hidden.
  final bool collapsed;

  /// Whether the row is thin ([denseHeaderHeight]).
  final bool dense;

  /// Collapses or expands the section; it does not collapse when null.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) => _TreeRow(
    depth: 0,
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
        Icon(Icons.push_pin_outlined, size: _iconSize(dense)),
      ],
    ),
    title: Text(
      'Pinned',
      maxLines: 1,
      style: _titleStyle(context, dense)?.copyWith(fontWeight: FontWeight.w600),
    ),
    trailing: _Counts(count: count, attention: attention, dense: dense),
  );
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
    this.place,
    this.pinned = false,
    this.depth = 2,
    this.dense = true,
  });

  /// The session to show.
  final SessionSummary session;

  /// Where the session lives (host and folder, [pinnedPlace]), shown
  /// first on the second line of a row in the "Pinned" section.
  final String? place;

  /// Tree depth of the row ([_indent]): 2 in a folder, 1 in the "Pinned"
  /// section.
  final int depth;

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
      ?place,
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
      depth: depth,
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
