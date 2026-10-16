import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/host_connection.dart';

import 'fixtures.dart';

/// A [HostConnection] with fixed state that records dispatched actions.
class FakeHostConnection extends HostConnection {
  FakeHostConnection(this.initial);

  final HostState initial;

  /// (channel, action) pairs, in order.
  final dispatched = <(String, JsonMap)>[];

  @override
  HostState build() => initial;

  @override
  Future<String?> openSession(String session) async => 'ahp-chat:/1';

  @override
  void closeSession(String session, String? chat) {}

  @override
  void dispatch(String channel, JsonMap action) =>
      dispatched.add((channel, action));

  /// The `type`s of the dispatched actions.
  List<Object?> get types => [for (final (_, a) in dispatched) a['type']];
}

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

HostState connected({ChatState? chat}) => HostState(
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
    expect(find.text('Changes (not implemented)'), findsOneWidget);
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
}
