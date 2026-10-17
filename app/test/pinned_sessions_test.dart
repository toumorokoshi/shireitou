/// Pinned sessions (AV-028): the pin set and its storage, ordering pinned
/// sessions and their folders first, and pinning from the row menu and
/// the session header.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_list/folder_grouping.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';
import 'package:shireitou/src/session_list/session_query.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _older = (host: 'h', session: 'pi:/a');

List<SessionSummary> get _sessions => [
  session(
    'a',
    directory: 'file:///src/app',
    title: 'Older one',
    modifiedAt: '2026-10-01T00:00:00Z',
  ),
  session(
    'b',
    directory: 'file:///src/app',
    title: 'Newer one',
    modifiedAt: '2026-10-03T00:00:00Z',
  ),
  session(
    'c',
    directory: 'file:///src/other',
    title: 'Newest elsewhere',
    modifiedAt: '2026-10-05T00:00:00Z',
  ),
];

Future<MemoryPrefsStore> _pump(
  WidgetTester tester, {
  Map<String, String> saved = const {},
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = MemoryPrefsStore(saved);
  final connection = FakeHostConnection(
    HostState(
      status: ConnectionStatus.connected,
      protocolVersion: '1.0.0',
      sessions: catalogueFromSummaries(_sessions),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...hostOverrides(connection: connection),
        prefsStoreProvider.overrideWithValue(prefs),
      ],
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('pin set', () {
    test('pins, unpins and round-trips through storage', () {
      final pins = withPinned(const {}, _older, pinned: true);
      expect(pins, {_older});
      expect(decodePinned(encodePinned(pins)), pins);
      expect(withPinned(pins, _older, pinned: false), isEmpty);
    });

    test('skips malformed storage', () {
      expect(decodePinned(null), isEmpty);
      expect(decodePinned('not json'), isEmpty);
      expect(decodePinned('{}'), isEmpty);
      expect(
        decodePinned('[{"host": "h"}, 3, {"host": "h", "session": "pi:/a"}]'),
        {_older},
      );
    });
  });

  group('ordering', () {
    final sessions = [for (final s in _sessions) HostSession('h', s)];

    test('pinned sessions come first in their folder, and their folder '
        'first in the list, for every sort', () {
      for (final sort in SessionSort.values) {
        final groups = groupHostSessions(
          sessions,
          sort: sort,
          pinned: {_older},
        );
        expect(groups.first.key, '/src/app', reason: sort.label);
        expect(groups.first.sessions.first.title, 'Older one');
      }
    });

    test('a pin on another host does not count', () {
      final groups = groupHostSessions(
        sessions,
        pinned: {(host: 'other', session: 'pi:/a')},
      );
      expect(groups.first.key, '/src/other');
      expect(groups.last.sessions.first.title, 'Newer one');
    });

    test('pinned sessions sort among themselves by the sort', () {
      final both = {_older, (host: 'h', session: 'pi:/b')};
      final groups = groupHostSessions(sessions, pinned: both);
      expect(groups.first.sessions.map((s) => s.title), [
        'Newer one',
        'Older one',
      ]);
    });
  });

  testWidgets('the row menu pins a session to the top and saves it', (
    tester,
  ) async {
    final prefs = await _pump(tester);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Newest elsewhere'), lessThan(top('Older one')));
    expect(find.byIcon(Icons.push_pin), findsNothing);

    await tester.tap(find.text('Older one'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin to top'));
    await tester.pumpAndSettle();
    expect(top('Older one'), lessThan(top('Newer one')));
    expect(top('Older one'), lessThan(top('Newest elsewhere')));
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(decodePinned(prefs.values['pinned_sessions']), {
      (host: testHost.key, session: 'pi:/a'),
    });

    await tester.longPress(find.text('Older one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpin'));
    await tester.pumpAndSettle();
    expect(top('Newest elsewhere'), lessThan(top('Older one')));
    expect(decodePinned(prefs.values['pinned_sessions']), isEmpty);
  });

  testWidgets('saved pins load on start; the header menu unpins', (
    tester,
  ) async {
    final prefs = await _pump(
      tester,
      saved: {
        'pinned_sessions': encodePinned({
          (host: testHost.key, session: 'pi:/a'),
        }),
      },
    );
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Older one'), lessThan(top('Newest elsewhere')));

    await tester.tap(find.text('Older one'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpin'));
    await tester.pumpAndSettle();
    expect(decodePinned(prefs.values['pinned_sessions']), isEmpty);
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    expect(find.text('Pin to top'), findsOneWidget);
  });
}
