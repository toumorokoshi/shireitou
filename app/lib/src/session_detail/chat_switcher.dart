/// The chat switcher for sessions with several chats (AV-069): side chats,
/// forks and subagents, in the session's catalogue order, which movable
/// chats can change (`moveChat`, 1.0.0).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

/// The chats of [session] the user can open, in catalogue order: every
/// chat but hidden internal workers.
List<ChatSummary> switchableChats(SessionState? session) => [
  for (final chat in session?.chats ?? const <ChatSummary>[])
    if (chat.interactivity != ChatInteractivity.hidden) chat,
];

/// Where to move [chat] so it ends up [delta] places later (negative:
/// earlier) among [session]'s chats, or null when it cannot move that far.
/// The destination names the chat to place it after, or none for the
/// start of the catalogue.
ChatMoveToSessionDestination? chatMoveDestination(
  String sessionUri,
  SessionState session,
  String chat,
  int delta,
) {
  final order = [for (final c in session.chats) c.resource];
  final from = order.indexOf(chat);
  final to = from + delta;
  if (from < 0 || delta == 0 || to < 0 || to >= order.length) return null;
  order.removeAt(from);
  return ChatMoveToSessionDestination(
    session: sessionUri,
    after: to == 0 ? null : order[to - 1],
  );
}

/// An icon for how [chat] came to be.
IconData chatOriginIcon(ChatSummary chat) => switch (chat.origin) {
  ChatOriginTool() => Icons.smart_toy_outlined,
  ChatOriginSideChat() => Icons.forum_outlined,
  ChatOriginFork() => Icons.call_split,
  _ => Icons.chat_bubble_outline,
};

/// Moves a chat by an offset among the session's chats.
typedef MoveChat = void Function(String chat, int delta);

/// Detaches a chat into a new session (`moveChat` with `newSession`).
typedef DetachChat = void Function(String chat);

/// Chips for the session's chats; the open one is selected. A movable
/// open chat has a menu to move it (when [onMove] or [onDetach] is set).
class ChatSwitcher extends StatelessWidget {
  /// Creates a [ChatSwitcher] for [chats] (at least two).
  const ChatSwitcher({
    super.key,
    required this.chats,
    required this.selected,
    required this.onSelect,
    this.onMove,
    this.onDetach,
  });

  /// The chats, in order.
  final List<ChatSummary> chats;

  /// The open chat.
  final String? selected;

  /// Opens a chat.
  final ValueChanged<String> onSelect;

  /// Moves a chat; null when the host cannot move chats (0.9.0).
  final MoveChat? onMove;

  /// Detaches a movable chat into a new session; null when the host
  /// cannot move chats (0.9.0).
  final DetachChat? onDetach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = chats.where((c) => c.resource == selected).firstOrNull;
    final index = current == null ? -1 : chats.indexOf(current);
    final onMove = this.onMove;
    final onDetach = this.onDetach;
    final movable = current != null && (current.movable ?? false);
    final hasActions =
        movable &&
        ((onMove != null && (index > 0 || index < chats.length - 1)) ||
            onDetach != null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chat in chats)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(
                          chat.status.isInputNeeded
                              ? Icons.front_hand_outlined
                              : chat.status.isInProgress
                              ? Icons.more_horiz
                              : chatOriginIcon(chat),
                          size: 16,
                        ),
                        label: Text(
                          [
                            chat.title,
                            if (chat.interactivity ==
                                ChatInteractivity.readOnly)
                              '(read-only)',
                          ].join(' '),
                        ),
                        selected: chat.resource == selected,
                        onSelected: (_) => onSelect(chat.resource),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasActions)
            PopupMenuButton<VoidCallback>(
              tooltip: 'Chat actions',
              icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                if (onMove != null && index > 0)
                  PopupMenuItem(
                    value: () => onMove(current.resource, -1),
                    child: const Text('Move left'),
                  ),
                if (onMove != null && index < chats.length - 1)
                  PopupMenuItem(
                    value: () => onMove(current.resource, 1),
                    child: const Text('Move right'),
                  ),
                if (onDetach != null)
                  PopupMenuItem(
                    value: () => onDetach(current.resource),
                    child: const Text('Detach to new session'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
