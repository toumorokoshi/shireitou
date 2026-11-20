/// Client-side queue for messages sent while a host is disconnected.
///
/// Messages are held locally in order and shown in [PendingMessagesPanel]
/// with a distinct local-queue indicator until the host connects, then
/// flushed in order via `sendMessageActionsForMessage`.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import 'chat_commands.dart';
import 'timeline_items.dart';

/// A message queued locally on the client while the host is disconnected.
class ClientQueuedMessage {
  /// Creates a [ClientQueuedMessage].
  const ClientQueuedMessage({
    required this.id,
    required this.chat,
    required this.message,
    this.sendNow = false,
  });

  /// Unique ID for the turn or pending message once sent.
  final String id;

  /// The chat channel URI this message targets.
  final String chat;

  /// The composed user message (text, model, attachments).
  final Message message;

  /// Whether the user asked to stop a running turn and send immediately.
  final bool sendNow;
}

/// The [PendingMessageItem]s for [chat] from [queue], marked `clientQueued`.
List<PendingMessageItem> clientQueuedForChat(
  List<ClientQueuedMessage> queue,
  String chat,
) => [
  for (final m in queue)
    if (m.chat == chat)
      PendingMessageItem(
        PendingMessageKind.queued,
        PendingMessage(id: m.id, message: m.message),
        clientQueued: true,
      ),
];

/// Appends [message] to [queue].
List<ClientQueuedMessage> enqueueClientMessage(
  List<ClientQueuedMessage> queue,
  ClientQueuedMessage message,
) => [...queue, message];

/// Replaces the text of the message with [id] in [queue].
List<ClientQueuedMessage> editClientMessage(
  List<ClientQueuedMessage> queue,
  String id,
  String text,
) => [
  for (final m in queue)
    if (m.id == id)
      ClientQueuedMessage(
        id: m.id,
        chat: m.chat,
        message: m.message.copyWith(text: text),
        sendNow: m.sendNow,
      )
    else
      m,
];

/// Removes the message with [id] from [queue].
List<ClientQueuedMessage> removeClientMessage(
  List<ClientQueuedMessage> queue,
  String id,
) => [
  for (final m in queue)
    if (m.id != id) m,
];

/// Moves the message at [from] to [to] within [chat]'s slice of [queue]
/// ([to] counted after the removal), leaving other chats' order intact.
List<ClientQueuedMessage> reorderClientMessages(
  List<ClientQueuedMessage> queue,
  String chat,
  int from,
  int to,
) {
  final chatItems = [
    for (final m in queue)
      if (m.chat == chat) m,
  ];
  if (from == to || from < 0 || from >= chatItems.length) return queue;
  final moved = chatItems.removeAt(from);
  chatItems.insert(to.clamp(0, chatItems.length), moved);
  var i = 0;
  return [for (final m in queue) m.chat == chat ? chatItems[i++] : m];
}

/// Per-host client-side queue of messages waiting for the host to connect.
final clientQueuedMessagesProvider =
    NotifierProvider.family<
      ClientQueuedMessagesNotifier,
      List<ClientQueuedMessage>,
      String
    >(ClientQueuedMessagesNotifier.new);

/// Holds one host's locally queued messages and flushes them on connect.
class ClientQueuedMessagesNotifier extends Notifier<List<ClientQueuedMessage>> {
  /// Creates the client queue for the host with key [host].
  ClientQueuedMessagesNotifier(this.host);

  /// The host key ([SavedHost.key]).
  final String host;

  @override
  List<ClientQueuedMessage> build() {
    ref.listen(hostConnectionProvider(host), (previous, next) {
      if (next.status == ConnectionStatus.connected && state.isNotEmpty) {
        _flush(next);
      } else if (previous != null &&
          previous.status != ConnectionStatus.disconnected &&
          next.status == ConnectionStatus.disconnected) {
        clear();
      }
    });
    return const [];
  }

  /// Appends [message] to the queue.
  void enqueue(ClientQueuedMessage message) =>
      state = enqueueClientMessage(state, message);

  /// Updates the text of the queued message [id].
  void edit(String id, String text) =>
      state = editClientMessage(state, id, text);

  /// Removes the queued message [id].
  void remove(String id) => state = removeClientMessage(state, id);

  /// Reorders [chat]'s queued messages from [from] to [to].
  void reorder(String chat, int from, int to) =>
      state = reorderClientMessages(state, chat, from, to);

  /// Clears all locally queued messages.
  void clear() => state = const [];

  void _flush(HostState hostState) {
    final connection = ref.read(hostConnectionProvider(host).notifier);
    final chats = <String, ChatState>{
      for (final entry in hostState.chatChannels.entries)
        entry.key: entry.value.state,
    };
    var sent = 0;
    try {
      for (final item in state) {
        var chat =
            chats[item.chat] ??
            ChatState(
              resource: item.chat,
              title: '',
              status: SessionStatus.idle,
              modifiedAt: '',
              turns: const [],
            );
        final actions = sendMessageActionsForMessage(
          chat,
          message: item.message,
          id: item.id,
          now: clock.now(),
          sendNow: item.sendNow,
        );
        for (final action in actions) {
          connection.dispatch(item.chat, action);
          chat = reduceChatJson(chat, action);
        }
        chats[item.chat] = chat;
        sent++;
      }
    } on StateError {
      // Connection dropped mid-flush; keep the unsent messages queued.
    } finally {
      if (sent > 0) {
        state = state.sublist(sent);
      }
    }
  }
}
