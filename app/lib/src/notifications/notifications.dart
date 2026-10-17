/// Local notifications for sessions that need attention (AV-121): the
/// OS notifier, the user's settings, and the widget that watches the
/// merged session list while the app runs.
///
/// Notifications are posted by this process, so they only arrive while
/// the app runs (also minimized or in the background on desktop, and
/// while the tab is open on the web). Push
/// notifications for a closed or suspended app need a relay (AV-123,
/// `specs/push-relay.md`).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../desktop/desktop_window.dart';
import '../hosts/open_hosts.dart';
import '../prefs.dart';
import 'attention_events.dart';
import 'browser_notifier_io.dart'
    if (dart.library.js_interop) 'browser_notifier_web.dart';
import 'os_notifier.dart';

export 'os_notifier.dart';

final _log = Logger('notifications');

/// [OsNotifier] on `flutter_local_notifications` (Linux through the
/// freedesktop notification service, macOS and iOS through
/// UserNotifications, Windows through toast notifications, Android
/// through a notification channel). [requestPermission] initializes the
/// plugin, which asks for permission on macOS, iOS and Android 13+; the
/// app calls it at start, so the prompt shows while the user is at the
/// app rather than when the first session finishes. Any failure (no
/// notification daemon, permission refused) is logged and the
/// notification dropped, and a refusal is not remembered: the next call
/// asks the system again, so permission granted later in the system
/// settings takes effect without a restart.
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
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('ic_notification'),
          windows: WindowsInitializationSettings(
            appName: 'shireitou',
            appUserModelId: 'Shireitou.Shireitou.Desktop',
            guid: '5c3e4b1e-8a0f-4f7e-9a51-2f4f0b6c9d21',
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onOpen(response.payload),
      );
      if (ok != true) {
        _log.warning('notification permission was not granted');
        return false;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // Android 13+ asks at run time; earlier versions answer true.
      return await android?.requestNotificationsPermission() ?? true;
    } on Object catch (error) {
      _log.warning('notifications are not available: $error');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    final ready = _ready ??= _initialize();
    final ok = await ready;
    if (!ok && identical(_ready, ready)) _ready = null;
    return ok;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!await requestPermission()) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: _details,
      );
    } on Object catch (error) {
      _log.warning('could not show a notification: $error');
    }
  }
}

/// Android's notification channel; other platforms need no details.
const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'attention',
    'Sessions that need you',
    channelDescription:
        'A session needs input, finished its turn or failed (AV-121).',
    importance: Importance.high,
    priority: Priority.high,
  ),
);

/// Whether this platform gets notifications from the app's process: the
/// desktop apps, iOS and Android while the app runs (also briefly in the
/// background), and the web build where the browser has the Notification
/// API. Widget tests run as Android on a desktop host unless they say
/// otherwise, so they get none: on Android and iOS the real platform
/// (`dart:io`) must agree.
bool get localNotificationsSupported =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.android => Platform.isAndroid,
      TargetPlatform.iOS => Platform.isIOS,
      _ => false,
    };

/// Sessions to open, from clicked notifications (and the run compare
/// page); the sessions screen selects them.
final openSessionRequestsProvider = Provider<StreamController<SessionRef>>((
  ref,
) {
  final controller = StreamController<SessionRef>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// The app's [OsNotifier], or null where there are no notifications. A
/// clicked notification brings the window to the front and opens its
/// session.
final notifierProvider = Provider<OsNotifier?>((ref) {
  if (!localNotificationsSupported) return null;
  void onOpen(String? payload) {
    if (sessionOfPayload(payload) case final session?) {
      unawaited(bringWindowToFront());
      ref.read(openSessionRequestsProvider).add(session);
    }
  }

  return kIsWeb
      ? browserNotifier(onOpen: onOpen)
      : LocalNotifier(onOpen: onOpen);
});

/// Whether the user allowed notifications: null until asked (at start,
/// by [AttentionNotifications]), then the last answer.
final notificationPermissionProvider =
    NotifierProvider<NotificationPermission, bool?>(NotificationPermission.new);

/// Asks for, and holds, the permission to notify.
class NotificationPermission extends Notifier<bool?> {
  @override
  bool? build() => null;

  /// Asks for permission (a prompt only when the user has not decided)
  /// and returns whether notifications can be shown.
  Future<bool> request() async {
    final granted =
        await ref.read(notifierProvider)?.requestPermission() ?? false;
    if (ref.mounted) state = granted;
    return granted;
  }
}

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

/// Asks for permission to notify at start, then watches the merged
/// session list while mounted and posts a notification for each
/// [AttentionEvent] the user wants and is not already looking at.
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
  bool _focused = isForeground(WidgetsBinding.instance.lifecycleState);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => _focused = isForeground(state),
    );
    if (ref.read(notifierProvider) != null) {
      unawaited(ref.read(notificationPermissionProvider.notifier).request());
    }
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
