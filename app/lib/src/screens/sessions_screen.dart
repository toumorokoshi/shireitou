/// The main screen: session list plus detail, laid out per tier (AV-003),
/// over every connected host (AV-012).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection_notices.dart';
import '../host_connection.dart';
import '../hosts/open_hosts.dart';
import '../layout.dart';
import '../session_detail/session_detail_view.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/pinned_store.dart';
import '../session_list/session_filter.dart';
import '../session_list/session_list_view.dart';
import '../session_list/session_query.dart';
import '../shortcuts.dart';
import '../notifications/notification_menu.dart';
import '../notifications/notifications.dart';
import '../runs/compare_screen.dart';
import '../runs/run_group_store.dart';
import '../runs/run_groups.dart';
import 'connect_screen.dart';
import 'host_storage_banner.dart';
import 'new_session_screen.dart';

/// Width of the session list pane on medium and wide layouts.
const _listPaneWidth = 380.0;

/// Full-screen session browser for the connected hosts: filters, search
/// and sort (AV-022, AV-026, AV-027), row actions and multi-select
/// (AV-024, AV-029), and the list's keyboard shortcuts (AV-140).
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

  /// The sessions picked for a bulk action; null when not selecting.
  Set<SessionRef>? _selection;

  /// The host the list is narrowed to; null shows every host.
  String? _hostFilter;

  /// The shown sessions in list order, for next/previous (AV-140).
  List<SessionRef> _order = const [];

  /// The session page pushed on compact layouts, while open.
  Route<void>? _detailRoute;

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

  Widget _detailPage(SessionRef session) => Scaffold(
    appBar: AppBar(),
    body: HostScope(
      host: session.host,
      child: SessionDetailView(
        key: ValueKey(session),
        session: session.session,
      ),
    ),
  );

  void _select(SessionRef session) {
    setState(() => _selected = session);
    if (_tier != LayoutTier.compact) return;
    final route = MaterialPageRoute<void>(builder: (_) => _detailPage(session));
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
        unawaited(_newSession());
      case AppCommand.searchSessions:
        if (detailOnTop) Navigator.of(context).pop();
        _searchFocus.requestFocus();
        _search.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _search.text.length,
        );
      case AppCommand.nextSession:
        _step(1);
      case AppCommand.previousSession:
        _step(-1);
      case AppCommand.stop || AppCommand.focusComposer:
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

  Future<void> _newSession({String? host, String? directory}) async {
    final session = await Navigator.of(context).push(
      MaterialPageRoute<SessionRef>(
        builder: (_) => NewSessionScreen(
          initialHost: host ?? _hostFilter,
          initialDirectory: directory,
        ),
      ),
    );
    if (session != null && mounted) _select(session);
  }

  Future<void> _addHost() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const ConnectScreen(addingHost: true),
    ),
  );

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

  void _toggleSelected(SessionRef session) => setState(() {
    final selection = {...?_selection};
    if (!selection.remove(session)) selection.add(session);
    _selection = selection;
  });

  void _endSelection() => setState(() => _selection = null);

  @override
  Widget build(BuildContext context) {
    final hosts = ref.watch(hostInfosProvider);
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
    final pinned = ref.watch(pinnedSessionsProvider);
    final groups = groupHostSessions(shown, sort: _sort, pinned: pinned);
    _order = [
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
    return Scaffold(
      appBar: AppBar(
        title: HostSwitcher(
          hosts: hosts,
          selected: hostFilter,
          onSelect: (host) => setState(() => _hostFilter = host),
          onAddHost: _addHost,
          onRetry: (host) => ref.read(openHostsProvider.notifier).retry(host),
          onRemove: (host) =>
              ref.read(openHostsProvider.notifier).disconnect(host),
        ),
        actions: [
          IconButton(
            tooltip: 'New session (${shortcutLabel(AppCommand.newSession)})',
            icon: const Icon(Icons.add),
            onPressed: _newSession,
          ),
          for (final (:host, :notice) in notices)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: hosts.length > 1 ? '${host.label}: $notice' : notice,
                child: Chip(
                  avatar: const Icon(Icons.info_outline, size: 18),
                  label: Text('AHP ${host.protocolVersion}'),
                ),
              ),
            ),
          if (reconnecting.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                label: Text(
                  hosts.length > 1
                      ? 'Reconnecting ${reconnecting.join(', ')}…'
                      : 'Reconnecting…',
                ),
              ),
            ),
          if (localNotificationsSupported) const NotificationsMenu(),
          IconButton(
            tooltip: hostFilter == null || hosts.length == 1
                ? 'Disconnect'
                : 'Disconnect ${labels[hostFilter]}',
            icon: const Icon(Icons.logout),
            onPressed: () => _disconnect(hosts),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tier = _tier = layoutTierFor(constraints.maxWidth);
          final list = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HostStorageBanner(),
              _SearchBar(
                controller: _search,
                focusNode: _searchFocus,
                sort: _sort,
                onChanged: () => setState(() {}),
                onSort: (sort) => setState(() => _sort = sort),
              ),
              if (selection == null)
                _FilterBar(
                  filter: _filter,
                  attention: attention,
                  onChanged: (filter) => setState(() => _filter = filter),
                )
              else
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
              Expanded(
                child: SessionListView(
                  groups: groups,
                  selected: _selected,
                  onSelect: _select,
                  hostLabels: hostFilter == null ? labels : const {},
                  onNewSession: (group) =>
                      _newSession(host: group.host, directory: group.key),
                  selection: selection,
                  runLabels: runLabels,
                  pinned: pinned,
                  emptyText: onHost.isEmpty
                      ? 'No sessions on this host yet.'
                      : 'No sessions match.',
                  actions: SessionRowActions(
                    onArchive: (s, archived) => _setArchived([s], archived),
                    onMarkRead: (s, read) => _setRead([s], read),
                    onSelect: _toggleSelected,
                    onPin: (s, pin) => ref
                        .read(pinnedSessionsProvider.notifier)
                        .setPinned(s, pinned: pin),
                    onCompare: _compare,
                  ),
                ),
              ),
            ],
          );
          return switch (tier) {
            LayoutTier.compact => list,
            LayoutTier.medium || LayoutTier.wide => Row(
              children: [
                SizedBox(width: _listPaneWidth, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? const Center(child: Text('Select a session'))
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

/// The host switcher in the title (AV-010 to AV-012): shows which host
/// the list is narrowed to (or "All hosts"), each host's connection
/// status and error, retries or removes a host that is not connected,
/// and adds hosts.
class HostSwitcher extends StatelessWidget {
  /// Creates a [HostSwitcher].
  const HostSwitcher({
    super.key,
    required this.hosts,
    required this.selected,
    required this.onSelect,
    required this.onAddHost,
    this.onRetry,
    this.onRemove,
  });

  /// The open hosts.
  final List<HostInfo> hosts;

  /// The host the list shows, or null for all.
  final String? selected;

  /// Narrows the list to a host (null for all).
  final ValueChanged<String?> onSelect;

  /// Opens the page that connects another host.
  final VoidCallback onAddHost;

  /// Connects a failed host again, by key.
  final ValueChanged<String>? onRetry;

  /// Closes a host that is not connected, by key.
  final ValueChanged<String>? onRemove;

  static Widget _dot(BuildContext context, HostInfo host) {
    final scheme = Theme.of(context).colorScheme;
    return Icon(
      Icons.circle,
      size: 10,
      color: switch (host.status) {
        ConnectionStatus.connected => Colors.green,
        ConnectionStatus.failed => scheme.error,
        _ => scheme.outline,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = hosts.where((h) => h.key == selected).firstOrNull;
    final title = switch ((current, hosts.length)) {
      (final host?, _) => host.label,
      (null, 1) => hosts.single.label,
      (null, 0) => 'shireitou',
      _ => 'All hosts',
    };
    final idle = [
      for (final h in hosts)
        if (h.status == ConnectionStatus.failed ||
            h.status == ConnectionStatus.disconnected)
          h,
    ];
    return PopupMenuButton<String?>(
      tooltip: 'Switch host',
      onSelected: (key) => switch (key) {
        _addHostValue => onAddHost(),
        final String k when k.startsWith(_retryPrefix) => onRetry?.call(
          k.substring(_retryPrefix.length),
        ),
        final String k when k.startsWith(_removePrefix) => onRemove?.call(
          k.substring(_removePrefix.length),
        ),
        _ => onSelect(key),
      },
      itemBuilder: (context) => [
        if (hosts.length > 1)
          CheckedPopupMenuItem(
            value: null,
            checked: selected == null,
            child: Text('All hosts (${hosts.length})'),
          ),
        for (final host in hosts)
          CheckedPopupMenuItem(
            value: host.key,
            checked: selected == host.key,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _dot(context, host),
              title: Text(host.label),
              subtitle: Text(hostStatusText(host)),
            ),
          ),
        for (final host in idle) ...[
          if (onRetry != null)
            PopupMenuItem(
              value: '$_retryPrefix${host.key}',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.refresh),
                title: Text('Retry ${host.label}'),
              ),
            ),
          if (onRemove != null)
            PopupMenuItem(
              value: '$_removePrefix${host.key}',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.close),
                title: Text('Remove ${host.label}'),
              ),
            ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _addHostValue,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.add_link),
            title: Text('Add host…'),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

/// The [HostSwitcher] menu value that adds a host (never a host key,
/// which is a ws:// URL).
const _addHostValue = '#add-host';

/// Prefixes of the [HostSwitcher] menu values that retry or remove a
/// host (followed by its key).
const _retryPrefix = '#retry:';
const _removePrefix = '#remove:';

/// Filter chips above the session list (AV-022); "Needs attention"
/// carries the attention count (AV-120).
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.attention,
    required this.onChanged,
  });

  final SessionFilter filter;
  final int attention;
  final ValueChanged<SessionFilter> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final f in SessionFilter.values)
          ChoiceChip(
            label: Text(
              f == SessionFilter.attention && attention > 0
                  ? '${f.label} ($attention)'
                  : f.label,
            ),
            selected: f == filter,
            onSelected: (_) => onChanged(f),
          ),
      ],
    ),
  );
}

/// The search field (AV-027, focused by Cmd/Ctrl+K) and the sort menu
/// (AV-026).
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.sort,
    required this.onChanged,
    required this.onSort,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SessionSort sort;
  final VoidCallback onChanged;
  final ValueChanged<SessionSort> onSort;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText:
                  'Search (${shortcutLabel(AppCommand.searchSessions)}); '
                  'agent: status: repo: host:',
              border: const OutlineInputBorder(),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onChanged();
                      },
                    ),
            ),
          ),
        ),
        PopupMenuButton<SessionSort>(
          tooltip: 'Sort: ${sort.label}',
          icon: const Icon(Icons.sort),
          initialValue: sort,
          onSelected: onSort,
          itemBuilder: (_) => [
            for (final s in SessionSort.values)
              CheckedPopupMenuItem(
                value: s,
                checked: s == sort,
                child: Text(s.label),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Bulk actions on the picked sessions (AV-029), in place of the filter
/// chips while selecting.
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
          icon: const Icon(Icons.close),
          onPressed: onDone,
        ),
      ],
    ),
  );
}
