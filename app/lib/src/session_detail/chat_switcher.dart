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

/// Chips for the session's chats; the open one is selected. A movable
/// open chat has a menu to move it (when [onMove] is set).
class ChatSwitcher extends StatelessWidget {
  /// Creates a [ChatSwitcher] for [chats] (at least two).
  const ChatSwitcher({
    super.key,
    required this.chats,
    required this.selected,
    required this.onSelect,
    this.onMove,
  });

  /// The chats, in order.
  final List<ChatSummary> chats;

  /// The open chat.
  final String? selected;

  /// Opens a chat.
  final ValueChanged<String> onSelect;

  /// Moves a chat; null when the host cannot move chats (0.9.0).
  final MoveChat? onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = chats.where((c) => c.resource == selected).firstOrNull;
    final index = current == null ? -1 : chats.indexOf(current);
    final onMove = this.onMove;
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
          if (current != null && (current.movable ?? false) && onMove != null)
            PopupMenuButton<int>(
              tooltip: 'Chat actions',
              icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface),
              onSelected: (delta) => onMove(current.resource, delta),
              itemBuilder: (_) => [
                if (index > 0)
                  const PopupMenuItem(value: -1, child: Text('Move left')),
                if (index < chats.length - 1)
                  const PopupMenuItem(value: 1, child: Text('Move right')),
              ],
            ),
        ],
      ),
    );
  }
}
