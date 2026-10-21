/// Notifications in the web build through the browser's Notification API
/// (AV-121). They are page notifications (`new Notification`), so they
/// need no service worker and only arrive while the tab is open.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

import 'os_notifier.dart';

final _log = Logger('notifications');

/// The browser's [OsNotifier], or null when the browser has no
/// Notification API (for example an embedded web view).
OsNotifier? browserNotifier({required ValueChanged<String?> onOpen}) =>
    globalContext.has('Notification') ? WebNotifier(onOpen: onOpen) : null;

/// [OsNotifier] on the browser's Notification API. Clicking a
/// notification focuses the tab and calls [onOpen] with its payload.
class WebNotifier implements OsNotifier {
  /// Creates a [WebNotifier].
  WebNotifier({required this.onOpen});

  /// Called with the payload of a clicked notification.
  final ValueChanged<String?> onOpen;

  /// The shown notifications by ID, closed when the same ID shows again.
  final _shown = <int, web.Notification>{};

  @override
  Future<bool> requestPermission() async {
    try {
      if (web.Notification.permission == 'default') {
        await web.Notification.requestPermission().toDart;
      }
    } on Object catch (error) {
      _log.warning('could not ask for notification permission: $error');
    }
    final granted = web.Notification.permission == 'granted';
    if (!granted) _log.info('notification permission was not granted');
    return granted;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool silent = false,
  }) async {
    if (web.Notification.permission != 'granted') return;
    _shown.remove(id)?.close();
    try {
      final notification = web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          tag: '$id',
          icon: 'favicon.png',
          silent: silent,
        ),
      );
      notification.onclick = ((web.Event _) {
        web.window.focus();
        notification.close();
        onOpen(payload);
      }).toJS;
      _shown[id] = notification;
    } on Object catch (error) {
      // Chrome on Android only allows service worker notifications.
      _log.warning('could not show a notification: $error');
    }
  }
}
