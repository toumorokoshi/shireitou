/// Pure reducer for session channels (AHP-021, AHP-024).
library;

import 'session_status.dart';
import 'wire.dart';

/// Applies [action] to [state], mirroring `sessionReducer` in protocol
/// 1.0.0 for the actions this client models. The rest (customizations, MCP
/// servers, changesets, server tools, active clients, working directories,
/// input requests, chat order, `_meta`) leave [state] unchanged.
SessionState reduceSession(SessionState state, SessionAction action) =>
    switch (action) {
      SessionReadyAction() => state.copyWith(lifecycle: SessionLifecycle.ready),
      SessionCreationFailedAction(:final error) => state.copyWith(
        lifecycle: SessionLifecycle.failed,
        creationError: error,
      ),
      SessionChatAddedAction(:final summary) => state.copyWith(
        chats: state.chats.any((c) => c.resource == summary.resource)
            ? [
                for (final c in state.chats)
                  c.resource == summary.resource ? summary : c,
              ]
            : [...state.chats, summary],
      ),
      SessionChatRemovedAction(:final chat) => state.copyWith(
        chats: [
          for (final c in state.chats)
            if (c.resource != chat) c,
        ],
        defaultChat: state.defaultChat == chat ? null : state.defaultChat,
      ),
      SessionChatUpdatedAction(:final chat, :final changes) => state.copyWith(
        chats: [
          for (final c in state.chats)
            c.resource == chat
                ? ChatSummary.fromJson({
                    ...c.toJson(),
                    ...changes,
                    'resource': chat,
                  })
                : c,
        ],
      ),
      SessionDefaultChatChangedAction(:final defaultChat) => state.copyWith(
        defaultChat: defaultChat,
      ),
      SessionTitleChangedAction(:final title) => state.copyWith(title: title),
      SessionIsReadChangedAction(:final isRead) => state.copyWith(
        status: state.status.withFlag(SessionStatus.isRead, enabled: isRead),
      ),
      SessionIsArchivedChangedAction(:final isArchived) => state.copyWith(
        status: state.status.withFlag(
          SessionStatus.isArchived,
          enabled: isArchived,
        ),
      ),
      SessionActivityChangedAction(:final activity) => state.copyWith(
        activity: activity,
      ),
      SessionConfigChangedAction(:final config, :final replace) =>
        switch (state.config) {
          null => state,
          final current => state.copyWith(
            config: current.copyWith(
              values: replace ?? false
                  ? {...config}
                  : {...current.values, ...config},
            ),
          ),
        },
      _ => state,
    };

/// [reduceSession] over a raw JSON action, for [ChannelMirror]s.
SessionState reduceSessionJson(SessionState state, JsonMap action) =>
    reduceSession(state, SessionAction.fromJson(action));
