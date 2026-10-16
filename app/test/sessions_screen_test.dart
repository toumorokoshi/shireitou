import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/host_connection.dart';

import 'fixtures.dart';

class _FakeHostConnection extends HostConnection {
  _FakeHostConnection(this.initial);

  final HostState initial;

  @override
  HostState build() => initial;
}

Future<void> _pump(WidgetTester tester, HostState state, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hostConnectionProvider.overrideWith(() => _FakeHostConnection(state)),
      ],
      child: const ShireitouApp(),
    ),
  );
}

void main() {
  final connected = HostState(
    status: ConnectionStatus.connected,
    serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
    sessions: catalogueFromSummaries([
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
    ]),
  );

  testWidgets('shows the connect screen when disconnected', (tester) async {
    await _pump(tester, const HostState(), const Size(800, 900));
    expect(find.text('Connect to a host'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
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
    await _pump(tester, connected, const Size(1400, 900));
    expect(find.text('app'), findsOneWidget);
    expect(find.text('fix-login'), findsOneWidget);
    expect(find.text('Needs input'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Select a session'), findsOneWidget);
    expect(find.text('Changes (not implemented)'), findsOneWidget);

    await tester.tap(find.text('Explain'));
    await tester.pumpAndSettle();
    expect(find.text('Folder: /src/app-worktrees/fix-login'), findsOneWidget);
  });

  testWidgets('compact layout opens the session on a new page', (tester) async {
    await _pump(tester, connected, const Size(400, 800));
    expect(find.text('Select a session'), findsNothing);
    await tester.tap(find.text('Fix login'));
    await tester.pumpAndSettle();
    expect(find.text('Folder: /src/app'), findsOneWidget);
  });
}
