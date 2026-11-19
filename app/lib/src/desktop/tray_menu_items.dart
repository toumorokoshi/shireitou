/// Pure data model and builder for the desktop system tray dropdown menu.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import '../hosts/open_hosts.dart';
import '../session_list/pinned_sessions.dart';
import '../session_list/session_filter.dart';
import '../session_list/session_tree.dart';
import '../session_list/status_badges.dart';

/// Maximum characters of a conversation title shown in a tray menu item.
const maxTrayTitleLength = 60;

/// Whether a session is currently active for the tray menu: non-archived
/// and either running (`InProgress`) or waiting on the user (`InputNeeded`).
bool isTrayActiveSession(SessionStatus status) =>
    !status.isArchivedFlag && (status.isInProgress || status.isInputNeeded);

/// One conversation entry in the system tray dropdown.
@immutable
class TrayConversationItem {
  /// Creates a [TrayConversationItem].
  const TrayConversationItem({
    required this.ref,
    required this.label,
    this.tooltip,
  });

  /// The session to open when clicked.
  final SessionRef ref;

  /// The menu item text (status prefix + truncated title).
  final String label;

  /// Optional hover tooltip with full title, status and workspace/host.
  final String? tooltip;

  @override
  bool operator ==(Object other) =>
      other is TrayConversationItem &&
      other.ref == ref &&
      other.label == label &&
      other.tooltip == tooltip;

  @override
  int get hashCode => Object.hash(ref, label, tooltip);
}

/// The full state of the system tray dropdown: active conversations at
/// the top, then pinned conversations, and the tray icon tooltip.
@immutable
class TrayMenuModel {
  /// Creates a [TrayMenuModel].
  const TrayMenuModel({
    this.active = const [],
    this.pinned = const [],
    this.tooltip = 'shireitou',
  });

  /// Active conversations (needs input first, then working; most recent
  /// first within each).
  final List<TrayConversationItem> active;

  /// Pinned non-archived conversations not already listed in [active], in
  /// pin order.
  final List<TrayConversationItem> pinned;

  /// Tooltip for the tray icon itself.
  final String tooltip;

  /// Whether there are no active or pinned conversations to list.
  bool get isEmpty => active.isEmpty && pinned.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is TrayMenuModel &&
      other.tooltip == tooltip &&
      listEquals(other.active, active) &&
      listEquals(other.pinned, pinned);

  @override
  int get hashCode =>
      Object.hash(tooltip, Object.hashAll(active), Object.hashAll(pinned));
}

/// Builds a [TrayMenuModel] from [sessions], [pins], [hostLabels] and
/// [attentionCount].
TrayMenuModel buildTrayMenuModel({
  required List<HostSession> sessions,
  required Set<SessionRef> pins,
  required Map<String, String> hostLabels,
  int attentionCount = 0,
}) {
  final nonArchived = [
    for (final s in sessions)
      if (!s.summary.status.isArchivedFlag) s,
  ];

  final activeSessions = [
    for (final s in nonArchived)
      if (isTrayActiveSession(s.summary.status)) s,
  ]..sort(_compareActive);

  final activeRefs = {for (final s in activeSessions) s.ref};
  final pinnedSessions = [
    for (final s in splitPinned(pins, nonArchived).pinned)
      if (!activeRefs.contains(s.ref)) s,
  ];

  return TrayMenuModel(
    active: [
      for (final s in activeSessions) _toItem(s, hostLabel: hostLabels[s.host]),
    ],
    pinned: [
      for (final s in pinnedSessions) _toItem(s, hostLabel: hostLabels[s.host]),
    ],
    tooltip: windowTitle(attentionCount),
  );
}

int _compareActive(HostSession a, HostSession b) {
  final aRank = a.summary.status.isInputNeeded ? 0 : 1;
  final bRank = b.summary.status.isInputNeeded ? 0 : 1;
  if (aRank != bRank) return aRank.compareTo(bRank);
  return b.summary.modifiedAt.compareTo(a.summary.modifiedAt);
}

TrayConversationItem _toItem(HostSession session, {String? hostLabel}) {
  final status = session.summary.status;
  final rawTitle = session.summary.title.trim();
  final fullTitle = rawTitle.isEmpty ? 'Untitled session' : rawTitle;
  final displayTitle = fullTitle.length > maxTrayTitleLength
      ? '${fullTitle.substring(0, maxTrayTitleLength - 1)}…'
      : fullTitle;
  final prefix = _statusPrefix(status);
  final statusLabel = _statusLabel(status);
  final place = sessionPlace(session.summary, hostLabel: hostLabel);
  final tooltipParts = [
    fullTitle,
    if (statusLabel.isNotEmpty) statusLabel,
    if (place.isNotEmpty) place,
  ];
  return TrayConversationItem(
    ref: session.ref,
    label: '$prefix$displayTitle',
    tooltip: tooltipParts.join(' · '),
  );
}

String _statusPrefix(SessionStatus status) {
  if (status.isInputNeeded) return '◆ ';
  if (status.isInProgress) return '● ';
  if (status.isError) return '✕ ';
  if (!status.isReadFlag) return '• ';
  return '';
}

String _statusLabel(SessionStatus status) {
  final badge = dotBadgeFor(status);
  return badge == SessionBadge.idle ? '' : badge.label;
}
