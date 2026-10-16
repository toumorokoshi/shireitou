/// The main screen: session list plus detail, laid out per tier (AV-003).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import '../layout.dart';
import '../session_list/folder_grouping.dart';
import '../session_list/session_list_view.dart';
import 'session_detail_placeholder.dart';

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

  void _select(BuildContext context, String uri, LayoutTier tier) {
    setState(() => _selected = uri);
    if (tier != LayoutTier.compact) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Consumer(
          builder: (context, ref, _) {
            final session = ref.watch(
              hostConnectionProvider.select((s) => s.sessions[uri]),
            );
            return Scaffold(
              appBar: AppBar(title: Text(session?.title ?? 'Session')),
              body: SessionDetailPlaceholder(session: session),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(hostConnectionProvider);
    final groups = groupSessionsByFolder(host.sessions.values);
    final selected = host.sessions[_selected];
    return Scaffold(
      appBar: AppBar(
        title: Text(host.serverInfo?.name ?? 'shireitou'),
        actions: [
          if (host.status == ConnectionStatus.reconnecting)
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
          final tier = layoutTierFor(constraints.maxWidth);
          final list = SessionListView(
            groups: groups,
            selected: _selected,
            onSelect: (uri) => _select(context, uri, tier),
          );
          return switch (tier) {
            LayoutTier.compact => list,
            LayoutTier.medium || LayoutTier.wide => Row(
              children: [
                SizedBox(width: _listPaneWidth, child: list),
                const VerticalDivider(width: 1),
                Expanded(child: SessionDetailPlaceholder(session: selected)),
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
