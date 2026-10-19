/// The session list (inbox): the sidebar's sections and session rows
/// (AV-092, AV-093).
library;

import 'dart:math' as math;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../editor/editor_target.dart';
import '../hosts/open_hosts.dart';
import '../theme/app_theme.dart';
import 'folder_grouping.dart';
import 'relative_time.dart';
import 'session_tree.dart';
import 'session_status_indicator.dart';
import 'status_badges.dart';
import '../theme/app_icons.dart';
import '../agent_names.dart';

/// What a session row's menu, hover buttons, swipe and multi-select can
/// do (AV-024, AV-028, AV-029). Each callback gets the session.
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
    this.onMarkDone,
  });

  /// Archives the session (true) or unarchives it (false).
  final void Function(SessionRef session, bool archived) onArchive;

  /// Archives the session from the "Mark as done" hover button (AV-093),
  /// where the caller can offer Undo; [onArchive] when null.
  final ValueChanged<SessionRef>? onMarkDone;

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

/// Shows the sidebar's sections ([sidebarRows], AV-092): the [pinned]
/// sessions (AV-028), the [chats] (no working directory), then the
/// [folders] (AV-025), each a header of an icon, its name and an
/// attention dot, collapsed by a tap, followed by its session rows
/// (AV-093). Folders are dragged onto each other to reorder them
/// ([onMoveFolder]) and have a "+" on hover for a new session there.
/// Rows have a menu (right-click or long-press) to rename, archive, mark
/// read or unread, pin or unpin, and select; pin and "Mark as done" on
/// hover; and swiping a row to the left archives (or unarchives) it.
/// While [selection] is set, rows show checkboxes and tapping toggles
/// them. [dense] rows are sized for pointers; otherwise rows keep
/// touch-sized targets.
class SessionListView extends StatelessWidget {
  /// Creates a [SessionListView].
  const SessionListView({
    super.key,
    required this.onSelect,
    this.pinned = const [],
    this.chats = const [],
    this.folders = const [],
    this.hostLabels = const {},
    this.agents = const {},
    this.collapsed = const {},
    this.onToggle,
    this.selected,
    this.onNewSession,
    this.openInEditor,
    this.onMoveFolder,
    this.now,
    this.actions,
    this.selection,
    this.runLabels = const {},
    this.emptyText = noSessionsText,
    this.dense = true,
  });

  /// The pinned sessions (AV-028), in the order shown in the "Pinned"
  /// section; not shown in their folders.
  final List<HostSession> pinned;

  /// The sessions with no working directory ([chatSessions]), in the
  /// "Chats" section.
  final List<HostSession> chats;

  /// The workspace folders, already grouped, sorted and ordered.
  final List<FolderGroup> folders;

  /// The labels of the hosts by key when several are open
  /// ([hostLabelsOf]), shown on rows and folder headers.
  final Map<String, String> hostLabels;

  /// The agents of each host by key, which name a session's agent on its
  /// hover card ([agentDisplayName]).
  final Map<String, List<AgentInfo>> agents;

  /// Ids of the collapsed sections and folders ([sidebarRows]).
  final Set<String> collapsed;

  /// Collapses or expands the section or folder with an id; they do not
  /// collapse when null.
  final ValueChanged<String>? onToggle;

  /// The selected session, highlighted in the list.
  final SessionRef? selected;

  /// Called with a session when its row is tapped.
  final ValueChanged<SessionRef> onSelect;

  /// Starts a session in a folder (the header's "+" button); no button
  /// when null.
  final ValueChanged<FolderGroup>? onNewSession;

  /// Opens a folder (with its absolute path) in the code editor (AV-015),
  /// with the button's and menu item's label; neither shows when null or
  /// for a folder that is not a path.
  final ({String label, void Function(FolderGroup group, String folder) open})?
  openInEditor;

  /// Moves `folders[from]` to index `to` of `folders`, the shown folders
  /// of every host in list order: a folder header dragged onto another
  /// (from the row with a pointer, after a long press on touch), or
  /// "Move up" and "Move down" in its menu and screen reader actions.
  /// Folders do not move when null.
  final void Function(List<FolderGroup> folders, int from, int to)?
  onMoveFolder;

