/// Several hosts at once (AV-010, AV-012), the composer's host picker,
/// folder browser, model options and session settings (AV-040, AV-041,
/// AV-043), the follow-up model and mode pickers, and the storage banner.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/composer/new_session_view.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_list/session_list_view.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _other = SavedHost(url: 'ws://10.0.0.2:2', name: 'build box');

const _agents = RootState(
  agents: [
    AgentInfo(
      provider: 'pi',
      displayName: 'Pi',
      description: 'pi',
      models: [
        SessionModelInfo(
          id: 'p/think',
          provider: 'pi',
          name: 'Thinker',
          configSchema: ConfigSchema(
            properties: {
              'thinkingLevel': ConfigPropertySchema(
                type: ConfigPropertySchemaType.string,
                title: 'Thinking',
                defaultValue: 'medium',
                enumValues: ['low', 'medium', 'high'],
                enumLabels: ['Low', 'Medium', 'High'],
              ),
            },
          ),
        ),
      ],
    ),
  ],
);

const _modeSchema = SessionConfigSchema(
  properties: {
    'mode': SessionConfigPropertySchema(
      type: SessionConfigPropertySchemaType.string,
      title: 'Mode',
      defaultValue: 'interactive',
      enumValues: ['interactive', 'plan'],
      enumLabels: ['Interactive', 'Plan'],
      sessionMutable: true,
    ),
  },
);

HostState _host(List<SessionSummary> sessions, {String? name}) => HostState(
  status: ConnectionStatus.connected,
  serverInfo: Implementation(name: name ?? 'pi-agent-host-protocol'),
  defaultDirectory: 'file:///home/user',
  root: _agents,
  sessions: catalogueFromSummaries(sessions),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(chatFixture())},
);

