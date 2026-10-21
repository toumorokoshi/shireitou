/// Pure logic for local notifications (AV-121): which catalogue changes
/// deserve one, the user's per-event settings, and the notification text.
library;

import 'dart:convert';
import 'dart:ui' show AppLifecycleState;

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

/// The user's turn starts when input becomes needed, or when a turn ends
/// (`InProgress` clears): failed if it ends in an error, otherwise
/// finished. An error that appears without a running turn also counts.
/// A host that keeps the `Error` bit through the next turn still gets
/// that turn's failure reported, because the turn ending is the trigger.
AttentionKind? _kind(SessionStatus old, SessionStatus now) {
  if (now.isInputNeeded) {
    return old.isInputNeeded ? null : AttentionKind.needsInput;
  }
  final turnEnded = old.isInProgress && !now.isInProgress;
  if (now.isError) {
    return turnEnded || !old.isError ? AttentionKind.failed : null;
  }
  return turnEnded ? AttentionKind.finished : null;
}

/// Whether the app's window has focus in lifecycle [state]; null (no
/// lifecycle reported yet, as in tests) counts as focused.
bool isForeground(AppLifecycleState? state) =>
    state == null || state == AppLifecycleState.resumed;

extension<T extends Object> on T? {
  R? let<R>(R Function(T value) f) => switch (this) {
    final T value => f(value),
    null => null,
  };
}

/// Which events notify (AV-121: "configurable per event"), and whether
/// they also chime.
@immutable
class NotificationSettings {
  /// Creates [NotificationSettings]; every event notifies and chimes by
  /// default.
  const NotificationSettings({this.disabled = const {}, this.sound = true});

  /// Decodes settings saved with [toJson]; unknown or broken data gives
  /// the defaults.
  factory NotificationSettings.fromJson(String? text) {
    if (text == null) return const NotificationSettings();
    try {
      final json = jsonDecode(text);
      if (json is! Map) return const NotificationSettings();
      final off = json['disabled'];
      return NotificationSettings(
        disabled: {
          for (final name in off is List ? off : const [])
            ?AttentionKind.values.where((k) => k.name == name).firstOrNull,
        },
        sound: json['sound'] != false,
      );
    } on FormatException {
      return const NotificationSettings();
    }
  }

  /// The events the user turned off.
  final Set<AttentionKind> disabled;

  /// Whether the events that notify also play the chime.
  final bool sound;

  /// Whether [kind] notifies.
  bool enabled(AttentionKind kind) => !disabled.contains(kind);

  /// A copy with [kind] turned on or off.
  NotificationSettings toggled(AttentionKind kind, {required bool on}) =>
      NotificationSettings(
        disabled: on ? ({...disabled}..remove(kind)) : {...disabled, kind},
        sound: sound,
      );

  /// A copy with the chime turned on or off.
  NotificationSettings withSound({required bool on}) =>
      NotificationSettings(disabled: disabled, sound: on);

  /// Encodes the settings.
  String toJson() => jsonEncode({
    'disabled': [
      for (final k in AttentionKind.values)
        if (disabled.contains(k)) k.name,
    ],
    'sound': sound,
  });

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      setEquals(other.disabled, disabled) &&
      other.sound == sound;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(disabled), sound);
}

/// Whether [event] should notify: its kind is on, and the user is not
/// already looking at the session (the window has focus and shows it).
bool shouldNotify(
  AttentionEvent event,
  NotificationSettings settings, {
  required bool focused,
  SessionRef? visible,
}) => settings.enabled(event.kind) && !(focused && visible == event.session);

/// Whether [events] (one change of the session list) play the chime:
/// the sound is on, at least one of them notifies, and the app is in
/// the foreground when [needsForeground]. Several sessions changing at
/// once chime once.
bool shouldChime(
  Iterable<AttentionEvent> events,
  NotificationSettings settings, {
  required bool focused,
  SessionRef? visible,
  bool needsForeground = false,
}) =>
    settings.sound &&
    (focused || !needsForeground) &&
    events.any(
      (e) => shouldNotify(e, settings, focused: focused, visible: visible),
    );

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