  /// Clock for relative times; defaults to `DateTime.now()`.
  final DateTime? now;

  /// Row menu, hover buttons, swipe and multi-select; none when null.
  final SessionRowActions? actions;

  /// The sessions picked for a bulk action, or null when not selecting.
  final Set<SessionRef>? selection;

  /// Labels of sessions started as parallel runs ("Run 2 of 3",
  /// AV-045), by session.
  final Map<SessionRef, String> runLabels;

  /// Shown when there are no rows ([noSessionsText] or [noMatchText]).
  final String emptyText;

  /// Whether rows are sized for pointers ([denseHeaderHeight],
  /// [denseSessionHeight]) rather than touch.
  final bool dense;

  Widget _row(
    SidebarRow row,
    DateTime clock,
    Set<SessionRef> pins,
  ) => switch (row) {
    SectionRow(:final id, :final collapsed, :final hasAttention) =>
      _SectionHeader(
        key: ValueKey(('section', id)),
        icon: id == pinnedNodeId ? AppIcons.pin : AppIcons.chats,
        label: id == pinnedNodeId ? 'Pinned' : 'Chats',
        attention: hasAttention,
        collapsed: collapsed,
        dense: dense,
        onToggle: onToggle == null ? null : () => onToggle!(id),
      ),
    FolderRow(:final group, :final collapsed, :final hostLabel) =>
      _FolderHeader(
        key: ValueKey(('folder', group.id)),
        group: group,
        hostLabel: hostLabel,
        collapsed: collapsed,
        dense: dense,
        onToggle: onToggle == null ? null : () => onToggle!(group.id),
        onNewSession: onNewSession == null ? null : () => onNewSession!(group),
        openInEditor: switch ((openInEditor, editorFolder(group.key))) {
          ((:final label, :final open), final folder?) => (
            label: label,
            open: () => open(group, folder),
          ),
          _ => null,
        },
        index: folders.indexOf(group),
        count: folders.length,
        onMove: onMoveFolder == null
            ? null
            : (from, to) => onMoveFolder!(folders, from, to),
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
      pinned: pins.contains(ref),
      actions: actions,
      onOpen: onSelect,
      runLabel: runLabels[ref],
      agent: agentDisplayName(session.provider, agents[ref.host] ?? const []),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final rows = sidebarRows(
      collapsed: collapsed,
      pinned: pinned,
      chats: chats,
      folders: folders,
      hostLabels: hostLabels,
    );
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          emptyText,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.of(context).mutedText),
        ),
      );
    }
    final pins = {for (final s in pinned) s.ref};
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) => _row(rows[index], clock, pins),
    );
  }
}

/// Height of a section or folder header in a dense sidebar.
const denseHeaderHeight = 28.0;

/// Height of a two-line session row in a dense sidebar (AV-093), as
/// measured in the reference screenshot.
const denseSessionHeight = 56.0;

/// Height of a two-line session row on touch layouts.
const touchSessionHeight = 52.0;

/// How long the pointer rests on a session row before its card shows.
const hoverCardDelay = Duration(milliseconds: 500);

/// Start padding of a row at [depth] (0 section headers, 1 sessions).
double _indent(int depth) => 8.0 + 8.0 * depth;

double _iconSize(bool dense) => dense ? 16 : 20;

TextStyle? _titleStyle(BuildContext context, bool dense) => Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(
      fontSize: dense ? 13 : 14,
      height: 1.25,
      fontWeight: FontWeight.normal,
    );

TextStyle? _detailStyle(BuildContext context, bool dense) =>
    Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.of(context).mutedText,
      fontWeight: FontWeight.normal,
      height: 1.25,
    );

/// Tracks whether the pointer is over the row or focus is inside it, so
/// a row shows its hover buttons to the mouse and the keyboard alike.
class _HoverRegion extends StatefulWidget {
  const _HoverRegion({required this.builder});

  /// Builds the row; `active` is true while hovered or focused.
  final Widget Function(BuildContext context, bool active) builder;

