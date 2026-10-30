/// Pure queries over the background work (`ChatState.backgroundWork`,
/// 1.0.0) of the chats the client mirrors (AHP-033).
///
/// Background work is absent from `SessionSummary` and `ChatSummary`, so
/// the client only knows about it for chats it is subscribed to.
library;

import 'host_state.dart';
import 'session_status.dart';
import 'wire.dart';

/// Whether the mirror of [chat] lists background work.
bool chatHasBackgroundWork(HostState state, String chat) =>
    state.chatChannels[chat]?.state.backgroundWork?.isNotEmpty ?? false;

/// The chats of [session] the client knows of: those of its session
/// mirror and of its catalogue entry.
Set<String> knownChatsOf(HostState state, String session) {
  final summary = state.sessions[session];
  return {
    for (final chat
        in state.sessionChannels[session]?.state.chats ?? const <ChatSummary>[])
      chat.resource,
    ?summary?.defaultChat,
    for (final chat in summary?.chats ?? const <SessionChatSummary>[])
      chat.resource,
  };
}

/// Whether [channel] still has background work running: a chat whose
/// mirror lists some, or a session with such a chat.
bool holdsBackgroundWork(HostState state, String channel) =>
    chatHasBackgroundWork(state, channel) ||
    (state.sessionChannels.containsKey(channel) &&
        knownChatsOf(
          state,
          channel,
        ).any((chat) => chatHasBackgroundWork(state, chat)));

/// The sessions with a mirrored chat that lists background work.
Set<String> sessionsWithBackgroundWork(HostState state) {
  if (!state.chatChannels.keys.any((c) => chatHasBackgroundWork(state, c))) {
    return const {};
  }
  return {
    for (final session in {
      ...state.sessions.keys,
      ...state.sessionChannels.keys,
    })
      if (knownChatsOf(
        state,
        session,
      ).any((chat) => chatHasBackgroundWork(state, chat)))
        session,
  };
}

/// [status] with the `InProgress` bit set (and `Idle` cleared) when the
/// session has background work running ([busy]), so it reads as working
/// after its turn ended. Other bits are kept.
SessionStatus withBackgroundWork(SessionStatus status, {required bool busy}) =>
    !busy || status.isInProgress
    ? status
    : status
          .withFlag(SessionStatus.inProgress, enabled: true)
          .withFlag(SessionStatus.idle, enabled: false);
