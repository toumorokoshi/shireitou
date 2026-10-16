/// The main screen: session list plus detail, laid out per tier (AV-003).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection_notices.dart';
import '../host_connection.dart';
import '../layout.dart';
import '../session_detail/session_detail_view.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/session_filter.dart';
import '../session_list/session_list_view.dart';
import 'new_session_screen.dart';

/// Width of the session list pane on medium and wide layouts.
const _listPaneWidth = 380.0;

/// Width of the review pane on wide layouts.
const _reviewPaneWidth = 360.0;

/// Full-screen session browser for the connected host.
class SessionsScreen extends ConsumerStatefulWidget {
  /// Creates the sessions screen.
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  String? _selected;
  SessionFilter _filter = SessionFilter.active;
  LayoutTier _tier = LayoutTier.medium;

  void _select(String uri) {
    setState(() => _selected = uri);
    if (_tier != LayoutTier.compact) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: SessionDetailView(key: ValueKey(uri), session: uri),
        ),
      ),
    );
  }

  Future<void> _newSession() async {
    final session = await Navigator.of(
      context,
    ).push(MaterialPageRoute<String>(builder: (_) => const NewSessionScreen()));
    if (session != null && mounted) _select(session);
  }

  @override
  Widget build(BuildContext context) {
    // Only the catalogue and connection fields; chat streaming does not
    // rebuild the list.
    final sessions = ref.watch(
      hostConnectionProvider.select((s) => s.sessions),
    );
    final status = ref.watch(hostConnectionProvider.select((s) => s.status));
    final serverName = ref.watch(
      hostConnectionProvider.select((s) => s.serverInfo?.name),
    );
    final version = ref.watch(
      hostConnectionProvider.select((s) => s.protocolVersion),
    );
    final notice = compatibilityNotice(version);
    final groups = groupSessionsByFolder(
      filterSessions(sessions.values, _filter),
    );
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        title: Text(serverName ?? 'shireitou'),
        actions: [
          IconButton(
            tooltip: 'New session',
            icon: const Icon(Icons.add),
            onPressed: _newSession,
          ),
          if (notice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: notice,
                child: Chip(
                  avatar: const Icon(Icons.info_outline, size: 18),
                  label: Text('AHP $version'),
                ),
              ),
            ),
          if (status == ConnectionStatus.reconnecting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Chip(label: Text('Reconnecting…')),
            ),
          IconButton(
            tooltip: 'Disconnect',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(hostConnectionProvider.notifier).disconnect(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tier = _tier = layoutTierFor(constraints.maxWidth);
          final list = Column(
            children: [
              _FilterBar(
                filter: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
              Expanded(
                child: SessionListView(
                  groups: groups,
                  selected: _selected,
                  onSelect: _select,
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
                      : SessionDetailView(
                          key: ValueKey(selected),
                          session: selected,
                        ),
                ),
                if (tier == LayoutTier.wide) ...[
                  const VerticalDivider(width: 1),
                  const SizedBox(
                    width: _reviewPaneWidth,
                    child: Center(child: Text('Changes (not implemented)')),
                  ),
                ],
              ],
            ),
          };
        },
      ),
    );
  }
}

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