Future<(FakeHostConnection, FakeHostConnection)> _pump(
  WidgetTester tester, {
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final first = FakeHostConnection(
    _host([session('1', directory: 'file:///src/app', title: 'Fix login')]),
  );
  final second = FakeHostConnection(
    _host([session('9', directory: 'file:///src/app', title: 'Deploy')]),
    host: _other.key,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: hostOverrides(
        connection: first,
        connections: {_other: second},
      ),
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (first, second);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('every host is a node of the sidebar tree with its folders, '
      'and tapping a host narrows the list', (tester) async {
    await _pump(tester);
    expect(find.text('All hosts'), findsOneWidget);
    expect(find.text('Fix login'), findsOneWidget);
    expect(find.text('Deploy'), findsOneWidget);
    // The same path on two hosts is two folders, each under its host.
    expect(find.text('test host'), findsOneWidget);
    expect(find.text('build box'), findsOneWidget);
    expect(find.text('app'), findsNWidgets(2));
    expect(find.text('/src/app'), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.semanticLabel == 'Connected',
      ),
      findsNWidgets(2),
    );

    // Collapsing a host hides its folders; expanding shows them again.
    await tester.tap(find.byTooltip('Collapse build box'));
    await tester.pumpAndSettle();
    expect(find.text('Deploy'), findsNothing);
    expect(find.text('app'), findsOneWidget);
    await tester.tap(find.byTooltip('Expand build box'));
    await tester.pumpAndSettle();
    expect(find.text('Deploy'), findsOneWidget);

    // Collapsing a folder hides its sessions (the build box is listed
    // first, as it was opened first).
    await tester.tap(find.text('app').first);
    await tester.pumpAndSettle();
    expect(find.text('Deploy'), findsNothing);
    expect(find.text('Fix login'), findsOneWidget);
    await tester.tap(find.text('app').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('build box'));
    await tester.pumpAndSettle();
    expect(find.text('Deploy'), findsOneWidget);
    expect(find.text('Fix login'), findsNothing);
    // The other host stays listed, without its folders.
    expect(find.text('test host'), findsOneWidget);
    expect(find.text('/src/app'), findsOneWidget);
    expect(find.text('build box'), findsNWidgets(2));
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect build box'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    // Opening a session shows it from its own host.
    await tester.tap(find.text('Deploy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Queue a follow-up'), findsOneWidget);

    // Disconnecting the host leaves the other one.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect build box'));
    await tester.pumpAndSettle();
    expect(find.text('Fix login'), findsOneWidget);
    expect(find.text('Deploy'), findsNothing);
    expect(find.text('test host'), findsNWidgets(2));
  });

  testWidgets('"Add host…" connects another host from a pushed page', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Add host…'));
    await tester.pumpAndSettle();
    expect(find.text('Connect to another host'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('All hosts'), findsOneWidget);
  });

  testWidgets('desktop rows are thin; compact rows keep touch targets', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      tester.getSize(find.byKey(const ValueKey('add-host'))).height,
      denseHeaderHeight,
    );
    expect(
      tester.getSize(find.widgetWithText(InkWell, 'Deploy')).height,
      lessThanOrEqualTo(denseSessionHeight),
    );

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('add-host'))).height,
      kMinInteractiveDimension,
    );
    expect(
      tester.getSize(find.widgetWithText(InkWell, 'Deploy')).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
  });

  testWidgets('the folder "+" opens the composer on that host and folder, '
      'with host picker, model options, settings and folder browser', (
    tester,
  ) async {
    final (_, second) = await _pump(tester);
    second
      ..settings = const ResolveSessionConfigResult(
        schema: _modeSchema,
        values: {'mode': 'interactive'},
      )
      ..folders['/src/app'] = ['lib', 'test']
      ..folders['/src/app/lib'] = [];
    // The build box's folder is listed first (its session is newer).
    await tester.tap(find.byTooltip('New session in app').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Host'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NewSessionView),
        matching: find.text('build box'),
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, '/src/app'), findsOneWidget);
    expect(find.byTooltip('Mode'), findsOneWidget);
    expect(find.text('Interactive'), findsOneWidget);
    // Recent folders of the host are offered.
    await tester.tap(find.byTooltip('Recent folders'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'app'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'app'));
    await tester.pumpAndSettle();

    // The model's configSchema becomes a "Thinking" picker.
    await tester.tap(find.text('Host default model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thinker').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Thinking'), findsOneWidget);
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interactive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();

    // Browse the host's folders.
    await tester.tap(find.byTooltip('Browse…'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a folder'), findsOneWidget);
    await tester.tap(find.text('lib'));
    await tester.pumpAndSettle();
    expect(find.text('No sub-folders'), findsOneWidget);
    await tester.tap(find.text('Choose this folder'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '/src/app/lib'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Prompt'), 'Go');
    await tester.tap(find.byTooltip('Start session'));
    await tester.pumpAndSettle();
    final start = second.started.single;
    expect(start.directory, 'file:///src/app/lib');
    expect(start.model?.id, 'p/think');
    expect(start.model?.config, {'thinkingLevel': 'high'});
    expect(start.config, {'mode': 'plan'});
    expect(second.resolved.last, {'mode': 'plan'});
  });

  testWidgets('a session that fails to start shows the host error', (
    tester,
  ) async {
    final (first, second) = await _pump(tester);
    const error = SessionCreationFailedError(
      'ahp-session:/x',
      ErrorInfo(errorType: 'creationFailed', message: 'No such folder'),
    );
    first.startError = error;
    second.startError = error;
    await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Prompt'), 'Go');
    await tester.tap(find.byTooltip('Start session'));
    await tester.pumpAndSettle();
    debugPrint(
      [for (final e in find.byType(Text).evaluate()) (e.widget as Text).data]
          .join(' | '),
    );
    expect(
      find.text('The session could not start: No such folder'),
      findsOneWidget,
    );
    // The prompt is kept, to try again.
    expect(find.widgetWithText(TextField, 'Go'), findsOneWidget);
  });

  testWidgets('follow-ups pick a model and its options, and the mode '
      'changes mid-session', (tester) async {
    final (first, _) = await _pump(tester);
    first.state = first.state.copyWith(
      sessionChannels: {
        'pi:/1': ChannelMirror.snapshot(
          const SessionState(
            provider: 'pi',
            title: 'Fix login',
            status: SessionStatus.idle,
            lifecycle: SessionLifecycle.ready,
            activeClients: [],
            chats: [],
            config: SessionConfigState(
              schema: _modeSchema,
              values: {'mode': 'interactive'},
            ),
          ),
        ),
      },
    );
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('Host default model'), findsOneWidget);
    await tester.tap(find.text('Host default model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thinker').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interactive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    expect(first.dispatched.last.$1, 'pi:/1');
    expect(first.dispatched.last.$2, {
      'type': 'session/configChanged',
      'config': {'mode': 'plan'},
    });

    await tester.enterText(find.byType(TextField).last, 'Next');
    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    final message = first.dispatched.last.$2['message'] as JsonMap;
    expect(message['model'], {
      'id': 'p/think',
      'config': {'thinkingLevel': 'low'},
    });
  });

  testWidgets('a locked keyring is shown with a retry', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...hostOverrides(connection: FakeHostConnection(const HostState())),
          hostStoreProvider.overrideWithValue(_LockedStore()),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('keyring is locked'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('keyring is locked'), findsNothing);
  });
}

class _LockedStore extends HostStore {
  _LockedStore() : super(const FlutterSecureStorage());

  @override
  Future<List<SavedHost>> loadHosts() async =>
      throw StateError('Cannot create an item in a locked collection');
}
