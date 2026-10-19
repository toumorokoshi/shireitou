/// The session list row's status dot and a working spinner (AV-021,
/// AV-093).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'status_badges.dart';

/// Whether the session is working: a turn is running ([SessionStatus]
/// `InProgress`, or [hasActiveTurn] before the catalogue catches up) and
/// it is not waiting on the user (`InputNeeded`).
bool isSessionWorking({
  required SessionStatus? status,
  bool hasActiveTurn = false,
}) {
  if (status?.isInputNeeded ?? false) return false;
  if (status?.isInProgress ?? false) return true;
  return hasActiveTurn;
}

/// A small spinner while [isSessionWorking] is true, else the status dot
/// ([dotBadgeFor]).
class SessionStatusLeading extends StatelessWidget {
  /// Creates a [SessionStatusLeading].
  const SessionStatusLeading({
    super.key,
    required this.status,
    this.hasActiveTurn = false,
    this.width = 12,
    this.dotSize = 6,
    this.spinnerSize = 12,
    this.semanticLabel,
  });

  /// The session's catalogue status.
  final SessionStatus status;

  /// An open chat's active turn when the catalogue has not set
  /// `InProgress` yet.
  final bool hasActiveTurn;

  /// Width of the leading slot in the row.
  final double width;

  /// Diameter of the idle status dot.
  final double dotSize;

  /// Diameter of the working spinner (or static icon).
  final double spinnerSize;

  /// Screen-reader text; the row title usually includes status already.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final working = isSessionWorking(
      status: status,
      hasActiveTurn: hasActiveTurn,
    );
    if (working) {
      final color = colors.statusColors.running;
      return ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Tooltip(
            message: SessionBadge.working.label,
            child: SessionWorkingIcon(
              size: spinnerSize,
              color: color,
              semanticLabel: semanticLabel ?? SessionBadge.working.label,
            ),
          ),
        ),
      );
    }
    final badge = dotBadgeFor(status);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: Icon(
          Icons.circle,
          size: dotSize,
          color: statusDotColor(
            badge,
            colors.statusColors,
            unread: Theme.of(context).colorScheme.onSurface,
          ),
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// Spinner for a working session; a static sync icon when the platform
/// asks for reduced motion.
class SessionWorkingIcon extends StatelessWidget {
  /// Creates a [SessionWorkingIcon].
  const SessionWorkingIcon({
    super.key,
    required this.size,
    required this.color,
    this.semanticLabel,
  });

  /// Width and height of the icon.
  final double size;

  /// Usually [StatusColors.running].
  final Color color;

  /// Announced to screen readers when semantics are not excluded.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? SessionBadge.working.label;
    final icon = MediaQuery.disableAnimationsOf(context)
        ? Icon(Icons.autorenew, size: size, color: color)
        : SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size <= 14 ? 2 : 2.5,
              color: color,
            ),
          );
    if (semanticLabel == null) return icon;
    return Semantics(label: label, child: icon);
  }
}
