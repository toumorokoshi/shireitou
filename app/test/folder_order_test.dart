/// Reordering the sidebar's workspace folders: the pure order functions,
/// dragging a folder row, "Move up" and "Move down", and keeping the
/// order and the collapsed hosts and folders across restarts.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_list/folder_grouping.dart';
import 'package:shireitou/src/session_list/folder_order.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

List<SessionSummary> get _sessions => [
  session('a', directory: 'file:///src/a', modifiedAt: '2026-10-03T00:00:00Z'),
  session('b', directory: 'file:///src/b', modifiedAt: '2026-10-02T00:00:00Z'),
  session('c', directory: 'file:///src/c', modifiedAt: '2026-10-01T00:00:00Z'),
];

final _groups = groupHostSessions([
  for (final s in _sessions) HostSession('h', s),
  HostSession(
    'x',
    session(
      'd',
      directory: 'file:///src/d',
      modifiedAt: '2026-09-01T00:00:00Z',
    ),
  ),
]);

List<String> _paths(List<FolderGroup> groups) => [
  for (final g in groups) g.path,
];

String _id(String host, String path) => '$host|$path';

Future<MemoryPrefsStore> _pump(
  WidgetTester tester, {
  Map<String, String> saved = const {},
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
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

/// The folder labels in the sidebar, top to bottom.
List<String> _shown(WidgetTester tester) {
  final labels = ['a', 'b', 'c'];
  return labels..sort(
    (x, y) => tester
        .getTopLeft(find.text(x))
        .dy
        .compareTo(tester.getTopLeft(find.text(y)).dy),
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('orderFolders', () {
    test('puts placed folders first in their order, then the rest', () {
      expect(_paths(orderFolders(_groups, const [])), [
        '/src/a',
        '/src/b',
        '/src/c',
        '/src/d',
      ]);
      expect(
        _paths(orderFolders(_groups, [_id('h', '/src/c'), _id('h', '/src/b')])),
        ['/src/c', '/src/b', '/src/a', '/src/d'],
      );
    });

    test('ignores ids of folders that are not shown', () {
      expect(_paths(orderFolders(_groups, ['gone|/x', _id('h', '/src/b')])), [
        '/src/b',
        '/src/a',
        '/src/c',
        '/src/d',
      ]);
    });
  });

  group('movedFolder', () {
    final host = orderFolders(
      _groups,
      const [],
    ).where((g) => g.host == 'h').toList();

    test('places every shown folder of the host, in the new order', () {
      expect(movedFolder(const [], host, 2, 0), [
        _id('h', '/src/c'),
        _id('h', '/src/a'),
        _id('h', '/src/b'),
      ]);
      expect(movedFolder(const [], host, 0, 1), [
        _id('h', '/src/b'),
        _id('h', '/src/a'),
        _id('h', '/src/c'),
      ]);
    });

    test('keeps the places of folders that are not shown', () {
      final order = [_id('h', '/src/b'), 'x|/src/d', 'h|/gone'];
      final shown = orderFolders(host, order);
      expect(_paths(shown), ['/src/b', '/src/a', '/src/c']);
      expect(movedFolder(order, shown, 2, 0), [
        _id('h', '/src/c'),
        'x|/src/d',
        'h|/gone',
        _id('h', '/src/b'),
        _id('h', '/src/a'),
      ]);
    });

    test('leaves the order alone for a move out of range or in place', () {
      final order = [_id('h', '/src/b')];
      expect(movedFolder(order, host, 1, 1), same(order));
      expect(movedFolder(order, host, 0, 3), same(order));
      expect(movedFolder(order, host, -1, 0), same(order));
    });
  });

  test('ids round-trip and malformed storage is skipped', () {
    expect(decodeIds(encodeIds(['a', 'b'])), ['a', 'b']);
    expect(decodeIds(null), isEmpty);
    expect(decodeIds('not json'), isEmpty);
    expect(decodeIds('{}'), isEmpty);
    expect(decodeIds('["a", 3, "a", "b"]'), ['a', 'b']);
  });

  testWidgets('dragging a folder row moves it and saves the order', (
    tester,
  ) async {
    final prefs = await _pump(tester);
    expect(_shown(tester), ['a', 'b', 'c']);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('c')),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('b')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('a')));
    await tester.pump();
    final indicator = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border! as Border).top.width == 2,
    );
    expect(indicator, findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_shown(tester), ['c', 'a', 'b']);
    expect(decodeIds(prefs.values['folder_order']), [
      _id(testHost.key, '/src/c'),
      _id(testHost.key, '/src/a'),
      _id(testHost.key, '/src/b'),
    ]);
  });

  testWidgets('a long press drags a folder on compact layouts', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    final gesture = await tester.startGesture(tester.getCenter(find.text('a')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.text('b')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('c')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_shown(tester), ['b', 'c', 'a']);
  });

  testWidgets('the menu and screen reader actions move a folder', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final prefs = await _pump(tester);

    await tester.tap(find.text('a'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Move up'), findsNothing);
    await tester.tap(find.text('Move down'));
    await tester.pumpAndSettle();
    expect(_shown(tester), ['b', 'a', 'c']);

    // The handle shows on hover and opens the same menu.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('c')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move c'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move up'));
    await tester.pumpAndSettle();
    expect(_shown(tester), ['b', 'c', 'a']);
    await mouse.removePointer();

    final moveDown = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: 'Move down'),
    );
    final node = find.semantics
        .byPredicate(
          (n) =>
              n.label.contains('/src/b') &&
              (n.getSemanticsData().customSemanticsActionIds?.contains(
                    moveDown,
                  ) ??
                  false),
        )
        .evaluate()
        .single;
    node.owner!.performAction(node.id, SemanticsAction.customAction, moveDown);
    await tester.pumpAndSettle();
    expect(_shown(tester), ['c', 'b', 'a']);
    expect(decodeIds(prefs.values['folder_order']), hasLength(3));
    semantics.dispose();
  });

  testWidgets('the folder order and collapsed folders load on start', (
    tester,
  ) async {
    final prefs = await _pump(
      tester,
      saved: {
        'folder_order': encodeIds([_id(testHost.key, '/src/b')]),
        'sidebar_collapsed': encodeIds([_id(testHost.key, '/src/c')]),
      },
    );
    // The placed folder comes before the more recent one.
    expect(_shown(tester), ['b', 'a', 'c']);
    expect(find.text('session c'), findsNothing);

    await tester.tap(find.text('c'));
    await tester.pumpAndSettle();
    expect(find.text('session c'), findsOneWidget);
    expect(decodeIds(prefs.values['sidebar_collapsed']), isEmpty);
    await tester.tap(find.text('a'));
    await tester.pumpAndSettle();
    expect(decodeIds(prefs.values['sidebar_collapsed']), [
      _id(testHost.key, '/src/a'),
    ]);
  });
}
