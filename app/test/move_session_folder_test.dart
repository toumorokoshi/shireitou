/// Moving a session's primary working directory to another folder
/// (`session/workingDirectoryReplaced`).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

RootState _root({MultipleWorkingDirectoriesCapability? mwd}) => RootState(
  agents: [
    AgentInfo(
      provider: 'pi',
      displayName: 'Pi',
      description: 'Test agent',
      models: const [],
      capabilities: mwd == null
          ? null
          : AgentCapabilities(multipleWorkingDirectories: mwd),
    ),
  ],
  activeSessions: 0,
);

SessionState _sessionState() => const SessionState(
  provider: 'pi',
  title: 'Fix login',
  status: SessionStatus.idle,
  lifecycle: SessionLifecycle.ready,
  activeClients: [],
  defaultChat: 'ahp-chat:/1',
  workingDirectories: ['file:///src/app'],
  chats: [
    ChatSummary(
      resource: 'ahp-chat:/1',
      title: 'Fix login',
      status: SessionStatus.idle,
      modifiedAt: '2026-10-01T00:00:00Z',
    ),
  ],
);

HostState _connected({MultipleWorkingDirectoriesCapability? mwd}) => HostState(
  status: ConnectionStatus.connected,
  protocolVersion: '1.0.0',
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  root: _root(mwd: mwd),
  sessions: catalogueFromSummaries([
    session('1', directory: 'file:///src/app', title: 'Fix login'),
    session('2', directory: 'file:///src/app', title: 'Explain'),
  ]),
  chatChannels: {
    'ahp-chat:/1': ChannelMirror.snapshot(
      chatFixture().copyWith(activeTurn: null),
    ),
  },
  sessionChannels: {'pi:/1': ChannelMirror.snapshot(_sessionState())},
);

Future<FakeHostConnection> _open(
  WidgetTester tester, {
  MultipleWorkingDirectoriesCapability? mwd,
  Map<String, List<String>> folders = const {},
}) async {
  reduceMotion(tester);
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(_connected(mwd: mwd))
    ..folders.addAll(folders);
  await tester.pumpWidget(
    ProviderScope(
      overrides: hostOverrides(connection: connection),
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Fix login'));
  await tester.pumpAndSettle();
  return connection;
}

List<JsonMap> _moves(FakeHostConnection connection) => [
  for (final (channel, action) in connection.dispatched)
    if (action['type'] == 'session/workingDirectoryReplaced')
      {'channel': channel, ...action},
];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('"Move to folder…" is hidden without primaryReplacement', (
    tester,
  ) async {
    await _open(
      tester,
      mwd: const MultipleWorkingDirectoriesCapability(immutablePrimary: true),
    );
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    expect(find.text('Move to folder…'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Move to folder…'), findsNothing);
  });

  testWidgets('"Move to folder…" in the header menu dispatches replace', (
    tester,
  ) async {
    final connection = await _open(
      tester,
      mwd: const MultipleWorkingDirectoriesCapability(
        immutablePrimary: true,
        primaryReplacement: true,
      ),
      folders: const {
        '/src/app': ['packages'],
        '/src/app/packages': [],
      },
    );
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to folder…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('packages'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Choose this folder'));
    await tester.pumpAndSettle();
    expect(_moves(connection), [
      {
        'channel': 'pi:/1',
        'type': 'session/workingDirectoryReplaced',
        'directory': 'file:///src/app',
        'replacement': 'file:///src/app/packages',
      },
    ]);
  });

  testWidgets('"Move to folder…" in the row menu dispatches or cancels', (
    tester,
  ) async {
    final connection = await _open(
      tester,
      mwd: const MultipleWorkingDirectoriesCapability(
        immutablePrimary: true,
        primaryReplacement: true,
      ),
      folders: const {
        '/src/app': ['api'],
        '/src/app/api': [],
      },
    );
    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to folder…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('api'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Choose this folder'));
    await tester.pumpAndSettle();
    expect(_moves(connection), [
      {
        'channel': 'pi:/2',
        'type': 'session/workingDirectoryReplaced',
        'directory': 'file:///src/app',
        'replacement': 'file:///src/app/api',
      },
    ]);

    // Cancel sends nothing.
    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to folder…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_moves(connection), hasLength(1));
  });
}
