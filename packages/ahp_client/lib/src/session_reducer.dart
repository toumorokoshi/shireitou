/// Pure reducer for session channels (AHP-021, AHP-024).
library;

import 'session_status.dart';
import 'session_wire.dart';
import 'wire.dart';

/// Applies [action] to [state], mirroring `sessionReducer` in protocol
/// 1.0.0 for the actions [SessionAction] models.
SessionState reduceSession(
  SessionState state,
  SessionAction action,
) => switch (action) {
  SessionReady() => state.copyWith(lifecycle: 'ready'),
  SessionCreationFailed(:final error) => state.copyWith(
    lifecycle: 'failed',
    creationError: error,
  ),
  SessionChatAdded(:final summary) => state.copyWith(
    chats: state.chats.any((c) => c.resource == summary.resource)
        ? [
            for (final c in state.chats)
              c.resource == summary.resource ? summary : c,
          ]
        : [...state.chats, summary],
  ),
  SessionChatRemoved(:final chat) => state.copyWith(
    chats: [
      for (final c in state.chats)
        if (c.resource != chat) c,
    ],
    defaultChat: state.defaultChat == chat ? null : state.defaultChat,
  ),
  SessionChatUpdated(:final chat, :final changes) => state.copyWith(
    chats: [
      for (final c in state.chats)
        c.resource == chat
            ? SessionChatSummary.fromJson({
                ...c.toJson(),
                ...changes,
                'resource': chat,
              })
            : c,
    ],
  ),
  SessionDefaultChatChanged(:final defaultChat) => state.copyWith(
    defaultChat: defaultChat,
  ),
  SessionTitleChanged(:final title) => state.copyWith(title: title),
  SessionIsReadChanged(:final isRead) => state.copyWith(
    status: state.status.withFlag(SessionStatus.isRead, enabled: isRead),
  ),
  SessionIsArchivedChanged(:final isArchived) => state.copyWith(
    status: state.status.withFlag(
      SessionStatus.isArchived,
      enabled: isArchived,
    ),
  ),
  SessionActivityChanged(:final activity) => state.copyWith(activity: activity),
  SessionConfigChanged(:final config, :final replace) => switch (state.config) {
    null => state,
    final current => state.copyWith(
      config: {
        ...current,
        'values': replace ?? false
            ? {...config}
            : {...?current['values'] as JsonMap?, ...config},
      },
    ),
  },
  SessionUnknownAction() => state,
};

/// [reduceSession] over a raw JSON action, for [ChannelMirror]s.
SessionState reduceSessionJson(SessionState state, JsonMap action) =>
    reduceSession(state, SessionAction.fromJson(action));
