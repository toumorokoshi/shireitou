/// Session list logic: the Done filter (AV-022), sort (AV-026), search
/// (AV-027), the attention count and title (AV-120), next/previous
/// (AV-140), and restoring open hosts.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/desktop/app_menu.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/screens/sessions_screen.dart';
import 'package:shireitou/src/session_list/folder_grouping.dart';
import 'package:shireitou/src/session_list/session_filter.dart';
import 'package:shireitou/src/session_list/session_query.dart';
import 'package:shireitou/src/shortcuts.dart';

import 'fixtures.dart';

// Status bits: 1 idle, 2 error, 8 in progress, 24 input needed,
// 32 read, 64 archived.
const _idleRead = 33;
const _idleUnread = 1;
const _working = 40;
const _input = 56;
const _error = 34;
const _archived = 97;

void main() {
  group('filters', () {
    test('Done is idle, not failed and not archived, read or not', () {
      bool done(int bits) =>
          matchesFilter(SessionStatus(bits), SessionFilter.done);
      expect(done(_idleRead), isTrue);
      expect(done(_idleUnread), isTrue);
      expect(done(_working), isFalse);
      expect(done(_input), isFalse);
      expect(done(_error), isFalse);
      expect(done(_archived), isFalse);
    });

    test('the attention count leaves out archived and read idle sessions', () {
      expect(
        attentionCount([
          session('a', status: _idleRead),
          session('b', status: _idleUnread),
          session('c', status: _input),
          session('d', status: _error),
          session('e', status: _archived & ~32),
        ]),
        3,
      );
    });

    test('the window title carries the attention count', () {
      expect(windowTitle(0), 'shireitou');
      expect(windowTitle(3), '(3) shireitou');
    });
  });

  group('sort', () {
    final sessions = [
      session('old', modifiedAt: '2026-10-01T00:00:00Z', status: _idleRead),
      session('mid', modifiedAt: '2026-10-02T00:00:00Z', status: _error),
      session('new', modifiedAt: '2026-10-03T00:00:00Z', status: _idleUnread),
      session('ask', modifiedAt: '2026-09-01T00:00:00Z', status: _input),
    ];
    List<String> order(SessionSort sort) => [
      for (final s in [
        ...sessions,
      ]..sort((a, b) => compareSessions(sort, a, b)))
        s.resource.substring(4),
    ];

    test('most recent, oldest, and needs attention first', () {
      expect(order(SessionSort.recent), ['new', 'mid', 'old', 'ask']);
      expect(order(SessionSort.oldest), ['ask', 'old', 'mid', 'new']);
      expect(order(SessionSort.attention), ['ask', 'mid', 'new', 'old']);
    });

    test('folders follow their first session in the chosen order', () {
      final groups = groupSessionsByFolder([
        session(
          'a',
          directory: 'file:///a',
          modifiedAt: '2026-10-03T00:00:00Z',
        ),
        session(
          'b',
          directory: 'file:///b',
          modifiedAt: '2026-10-01T00:00:00Z',
        ),
      ], sort: SessionSort.oldest);
      expect(groups.map((g) => g.label), ['b', 'a']);
    });
  });

  group('search', () {
    test('parses terms, qualifiers, quotes and alternatives', () {
      final query = parseSessionQuery(
        'Login agent:pi status:input,error "fix it" when:soon',
      );
      expect(query.terms, ['login', 'fix it', 'when:soon']);
      expect(query.qualifiers, {
        'agent': ['pi'],
        'status': ['input', 'error'],
      });
      expect(parseSessionQuery('   ').isEmpty, isTrue);
    });

    HostSession hs(SessionSummary s, [String host = 'ws://h:1']) =>
        HostSession(host, s);
    bool matches(String text, HostSession s, {String? label}) =>
        matchesQuery(s, parseSessionQuery(text), hostLabel: label);

    test('terms match titles; qualifiers match agent, status, folder and '
        'host', () {
      final fix = hs(
        session(
          '1',
          title: 'Fix login bug',
          directory: 'file:///src/app',
          status: _input,
        ),
      );
      expect(matches('login', fix), isTrue);
      expect(matches('login fix', fix), isTrue);
      expect(matches('logout', fix), isFalse);
      expect(matches('agent:pi', fix), isTrue);
      expect(matches('agent:claude', fix), isFalse);
      expect(matches('status:input', fix), isTrue);
      expect(matches('status:done', fix), isFalse);
      expect(matches('status:done,input', fix), isTrue);
      expect(matches('status:bogus', fix), isFalse);
      expect(matches('repo:app', fix), isTrue);
      expect(matches('repo:other', fix), isFalse);
      expect(matches('host:laptop', fix, label: 'laptop'), isTrue);
      expect(matches('host:h:1', fix), isTrue);
      expect(matches('host:desk', fix, label: 'laptop'), isFalse);
    });
  });

  test('next and previous step through the list and stop at the ends', () {
    const a = (host: 'h', session: 'a');
    const b = (host: 'h', session: 'b');
    const c = (host: 'h', session: 'c');
    const order = [a, b, c];
    expect(steppedSession(order, null, 1), a);
    expect(steppedSession(order, null, -1), c);
    expect(steppedSession(order, a, 1), b);
    expect(steppedSession(order, c, 1), c);
    expect(steppedSession(order, a, -1), a);
    expect(steppedSession(const [], a, 1), isNull);
  });

  group('shortcuts', () {
    test('Cmd on Apple platforms, Ctrl elsewhere', () {
      expect(
        activatorFor(AppCommand.searchSessions, apple: true),
        isA<SingleActivator>()
            .having((a) => a.meta, 'meta', isTrue)
            .having((a) => a.control, 'control', isFalse),
      );
      expect(shortcutLabel(AppCommand.searchSessions, apple: false), 'Ctrl+K');
      expect(shortcutLabel(AppCommand.newSession, apple: true), '⌘N');
      expect(shortcutLabel(AppCommand.stop, apple: false), 'Ctrl+.');
      expect(shortcutLabel(AppCommand.nextSession, apple: false), 'Alt+↓');
      expect(shortcutLabel(AppCommand.toggleTerminal, apple: true), '⌥T');
      expect(shortcutLabel(AppCommand.toggleTerminal, apple: false), 'Alt+T');
      expect(shortcutLabel(AppCommand.previousSession, apple: true), '⌥↑');
      expect(
        shortcutLabel(AppCommand.toggleReviewPane, apple: false),
        'Ctrl+Alt+B',
      );
      expect(shortcutLabel(AppCommand.toggleReviewPane, apple: true), '⌥⌘B');
      expect(
        shortcutLabel(AppCommand.previousTurn, apple: false),
        'Ctrl+Alt+↑',
      );
      expect(shortcutLabel(AppCommand.nextTurn, apple: true), '⌥⌘↓');
    });

    test('the terminal toggles with Alt+T and Ctrl+`', () {
      expect(activatorsFor(AppCommand.toggleTerminal, apple: true), const [
        SingleActivator(LogicalKeyboardKey.keyT, alt: true),
        SingleActivator(LogicalKeyboardKey.backquote, control: true),
      ]);
      expect(extraActivatorsFor(AppCommand.newSession), isEmpty);
    });

    testWidgets('under a native menu bar only the extra keys are mapped', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sent = <AppCommand>[];
      container.read(appCommandsProvider).stream.listen(sent.add);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AppShortcuts(
            enabled: false,
            child: Focus(autofocus: true, child: SizedBox()),
          ),
        ),
      );
      Future<void> press(LogicalKeyboardKey modifier, LogicalKeyboardKey key) =>
          tester
              .sendKeyDownEvent(modifier)
              .then((_) => tester.sendKeyEvent(key))
              .then((_) => tester.sendKeyUpEvent(modifier));
      await press(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyT);
      expect(sent, isEmpty);
      await press(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.backquote);
      expect(sent, [AppCommand.toggleTerminal]);
    });

    test('the macOS Session menu lists every command with its key', () {
      final sent = <AppCommand>[];
      List<PlatformMenuItem> flatten(List<PlatformMenuItem> groups) => [
        for (final g in groups.whereType<PlatformMenuItemGroup>()) ...g.members,
      ];
      final items = flatten(
        sessionMenuItems(connected: true, onCommand: sent.add),
      );
      expect(
        [for (final i in items) i.label],
        [for (final c in AppCommand.values) c.label],
      );
      expect(
        (items.first.shortcut as SingleActivator).trigger,
        LogicalKeyboardKey.keyN,
      );
      items.last.onSelected!();
      expect(sent, [AppCommand.toggleTerminal]);
      final disabled = flatten(
        sessionMenuItems(connected: false, onCommand: sent.add),
      );
      expect(disabled.every((i) => i.onSelected == null), isTrue);
    });
  });

  group('open hosts', () {
    test('restores remembered hosts in order, skipping open and forgotten '
        'ones', () {
      const a = SavedHost(url: 'ws://a:1?tkn=x');
      const b = SavedHost(url: 'ws://b:1');
      const c = SavedHost(url: 'ws://c:1');
      expect(
        hostsToRestore(
          ['ws://c:1', 'ws://a:1', 'ws://gone:1', 'ws://b:1', 'ws://c:1'],
          const [a, b, c],
          open: const [b],
        ),
        [c, a],
      );
    });

    test('decodes stored keys leniently', () {
      expect(decodeHostKeys('["ws://a:1", 3, ""]'), ['ws://a:1']);
      expect(decodeHostKeys('{'), isEmpty);
      expect(decodeHostKeys(null), isEmpty);
    });
  });
}
