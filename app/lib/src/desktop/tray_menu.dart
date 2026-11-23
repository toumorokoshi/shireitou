/// System tray icon and dropdown widget that tracks active and pinned
/// conversations across connected hosts.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/open_hosts.dart';
import '../notifications/notifications.dart';
import '../session_list/pinned_store.dart';
import '../session_list/session_filter.dart';
import '../session_list/session_tree.dart';
import '../theme/app_colors.dart';
import 'desktop_window.dart';
import 'tray_backend.dart';
import 'tray_menu_items.dart';

/// The active [TrayBackend], or null on platforms without a system tray.
/// Tests can override this provider to inspect menu updates.
final trayBackendProvider = Provider<TrayBackend?>((ref) {
  final backend = createTrayBackend();
  if (backend != null) ref.onDispose(backend.dispose);
  return backend;
});

/// Keeps the system tray icon's dropdown menu synced with active and
/// pinned conversations while mounted.
class TrayMenu extends ConsumerWidget {
  /// Creates a [TrayMenu] around [child].
  const TrayMenu({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(trayBackendProvider);
    if (backend == null) return child;

    final sessions = ref.watch(allSessionsProvider);
    final pins = ref.watch(pinnedSessionsProvider);
    final hosts = ref.watch(hostInfosProvider);
    final attention = ref.watch(attentionCountProvider);
    final colors = AppColors.of(context);
    final unreadColor = Theme.of(context).colorScheme.onSurface;

    final model = buildTrayMenuModel(
      sessions: sessions,
      pins: pins,
      hostLabels: hostLabelsOf(hosts),
      attentionCount: attention,
      statusColors: colors.statusColors,
      unreadColor: unreadColor,
    );

    backend.update(
      model,
      onSelectSession: (session) {
        unawaited(bringWindowToFront());
        ref.read(openSessionRequestsProvider).add(session);
      },
      onShowWindow: () => unawaited(bringWindowToFront()),
      onQuit: () => unawaited(
        ServicesBinding.instance.exitApplication(AppExitType.required),
      ),
    );

    return child;
  }
}
