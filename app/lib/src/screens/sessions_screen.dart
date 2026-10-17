/// The main screen: session list plus detail, laid out per tier (AV-003),
/// over every connected host (AV-012).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../composer/new_session_draft.dart';
import '../composer/new_session_view.dart';
import '../connection_notices.dart';
import '../desktop/desktop_window.dart';
import '../host_connection.dart';
import '../hosts/open_hosts.dart';
import '../hosts/saved_hosts.dart';
import '../layout.dart';
import '../session_detail/editable_title.dart';
import '../session_detail/session_detail_view.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/pinned_sessions.dart';
import '../session_list/pinned_store.dart';
import '../session_list/session_filter.dart';
import '../session_list/session_list_view.dart';
import '../session_list/session_query.dart';
import '../session_list/session_tree.dart';
import '../session_list/sidebar_store.dart';
import '../session_list/folder_order.dart';
import '../session_title.dart';
import '../shortcuts.dart';
import '../ssh/ssh_connect.dart';
import '../ssh/ssh_terminal_screen.dart';
import '../notifications/notification_menu.dart';
import '../notifications/notifications.dart';
import '../runs/compare_screen.dart';
import '../runs/run_group_store.dart';
import '../runs/run_groups.dart';
import '../review/changes_pane.dart';
import '../review/review_pane_store.dart';
import '../title_bar/session_history.dart';
import '../theme/app_colors.dart';
import '../title_bar/title_bar.dart';
import '../pane_resize_handle.dart';
import 'connect_screen.dart';
import 'host_storage_banner.dart';
import '../theme/app_icons.dart';

