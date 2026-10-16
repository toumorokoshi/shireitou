/// The main screen: session list plus detail, laid out per tier (AV-003),
/// over every connected host (AV-012).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection_notices.dart';
import '../host_connection.dart';
import '../hosts/open_hosts.dart';
import '../layout.dart';
import '../session_detail/session_detail_view.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/session_filter.dart';
import '../session_list/session_list_view.dart';
import 'connect_screen.dart';
import 'host_storage_banner.dart';
import 'new_session_screen.dart';

/// Width of the session list pane on medium and wide layouts.
const _listPaneWidth = 380.0;

/// Full-screen session browser for the connected hosts.
class SessionsScreen extends ConsumerStatefulWidget {
  /// Creates the sessions screen.
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  SessionRef? _selected;
  SessionFilter _filter = SessionFilter.active;
  LayoutTier _tier = LayoutTier.medium;

  /// The host the list is narrowed to; null shows every host.
  String? _hostFilter;

  void _select(SessionRef session) {
    setState(() => _selected = session);
    if (_tier != LayoutTier.compact) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: HostScope(
            host: session.host,
            child: SessionDetailView(
              key: ValueKey(session),
              session: session.session,
            ),
          ),
        ),
      ),
    );
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
    final shown = [
      for (final s in sessions)
        if ((hostFilter == null || s.host == hostFilter) &&
            matchesFilter(s.summary.status, _filter))
          s,
    ];
    final groups = groupHostSessions(shown);
    final labels = {for (final h in hosts) h.key: h.label};
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
    return Scaffold(
      appBar: AppBar(
        title: HostSwitcher(
          hosts: hosts,
          selected: hostFilter,
          onSelect: (host) => setState(() => _hostFilter = host),
          onAddHost: _addHost,
        ),
        actions: [
          IconButton(
            tooltip: 'New session',
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
              _FilterBar(
                filter: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
              Expanded(
                child: SessionListView(
                  groups: groups,
                  selected: _selected,
                  onSelect: _select,
                  hostLabels: hostFilter == null ? labels : const {},
                  onNewSession: (group) =>
                      _newSession(host: group.host, directory: group.key),
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

/// The host switcher in the title (AV-010, AV-012): shows which host the
/// list is narrowed to (or "All hosts"), each host's connection status
/// and error, and adds hosts.
class HostSwitcher extends StatelessWidget {
  /// Creates a [HostSwitcher].
  const HostSwitcher({
    super.key,
    required this.hosts,
    required this.selected,
    required this.onSelect,
    required this.onAddHost,
  });

  /// The open hosts.
  final List<HostInfo> hosts;

  /// The host the list shows, or null for all.
  final String? selected;

  /// Narrows the list to a host (null for all).
  final ValueChanged<String?> onSelect;

  /// Opens the page that connects another host.
  final VoidCallback onAddHost;

  static String _status(HostInfo host) => switch (host.status) {
    ConnectionStatus.connected => 'Connected',
    ConnectionStatus.reconnecting => 'Reconnecting…',
    ConnectionStatus.connecting => 'Connecting…',
    ConnectionStatus.failed => host.error ?? 'Failed',
    ConnectionStatus.disconnected => 'Disconnected',
  };

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
    return PopupMenuButton<String?>(
      tooltip: 'Switch host',
      onSelected: (key) => key == _addHostValue ? onAddHost() : onSelect(key),
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
              subtitle: Text(_status(host)),
            ),
          ),
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

/// Filter chips above the session list (AV-022).
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final SessionFilter filter;
  final ValueChanged<SessionFilter> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final f in SessionFilter.values)
          ChoiceChip(
            label: Text(f.label),
            selected: f == filter,
            onSelected: (_) => onChanged(f),
          ),
      ],
    ),
  );
}