  @override
  State<_HoverRegion> createState() => _HoverRegionState();
}

class _HoverRegionState extends State<_HoverRegion> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (focused) => setState(() => _focused = focused),
    child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered || _focused),
    ),
  );
}

/// One sidebar row: [leading], [title] (with [subtitle] under it) and
/// [trailing] in a row at least [height] high, indented by [depth], with
/// button semantics when [onTap] is set (as a [ListTile] has). A
/// [selected] row has a subtle rounded fill.
class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.depth,
    required this.height,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.expanded,
    this.mouseCursor,
    this.semanticsActions,
  });

  /// Indent level ([_indent]).
  final int depth;

  /// Minimum row height.
  final double height;

  /// Shown first.
  final Widget? leading;

  /// The row's text.
  final Widget title;

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
    final colors = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? colors.selectedFill : Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          mouseCursor: mouseCursor,
          customBorder: shape,
          hoverColor: colors.hoverFill,
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
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: title),
                    ?trailing,
                  ],
                ),
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

/// The label of a section's attention dot, for screen readers.
const attentionDotLabel = 'Needs attention';

/// A small dot after a section's name when one of its sessions needs
/// attention (AV-092); headers show no counts.
class _AttentionDot extends StatelessWidget {
  const _AttentionDot();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 6),
    child: Icon(
      Icons.circle,
      size: 6,
      color: AppColors.of(context).statusColors.attention,
      semanticLabel: attentionDotLabel,
    ),
  );
}

/// A section's header (AV-092): [icon], [label] (and [detail] after it,
/// muted), an attention dot, a chevron while collapsed, and [actions] at
/// the end. Tapping it collapses or expands the section.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.attention,
    required this.collapsed,
    required this.dense,
    this.detail,
    this.tooltip,
    this.onToggle,
    this.actions = const [],
    this.mouseCursor,
    this.semanticsActions,
  });

  /// Shown before [label].
  final IconData icon;

  /// The section's name.
  final String label;

  /// Shown after [label] in the detail style (the folder's host).
  final String? detail;

  /// Shown when the pointer rests on the name (a folder's path).
  final String? tooltip;

  /// Whether a session in the section needs attention.
  final bool attention;

  /// Whether the section's sessions are hidden.
  final bool collapsed;

  /// Whether the row is sized for pointers ([denseHeaderHeight]).
  final bool dense;

  /// Collapses or expands the section; it does not collapse when null.
  final VoidCallback? onToggle;

  /// Buttons at the end of the row.
  final List<Widget> actions;

  /// The cursor over the row ([_TreeRow.mouseCursor]).
  final MouseCursor? mouseCursor;

  /// Screen reader actions on the row, by label.
  final Map<String, VoidCallback>? semanticsActions;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).mutedText;
    final detail = this.detail;
    final tooltip = this.tooltip;
    final name = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _titleStyle(
        context,
        dense,
      )?.copyWith(color: muted, fontWeight: FontWeight.w600),
    );
    return _TreeRow(
      depth: 0,
      height: dense ? denseHeaderHeight : kMinInteractiveDimension,
      onTap: onToggle,
      expanded: onToggle == null ? null : !collapsed,
      mouseCursor: mouseCursor,
      semanticsActions: semanticsActions,
      leading: Icon(icon, size: _iconSize(dense), color: muted),
      title: Row(
        children: [
          Flexible(
            child: tooltip == null || tooltip.isEmpty
                ? name
                : Tooltip(
                    excludeFromSemantics: true,
                    // A long press drags the folder on touch layouts.
                    triggerMode: TooltipTriggerMode.manual,
                    message: tooltip,
                    child: name,
                  ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _detailStyle(context, dense),
              ),
            ),
          ],
          if (attention) const _AttentionDot(),
          if (collapsed)
            Icon(AppIcons.expand, size: _iconSize(dense), color: muted),
        ],
      ),
      trailing: actions.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: actions),
    );
  }
}

/// The folder a folder header drag carries: its index among the shown
/// folders.
@immutable
class _DraggedFolder {
  const _DraggedFolder(this.index);