/// Full-screen session browser for the connected hosts: the sidebar
/// header (AV-092) with filters, search and sort (AV-022, AV-026,
/// AV-027) and the hosts' menu, row actions and multi-select (AV-024,
/// AV-029), and the list's keyboard shortcuts (AV-140).
class SessionsScreen extends ConsumerStatefulWidget {
  /// Creates the sessions screen.
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  SessionRef? _selected;
  SessionFilter _filter = SessionFilter.active;
  SessionSort _sort = SessionSort.recent;
  LayoutTier _tier = LayoutTier.medium;
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'session search');

  /// Whether the search field is shown (the header's search icon or
  /// Cmd/Ctrl+K); it also shows while it holds a query.
  bool _searchOpen = false;

  /// The sessions opened, for the title bar's back and forward (AV-091).
  SessionHistory _history = emptySessionHistory;

  /// The sessions picked for a bulk action; null when not selecting.
  Set<SessionRef>? _selection;

  /// The host the list is narrowed to; null shows every host.
  String? _hostFilter;

  /// The shown folders, to reveal a selected session's folder.
  List<FolderGroup> _groups = const [];

  /// The shown pinned sessions, to reveal a selected pinned session.
  List<SessionRef> _pinned = const [];

  /// The shown sessions of the "Chats" section, to reveal one.
  List<SessionRef> _chats = const [];

  /// The shown sessions in list order, for next/previous (AV-140).
  List<SessionRef> _order = const [];

  /// The session (or new-session) page pushed on compact layouts, while
  /// open.
  Route<void>? _detailRoute;

  /// The new session being drafted (AV-040), shown in the session pane
  /// while [_selected] is null and listed atop the sidebar until it
  /// starts or is discarded.
  NewSessionTarget? _draft;

  /// What was typed in drafts, by where they were opened; kept in memory.
  var _drafts = <NewSessionTarget, NewSessionDraft>{};

  StreamSubscription<AppCommand>? _commands;

  /// Sessions to open from notifications and the run comparison.
  StreamSubscription<SessionRef>? _openRequests;

  /// Actions dispatched from the list, by host, whose failures this
  /// screen reports, and the subscriptions to each host's failures.
  final _dispatched = <String, Set<int>>{};
  final _failureSubscriptions = <String, StreamSubscription<ActionFailure>>{};

  @override
  void initState() {
    super.initState();
    _commands = ref.read(appCommandsProvider).stream.listen(_onCommand);
    _openRequests = ref
        .read(openSessionRequestsProvider)
        .stream
        .listen(_openRequested);
  }

  /// Shows [session] (a clicked notification or "Open" in the run
  /// comparison), clearing a host filter that would hide it.
  void _openRequested(SessionRef session) {
    if (!mounted) return;
    if (_hostFilter != null && _hostFilter != session.host) {
      setState(() => _hostFilter = null);
    }
    _select(session);
  }

  /// Tells the notifications which session is on screen.
  void _syncVisible() {
    final visible =
        _tier == LayoutTier.compact && !(_detailRoute?.isActive ?? false)
        ? null
        : _selected;
    final notifier = ref.read(visibleSessionProvider.notifier);
    if (ref.read(visibleSessionProvider) != visible) notifier.show(visible);
  }

  Future<void> _compare(SessionRef session) async {
    final group = groupOf(ref.read(runGroupsProvider), session);
    if (group == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareRunsScreen(groupId: group.id),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_commands?.cancel());
    unawaited(_openRequests?.cancel());
    for (final subscription in _failureSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  /// A session's page on compact layouts: the session header, with a
  /// back button, is its only bar.
  Widget _detailPage(SessionRef session) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: HostScope(
        host: session.host,
        child: SessionDetailView(
          key: ValueKey(session),
          session: session.session,
          showBackButton: true,
        ),
      ),
    ),
  );

  Widget _draftView(NewSessionTarget target) => NewSessionView(
    key: ValueKey(target),
    target: target,
    draft: _drafts[target],
    onDraftChanged: (draft) => _drafts = withDraft(_drafts, target, draft),
    onStarted: (session) {
      _discardDraft(target, closePage: false);
      _select(session);
    },
  );

  /// Opens [session]; [record] adds it to the back and forward history
  /// (false when going back or forward).
  void _select(SessionRef session, {bool record = true}) {
    setState(() {
      _selected = session;
      if (record) _history = visitedSession(_history, session);
    });
    final groups = _groups;
    final pinned = _pinned;
    final chats = _chats;
    unawaited(
      ref
          .read(collapsedNodesProvider.notifier)
          .change(
            (ids) => revealSession(
              {...ids},
              groups,
              session,
              pinned: pinned,
              chats: chats,
            ),
          ),
    );
    _showPage((_) => _detailPage(session));
  }

  /// Opens the session [delta] entries away in the history (AV-091).
  void _goInHistory(int delta) {
    _history = steppedHistory(_history, delta);
    if (currentSession(_history) case final session?) {
      _select(session, record: false);
    }
  }

  /// Expands the sidebar if it is collapsed, then focuses and selects the
  /// search field (AV-027).
  Future<void> _focusSearch() async {
    if (ref.read(sidebarCollapsedProvider)) {
      await ref.read(sidebarCollapsedProvider.notifier).set(false);
    }
    if (!mounted) return;
    // The search field is built in the next frame when it was hidden.
    setState(() => _searchOpen = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _searchFocus.requestFocus();
    _search.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _search.text.length,
    );
  }

  /// Clears and hides the search field.
  void _closeSearch() => setState(() {
    _search.clear();
    _searchOpen = false;
  });

  /// Shows the draft for [target] in the session pane, or as a page on
  /// compact layouts.
  void _openDraft(NewSessionTarget target) {
    setState(() {
      _draft = target;
      _selected = null;
    });
    _showPage((_) => Scaffold(appBar: AppBar(), body: _draftView(target)));
  }

  /// Forgets the draft for [target]; pops its page on compact layouts
  /// when [closePage].
  void _discardDraft(NewSessionTarget target, {bool closePage = true}) {
    _drafts = {
      for (final MapEntry(:key, :value) in _drafts.entries)
        if (key != target) key: value,
    };
    if (_draft != target) return;
    setState(() => _draft = null);
    if (closePage && (_detailRoute?.isCurrent ?? false)) {
      Navigator.of(context).pop();
    }
  }

  /// Pushes [page] on compact layouts, replacing the open session or
  /// draft page; the other layouts show it in the pane.
  void _showPage(WidgetBuilder page) {
    if (_tier != LayoutTier.compact) return;
    final route = MaterialPageRoute<void>(builder: page);
    final navigator = Navigator.of(context);
    final previous = _detailRoute;
    _detailRoute = route;
    unawaited(
      route.popped.then((_) {
        if (_detailRoute == route) _detailRoute = null;
        if (mounted) _syncVisible();
      }),
    );
    // Next/previous on a compact layout replaces the open session.
    if (previous != null && previous.isActive) {
      navigator.replace(oldRoute: previous, newRoute: route);
    } else {
      unawaited(navigator.push(route));
    }
  }

  void _onCommand(AppCommand command) {
    if (!mounted) return;
    final detailOnTop = _detailRoute?.isCurrent ?? false;
    if (!(ModalRoute.of(context)?.isCurrent ?? false) && !detailOnTop) return;
    switch (command) {
      case AppCommand.newSession:
        _newSession();
      case AppCommand.searchSessions:
        if (detailOnTop) Navigator.of(context).pop();
        unawaited(_focusSearch());
      case AppCommand.nextSession:
        _step(1);
      case AppCommand.previousSession:
        _step(-1);
      case AppCommand.stop ||
          AppCommand.focusComposer ||
          AppCommand.previousTurn ||
          AppCommand.nextTurn ||
          AppCommand.toggleReviewPane:
        // The open session view handles these.
        break;
    }
  }

  /// Selects the session [delta] rows away from the selected one (the
  /// first or last when none is selected).
  void _step(int delta) {
    final next = steppedSession(_order, _selected, delta);
    if (next != null && next != _selected) _select(next);
  }

  /// Opens a new-session draft (AV-040) on [host] in [directory] (a
  /// folder's "+"), else on the filtered host.
  void _newSession({String? host, String? directory}) =>
      _openDraft((host: host ?? _hostFilter, directory: directory));

  Future<void> _addHost() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const ConnectScreen(addingHost: true),
    ),
  );

  /// Calls [action] with the open host whose key is [key], if any.
  void _withOpenHost(String key, Future<void> Function(SavedHost) action) {
    final host = ref
        .read(openHostsProvider)
        .where((h) => h.key == key)
        .firstOrNull;
    if (host != null) unawaited(action(host));
  }

  Future<void> _disconnect(List<HostInfo> hosts) async {
    final hostFilter = _hostFilter;
    setState(() {
      if (hostFilter == null || _selected?.host == hostFilter) {
        _selected = null;
      }
      _hostFilter = null;
    });
    final open = ref.read(openHostsProvider.notifier);
    if (hostFilter == null) {
      await open.disconnectAll();
    } else {
      await open.disconnect(hostFilter);
    }
  }

  /// Dispatches a session [action] from the list; the host's rejection is
  /// reported here unless the session is open (its view reports it).
  void _dispatchToSession(SessionRef session, JsonMap action) {
    final connection = ref.read(hostConnectionProvider(session.host).notifier);
    _failureSubscriptions[session.host] ??= connection.failures.listen((
      failure,
    ) {
      final mine = _dispatched[session.host]?.remove(failure.clientSeq);
      if (mine != true || failure.channel == _selected?.session) return;
      _showMessage(describeActionFailure(failure));
    });
    try {
      final seq = connection.dispatch(session.session, action);
      (_dispatched[session.host] ??= {}).add(seq);
    } on StateError catch (error) {
      _showMessage('Could not send that: ${error.message}');
    }
  }

  /// Archives [session] from its row's "Mark as done" button (AV-093),
  /// with Undo on a snackbar.
  void _markDone(SessionRef session) {
    _setArchived([session], true);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: const Text('Marked as done'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _setArchived([session], false),
        ),
      ),
    );
  }

  void _setArchived(Iterable<SessionRef> sessions, bool archived) {
    for (final session in sessions) {
      _dispatchToSession(
        session,
        SessionIsArchivedChangedAction(isArchived: archived).toJson(),
      );
    }
  }

  void _setRead(Iterable<SessionRef> sessions, bool read) {
    for (final session in sessions) {
      _dispatchToSession(
        session,
        SessionIsReadChangedAction(isRead: read).toJson(),
      );
    }
  }

  /// Asks for a new title and renames [session] (AV-073).
  Future<void> _rename(SessionRef session) async {
    final current = ref
        .read(allSessionsProvider)
        .where((s) => s.ref == session)
        .firstOrNull
        ?.summary
        .title;
    if (current == null) return;
    final typed = await showRenameDialog(context, current);
    if (typed == null || !mounted) return;
    if (renameAction(current, typed) case final action?) {
      _dispatchToSession(session, action);
    }
  }

  void _toggleSelected(SessionRef session) => setState(() {
    final selection = {...?_selection};
    if (!selection.remove(session)) selection.add(session);
    _selection = selection;
  });

  void _endSelection() => setState(() => _selection = null);

  @override
  Widget build(BuildContext context) {
    final hosts = ref.watch(hostInfosProvider);
    // Each host's agents, so hover cards name the agent ("Pi", not "pi").
    final agents = {
      for (final h in hosts)
        h.key: ref.watch(
          hostConnectionProvider(h.key)
              .select((s) => s.root?.agents ?? const <AgentInfo>[]),
        ),
    };
    // A host that went away clears the filter and the selection.
    if (_hostFilter case final filter?
        when !hosts.any((h) => h.key == filter)) {
      _hostFilter = null;
    }
    if (_selected case final selected?
        when !hosts.any((h) => h.key == selected.host && h.live)) {
      _selected = null;
    }
    // Only the catalogues and connection fields; chat streaming does not
    // rebuild the list.
    final sessions = ref.watch(allSessionsProvider);
    final hostFilter = _hostFilter;
    final labels = {for (final h in hosts) h.key: h.label};
    final query = parseSessionQuery(_search.text);
    final onHost = [
      for (final s in sessions)
        if (hostFilter == null || s.host == hostFilter) s,
    ];
    final shown = [
      for (final s in onHost)
        if (matchesFilter(s.summary.status, _filter) &&
            matchesQuery(s, query, hostLabel: labels[s.host]))
          s,
    ];
    final (:pinned, :rest) = splitPinned(
      ref.watch(pinnedSessionsProvider),
      shown,
    );
    final chats = chatSessions(rest, sort: _sort);
    final groups = _groups = orderFolders(
      groupHostSessions([
        for (final s in rest)
          if (folderKeyOf(s.summary) != null) s,
      ], sort: _sort),
      ref.watch(folderOrderProvider),
    );
    _pinned = [for (final s in pinned) s.ref];
    _chats = [for (final s in chats) s.ref];
    _order = [
      ..._pinned,
      ..._chats,
      for (final g in groups)
        for (final s in g.sessions) (host: g.host, session: s.resource),
    ];
    // Picked sessions that are no longer shown are dropped.
    final selection = _selection?.where(_order.contains).toSet();
    final attention = attentionCount([for (final s in onHost) s.summary]);
    final notices = [
      for (final h in hosts)
        if (compatibilityNotice(h.protocolVersion) case final notice?)
          (host: h, notice: notice),
    ];
    final reconnecting = [
      for (final h in hosts)
        if (h.status == ConnectionStatus.reconnecting) h.label,
    ];
    final selected = _selected;
    final byRef = {for (final s in sessions) s.ref: s.summary};
    final runLabels = labelsOfRuns(ref.watch(runGroupsProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncVisible();
    });
    final actions = <Widget>[
      for (final (:host, :notice) in notices)
        Tooltip(
          message: hosts.length > 1 ? '${host.label}: $notice' : notice,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 4),
                Text('AHP ${host.protocolVersion}'),
              ],
            ),
          ),
        ),
      if (reconnecting.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            hosts.length > 1
                ? 'Reconnecting ${reconnecting.join(', ')}…'
                : 'Reconnecting…',
          ),
        ),
      if (ref.watch(notifierProvider) != null) const NotificationsMenu(),
    ];
    final sidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    final history = _history;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tier = _tier = layoutTierFor(constraints.maxWidth);
          // The session keeps at least the sidebar's minimum width.
          final sidebarWidth = clampedPaneWidth(
            ref.watch(sidebarWidthProvider),
            available: constraints.maxWidth - minPaneWidth,
          );
          final list = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HostStorageBanner(),
              _SidebarHeader(
                filter: _filter,
                sort: _sort,
                attention: attention,
                onNewSession: () => _newSession(),
                onFilter: (filter) => setState(() => _filter = filter),
                onSort: (sort) => setState(() => _sort = sort),
                onSearch: () => unawaited(_focusSearch()),
                menu: _HostsMenu(
                  hosts: hosts,
                  hostFilter: hostFilter,
                  onSelect: () => setState(() => _selection = {}),
                  onAddHost: _addHost,
                  onDisconnect: () => _disconnect(hosts),
                  onShowOnly: (host) => setState(() => _hostFilter = host),
                  onRetry: (host) =>
                      ref.read(openHostsProvider.notifier).retry(host),
                  onRemove: (host) =>
                      ref.read(openHostsProvider.notifier).disconnect(host),
                  onSshTerminal: (key) => _withOpenHost(
                    key,
                    (host) => openSshTerminal(context, ref, host),
                  ),
                  onSshSettings: sshSupported
                      ? (key) => _withOpenHost(
                          key,
                          (host) => editSshSettings(context, ref, host),
                        )
                      : null,
                ),
              ),
              if (_searchOpen || _search.text.isNotEmpty)
                _SearchField(
                  controller: _search,
                  focusNode: _searchFocus,
                  onChanged: () => setState(() {}),
                  onClose: _closeSearch,
                ),
              if (selection != null)
                _SelectionBar(
                  count: selection.length,
                  allArchived:
                      selection.isNotEmpty &&
                      selection.every(
                        (s) => byRef[s]?.status.isArchivedFlag ?? false,
                      ),
                  onSelectAll: () =>
                      setState(() => _selection = _order.toSet()),
                  onArchive: (archived) {
                    _setArchived(selection, archived);
                    _endSelection();
                  },
                  onMarkRead: (read) {
                    _setRead(selection, read);
                    _endSelection();
                  },
                  onDone: _endSelection,
                ),
              if (_draft case final draft?)
                _DraftRow(
                  selected:
                      selected == null &&
                      (tier != LayoutTier.compact ||
                          (_detailRoute?.isActive ?? false)),
                  dense: tier != LayoutTier.compact,
                  onOpen: () => _openDraft(draft),
                  onDiscard: () => _discardDraft(draft),
                ),
              Expanded(
                child: SessionListView(
                  pinned: pinned,
                  chats: chats,
                  folders: groups,
                  hostLabels: hostLabelsOf(hosts),
                  agents: agents,
                  emptyText: onHost.isEmpty ? noSessionsText : noMatchText,
                  collapsed: {...ref.watch(collapsedNodesProvider)},
                  onToggle: (id) => ref
                      .read(collapsedNodesProvider.notifier)
                      .change((ids) => toggledNode({...ids}, id)),
                  onMoveFolder: (folders, from, to) => ref
                      .read(folderOrderProvider.notifier)
                      .change((order) => movedFolder(order, folders, from, to)),
                  selected: _selected,
                  onSelect: _select,
                  onNewSession: (group) =>
                      _newSession(host: group.host, directory: group.key),
                  selection: selection,
                  runLabels: runLabels,
                  dense: tier != LayoutTier.compact,
                  actions: SessionRowActions(
                    onArchive: (s, archived) => _setArchived([s], archived),
                    onMarkDone: _markDone,
                    onMarkRead: (s, read) => _setRead([s], read),
                    onSelect: _toggleSelected,
                    onPin: (s, pin) => ref
                        .read(pinnedSessionsProvider.notifier)
                        .setPinned(s, pinned: pin),
                    onCompare: _compare,
                    onRename: _rename,
                  ),
                ),
              ),
            ],
          );
          final workspace = workspaceTitle(
            selected == null ? null : byRef[selected],
          );
          return switch (tier) {
            LayoutTier.compact => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  title: Text(hostsTitle(hosts, hostFilter)),
                  actions: actions,
                ),
                Expanded(child: list),
              ],
            ),
            LayoutTier.medium || LayoutTier.wide => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: AppColors.of(context).titleBarBackground,
                  child: SafeArea(
                    bottom: false,
                    child: TitleBar(
                      title: workspace ?? hostsTitle(hosts, hostFilter),
                      isWorkspace: workspace != null,
                      searchTooltip:
                          'Search sessions '
                          '(${shortcutLabel(AppCommand.searchSessions)})',
                      onSearch: () => unawaited(_focusSearch()),
                      sidebarCollapsed: sidebarCollapsed,
                      onToggleSidebar: () => unawaited(
                        ref.read(sidebarCollapsedProvider.notifier).toggle(),
                      ),
                      onBack: canGoBack(history)
                          ? () => _goInHistory(-1)
                          : null,
                      onForward: canGoForward(history)
                          ? () => _goInHistory(1)
                          : null,
                      leadingInset: drawsInWindowTitleBar
                          ? trafficLightsWidth
                          : 0,
                      draggable: drawsInWindowTitleBar,
                      actions: [
                        if (tier == LayoutTier.wide)
                          ReviewPaneToggle(
                            open: ref.watch(reviewPaneOpenProvider),
                            changes: byRef[selected]?.changes,
                            onToggle: () => unawaited(
                              ref
                                  .read(reviewPaneOpenProvider.notifier)
                                  .toggle(),
                            ),
                          ),
                        ...actions,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          if (!sidebarCollapsed) ...[
                            SizedBox(
                              width: sidebarWidth,
                              child: Material(
                                color: AppColors.of(context).sidebarBackground,
                                child: list,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                          ],
                          Expanded(
                            child: selected == null
                                ? switch (_draft) {
                                    final draft? => _draftView(draft),
                                    null => const Center(
                                      child: Text('Select a session'),
                                    ),
                                  }
                                : HostScope(
                                    host: selected.host,
                                    child: SessionDetailView(
                                      key: ValueKey(selected),
                                      session: selected.session,
                                      reviewAsPane: tier == LayoutTier.wide,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      // Over the divider, half on each side of it.
                      if (!sidebarCollapsed)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: sidebarWidth - paneResizeHandleWidth / 2,
                          child: PaneResizeHandle(
                            label: 'Resize sidebar',
                            onDrag: (dx) => ref
                                .read(sidebarWidthProvider.notifier)
                                .resize(dx),
                            onDragEnd: () => unawaited(
                              ref.read(sidebarWidthProvider.notifier).save(),
                            ),
                            onReset: () => unawaited(
                              ref.read(sidebarWidthProvider.notifier).reset(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

/// The session [delta] places from [current] in [order]: the first (or,
/// going back, the last) when [current] is not in it, clamped at the
/// ends; null when [order] is empty.
SessionRef? steppedSession(
  List<SessionRef> order,
  SessionRef? current,
  int delta,
) {
  if (order.isEmpty) return null;
  final index = current == null ? -1 : order.indexOf(current);
  if (index < 0) return delta >= 0 ? order.first : order.last;
  return order[(index + delta).clamp(0, order.length - 1)];
}

/// The sidebar's header (AV-092): "Sessions", the "New" button, the
/// filter and sort menu (AV-022, AV-026; "Needs attention" carries the
/// attention count, AV-120), the search icon (AV-027) and [menu].
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.filter,
    required this.sort,
    required this.attention,
    required this.onNewSession,
    required this.onFilter,
    required this.onSort,
    required this.onSearch,
    required this.menu,
  });

  /// The chosen filter, checked in the menu.
  final SessionFilter filter;

  /// The chosen sort, checked in the menu.
  final SessionSort sort;

  /// Number of sessions that need attention.
  final int attention;

  /// Opens a new-session draft.
  final VoidCallback onNewSession;

  /// Picks a filter.
  final ValueChanged<SessionFilter> onFilter;

  /// Picks a sort.
  final ValueChanged<SessionSort> onSort;

  /// Shows the search field.
  final VoidCallback onSearch;

  /// The "…" menu ([_HostsMenu]).
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const compact = VisualDensity(horizontal: -4, vertical: -4);
    // Small icon buttons, as in the reference, so the header fits the
    // narrowest sidebar (minPaneWidth).
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: (theme.iconButtonTheme.style ?? const ButtonStyle()).merge(
          IconButton.styleFrom(
            minimumSize: const Size(30, 30),
            padding: const EdgeInsets.all(6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => _row(
          context,
          compact: compact,
          // The key cap is left out of a narrow sidebar; the tooltip
          // still names the shortcut.
          showShortcut: constraints.maxWidth >= 300,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required VisualDensity compact,
    required bool showShortcut,
  }) {
    final theme = Theme.of(context);
    final muted = AppColors.of(context).mutedText;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sessions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Tooltip(
            message: 'New session (${shortcutLabel(AppCommand.newSession)})',
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onNewSession,
              // Named "New session" for screen readers rather than by its
              // short visible text and shortcut.
              child: Semantics(
                label: 'New session',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                    // The shortcut as a key cap, as in the reference.
                    if (showShortcut) ...[
                      const SizedBox(width: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.of(context).bubbleFill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          child: Text(
                            shortcutLabel(AppCommand.newSession),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<Object>(
            tooltip: 'Filter and sort',
            icon: Icon(
              filter == SessionFilter.active
                  ? AppIcons.filter
                  : AppIcons.filterActive,
              size: 18,
            ),
            onSelected: (choice) => switch (choice) {
              final SessionFilter f => onFilter(f),
              final SessionSort s => onSort(s),
              _ => null,
            },
            itemBuilder: (_) => [
              for (final f in SessionFilter.values)
                CheckedPopupMenuItem<Object>(
                  value: f,
                  checked: f == filter,
                  child: Text(
                    f == SessionFilter.attention && attention > 0
                        ? '${f.label} ($attention)'
                        : f.label,
                  ),
                ),
              const PopupMenuDivider(),
              for (final s in SessionSort.values)
                CheckedPopupMenuItem<Object>(
                  value: s,
                  checked: s == sort,
                  child: Text(s.label),
                ),
            ],
          ),
          IconButton(
            tooltip:
                'Search sessions (${shortcutLabel(AppCommand.searchSessions)})',
            icon: const Icon(AppIcons.search, size: 18),
            onPressed: onSearch,
          ),
          menu,
        ],
      ),
    );
  }
}

/// The sidebar header's "…" menu (AV-092): "Select" (AV-029), "Add
/// host…", "Disconnect", and a submenu per open host with its status
/// (AV-011), "Show only this host" with several hosts, Retry and Remove
/// for a host that is not connected, and the SSH terminal (AV-014). The
/// icon has a dot while a host is not connected.
class _HostsMenu extends StatelessWidget {
  const _HostsMenu({
    required this.hosts,
    required this.hostFilter,
    required this.onSelect,
    required this.onAddHost,
    required this.onDisconnect,
    required this.onShowOnly,
    required this.onRetry,
    required this.onRemove,
    required this.onSshTerminal,
    this.onSshSettings,
  });

  /// The open hosts.
  final List<HostInfo> hosts;

  /// The host the list is narrowed to; null for every host.
  final String? hostFilter;

  /// Starts multi-select.
  final VoidCallback onSelect;

  /// Opens the page that connects another host.
  final VoidCallback onAddHost;

  /// Disconnects [hostFilter], or every host when it is null.
  final VoidCallback onDisconnect;

  /// Narrows the list to a host, or to every host (null).
  final ValueChanged<String?> onShowOnly;

  /// Connects a failed host again, by key.
  final ValueChanged<String> onRetry;

  /// Closes a host that is not connected, by key.
  final ValueChanged<String> onRemove;

  /// Opens an SSH terminal to a host, by key.
  final ValueChanged<String> onSshTerminal;

  /// Edits a host's SSH settings, by key; no item when null.
  final ValueChanged<String>? onSshSettings;

  Widget _hostMenu(BuildContext context, HostInfo host) {
    final status = AppColors.of(context).statusColors;
    final idle =
        host.status == ConnectionStatus.failed ||
        host.status == ConnectionStatus.disconnected;
    final onSshSettings = this.onSshSettings;
    return SubmenuButton(
      leadingIcon: Icon(
        Icons.circle,
        size: 10,
        color: switch (host.status) {
          ConnectionStatus.connected => status.done,
          ConnectionStatus.failed => status.error,
          _ => status.idle,
        },
      ),
      menuChildren: [
        if (hosts.length > 1)
          CheckboxMenuButton(
            value: hostFilter == host.key,
            onChanged: (_) =>
                onShowOnly(hostFilter == host.key ? null : host.key),
            child: const Text('Show only this host'),
          ),
        if (idle) ...[
          MenuItemButton(
            leadingIcon: const Icon(Icons.refresh),
            onPressed: () => onRetry(host.key),
            child: Text('Retry ${host.label}'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.close),
            onPressed: () => onRemove(host.key),
            child: Text('Remove ${host.label}'),
          ),
        ],
        MenuItemButton(
          leadingIcon: const Icon(Icons.terminal),
          onPressed: () => onSshTerminal(host.key),
          child: const Text(openSshTerminalLabel),
        ),
        if (onSshSettings != null)
          MenuItemButton(
            onPressed: () => onSshSettings(host.key),
            child: const Text('SSH settings…'),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(
          '${host.label} · ${hostStatusText(host)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notConnected = hosts.any((h) => h.status == ConnectionStatus.failed);
    final narrowed = hosts.where((h) => h.key == hostFilter).firstOrNull;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.checklist),
          onPressed: onSelect,
          child: const Text('Select'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add_link),
          onPressed: onAddHost,
          child: const Text('Add host…'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout),
          onPressed: onDisconnect,
          child: Text(
            narrowed == null || hosts.length == 1
                ? 'Disconnect'
                : 'Disconnect ${narrowed.label}',
          ),
        ),
        if (hosts.isNotEmpty) const Divider(height: 8),
        for (final host in hosts) _hostMenu(context, host),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: notConnected
            ? 'More actions (a host is not connected)'
            : 'More actions',
        icon: Badge(
          isLabelVisible: notConnected,
          smallSize: 6,
          child: const Icon(AppIcons.more, size: 18),
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// The search field (AV-027), shown by the header's search icon and
/// Cmd/Ctrl+K; Escape or its close button clears and hides it.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  /// The query.
  final TextEditingController controller;

  /// Focused when the field opens.
  final FocusNode focusNode;

  /// Called when the query changes.
  final VoidCallback onChanged;

  /// Clears and hides the field.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
    child: CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(AppIcons.search, size: 18),
          hintText:
              'Search (${shortcutLabel(AppCommand.searchSessions)}); '
              'agent: status: repo: host:',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Close search',
            icon: const Icon(AppIcons.close, size: 18),
            onPressed: onClose,
          ),
        ),
      ),
    ),
  );
}

/// Bulk actions on the picked sessions (AV-029), under the sidebar header
/// while selecting.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.allArchived,
    required this.onSelectAll,
    required this.onArchive,
    required this.onMarkRead,
    required this.onDone,
  });

  final int count;

  /// Whether every picked session is archived (then the bar unarchives).
  final bool allArchived;
  final VoidCallback onSelectAll;
  final ValueChanged<bool> onArchive;
  final ValueChanged<bool> onMarkRead;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
    child: Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$count selected'),
        TextButton(onPressed: onSelectAll, child: const Text('Select all')),
        TextButton(
          onPressed: count == 0 ? null : () => onArchive(!allArchived),
          child: Text(allArchived ? 'Unarchive' : 'Archive'),
        ),
        TextButton(
          onPressed: count == 0 ? null : () => onMarkRead(true),
          child: const Text('Mark read'),
        ),
        TextButton(
          onPressed: count == 0 ? null : () => onMarkRead(false),
          child: const Text('Mark unread'),
        ),
        IconButton(
          tooltip: 'Done selecting',
          icon: const Icon(AppIcons.close),
          onPressed: onDone,
        ),
      ],
    ),
  );
}

/// The new-session draft atop the session list (AV-040): selected while
/// the session pane shows it; it reopens the draft or discards it.
class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.selected,
    required this.dense,
    required this.onOpen,
    required this.onDiscard,
  });

  /// Whether the session pane shows the draft.
  final bool selected;

  /// Thin rows for desktop layouts.
  final bool dense;

  /// Shows the draft.
  final VoidCallback onOpen;

  /// Forgets the draft and what was typed in it.
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) => ListTile(
    key: const ValueKey('new-session-draft'),
    dense: dense,
    selected: selected,
    leading: const Icon(Icons.edit_note),
    title: const Text(newSessionTitle),
    subtitle: const Text('Draft'),
    onTap: onOpen,
    trailing: IconButton(
      tooltip: 'Discard the draft',
      icon: const Icon(AppIcons.close),
      onPressed: onDiscard,
    ),
  );
}
