import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_detail/session_status_widgets.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

Future<FakeHostConnection> _pump(
  WidgetTester tester,
  HostState state,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hostConnectionProvider.overrideWith(() => connection)],
      child: const ShireitouApp(),
    ),
  );
  return connection;
}

HostState connected({ChatState? chat, SessionState? sessionState}) => HostState(
  status: ConnectionStatus.connected,
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  sessions: catalogueFromSummaries([
    session('1', directory: 'file:///src/app', title: 'Fix login', status: 24),
    session(
      '2',
      directory: 'file:///src/app-worktrees/fix-login',
      title: 'Explain',
    ),
    session('3', directory: 'file:///src/old', title: 'Old', status: 97),
  ]),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(chat ?? chatFixture())},
  sessionChannels: {
    if (sessionState != null) 'pi:/1': ChannelMirror.snapshot(sessionState),
  },
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('shows the connect screen when disconnected', (tester) async {
    await _pump(tester, const HostState(), const Size(800, 900));
    expect(find.text('Connect to a host'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
  });

  testWidgets('prefills the last host from secure storage', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'last_host_url': 'ws://127.0.0.1:1234?tkn=abc',
      'last_host_token': '',
    });
    await _pump(tester, const HostState(), const Size(800, 900));
    await tester.pumpAndSettle();
    expect(find.text('ws://127.0.0.1:1234?tkn=abc'), findsOneWidget);
  });

  testWidgets('lists remembered hosts without their tokens', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'hosts': encodeHosts(const [
        SavedHost(url: 'ws://127.0.0.1:1?tkn=secret', name: 'laptop'),
        SavedHost(url: 'ws://10.0.0.2:2?tkn=other'),
      ]),
    });
    await _pump(tester, const HostState(), const Size(800, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Recent hosts'), findsOneWidget);
    expect(find.text('laptop'), findsWidgets);
    expect(find.text('ws://10.0.0.2:2'), findsOneWidget);
    expect(find.textContaining('other'), findsNothing);
    // The most recent host is prefilled.
    expect(find.text('ws://127.0.0.1:1?tkn=secret'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit ws://10.0.0.2:2'));
    await tester.pump();
    expect(find.text('ws://10.0.0.2:2?tkn=other'), findsOneWidget);

    await tester.tap(find.byTooltip('Forget ws://10.0.0.2:2'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Forget ws://10.0.0.2:2'), findsNothing);
    final stored = await const FlutterSecureStorage().read(key: 'hosts');
    expect(decodeHosts(stored).map((h) => h.label), ['laptop']);
  });

  testWidgets('macOS shows a native menu bar', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await _pump(tester, const HostState(), const Size(800, 900));
    expect(find.byType(PlatformMenuBar), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows a connection error', (tester) async {
    await _pump(
      tester,
      const HostState(status: ConnectionStatus.failed, error: 'boom'),
      const Size(800, 900),
    );
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('wide layout shows folders, badges and three panes', (
    tester,
  ) async {
    await _pump(tester, connected(), const Size(1400, 900));
    expect(find.text('app'), findsOneWidget);
    expect(find.text('fix-login'), findsOneWidget);
    expect(find.text('Needs input'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Select a session'), findsOneWidget);
  });

  testWidgets('archived sessions are hidden until the Archived filter', (
    tester,
  ) async {
    await _pump(tester, connected(), const Size(1400, 900));
    expect(find.text('Old'), findsNothing);
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('Explain'), findsNothing);
  });

  testWidgets('opening a session shows the timeline and marks it read', (
    tester,
  ) async {
    final connection = await _pump(tester, connected(), const Size(1400, 900));
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();

    expect(find.text('List the files'), findsOneWidget);
    expect(find.text('Thinking'), findsOneWidget);
    expect(find.text('I should run ls.'), findsNothing);
    expect(find.text('Ran `ls`'), findsOneWidget);
    expect(find.textContaining('one'), findsWidgets);
    expect(find.textContaining('1,200 in'), findsOneWidget);
    expect(find.text('Run `rm a.txt`'), findsOneWidget);
    expect(find.text('Which branch?'), findsOneWidget);
    expect(connection.dispatched.first.$1, 'pi:/1');
    expect(connection.dispatched.first.$2, {
      'type': 'session/isReadChanged',
      'isRead': true,
    });
  });

  testWidgets('approve, stop and answer dispatch chat actions', (tester) async {
    final connection = await _pump(tester, connected(), const Size(1400, 900));
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve'));
    await tester.tap(find.text('Stop'));
    final submit = find.widgetWithText(FilledButton, 'Submit');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Branch name *'),
      'main',
    );
    await tester.pump();
    await tester.tap(submit);

    final chatActions = [
      for (final (channel, action) in connection.dispatched)
        if (channel == 'ahp-chat:/1') action,
    ];
    expect(chatActions.map((a) => a['type']), [
      'chat/toolCallConfirmed',
      'chat/turnCancelled',
      'chat/inputCompleted',
    ]);
    expect(chatActions[0]['approved'], isTrue);
    expect(chatActions[0]['toolCallId'], 'rm');
    expect(chatActions[1]['turnId'], 'turn-2');
    expect(chatActions[2]['answers'], {
      'branch': {
        'state': 'submitted',
        'value': {'kind': 'text', 'value': 'main'},
      },
    });
  });

  testWidgets('Enter queues while working; Shift+Enter adds a newline', (
    tester,
  ) async {
    final connection = await _pump(tester, connected(), const Size(1400, 900));
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();

    final input = find.byType(TextField).last;
    await tester.enterText(input, 'also check README');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(connection.types, isNot(contains('chat/pendingMessageSet')));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final (channel, action) = connection.dispatched.last;
    expect(channel, 'ahp-chat:/1');
    expect(action['type'], 'chat/pendingMessageSet');
    expect(action['kind'], 'queued');
    expect((action['message']! as JsonMap)['text'], 'also check README');
  });

  testWidgets('Enter starts a turn when idle', (tester) async {
    final connection = await _pump(
      tester,
      connected(chat: chatFixture(active: false)),
      const Size(1400, 900),
    );
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'thanks');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(connection.types.last, 'chat/turnStarted');
  });

  testWidgets('compact layout opens the session on a new page', (tester) async {
    await _pump(tester, connected(), const Size(400, 800));
    expect(find.text('Select a session'), findsNothing);
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('Which branch?'), findsOneWidget);
  });

  testWidgets('the composer lists agents and models', (tester) async {
    await _pump(
      tester,
      connected().copyWith(
        defaultDirectory: 'file:///home/user/project/',
        root: const RootState(
          agents: [
            AgentInfo(
              provider: 'pi',
              displayName: 'Pi',
              description: 'pi',
              models: [
                SessionModelInfo(id: 'p/m', provider: 'pi', name: 'Model M'),
              ],
            ),
          ],
        ),
      ),
      const Size(1400, 900),
    );
    await tester.tap(find.byTooltip('New session'));
    await tester.pumpAndSettle();
    expect(find.text('Pi'), findsOneWidget);
    expect(find.text('Host default'), findsOneWidget);
    expect(find.text('/home/user/project'), findsOneWidget);
  });

  testWidgets('an open session is marked read again after a new turn', (
    tester,
  ) async {
    final connection = await _pump(tester, connected(), const Size(1400, 900));
    await tester.tap(find.text('Explain'));
    await tester.pumpAndSettle();
    expect(connection.types, isEmpty);
    final unread = connection.state.sessions['pi:/2']!.copyWith(
      status: const SessionStatus(1),
    );
    connection.state = connection.state.copyWith(
      sessions: applySessionAdded(connection.state.sessions, unread),
    );
    await tester.pumpAndSettle();
    expect(connection.types, ['session/isReadChanged']);
  });

  testWidgets('a 0.9.0 host shows the compatibility chip', (tester) async {
    await _pump(
      tester,
      connected().copyWith(protocolVersion: '0.9.0'),
      const Size(1400, 900),
    );
    expect(find.text('AHP 0.9.0'), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: find.text('AHP 0.9.0'), matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, contains('archiving single chats'));
  });

  testWidgets('a 1.0.0 host shows no compatibility chip', (tester) async {
    await _pump(
      tester,
      connected().copyWith(protocolVersion: '1.0.0'),
      const Size(1400, 900),
    );
    expect(find.textContaining('AHP '), findsNothing);
  });

  testWidgets('a session the host could not resume says so', (tester) async {
    final connection = await _pump(tester, connected(), const Size(1400, 900));
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    connection.state = connection.state.copyWith(
      missingChannels: {'ahp-chat:/1'},
    );
    await tester.pumpAndSettle();
    expect(
      find.text('This session is no longer available on the host.'),
      findsOneWidget,
    );
  });

  testWidgets('undone actions show a snackbar', (tester) async {
    final connection = await _pump(tester, connected(), const Size(1400, 900));
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    connection.failureController.add(
      const ActionFailure(
        channel: 'ahp-chat:/1',
        clientSeq: 3,
        action: {'type': 'chat/turnStarted'},
        kind: ActionFailureKind.timedOut,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('did not confirm that in time'), findsOneWidget);
  });

  testWidgets('session-level requests from another chat are answered in '
      'the panel; ones the timeline shows are not repeated', (tester) async {
    final connection = await _pump(
      tester,
      connected(sessionState: sessionWithRequests()),
      const Size(1400, 1000),
    );
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    final panel = find.byType(SessionInputPanel);
    expect(find.text('Waiting for you (1)'), findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('In Reviewer')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('Run `rm a.txt`')),
      findsNothing,
    );
    await tester.tap(find.descendant(of: panel, matching: find.text('Submit')));
    final (channel, action) = connection.dispatched.last;
    expect(channel, 'ahp-chat:/side');
    expect(action['type'], 'chat/inputCompleted');
    expect(action['requestId'], 'side-req');
    expect(action['answers'], {
      'merge': {
        'state': 'submitted',
        'value': {'kind': 'boolean', 'value': true},
      },
    });
  });

  testWidgets('MCP sign-in, background work and change counts', (tester) async {
    final connection = await _pump(
      tester,
      connected(chat: authChatFixture()).copyWith(
        protocolVersion: '1.0.0',
        sessions: catalogueFromSummaries([
          session('1', title: 'Fix login', status: 24).copyWith(
            changes: const ChangesSummary(additions: 3, deletions: 1, files: 1),
          ),
        ]),
      ),
      const Size(1400, 1000),
    );
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign-in required'), findsWidgets);
    expect(find.text('1 in background'), findsOneWidget);
    expect(find.textContaining('+3 −1 · 1 file'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Access token'),
      'tok',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in').last);
    await tester.pumpAndSettle();
    expect(connection.authenticated, [('https://mcp.example.com', 'tok')]);

    await tester.tap(find.text('Cancel tool call'));
    final (channel, action) = connection.dispatched.last;
    expect(channel, 'ahp-chat:/1');
    expect(action['type'], 'chat/toolCallComplete');
    expect((action['result']! as JsonMap)['success'], isFalse);
  });

  testWidgets('a 0.9.0 host shows no background work', (tester) async {
    await _pump(
      tester,
      connected(chat: authChatFixture()).copyWith(protocolVersion: '0.9.0'),
      const Size(1400, 1000),
    );
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('1 in background'), findsNothing);
  });
}
