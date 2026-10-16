/// Local notifications for sessions that need attention (AV-121): the
/// OS notifier, the user's settings, and the widget that watches the
/// merged session list while the app runs.
///
/// Notifications are posted by this process, so they only arrive while
/// the app runs (also minimized or in the background on desktop). Push
/// notifications for a closed or suspended app need a relay (AV-123,
/// `specs/push-relay.md`).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../hosts/open_hosts.dart';
import '../prefs.dart';
import 'attention_events.dart';

final _log = Logger('notifications');

/// Posts notifications.
abstract interface class OsNotifier {
  /// Shows a notification with [payload], which comes back when it is
  /// clicked.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  });
}

/// [OsNotifier] on `flutter_local_notifications` (Linux through the
/// freedesktop notification service, macOS through UserNotifications,
/// Windows through toast notifications). Initialized on first use; any
/// failure (no notification daemon, permission refused) is logged and
/// the notification dropped.
class LocalNotifier implements OsNotifier {
  /// Creates a [LocalNotifier] that calls [onOpen] with a clicked
  /// notification's payload.
  LocalNotifier({required this.onOpen});

  /// Called with the payload of a clicked notification.
  final ValueChanged<String?> onOpen;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  Future<bool> _initialize() async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
          macOS: DarwinInitializationSettings(),
          windows: WindowsInitializationSettings(
            appName: 'shireitou',
            appUserModelId: 'Shireitou.Shireitou.Desktop',
            guid: '5c3e4b1e-8a0f-4f7e-9a51-2f4f0b6c9d21',
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onOpen(response.payload),
      );
      return ok ?? false;
    } on Object catch (error) {
      _log.warning('notifications are not available: $error');
      return false;
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!await (_ready ??= _initialize())) return;
    try {
      await _plugin.show(id: id, title: title, body: body, payload: payload);
    } on Object catch (error) {
      _log.warning('could not show a notification: $error');
    }
  }
}

/// Whether this platform gets local notifications: the desktop apps.
/// The web build would need the plugin's service worker in place of
/// Flutter's, and mobile is out of scope (see GAPS.md). Widget tests run
/// as Android unless they say otherwise, so they get none.
bool get localNotificationsSupported =>
    !kIsWeb &&
    const {
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }.contains(defaultTargetPlatform);

/// Sessions to open, from clicked notifications (and the run compare
/// page); the sessions screen selects them.
final openSessionRequestsProvider = Provider<StreamController<SessionRef>>((
  ref,
) {
  final controller = StreamController<SessionRef>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// The app's [OsNotifier], or null where there are no notifications.
final notifierProvider = Provider<OsNotifier?>(
  (ref) => localNotificationsSupported
      ? LocalNotifier(
          onOpen: (payload) {
            if (sessionOfPayload(payload) case final session?) {
              ref.read(openSessionRequestsProvider).add(session);
            }
          },
        )
      : null,
);

/// The session the sessions screen shows, if any.
final visibleSessionProvider = NotifierProvider<VisibleSession, SessionRef?>(
  VisibleSession.new,
);

/// Holds the session the sessions screen shows.
class VisibleSession extends Notifier<SessionRef?> {
  @override
  SessionRef? build() => null;

  /// Sets the shown session.
  void show(SessionRef? session) => state = session;
}

const _settingsKey = 'notification_settings';

/// The user's notification settings, saved with [prefsStoreProvider].
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsStore, NotificationSettings>(
      NotificationSettingsStore.new,
    );

/// Loads and saves [NotificationSettings].
class NotificationSettingsStore extends Notifier<NotificationSettings> {
  bool _changed = false;

  @override
  NotificationSettings build() {
    unawaited(_load());
    return const NotificationSettings();
  }

  Future<void> _load() async {
    final text = await ref.read(prefsStoreProvider).read(_settingsKey);
    if (!_changed && text != null) {
      state = NotificationSettings.fromJson(text);
    }
  }

  /// Turns notifications for [kind] on or off.
  Future<void> set(AttentionKind kind, {required bool on}) async {
    _changed = true;
    state = state.toggled(kind, on: on);
    await ref.read(prefsStoreProvider).write(_settingsKey, state.toJson());
  }
}

/// Watches the merged session list while mounted and posts a
/// notification for each [AttentionEvent] the user wants and is not
/// already looking at.
class AttentionNotifications extends ConsumerStatefulWidget {
  /// Creates an [AttentionNotifications] around [child].
  const AttentionNotifications({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  ConsumerState<AttentionNotifications> createState() =>
      _AttentionNotificationsState();
}

class _AttentionNotificationsState
    extends ConsumerState<AttentionNotifications> {
  late final AppLifecycleListener _lifecycle;
  bool _focused = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => _focused = state == AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onSessions(List<HostSession>? before, List<HostSession> after) {
    final notifier = ref.read(notifierProvider);
    if (notifier == null || before == null) return;
    final settings = ref.read(notificationSettingsProvider);
    final visible = ref.read(visibleSessionProvider);
    final hosts = ref.read(hostInfosProvider);
    for (final event in attentionEvents(before, after)) {
      if (!shouldNotify(event, settings, focused: _focused, visible: visible)) {
        continue;
      }
      final text = notificationText(
        event,
        hostLabel: hosts.length > 1
            ? hosts.where((h) => h.key == event.session.host).firstOrNull?.label
            : null,
      );
      unawaited(
        notifier.show(
          id: notificationId(event),
          title: text.title,
          body: text.body,
          payload: notificationPayload(event.session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(allSessionsProvider, _onSessions);
    return widget.child;
  }
}
