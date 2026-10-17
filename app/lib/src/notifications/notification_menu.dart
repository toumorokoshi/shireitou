/// The notifications menu in the sessions screen's app bar (AV-121).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attention_events.dart';
import 'notifications.dart';

/// Turns notifications for each [AttentionKind] on or off, and asks for
/// permission again when it was not granted.
class NotificationsMenu extends ConsumerWidget {
  /// Creates a [NotificationsMenu].
  const NotificationsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final blocked = ref.watch(notificationPermissionProvider) == false;
    final anyOn = !blocked && AttentionKind.values.any(settings.enabled);
    return PopupMenuButton<AttentionKind>(
      tooltip: 'Notifications',
      icon: Icon(
        anyOn
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      onSelected: (kind) => unawaited(
        ref
            .read(notificationSettingsProvider.notifier)
            .set(kind, on: !settings.enabled(kind)),
      ),
      itemBuilder: (_) => [
        if (blocked)
          PopupMenuItem<AttentionKind>(
            onTap: () => unawaited(_allow(context, ref)),
            child: const Text('Allow notifications…'),
          ),
        const PopupMenuItem<AttentionKind>(
          enabled: false,
          child: Text('Notify me when a session…'),
        ),
        for (final kind in AttentionKind.values)
          CheckedPopupMenuItem(
            value: kind,
            checked: settings.enabled(kind),
            child: Text(switch (kind) {
              AttentionKind.needsInput => 'needs my input',
              AttentionKind.finished => 'finishes its turn',
              AttentionKind.failed => 'fails',
            }),
          ),
      ],
    );
  }

  /// Asks for permission again (a user gesture, which browsers require),
  /// and says where to allow notifications when the answer is still no.
  Future<void> _allow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (await ref.read(notificationPermissionProvider.notifier).request()) {
      return;
    }
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are blocked. Allow them for shireitou in the '
          "system's notification settings (or the browser's site settings).",
        ),
      ),
    );
  }
}
