/// Side-by-side comparison of a run group's sessions, to pick the best
/// one (best-of-N, AV-045).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../channels.dart';
import '../host_connection.dart';
import '../hosts/open_hosts.dart';
import '../notifications/notifications.dart';
import '../session_list/status_badges.dart';
import '../session_list/session_list_view.dart';
import '../session_detail/session_inputs.dart';
import '../session_detail/todo_list.dart';
import '../theme/app_theme.dart';
import 'run_group_store.dart';
import 'run_groups.dart';

/// Width of one run's column on wide layouts.
const _columnWidth = 380.0;

/// Shows run group [groupId]: each run's agent and model, status, change
/// counts and latest reply, side by side on wide screens and stacked on
/// narrow ones. "Pick" marks the winner; "Archive the others" archives
/// the runs that were not picked; "Open" shows a run in the session list.
class CompareRunsScreen extends ConsumerWidget {
  /// Creates a [CompareRunsScreen].
  const CompareRunsScreen({super.key, required this.groupId});

  /// The [RunGroup.id].
  final String groupId;

  void _archiveOthers(WidgetRef ref, RunGroup group) {
    for (final member in group.members) {
      if (member.ref == group.winner) continue;
      try {
        ref
            .read(hostConnectionProvider(member.host).notifier)
            .dispatch(
              member.session,
              const SessionIsArchivedChangedAction(isArchived: true).toJson(),
            );
      } on StateError {
        // The host is not connected; that run stays as it is.
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(
      runGroupsProvider.select(
        (groups) => groups.where((g) => g.id == groupId).firstOrNull,
      ),
    );
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare runs')),
        body: const Center(child: Text('This run group is gone.')),
      );
    }
    final sessions = {
      for (final s in ref.watch(allSessionsProvider)) s.ref: s.summary,
    };
    final columns = [
      for (final (i, member) in group.members.indexed)
        _RunColumn(
          key: ValueKey(member.ref),
          position: i + 1,
          member: member,
          summary: sessions[member.ref],
          picked: group.winner == member.ref,
          onPick: () => unawaited(
            ref
                .read(runGroupsProvider.notifier)
                .pick(group.id, group.winner == member.ref ? null : member.ref),
          ),
          onOpen: () {
            ref.read(openSessionRequestsProvider).add(member.ref);
            Navigator.of(context).pop();
          },
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare ${group.members.length} runs'),
        actions: [
          if (group.winner != null)
            TextButton.icon(
              onPressed: () => _archiveOthers(ref, group),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive the others'),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              group.prompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth >= _columnWidth * 2
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final column in columns)
                          SizedBox(
                            width:
                                constraints.maxWidth >=
                                    _columnWidth * columns.length + 16
                                ? (constraints.maxWidth - 16) / columns.length
                                : _columnWidth,
                            child: column,
                          ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final column in columns)
                          SizedBox(height: 420, child: column),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One run: header, status, counts, its latest reply (from its default
/// chat, subscribed while shown) and the Open and Pick buttons.
class _RunColumn extends StatelessWidget {
  const _RunColumn({
    super.key,
    required this.position,
    required this.member,
    required this.summary,
    required this.picked,
    required this.onPick,
    required this.onOpen,
  });

  final int position;
  final RunMember member;
  final SessionSummary? summary;
  final bool picked;
  final VoidCallback onPick;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = this.summary;
    final chat = summary?.defaultChat;
    return Card(
      margin: const EdgeInsets.all(8),
      shape: picked
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(appRadius),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Run $position · ${member.label}',
              style: theme.textTheme.titleMedium,
            ),
            if (summary == null)
              const Text('Not available (host not connected, or removed).')
            else ...[
              Text(summary.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final badge in badgesFor(summary.status))
                    StatusBadgeChip(badge: badge),
                  if (changesLabel(summary.changes) case final changes?)
                    Text(changes, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
            const Divider(),
            Expanded(
              child: chat == null
                  ? const SizedBox.shrink()
                  : HostScope(
                      host: member.host,
                      child: ChannelSubscriber(
                        channel: chat,
                        kind: ChannelKind.chat,
                        builder: (context, failed) => failed
                            ? const Text('Could not open this run.')
                            : _LatestReply(host: member.host, chat: chat),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(onPressed: onOpen, child: const Text('Open')),
                picked
                    ? FilledButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Picked'),
                      )
                    : FilledButton.tonal(
                        onPressed: summary == null ? null : onPick,
                        child: const Text('Pick this run'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The run's latest reply and todo progress, from its mirrored chat.
class _LatestReply extends ConsumerWidget {
  const _LatestReply({required this.host, required this.chat});

  final String host;
  final String chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      hostConnectionProvider(host).select((s) => s.chatChannels[chat]?.state),
    );
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final reply = lastReplyOf(state);
    final todos = latestTodoList(state);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (todos != null)
            Text(
              'Todo list · ${todos.progressLabel}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          if (reply == null)
            const Text('No reply yet.')
          else
            MarkdownBody(data: reply, selectable: true),
        ],
      ),
    );
  }
}
