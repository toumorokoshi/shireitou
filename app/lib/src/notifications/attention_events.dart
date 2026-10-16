/// Pure logic for local notifications (AV-121): which catalogue changes
/// deserve one, the user's per-event settings, and the notification text.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import '../hosts/open_hosts.dart';

/// What happened to a session.
enum AttentionKind {
  /// The agent waits for an approval or an answer.
  needsInput('Needs your input'),

  /// The agent finished its turn.
  finished('Finished'),

  /// The turn failed.
  failed('Failed');

  const AttentionKind(this.label);

  /// The notification's title prefix and the setting's label.
  final String label;
}

/// A change in a session's status worth telling the user about.
@immutable
class AttentionEvent {
  /// Creates an [AttentionEvent].
  const AttentionEvent(this.session, this.kind, this.title);

  /// The session.
  final SessionRef session;

  /// What happened.
  final AttentionKind kind;

  /// The session's title.
  final String title;

  @override
  bool operator ==(Object other) =>
      other is AttentionEvent &&
      other.session == session &&
      other.kind == kind &&
      other.title == title;

  @override
  int get hashCode => Object.hash(session, kind, title);

  @override
  String toString() => 'AttentionEvent(${session.session}, $kind)';
}

/// What changed from [before] to [after] (two snapshots of the merged
/// session list) that deserves a notification. Sessions that appear or
/// disappear (a host connecting or reloading its catalogue) and archived
/// sessions are left out, so connecting never floods the user.
List<AttentionEvent> attentionEvents(
  List<HostSession> before,
  List<HostSession> after,
) {
  final previous = {for (final s in before) s.ref: s.summary.status};
  return [
    for (final s in after)
      if (previous[s.ref] case final old?)
        if (!s.summary.status.isArchivedFlag)
          ?_kind(
            old,
            s.summary.status,
          ).let((kind) => AttentionEvent(s.ref, kind, s.summary.title)),
  ];
}

AttentionKind? _kind(SessionStatus old, SessionStatus now) {
  if (now.isInputNeeded && !old.isInputNeeded) return AttentionKind.needsInput;
  if (now.isError && !old.isError) return AttentionKind.failed;
  if (old.isInProgress && !now.isInProgress && !now.isError) {
    return AttentionKind.finished;
  }
  return null;
}

extension<T extends Object> on T? {
  R? let<R>(R Function(T value) f) => switch (this) {
    final T value => f(value),
    null => null,
  };
}

/// Which events notify (AV-121: "configurable per event").
@immutable
class NotificationSettings {
  /// Creates [NotificationSettings]; every event notifies by default.
  const NotificationSettings({this.disabled = const {}});

  /// Decodes settings saved with [toJson]; unknown or broken data gives
  /// the defaults.
  factory NotificationSettings.fromJson(String? text) {
    if (text == null) return const NotificationSettings();
    try {
      final json = jsonDecode(text);
      final off = json is Map ? json['disabled'] : null;
      return NotificationSettings(
        disabled: {
          for (final name in off is List ? off : const [])
            ?AttentionKind.values.where((k) => k.name == name).firstOrNull,
        },
      );
    } on FormatException {
      return const NotificationSettings();
    }
  }

  /// The events the user turned off.
  final Set<AttentionKind> disabled;

  /// Whether [kind] notifies.
  bool enabled(AttentionKind kind) => !disabled.contains(kind);

  /// A copy with [kind] turned on or off.
  NotificationSettings toggled(AttentionKind kind, {required bool on}) =>
      NotificationSettings(
        disabled: on ? ({...disabled}..remove(kind)) : {...disabled, kind},
      );

  /// Encodes the settings.
  String toJson() => jsonEncode({
    'disabled': [
      for (final k in AttentionKind.values)
        if (disabled.contains(k)) k.name,
    ],
  });

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings && setEquals(other.disabled, disabled);

  @override
  int get hashCode => Object.hashAllUnordered(disabled);
}

/// Whether [event] should notify: its kind is on, and the user is not
/// already looking at the session (the window has focus and shows it).
bool shouldNotify(
  AttentionEvent event,
  NotificationSettings settings, {
  required bool focused,
  SessionRef? visible,
}) => settings.enabled(event.kind) && !(focused && visible == event.session);

/// The notification's title and body for [event]; [hostLabel] is added
/// when several hosts are open.
({String title, String body}) notificationText(
  AttentionEvent event, {
  String? hostLabel,
}) => (
  title: event.kind.label,
  body: hostLabel == null ? event.title : '${event.title} · $hostLabel',
);

/// The payload that brings [session] back when the notification is
/// clicked.
String notificationPayload(SessionRef session) =>
    jsonEncode({'host': session.host, 'session': session.session});

/// The session in a [notificationPayload], or null.
SessionRef? sessionOfPayload(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json case {'host': final String host, 'session': final String s}) {
      return (host: host, session: s);
    }
  } on FormatException {
    return null;
  }
  return null;
}

/// A stable notification ID for [event], so a newer event of the same
/// session replaces the older notification instead of piling up.
int notificationId(AttentionEvent event) =>
    Object.hash(event.session.host, event.session.session) & 0x7fffffff;
