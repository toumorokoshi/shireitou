import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/timeline_items.dart';
import 'package:shireitou/src/session_detail/turn_markers.dart';

import 'fixtures.dart';

TurnMarker _marker(int row) => TurnMarker(
  turnId: 't$row',
  text: 'turn $row',
  state: TurnMarkerState.done,
  row: row,
);

void main() {
  test('firstLine skips blank lines, trims and shortens', () {
    expect(firstLine('\n  Fix the tests  \nthen push'), 'Fix the tests');
    expect(firstLine(''), '');
    expect(firstLine('abcdef', max: 4), 'abc…');
  });

  test('turnMarkers lists each turn with its message row and state', () {
    final chat = chatFixture().copyWith(
      turnsNextCursor: 'c1',
      turns: [
        ...chatFixture().turns,
        Turn(
          id: 'turn-x',
          message: userMessage('Break it\nplease'),
          state: TurnState.error,
          responseParts: const [],
        ),
      ],
    );
    final rows = timelineItems(chat);
    final markers = turnMarkers(chat, rows);
    expect(
      [for (final m in markers) (m.turnId, m.text, m.state)],
      [
        ('turn-1', 'List the files', TurnMarkerState.done),
        ('turn-x', 'Break it', TurnMarkerState.error),
        ('turn-2', 'Delete it', TurnMarkerState.running),
      ],
    );
    for (final m in markers) {
      expect(rows[m.row], isA<UserMessageItem>());
      expect((rows[m.row] as UserMessageItem).turnId, m.turnId);
    }
    // Row 0 is the "load older" row.
    expect(markers.first.row, 1);
    expect(turnMarkerLabel(markers, 0), 'Turn 1: List the files');
    expect(turnMarkerLabel(markers, 1), 'Turn 2: Break it (failed)');
    expect(turnMarkerLabel(markers, 2), 'Turn 3: Delete it (running)');
  });

  test('currentTurn is the newest turn starting at or above the top', () {
    final markers = [_marker(1), _marker(5), _marker(9)];
    expect(currentTurn(const [], 3), isNull);
    expect(currentTurn(markers, 0), 0);
    expect(currentTurn(markers, 4), 0);
    expect(currentTurn(markers, 5), 1);
    expect(currentTurn(markers, 20), 2);
  });

  test('steppedTurn goes to the turn above or below the top row', () {
    final markers = [_marker(1), _marker(5), _marker(9)];
    // At a message, back goes to the turn before it.
    expect(steppedTurn(markers, 5, -1), 0);
    // Inside a turn, back goes to its own message.
    expect(steppedTurn(markers, 7, -1), 1);
    expect(steppedTurn(markers, 5, 1), 2);
    expect(steppedTurn(markers, 1, -1), isNull);
    expect(steppedTurn(markers, 9, 1), isNull);
  });

  test('turnRailLayout spreads, compresses, then scrolls', () {
    expect(turnRailLayout(0, 100), (spacing: 24.0, scrolls: false));
    expect(turnRailLayout(2, 400), (spacing: 24.0, scrolls: false));
    expect(turnRailLayout(20, 200), (spacing: 10.0, scrolls: false));
    expect(turnRailLayout(100, 200), (spacing: 4.0, scrolls: true));
  });

  test('turnAtOffset and turnRailScrollOffset', () {
    expect(turnAtOffset(-5, 10, 4), 0);
    expect(turnAtOffset(25, 10, 4), 2);
    expect(turnAtOffset(500, 10, 4), 3);
    expect(turnRailScrollOffset(3, 4, 10, 100), 0);
    expect(turnRailScrollOffset(50, 100, 4, 100), 152);
    expect(turnRailScrollOffset(99, 100, 4, 100), 300);
  });
}
