/// The notifications menu in the sessions screen's app bar (AV-121).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attention_events.dart';
import 'notifications.dart';

/// Turns notifications for each [AttentionKind] on or off.
class NotificationsMenu extends ConsumerWidget {
  /// Creates a [NotificationsMenu].
  const NotificationsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final anyOn = AttentionKind.values.any(settings.enabled);
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
}
