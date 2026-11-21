/// The session list row's status dot and a working spinner (AV-021,
/// AV-093).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'status_badges.dart';

/// Whether the session is working: a turn is running ([SessionStatus]
/// `InProgress`, or [hasActiveTurn] before the catalogue catches up) or
/// background work is ([hasBackgroundWork]), and it is not waiting on the
/// user (`InputNeeded`).
bool isSessionWorking({
  required SessionStatus? status,
  bool hasActiveTurn = false,
  bool hasBackgroundWork = false,
}) {
  if (status?.isInputNeeded ?? false) return false;
  if (status?.isInProgress ?? false) return true;
  return hasActiveTurn || hasBackgroundWork;
}

/// A small spinner while [isSessionWorking] is true, else the status dot
/// ([dotBadgeFor]).
class SessionStatusLeading extends StatelessWidget {
  /// Creates a [SessionStatusLeading].
  const SessionStatusLeading({
    super.key,
    required this.status,
    this.hasActiveTurn = false,
    this.workingTooltip,
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

  /// Hover tooltip while working; defaults to [SessionBadge.working.label].
  final String? workingTooltip;

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
            message: workingTooltip ?? SessionBadge.working.label,
            textAlign: TextAlign.start,
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

/// A short label for background [work]: "Shell: npm test" or
/// "Subagent: Explore".
String backgroundWorkLabel(BackgroundWork work) => switch (work) {
  BackgroundShellWork(:final label) => 'Shell: $label',
  BackgroundSubagentWork(:final label) => 'Subagent: $label',
  BackgroundWorkUnknown(:final label) => label,
};

String _toolCallActivityLabel(ToolCallState toolCall) {
  final message = toolCall.invocationMessage?.text.trim();
  return (message != null && message.isNotEmpty)
      ? message
      : toolCall.displayName;
}

bool _isVisiblePart(ResponsePart part) => switch (part) {
  MarkdownResponsePart(:final content) ||
  ReasoningResponsePart(:final content) => content.trim().isNotEmpty,
  _ => true,
};

/// Builds a tooltip for a working session's spinner, listing foreground
/// processes (running tools, thinking, responding) and background tasks
/// (shells, subagents, or summary count) when known.
String workingStatusTooltip({
  SessionSummary? summary,
  List<ChatState> chats = const [],
  List<BackgroundWork> backgroundWork = const [],
  List<SessionToolClientExecutionRequest> clientExecutions = const [],
}) {
  final foreground = <String>[];
  for (final chat in chats) {
    if (chat.activeTurn case final active?) {
      final runningTools = [
        for (final part in active.responseParts)
          if (part case ToolCallResponsePart(:final toolCall)
              when !toolCall.isFinished && !toolCall.isBlocking)
            _toolCallActivityLabel(toolCall),
      ];
      if (runningTools.isNotEmpty) {
        foreground.addAll(runningTools);
      } else {
        ResponsePart? lastVisible;
        for (final part in active.responseParts.reversed) {
          if (_isVisiblePart(part)) {
            lastVisible = part;
            break;
          }
        }
        final activity = chat.activity?.trim();
        if (lastVisible is ReasoningResponsePart) {
          foreground.add('Thinking');
        } else if (activity != null && activity.isNotEmpty) {
          foreground.add(activity);
        } else if (lastVisible is MarkdownResponsePart) {
          foreground.add('Responding');
        } else {
          foreground.add('Thinking');
        }
      }
    } else if (chat.status.isInProgress) {
      final activity = chat.activity?.trim();
      if (activity != null && activity.isNotEmpty) {
        foreground.add(activity);
      }
    }
  }

  for (final execution in clientExecutions) {
    foreground.add(
      '${execution.toolCall.displayName} (client ${execution.clientId})',
    );
  }

  if (foreground.isEmpty && chats.isEmpty) {
    final activity = summary?.activity?.trim();
    if (activity != null && activity.isNotEmpty) {
      foreground.add(activity);
    }
  }

  final seenBackgroundIds = <String>{};
  final allBackground = <BackgroundWork>[
    for (final w in backgroundWork)
      if (seenBackgroundIds.add(w.id)) w,
    for (final chat in chats)
      for (final w in chat.backgroundWork ?? const <BackgroundWork>[])
        if (seenBackgroundIds.add(w.id)) w,
  ];
  final background = <String>[
    for (final w in allBackground) backgroundWorkLabel(w),
  ];
  if (background.isEmpty && summary != null) {
    if (summary.meta?[backgroundWorkMetaKey] case final num count
        when count > 0) {
      final n = count.toInt();
      background.add(n == 1 ? '1 background task' : '$n background tasks');
    }
  }

  if (foreground.isEmpty && background.isEmpty) {
    return SessionBadge.working.label;
  }
  if (foreground.length == 1 && background.isEmpty) {
    return foreground.single;
  }
  return [
    if (foreground.isNotEmpty) ...[
      'Foreground:',
      for (final item in foreground) '• $item',
    ],
    if (background.isNotEmpty) ...[
      'Background:',
      for (final item in background) '• $item',
    ],
  ].join('\n');
}

/// Builds [workingStatusTooltip] for [summary] using all mirrored chats and
/// session state in [state].
String workingStatusTooltipForSession(HostState state, SessionSummary summary) {
  final chats = [
    for (final chatId in knownChatsOf(state, summary.resource))
      ?state.chatChannels[chatId]?.state,
  ];
  final clientExecutions =
      state.sessionChannels[summary.resource]?.state.inputNeeded
          ?.whereType<SessionToolClientExecutionRequest>()
          .toList() ??
      const <SessionToolClientExecutionRequest>[];
  return workingStatusTooltip(
    summary: summary,
    chats: chats,
    clientExecutions: clientExecutions,
  );
}
