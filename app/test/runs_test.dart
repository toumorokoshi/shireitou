/// Parallel runs (best-of-N, AV-045): the run group model, starting
/// several runs from the composer, and comparing and picking them.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/runs/run_groups.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _agents = RootState(
  agents: [
    AgentInfo(
      provider: 'pi',
      displayName: 'Pi',
      description: 'pi',
      models: [
        SessionModelInfo(id: 'fast', provider: 'pi', name: 'Fast'),
        SessionModelInfo(id: 'smart', provider: 'pi', name: 'Smart'),
      ],
    ),
  ],
);

RunGroup _group({SessionRef? winner}) => RunGroup(
  id: 'g1',
  prompt: 'Fix the parser',
  createdAt: '2026-10-16T00:00:00Z',
  members: [
    RunMember(host: testHost.key, session: 'pi:/1', label: 'Pi · Fast'),
    RunMember(host: testHost.key, session: 'pi:/2', label: 'Pi · Smart'),
  ],
  winner: winner,
);

SessionSummary _run(String id, String title) => SessionSummary(
  resource: 'pi:/$id',
  provider: 'pi',
  title: title,
  status: SessionStatus(33),
  createdAt: '2026-10-01T00:00:00Z',
  modifiedAt: '2026-10-0${id}T00:00:00Z',
  workingDirectories: const ['file:///src/app'],
  defaultChat: 'ahp-chat:/1',
  changes: const ChangesSummary(additions: 3, deletions: 1, files: 1),
);

Future<(FakeHostConnection, MemoryPrefsStore)> _pump(
  WidgetTester tester, {
  List<RunGroup> groups = const [],
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = MemoryPrefsStore({
    if (groups.isNotEmpty) 'run_groups': encodeRunGroups(groups),
  });
  final connection = FakeHostConnection(
    HostState(
      status: ConnectionStatus.connected,
      protocolVersion: '1.0.0',
      defaultDirectory: 'file:///src/app',
      root: _agents,
      sessions: catalogueFromSummaries([
        _run('1', 'Fix login'),
        _run('2', 'Fix login, take two'),
      ]),
      chatChannels: {
        'ahp-chat:/1': ChannelMirror.snapshot(chatFixture(active: false)),
      },
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
  return (connection, prefs);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('run groups', () {
    test('add, pick, find and label', () {
      final groups = withGroup(const [], _group());
      expect(groupOf(groups, (host: testHost.key, session: 'pi:/2'))?.id, 'g1');
      expect(groupOf(groups, (host: testHost.key, session: 'pi:/3')), isNull);
      final picked = withWinner(groups, 'g1', (
        host: testHost.key,
        session: 'pi:/2',
      ));
      expect(labelsOfRuns(picked), {
        (host: testHost.key, session: 'pi:/1'): 'Run 1 of 2',
        (host: testHost.key, session: 'pi:/2'): 'Run 2 of 2 · picked',
      });
      // Re-adding replaces; the list is capped.
      expect(withGroup(picked, _group()).single.winner, isNull);
      var many = <RunGroup>[];
      for (var i = 0; i < maxRunGroups + 5; i++) {
        many = withGroup(
          many,
          RunGroup(id: '$i', prompt: '', createdAt: '', members: const []),
        );
      }
      expect(many, hasLength(maxRunGroups));
      expect(many.first.id, '${maxRunGroups + 4}');
    });

    test('encode and decode, skipping broken entries', () {
      final groups = [_group(winner: (host: testHost.key, session: 'pi:/1'))];
      expect(decodeRunGroups(encodeRunGroups(groups)), groups);
      expect(decodeRunGroups('[{"id":1},{"nope":true}]'), isEmpty);
      expect(decodeRunGroups('not json'), isEmpty);
      expect(decodeRunGroups(null), isEmpty);
    });

    test('the outcome of starting runs', () {
      final one = runOutcome(host: 'h', labels: ['A'], results: ['pi:/1']);
      expect(one.started.single.ref, (host: 'h', session: 'pi:/1'));
      expect(one.started.single.label, 'A');
      expect(one.failures, isEmpty);
      expect(
        runOutcome(
          host: 'h',
          labels: ['A'],
          results: [StateError('x')],
        ).failures,
        ['Bad state: x'],
      );
      final mixed = runOutcome(
        host: 'h',
        labels: ['A', 'B'],
        results: ['pi:/1', StateError('x')],
      );
      expect(mixed.started.map((m) => m.label), ['A']);
      expect(mixed.failures, ['Run 2: Bad state: x']);
    });

    test('the latest reply of a chat', () {
      expect(lastReplyOf(chatFixture()), 'There is **one** file.');
      expect(
        lastReplyOf(chatFixture().copyWith(turns: const [], activeTurn: null)),
        isNull,
      );
    });
  });

  testWidgets('the composer starts several runs and groups them', (
    tester,
  ) async {
    final (connection, prefs) = await _pump(tester);
    await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a run'));
    await tester.pumpAndSettle();
    // Run 2 picks another model.
    await tester.tap(find.text('Host default').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smart').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a run'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove run 3'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Prompt'),
      'Fix the parser',
    );
    await tester.tap(find.byTooltip('Start 2 runs'));
    await tester.pumpAndSettle();

    expect(connection.started.map((s) => s.prompt), [
      'Fix the parser',
      'Fix the parser',
    ]);
    expect(connection.started.first.model, isNull);
    expect(connection.started.last.model?.id, 'smart');
    final saved = decodeRunGroups(prefs.values['run_groups']);
    expect(saved.single.members.map((m) => (m.session, m.label)), [
      ('pi:/1', 'Pi · default model'),
      ('pi:/2', 'Pi · Smart'),
    ]);
    // The list labels both runs; the first one is open.
    expect(find.textContaining('Run 1 of 2 · pi'), findsOneWidget);
    expect(find.textContaining('Run 2 of 2 · pi'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Run 1 of 2'), findsOneWidget);
  });

  testWidgets('compare runs side by side, pick one and archive the others', (
    tester,
  ) async {
    final (connection, prefs) = await _pump(tester, groups: [_group()]);
    await tester.longPress(find.text('Fix login, take two'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare runs'));
    await tester.pumpAndSettle();

    expect(find.text('Compare 2 runs'), findsOneWidget);
    expect(find.text('Run 1 · Pi · Fast'), findsOneWidget);
    expect(find.text('Run 2 · Pi · Smart'), findsOneWidget);
    expect(find.text('+3 −1 · 1 file'), findsNWidgets(2));
    expect(find.byType(MarkdownBody), findsNWidgets(2));
    expect(find.text('Archive the others'), findsNothing);

    await tester.tap(find.text('Pick this run').last);
    await tester.pumpAndSettle();
    expect(find.text('Picked'), findsOneWidget);
    expect(
      decodeRunGroups(prefs.values['run_groups']).single.winner?.session,
      'pi:/2',
    );
    await tester.tap(find.text('Archive the others'));
    await tester.pump();
    expect(connection.dispatched.single.$1, 'pi:/1');
    expect(connection.dispatched.single.$2, {
      'type': 'session/isArchivedChanged',
      'isArchived': true,
    });

    // "Open" goes back to the list with the run selected.
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    expect(find.text('Compare 2 runs'), findsNothing);
    expect(find.widgetWithText(ActionChip, 'Run 2 of 2 · picked'), findsOne);
  });
}
