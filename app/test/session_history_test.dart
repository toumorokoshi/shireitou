import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/title_bar/session_history.dart';

const _a = (host: 'h', session: 'a');
const _b = (host: 'h', session: 'b');
const _c = (host: 'h', session: 'c');

void main() {
  test('an empty history goes nowhere', () {
    expect(canGoBack(emptySessionHistory), isFalse);
    expect(canGoForward(emptySessionHistory), isFalse);
    expect(currentSession(emptySessionHistory), isNull);
    expect(steppedHistory(emptySessionHistory, -1), emptySessionHistory);
  });

  test('visiting appends and makes the session current', () {
    final history = visitedSession(visitedSession(emptySessionHistory, _a), _b);
    expect(history.entries, [_a, _b]);
    expect(currentSession(history), _b);
    expect(canGoBack(history), isTrue);
    expect(canGoForward(history), isFalse);
  });

  test('visiting the current session again changes nothing', () {
    final history = visitedSession(emptySessionHistory, _a);
    expect(visitedSession(history, _a), same(history));
  });

  test('back and forward move the index, clamped at the ends', () {
    var history = visitedSession(visitedSession(emptySessionHistory, _a), _b);
    history = steppedHistory(history, -1);
    expect(currentSession(history), _a);
    expect(canGoForward(history), isTrue);
    expect(currentSession(steppedHistory(history, -5)), _a);
    expect(currentSession(steppedHistory(history, 1)), _b);
  });

  test('visiting after going back drops the forward entries', () {
    var history = visitedSession(visitedSession(emptySessionHistory, _a), _b);
    history = visitedSession(steppedHistory(history, -1), _c);
    expect(history.entries, [_a, _c]);
    expect(canGoForward(history), isFalse);
  });

  test('the history keeps the last sessionHistoryLimit entries', () {
    var history = emptySessionHistory;
    for (var i = 0; i < sessionHistoryLimit + 5; i++) {
      history = visitedSession(history, (host: 'h', session: '$i'));
    }
    expect(history.entries, hasLength(sessionHistoryLimit));
    expect(history.entries.first, (host: 'h', session: '5'));
    expect(currentSession(history), (
      host: 'h',
      session: '${sessionHistoryLimit + 4}',
    ));
  });
}
