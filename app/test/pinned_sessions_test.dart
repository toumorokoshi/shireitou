/// Pinned sessions (AV-028): the pin set and its storage, the "Pinned"
/// section at the top of the sidebar, and pinning from the row menu and
/// the session header.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_list/folder_order.dart';
import 'package:shireitou/src/session_list/pinned_sessions.dart';
import 'package:shireitou/src/session_list/session_tree.dart';

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

    test('keeps the order pinned in, through storage', () {
      const newer = (host: 'h', session: 'pi:/b');
      final pins = withPinned(
        withPinned(const {}, newer, pinned: true),
        _older,
        pinned: true,
      );
      expect([...decodePinned(encodePinned(pins))], [newer, _older]);
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

  group('splitPinned', () {
    final sessions = [for (final s in _sessions) HostSession('h', s)];

    test('takes pinned sessions out, in the order pinned', () {
      final (:pinned, :rest) = splitPinned({
        (host: 'h', session: 'pi:/c'),
        _older,
      }, sessions);
      expect(
        [for (final s in pinned) s.summary.title],
        ['Newest elsewhere', 'Older one'],
      );
      expect([for (final s in rest) s.summary.title], ['Newer one']);
    });

    test('skips pins of sessions not listed, or on another host', () {
      final (:pinned, :rest) = splitPinned({
        (host: 'other', session: 'pi:/a'),
        (host: 'h', session: 'pi:/gone'),
      }, sessions);
      expect(pinned, isEmpty);
      expect(rest, hasLength(3));
    });
  });

  testWidgets('the row menu moves a session into the Pinned section at '
      'the top, and saves it', (tester) async {
    final prefs = await _pump(tester);
    double top(Finder finder) => tester.getTopLeft(finder).dy;
    expect(find.text('Pinned'), findsNothing);
    expect(find.byIcon(Icons.push_pin), findsNothing);

    await tester.tap(find.text('Older one'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin to top'));
    await tester.pumpAndSettle();
    // Above every host and folder, listed once, with its folder's name.
    expect(top(find.text('Pinned')), lessThan(top(find.text('Older one'))));
    expect(top(find.text('Older one')), lessThan(top(find.text('other'))));
    expect(top(find.text('Older one')), lessThan(top(find.text('app'))));
    expect(find.text('Older one'), findsOneWidget);
    expect(find.textContaining('app · pi'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(decodePinned(prefs.values['pinned_sessions']), {
      (host: testHost.key, session: 'pi:/a'),
    });

    await tester.longPress(find.text('Older one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpin'));
    await tester.pumpAndSettle();
    expect(find.text('Pinned'), findsNothing);
    expect(
      top(find.text('Newest elsewhere')),
      lessThan(top(find.text('Older one'))),
    );
    expect(decodePinned(prefs.values['pinned_sessions']), isEmpty);
  });

  testWidgets('the Pinned section collapses, follows the search, and comes '
      'first for next session', (tester) async {
    reduceMotion(tester);
    final prefs = await _pump(
      tester,
      saved: {
        'pinned_sessions': encodePinned({
          (host: testHost.key, session: 'pi:/a'),
        }),
      },
    );
    await tester.tap(find.text('Pinned'));
    await tester.pumpAndSettle();
    expect(find.text('Older one'), findsNothing);
    expect(decodeIds(prefs.values['sidebar_collapsed']), [pinnedNodeId]);

    // Next session opens the pinned one first and expands the section.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SessionDetailView>(find.byType(SessionDetailView)).session,
      'pi:/a',
    );
    expect(decodeIds(prefs.values['sidebar_collapsed']), isEmpty);

    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText ?? '').startsWith('Search'),
      ),
      'newest',
    );
    await tester.pumpAndSettle();
    expect(find.text('Pinned'), findsNothing);
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
    expect(top('Pinned'), lessThan(top('Older one')));
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
