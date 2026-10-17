/// The session list's Done filter, search and sort, row menu, hover
/// buttons and card, swipe and multi-select (AV-022 to AV-029, AV-092,
/// AV-093), the attention count (AV-120), the
/// keyboard shortcuts (AV-140), the "Waiting for you" panel's answered
/// entries, client tool executions, and restoring open hosts.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_detail/session_status_widgets.dart';
import 'package:shireitou/src/session_list/session_list_view.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

HostState _connected({
  SessionState? sessionState,
  List<SessionSummary>? list,
}) => HostState(
  status: ConnectionStatus.connected,
  protocolVersion: '1.0.0',
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  sessions: catalogueFromSummaries(
    list ??
        [
          session(
            '1',
            directory: 'file:///src/app',
            title: 'Fix login',
            status: 24,
          ),
          session(
            '2',
            directory: 'file:///src/app-worktrees/fix-login',
            title: 'Explain',
          ),
          session('3', directory: 'file:///src/old', title: 'Old', status: 97),
        ],
  ),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(chatFixture())},
  sessionChannels: {
    if (sessionState != null) 'pi:/1': ChannelMirror.snapshot(sessionState),
  },
);

Future<FakeHostConnection> _pump(
  WidgetTester tester,
  HostState state, {
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: hostOverrides(connection: connection),
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  return connection;
}

Finder get _search => find.byWidgetPredicate(
  (w) => w is TextField && (w.decoration?.hintText ?? '').startsWith('Search'),
);

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  LogicalKeyboardKey modifier = LogicalKeyboardKey.controlLeft,
}) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('the Done filter, search, sort and the attention count', (
    tester,
  ) async {
    await _pump(tester, _connected());
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      '(1) shireitou',
    );
    // The filter menu checks the current filter and counts attention.
    await tester.tap(find.byTooltip('Filter and sort'));
    await tester.pumpAndSettle();
    expect(find.text('Needs attention (1)'), findsOneWidget);
    expect(
      tester
          .widget<CheckedPopupMenuItem<Object>>(
            find.widgetWithText(CheckedPopupMenuItem<Object>, 'Active'),
          )
          .checked,
      isTrue,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Explain'), findsOneWidget);
    expect(find.text('Fix login'), findsNothing);

    await pickFilter(tester, 'All');
    expect(_search, findsNothing);
    await openSearch(tester);
    await tester.enterText(_search, 'fix');
    await tester.pumpAndSettle();
    expect(find.text('Fix login'), findsOneWidget);
    expect(find.text('Explain'), findsNothing);
    await tester.enterText(_search, 'status:archived');
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('Fix login'), findsNothing);
    await tester.enterText(_search, 'nothing like this');
    await tester.pumpAndSettle();
    expect(find.text('No sessions match.'), findsOneWidget);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.text('Fix login'), findsOneWidget);
    expect(_search, findsNothing);
  });

  testWidgets('sorting reorders the sessions of a folder', (tester) async {
    await _pump(
      tester,
      _connected(
        list: [
          session(
            'a',
            directory: 'file:///src/app',
            title: 'Older one',
            modifiedAt: '2026-10-01T00:00:00Z',
            status: 24,
          ),
          session(
            'b',
            directory: 'file:///src/app',
            title: 'Newer one',
            modifiedAt: '2026-10-03T00:00:00Z',
          ),
        ],
      ),
    );
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Newer one'), lessThan(top('Older one')));
    await pickFilter(tester, 'Oldest');
    expect(top('Older one'), lessThan(top('Newer one')));
    await pickFilter(tester, 'Needs attention first');
    expect(top('Older one'), lessThan(top('Newer one')));
  });

  testWidgets('the row menu, swipe and multi-select archive and mark read', (
    tester,
  ) async {
    final connection = await _pump(tester, _connected());
    JsonMap last(String channel) =>
        connection.dispatched.lastWhere((d) => d.$1 == channel).$2;

    // Right-click menu.
    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(last('pi:/2'), {
      'type': 'session/isArchivedChanged',
      'isArchived': true,
    });

    // Long-press menu.
    await tester.longPress(find.text('Fix login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();
    expect(last('pi:/1'), {'type': 'session/isReadChanged', 'isRead': true});

    // Swipe to archive; the row stays until the host agrees.
    final before = connection.dispatched.length;
    await tester.drag(find.text('Fix login'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(connection.dispatched.length, before + 1);
    expect(last('pi:/1')['type'], 'session/isArchivedChanged');
    expect(find.text('Fix login'), findsOneWidget);

    // A rejected list action is reported.
    connection.failureController.add(
      ActionFailure(
        channel: 'pi:/1',
        clientSeq: connection.dispatched.length,
        action: last('pi:/1'),
        kind: ActionFailureKind.rejected,
        reason: 'no',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('rejected'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .clearSnackBars();
    await tester.pumpAndSettle();

    // Multi-select, then mark both unread.
    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Mark unread'));
    await tester.pumpAndSettle();
    expect(last('pi:/1'), {'type': 'session/isReadChanged', 'isRead': false});
    expect(last('pi:/2'), {'type': 'session/isReadChanged', 'isRead': false});
    expect(find.text('2 selected'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    // Picking a session no longer opens it.
    expect(find.text('Select a session'), findsOneWidget);
  });

  testWidgets('sessions with no folder are listed under Chats, above the '
      'folders', (tester) async {
    await _pump(
      tester,
      _connected(
        list: [
          session('1', directory: 'file:///src/app', title: 'In a folder'),
          session('2', title: 'A chat'),
        ],
      ),
    );
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Chats'), lessThan(top('A chat')));
    expect(top('A chat'), lessThan(top('app')));
    expect(top('app'), lessThan(top('In a folder')));
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(find.text('A chat'), findsNothing);
  });

  testWidgets('hovering a row shows "Mark as done", with Undo, and then '
      'its card', (tester) async {
    final connection = await _pump(tester, _connected());
    JsonMap last(String channel) =>
        connection.dispatched.lastWhere((d) => d.$1 == channel).$2;
    expect(find.byTooltip(markDoneLabel), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Explain')));
    await tester.pump();
    expect(find.byTooltip('Pin to top'), findsOneWidget);
    // The card shows after the pointer rests on the row.
    await tester.pump(hoverCardDelay + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Workspace · /src/app-worktrees/fix-login',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Explain · pi · fix-login', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(markDoneLabel));
    await tester.pumpAndSettle();
    expect(last('pi:/2'), {
      'type': 'session/isArchivedChanged',
      'isArchived': true,
    });
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(last('pi:/2'), {
      'type': 'session/isArchivedChanged',
      'isArchived': false,
    });
    await mouse.removePointer();
  });

  testWidgets('"Select" in the "…" menu starts multi-select', (tester) async {
    await _pump(tester, _connected());
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('keyboard shortcuts search, step through sessions, focus the '
      'composer, stop and start a session', (tester) async {
    final connection = await _pump(tester, _connected());
    await _press(tester, LogicalKeyboardKey.keyK);
    expect(tester.widget<TextField>(_search).focusNode!.hasFocus, isTrue);

    // Alt+↓ opens the first session, then the next.
    await _press(
      tester,
      LogicalKeyboardKey.arrowDown,
      modifier: LogicalKeyboardKey.altLeft,
    );
    final first = tester.widget<SessionDetailView>(
      find.byType(SessionDetailView),
    );
    await _press(
      tester,
      LogicalKeyboardKey.arrowDown,
      modifier: LogicalKeyboardKey.altLeft,
    );
    final second = tester.widget<SessionDetailView>(
      find.byType(SessionDetailView),
    );
    expect(second.session, isNot(first.session));
    await _press(
      tester,
      LogicalKeyboardKey.arrowUp,
      modifier: LogicalKeyboardKey.altLeft,
    );
    expect(
      tester.widget<SessionDetailView>(find.byType(SessionDetailView)).session,
      first.session,
    );
    if (first.session != 'pi:/1') {
      await tester.tap(find.text('Fix login'));
      await tester.pumpAndSettle();
    }

    await _press(tester, LogicalKeyboardKey.keyL);
    final composer = find.descendant(
      of: find.byType(FollowUpInput),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(composer).focusNode!.hasFocus, isTrue);

    await _press(tester, LogicalKeyboardKey.period);
    expect(connection.dispatched.last.$1, 'ahp-chat:/1');
    expect(connection.dispatched.last.$2['type'], 'chat/turnCancelled');

    await _press(tester, LogicalKeyboardKey.keyN);
    expect(find.byTooltip('Start session'), findsOneWidget);
    // Cmd/Ctrl+L focuses the draft's prompt too.
    final prompt = find.widgetWithText(TextField, 'Prompt');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await _press(tester, LogicalKeyboardKey.keyL);
    expect(tester.widget<TextField>(prompt).focusNode!.hasFocus, isTrue);
  });

  testWidgets('a compact layout steps through sessions page by page', (
    tester,
  ) async {
    await _pump(tester, _connected(), size: const Size(500, 900));
    await _press(
      tester,
      LogicalKeyboardKey.arrowDown,
      modifier: LogicalKeyboardKey.altLeft,
    );
    expect(find.byType(SessionDetailView), findsOneWidget);
    final first = tester
        .widget<SessionDetailView>(find.byType(SessionDetailView))
        .session;
    await _press(
      tester,
      LogicalKeyboardKey.arrowDown,
      modifier: LogicalKeyboardKey.altLeft,
    );
    expect(find.byType(SessionDetailView), findsOneWidget);
    expect(
      tester.widget<SessionDetailView>(find.byType(SessionDetailView)).session,
      isNot(first),
    );
    // One page back reaches the list.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SessionDetailView), findsNothing);
    expect(find.text('Explain'), findsOneWidget);
  });

  group('"Waiting for you" answers', () {
    Future<FakeHostConnection> answer(WidgetTester tester) async {
      final connection = await _pump(
        tester,
        _connected(sessionState: sessionWithRequests()),
      );
      await tester.tap(find.text('Fix login'));
      await tester.pumpAndSettle();
      final panel = find.byType(SessionInputPanel);
      await tester.tap(
        find.descendant(of: panel, matching: find.text('Submit')),
      );
      await tester.pumpAndSettle();
      return connection;
    }

    testWidgets('an answered request is hidden, and shown again when the '
        'host rejects the answer', (tester) async {
      final connection = await answer(tester);
      expect(find.byType(SessionInputPanel), findsNothing);
      final (channel, action) = connection.dispatched.last;
      expect(channel, 'ahp-chat:/side');
      connection.failureController.add(
        ActionFailure(
          channel: channel,
          clientSeq: connection.dispatched.length,
          action: action,
          kind: ActionFailureKind.rejected,
          reason: 'already answered elsewhere',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SessionInputPanel), findsOneWidget);
      expect(find.textContaining('already answered elsewhere'), findsOneWidget);
    });

    testWidgets('an answer the host never confirms is shown again', (
      tester,
    ) async {
      await answer(tester);
      expect(find.byType(SessionInputPanel), findsNothing);
      await tester.pump(answerConfirmTimeout + const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(SessionInputPanel), findsOneWidget);
      expect(
        find.textContaining('did not confirm your answer'),
        findsOneWidget,
      );
    });

    testWidgets('an answer the host removed stays gone', (tester) async {
      final connection = await answer(tester);
      final resolved = sessionWithRequests().copyWith(
        inputNeeded: [sessionWithRequests().inputNeeded!.first],
      );
      connection.state = connection.state.copyWith(
        sessionChannels: {'pi:/1': ChannelMirror.snapshot(resolved)},
      );
      await tester.pump(answerConfirmTimeout + const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(SessionInputPanel), findsNothing);
      expect(find.textContaining('did not confirm'), findsNothing);
    });
  });

  testWidgets('client tool executions: another client\'s is shown as '
      'running elsewhere; one delegated to this client is turned down '
      'once', (tester) async {
    final connection = await _pump(
      tester,
      _connected(
        sessionState: sessionWithExecutions([testClientId, 'fake-ide']),
      ),
    );
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('1 tool running on another client'), findsOneWidget);
    expect(find.text('Waiting for you (1)'), findsOneWidget);
    final completes = connection.dispatched
        .where((d) => d.$2['type'] == 'chat/toolCallComplete')
        .toList();
    expect(completes, hasLength(1));
    expect(completes.single.$2['toolCallId'], 'call-exec-0');
    expect((completes.single.$2['result']! as JsonMap)['success'], isFalse);
    // Rebuilding does not turn it down again.
    connection.state = connection.state.copyWith(protocolVersion: '1.0.0');
    await tester.pumpAndSettle();
    expect(
      connection.dispatched.where(
        (d) => d.$2['type'] == 'chat/toolCallComplete',
      ),
      hasLength(1),
    );
  });

  group('open hosts', () {
    const other = SavedHost(url: 'ws://10.0.0.2:2', name: 'build box');
    late Map<String, FakeHostConnection> connections;

    Future<ProviderContainer> pumpRestoring(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      connections = {
        testHost.key: FakeHostConnection(
          const HostState(),
          connectResult: _connected(),
        ),
        other.key: FakeHostConnection(
          const HostState(),
          host: other.key,
          connectResult: const HostState(
            status: ConnectionStatus.failed,
            error: 'Connection refused',
          ),
        ),
      };
      final container = ProviderContainer(
        overrides: [
          hostConnectionProvider.overrideWith2(
            (key) => connections[key] ?? FakeHostConnection(const HostState()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ShireitouApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('the hosts open at the last run are reconnected; one that '
        'fails stays listed with Retry', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'hosts': encodeHosts(const [testHost, other]),
        'open_hosts': jsonEncode([testHost.key, other.key]),
      });
      final container = await pumpRestoring(tester);
      expect(connections[testHost.key]!.connected, [testHost.url]);
      expect(connections[other.key]!.connected, [other.url]);
      expect(find.text('Fix login'), findsOneWidget);
      expect(container.read(openHostsProvider).map((h) => h.key), [
        testHost.key,
        other.key,
      ]);

      // The "…" menu has a dot while a host is not connected, and lists
      // the host's error with Retry and Remove.
      await tester.tap(
        find.byTooltip('More actions (a host is not connected)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('build box · Connection refused'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry build box'));
      await tester.pumpAndSettle();
      expect(connections[other.key]!.connected, [other.url, other.url]);

      await tester.tap(
        find.byTooltip('More actions (a host is not connected)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('build box · Connection refused'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove build box'));
      await tester.pumpAndSettle();
      expect(container.read(openHostsProvider).map((h) => h.key), [
        testHost.key,
      ]);
      final stored = await const FlutterSecureStorage().read(key: 'open_hosts');
      expect(decodeHostKeys(stored), [testHost.key]);
    });

    testWidgets('when every restored host fails, the connect screen lists '
        'them with their errors', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'hosts': encodeHosts(const [other]),
        'open_hosts': jsonEncode([other.key]),
      });
      await pumpRestoring(tester);
      expect(find.text('Connect to a host'), findsOneWidget);
      expect(find.textContaining('Connection refused'), findsOneWidget);
      // Tapping it retries.
      await tester.tap(find.widgetWithText(ListTile, 'build box'));
      await tester.pumpAndSettle();
      expect(connections[other.key]!.connected, hasLength(2));
    });

    testWidgets('a host that never connected is dropped when it fails', (
      tester,
    ) async {
      final container = await pumpRestoring(tester);
      await container.read(openHostsProvider.notifier).connect(other);
      await tester.pumpAndSettle();
      expect(container.read(openHostsProvider), isEmpty);
      final stored = await const FlutterSecureStorage().read(key: 'open_hosts');
      expect(decodeHostKeys(stored), isEmpty);
    });
  });
}