  /// The folder's index among the shown folders.
  final int index;
}

/// A workspace folder's header (AV-025, AV-092): a folder icon,
/// "folder [project]" ([workspaceLabel]), its host when several are
/// open, the attention dot, and the "+" button (on hover with a pointer).
/// With [onMove] it is dragged onto another folder header to take that
/// folder's place (from the row in a [dense] sidebar, with a grab cursor
/// and a handle on hover or focus; after a long press otherwise), and
/// its menu (right-click, the handle) and screen reader actions move it
/// up or down.
class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    super.key,
    required this.group,
    required this.collapsed,
    required this.dense,
    required this.index,
    required this.count,
    this.hostLabel,
    this.onToggle,
    this.onNewSession,
    this.openInEditor,
    this.onMove,
  });

  /// The folder and its sessions.
  final FolderGroup group;

  /// The folder's host when several hosts are open.
  final String? hostLabel;

  /// Whether the folder's sessions are hidden.
  final bool collapsed;

  /// Whether the row is sized for pointers.
  final bool dense;

  /// The folder's index among the [count] shown folders.
  final int index;

  /// Number of shown folders.
  final int count;

  /// Collapses or expands the folder.
  final VoidCallback? onToggle;

  /// Starts a session in the folder (the "+" button).
  final VoidCallback? onNewSession;

  /// Opens the folder in the code editor (a hover button and a menu
  /// item), with their label.
  final ({String label, VoidCallback open})? openInEditor;

  /// Moves the folder at the first index among the shown folders to the
  /// second.
  final void Function(int from, int to)? onMove;

  /// The items of the folder's menu: [openInEditor] and [_moves].
  Map<String, VoidCallback> get _menu => {
    if (openInEditor case (:final label, :final open)) label: open,
    ..._moves,
  };

  /// "Move up" and "Move down", where the folder can move that way.
  Map<String, VoidCallback> get _moves {
    final onMove = this.onMove;
    return {
      if (onMove != null && index > 0)
        'Move up': () => onMove(index, index - 1),
      if (onMove != null && index < count - 1)
        'Move down': () => onMove(index, index + 1),
    };
  }

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final menu = _menu;
    if (menu.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final MapEntry(key: label, value: item) in menu.entries)
          PopupMenuItem(value: item, child: Text(label)),
      ],
    );
    action?.call();
  }

  Widget _row({required bool interactive, bool active = false}) {
    final onNewSession = this.onNewSession;
    final openInEditor = this.openInEditor;
    final movable = interactive && _moves.isNotEmpty;
    // Touch layouts have no hover, so their "+" always shows.
    final showActions = interactive && (active || !dense);
    return _SectionHeader(
      icon: AppIcons.folder,
      label: workspaceLabel(group.label, group.project),
      detail: hostLabel,
      tooltip: folderDetails(group),
      attention: group.attentionCount > 0,
      collapsed: collapsed,
      dense: dense,
      onToggle: interactive ? onToggle : null,
      mouseCursor: movable && dense ? SystemMouseCursors.grab : null,
      semanticsActions: interactive && _menu.isNotEmpty ? _menu : null,
      actions: [
        if (showActions && dense && openInEditor != null)
          _RowButton(
            tooltip: openInEditor.label,
            icon: AppIcons.vscode,
            dense: dense,
            onPressed: openInEditor.open,
          ),
        if (showActions && onNewSession != null)
          _RowButton(
            tooltip: 'New session in ${group.label}',
            icon: AppIcons.add,
            dense: dense,
            onPressed: onNewSession,
          ),
        if (movable && dense && active)
          Builder(
            builder: (context) => _RowButton(
              tooltip: 'Move ${group.label}',
              icon: AppIcons.drag,
              dense: dense,
              onPressed: () {
                final box = context.findRenderObject()! as RenderBox;
                _showMenu(
                  context,
                  box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onMove = this.onMove;
    final hoverable = _HoverRegion(
      builder: (_, active) => _row(interactive: true, active: active),
    );
    final interactiveRow = _menu.isEmpty
        ? hoverable
        : GestureDetector(
            onSecondaryTapUp: (details) =>
                _showMenu(context, details.globalPosition),
            child: hoverable,
          );
    if (onMove == null || count < 2) return interactiveRow;
    final data = _DraggedFolder(index);
    final dimmed = Opacity(opacity: 0.4, child: _row(interactive: false));
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = AppColors.of(context);
        final feedback = Material(
          color: colors.raisedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appRadius),
            side: BorderSide(color: colors.hairline),
          ),
          child: SizedBox(
            width: constraints.maxWidth,
            child: _row(interactive: false),
          ),
        );
        final draggable = dense
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
          onWillAcceptWithDetails: (details) => details.data.index != index,
          onAcceptWithDetails: (details) => onMove(details.data.index, index),
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
                    : from > index
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

/// A [SessionTile] with the row menu, hover buttons (pin and "Mark as
/// done"), swipe to archive and multi-select.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    super.key,
    required this.session,
    required this.ref,
    required this.place,
    required this.now,
    required this.dense,
    required this.selected,
    required this.checked,
    required this.pinned,
    required this.actions,
    required this.onOpen,
    this.runLabel,
    this.agent,
  });

  final SessionSummary session;

  /// The agent's name for the hover card ([agentDisplayName]).
  final String? agent;

  /// Where the session lives ([sessionPlace]).
  final String place;
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

  /// Pin and "Mark as done" (or "Unarchive"), shown on hover (AV-093).
  List<Widget> _hoverButtons(SessionRowActions actions) => [
    if (actions.onPin case final onPin?)
      _RowButton(
        tooltip: pinLabel(pinned: pinned),
        icon: pinned ? AppIcons.unpin : AppIcons.pin,
        dense: dense,
        onPressed: () => onPin(ref, !pinned),
      ),
    _RowButton(
      tooltip: _archived ? 'Unarchive' : markDoneLabel,
      icon: _archived ? AppIcons.unarchive : AppIcons.markDone,
      dense: dense,
      onPressed: switch ((_archived, actions.onMarkDone)) {
        (false, final onMarkDone?) => () => onMarkDone(ref),
        _ => () => actions.onArchive(ref, !_archived),
      },
    ),
  ];

  Widget _tile({bool active = false}) {
    final actions = this.actions;
    final checked = this.checked;
    return SessionTile(
      session: session,
      now: now,
      runLabel: runLabel,
      agent: agent,
      place: place,
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
      // Touch layouts have no hover; they swipe and long-press instead.
      trailing: actions != null && checked == null && active && dense
          ? _hoverButtons(actions)
          : const [],
      onTap: checked == null ? () => onOpen(ref) : () => actions?.onSelect(ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = this.actions;
    final checked = this.checked;
    if (actions == null) return _tile();
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
        child: _HoverRegion(builder: (_, active) => _tile(active: active)),
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
                  _archived ? AppIcons.unarchive : AppIcons.archive,
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

/// The tooltip of the hover button that archives a session (AV-093).
const markDoneLabel = 'Mark as done';

/// The pin action's label for a session that is [pinned] or not
/// (AV-028).
String pinLabel({required bool pinned}) => pinned ? 'Unpin' : 'Pin to top';

/// A folder's repository and branch when the host reports them, and its
/// full path, shown when the pointer rests on its header.
String folderDetails(FolderGroup group) => [
  ?group.repo,
  if (group.branch case final branch?) '⎇ $branch',
  if (group.path.isNotEmpty) group.path,
].join(' · ');

/// The text after the title on a session's hover card (AV-093),
/// " · agent · workspace" (the agent is [agent], its display name, else
/// the provider id; the workspace is the project's name, else the
/// folder's), and the folder's full path for the line under it (null
/// with no folder).
({String heading, String? path}) hoverCardOf(
  SessionSummary summary, {
  String? agent,
}) {
  final key = folderKeyOf(summary);
  final workspace =
      projectNameOf(summary) ?? (key == null ? null : folderLabelOf(key));
  return (
    heading: [
      '',
      if ((agent ?? summary.provider) case final name when name.isNotEmpty)
        name,
      ?workspace,
    ].join(' · '),
    path: key,
  );
}

/// Where a row's hover card goes (AV-093): past the end of the row and
/// centred on it, as in the reference, so it covers the pane rather
/// than the neighbouring rows or the row's hover buttons; kept inside
/// the window.
Offset hoverCardPosition(TooltipPositionContext context) {
  final TooltipPositionContext(:target, :targetSize, :tooltipSize) = context;
  final overlay = context.overlaySize;
  final x = target.dx + targetSize.width / 2 + 4;
  final y = target.dy - tooltipSize.height / 2;
  return Offset(
    x.clamp(0, math.max(0, overlay.width - tooltipSize.width)),
    y.clamp(0, math.max(0, overlay.height - tooltipSize.height)),
  );
}

/// One session row (AV-093): a status dot ([dotBadgeFor]) and the
/// title, then a folder icon, [place] and the relative modified time on a
/// smaller second line. A longer hover shows a card with the agent and
/// the full path ([hoverCardOf]).
class SessionTile extends StatelessWidget {
  /// Creates a [SessionTile].
  const SessionTile({
    super.key,
    required this.session,
    required this.now,
    required this.onTap,
    this.place = '',
    this.selected = false,
    this.leading,
    this.trailing = const [],
    this.runLabel,
    this.agent,
    this.dense = true,
  });

  /// The session to show.
  final SessionSummary session;

  /// Where the session lives ([sessionPlace]): its workspace and, with
  /// several hosts, its host.
  final String place;

  /// "Run 2 of 3" when the session is one of several parallel runs
  /// (AV-045).
  final String? runLabel;

  /// The agent's name for the hover card ([agentDisplayName]); the
  /// provider id when null.
  final String? agent;

  /// Clock for the relative modified time.
  final DateTime now;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Whether the row is highlighted.
  final bool selected;

  /// Shown in place of the status dot (the multi-select checkbox).
  final Widget? leading;

  /// Buttons at the end of the row (pin and "Mark as done" on hover).
  final List<Widget> trailing;

  /// Whether the row is sized for pointers ([denseSessionHeight]) rather
  /// than touch ([touchSessionHeight]).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final muted = colors.mutedText;
    final modified = DateTime.tryParse(session.modifiedAt);
    final details = [
      if (place.isNotEmpty) place,
      ?runLabel,
      if (modified != null) formatRelativeTime(modified, now),
    ].join(' · ');
    final status = session.status;
    final statusLabel = [for (final badge in badgesFor(status)) badge.label]
        .join(', ');
    final card = hoverCardOf(session, agent: agent);
    final detailStyle = _detailStyle(context, dense);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.title,
          // The status follows the title for screen readers, which name
          // the row by its title first.
          semanticsLabel: '${session.title}, $statusLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _titleStyle(context, dense),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (folderKeyOf(session) != null) ...[
              Icon(AppIcons.folder, size: dense ? 12 : 14, color: muted),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: detailStyle,
              ),
            ),
          ],
        ),
      ],
    );
    final row = _TreeRow(
      depth: 1,
      height: dense ? denseSessionHeight : touchSessionHeight,
      selected: selected,
      onTap: onTap,
      leading:
          leading ??
          SessionStatusLeading(status: status, semanticLabel: statusLabel),
      title: content,
      trailing: trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: trailing),
    );
    // The card shows only for a resting pointer: touch long-presses
    // open the row menu. It wraps the whole row so it opens past the
    // row's end, clear of the hover buttons.
    return Tooltip(
      excludeFromSemantics: true,
      waitDuration: hoverCardDelay,
      triggerMode: TooltipTriggerMode.manual,
      positionDelegate: hoverCardPosition,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: colors.raisedSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.hairline),
      ),
      richMessage: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: session.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: card.heading, style: detailStyle),
          if (card.path case final path?) ...[
            const TextSpan(text: '\n'),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 6, end: 6),
                child: Icon(AppIcons.folder, size: 14, color: muted),
              ),
            ),
            TextSpan(text: 'Workspace · $path', style: detailStyle),
          ],
        ],
      ),
      child: row,
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
