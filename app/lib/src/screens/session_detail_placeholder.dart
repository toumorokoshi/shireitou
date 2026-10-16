/// Placeholder for the session timeline (AV-060 onward, not built yet).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../session_list/folder_grouping.dart';
import '../session_list/session_list_view.dart';
import '../session_list/status_badges.dart';

/// Shows a session's header fields until the timeline exists.
class SessionDetailPlaceholder extends StatelessWidget {
  /// Creates a [SessionDetailPlaceholder].
  const SessionDetailPlaceholder({super.key, required this.session});

  /// The selected session, or null when none is selected.
  final SessionSummary? session;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    if (session == null) {
      return const Center(child: Text('Select a session'));
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(session.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: [
            for (final badge in badgesFor(session.status))
              StatusBadgeChip(badge: badge),
          ],
        ),
        const SizedBox(height: 16),
        Text('Agent: ${session.provider}'),
        Text('Folder: ${folderKeyOf(session) ?? noFolderLabel}'),
        if (session.activity != null) Text('Activity: ${session.activity}'),
        const SizedBox(height: 24),
        Text(
          'The session timeline is not implemented yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
