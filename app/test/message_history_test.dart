/// Tests for the pure helpers behind ↑ and ↓ in the follow-up box
/// (AV-087).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/message_history.dart';

Turn _turn(String id, String text) => Turn(
  id: id,
  message: userMessage(text),
  responseParts: const [],
  state: TurnState.complete,
);

void main() {
  test('sent messages are listed oldest first, running turn last', () {
    final chat = ChatState(
      resource: 'ahp-chat:/1',
      title: 'Chat',
      status: SessionStatus.idle,
      modifiedAt: '2026-10-18T00:00:00Z',
      turns: [
        _turn('t1', 'first'),
        _turn('t2', '  '),
        _turn('t3', 'again'),
        _turn('t4', 'again'),
      ],
      activeTurn: ActiveTurn(
        id: 't5',
        startedAt: '2026-10-18T00:00:00Z',
        message: userMessage('now'),
        responseParts: const [],
      ),
    );
    expect(sentMessages(chat), ['first', 'again', 'now']);
  });

  test('↑ steps back to the oldest and stays there', () {
    expect(olderIndex(0, null), isNull);
    expect(olderIndex(3, null), 2);
    expect(olderIndex(3, 2), 1);
    expect(olderIndex(3, 0), 0);
  });

  test('↓ steps forward and empties the box past the newest', () {
    expect(newerIndex(3, 0), 1);
    expect(newerIndex(3, 2), isNull);
  });

  test('the caret is on the first or last line', () {
    expect(caretOnFirstLine('', 0), isTrue);
    expect(caretOnFirstLine('a\nb', 1), isTrue);
    expect(caretOnFirstLine('a\nb', 2), isFalse);
    expect(caretOnLastLine('a\nb', 2), isTrue);
    expect(caretOnLastLine('a\nb', 1), isFalse);
  });
}
