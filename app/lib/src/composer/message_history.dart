/// Pure helpers behind recalling earlier messages with ↑ and ↓ in the
/// follow-up box (AV-087): the chat's sent messages and the steps through
/// them.
library;

import 'package:ahp_client/ahp_client.dart';

/// The texts of the messages the user sent in [chat], oldest first: each
/// turn's message, then the running turn's. Blank messages are left out,
/// and a message repeated back to back is listed once.
List<String> sentMessages(ChatState chat) {
  final texts = [
    for (final turn in chat.turns) turn.message.text,
    ?chat.activeTurn?.message.text,
  ].where((t) => t.trim().isNotEmpty).toList();
  return [
    for (final (i, text) in texts.indexed)
      if (i == 0 || texts[i - 1] != text) text,
  ];
}

/// The index of the message ↑ recalls from a history [length] long, when
/// [index] is recalled now (null when nothing is): the one before it, or
/// the newest when nothing is recalled. Null when there is no history; the
/// oldest stays recalled.
int? olderIndex(int length, int? index) => switch ((length, index)) {
  (0, _) => null,
  (_, null) => length - 1,
  (_, final i?) => i > 0 ? i - 1 : 0,
};

/// The index of the message ↓ recalls after [index] in a history [length]
/// long; null past the newest, which empties the box again.
int? newerIndex(int length, int index) => index + 1 < length ? index + 1 : null;

/// Whether a caret at [offset] in [text] is on its first line, where ↑
/// leaves the text instead of moving the caret.
bool caretOnFirstLine(String text, int offset) =>
    !text.substring(0, offset.clamp(0, text.length)).contains('\n');

/// Whether a caret at [offset] in [text] is on its last line, where ↓
/// leaves the text instead of moving the caret.
bool caretOnLastLine(String text, int offset) =>
    !text.substring(offset.clamp(0, text.length)).contains('\n');
