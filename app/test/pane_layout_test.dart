import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/agent_names.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/composer/composer_labels.dart';
import 'package:shireitou/src/layout.dart';
import 'package:shireitou/src/pane_resize_handle.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_list/session_list_view.dart';
import 'package:shireitou/src/session_list/sidebar_store.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _pi = AgentInfo(
  provider: 'pi',
  displayName: 'Pi',
  description: 'pi',
  models: [],
);

/// A finished chat of [count] turns with long replies, to scroll.
ChatState _longChat(int count) => ChatState(
  resource: 'ahp-chat:/1',
  title: 'Fix login',
  status: SessionStatus.idle,
  modifiedAt: '2026-10-01T00:00:00Z',
  turns: [
    for (var i = 0; i < count; i++)
      Turn(
        id: 'q$i',
        message: userMessage('Question $i'),
        state: TurnState.complete,
        responseParts: [
          MarkdownResponsePart(
            id: 'a$i',
            content: [for (var l = 0; l < 30; l++) 'Answer $i, line $l']
                .join('\n\n'),
          ),
        ],
      ),
  ],
);

HostState _state() => HostState(
  status: ConnectionStatus.connected,
  protocolVersion: '1.0.0',
  sessions: catalogueFromSummaries([
    session('1', directory: 'file:///src/app', title: 'Fix login'),
  ]),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(_longChat(4))},
);

Future<void> _pump(
  WidgetTester tester, {
  required MemoryPrefsStore prefs,
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...hostOverrides(connection: FakeHostConnection(_state())),
        prefsStoreProvider.overrideWithValue(prefs),
      ],
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// The sidebar's resize handle; its centre is the sidebar's edge.
final _sidebarHandle = find.bySemanticsLabel('Resize sidebar');

double _sidebarEdge(WidgetTester tester) => tester.getCenter(_sidebarHandle).dx;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('clampedPaneWidth keeps a pane between 240 and 600 and the room '
      'left', () {
    expect(clampedPaneWidth(400), 400);
    expect(clampedPaneWidth(100), minPaneWidth);
    expect(clampedPaneWidth(900), maxPaneWidth);
    expect(clampedPaneWidth(500, available: 300), 300);
    // A window too narrow for both still gets the minimum.
    expect(clampedPaneWidth(500, available: 100), minPaneWidth);
  });

  test('agentDisplayName prefers the display name over the provider id', () {
    expect(agentDisplayName('pi', const [_pi]), 'Pi');
    expect(agentDisplayName('pi', const []), 'pi');
    expect(agentDisplayName('other', const [_pi]), 'other');
    expect(agentDisplayName('pi', [_pi.copyWith(displayName: '')]), 'pi');
    // The composer's placeholder uses it.
    expect(
      composerPlaceholder(
        agent: agentDisplayName('pi', const [_pi]),
        folder: 'cruise',
      ),
      'Chat with Pi [cruise]',
    );
  });

  test('hoverCardOf names the agent it is given, else the provider', () {
    final summary = session('1', directory: 'file:///src/app');
    expect(hoverCardOf(summary, agent: 'Pi').heading, ' · Pi · app');
    expect(hoverCardOf(summary).heading, ' · pi · app');
  });

  test('timelineEndInset is the padding plus the room beside the column', () {
    expect(timelineEndInset(500), timelineSidePadding);
    expect(
      timelineEndInset(timelineMaxWidth + 2 * timelineSidePadding + 200),
      timelineSidePadding + 100,
    );
  });

  test('StoredWidth loads, resizes, saves and resets a width', () async {
    final prefs = MemoryPrefsStore({'sidebar_width': '900'});
    final container = ProviderContainer(
      overrides: [prefsStoreProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(sidebarWidthProvider.notifier);
    expect(container.read(sidebarWidthProvider), defaultSidebarWidth);
    await notifier.save();
    // A saved width outside the limits is clamped.
    expect(container.read(sidebarWidthProvider), maxPaneWidth);
    notifier.resize(-100);
    expect(container.read(sidebarWidthProvider), 500);
    expect(prefs.values['sidebar_width'], '600.0');
    await notifier.save();
    expect(prefs.values['sidebar_width'], '500.0');
    await notifier.reset();
    expect(container.read(sidebarWidthProvider), defaultSidebarWidth);
    expect(prefs.values['sidebar_width'], '$defaultSidebarWidth');
  });

  testWidgets('dragging the sidebar edge resizes it within its limits, '
      'saves it, and a double-click resets it (AV-005)', (tester) async {
    final prefs = MemoryPrefsStore();
    await _pump(tester, prefs: prefs);
    expect(_sidebarEdge(tester), defaultSidebarWidth);
    expect(
      tester
          .widget<MouseRegion>(
            find.descendant(
              of: find.byType(PaneResizeHandle),
              matching: find.byType(MouseRegion),
            ),
          )
          .cursor,
      SystemMouseCursors.resizeColumn,
    );

    await tester.drag(_sidebarHandle, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(_sidebarEdge(tester), defaultSidebarWidth + 60);
    expect(prefs.values['sidebar_width'], '${defaultSidebarWidth + 60}');

    await tester.drag(_sidebarHandle, const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(_sidebarEdge(tester), minPaneWidth);

    await tester.tap(_sidebarHandle);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_sidebarHandle);
    await tester.pumpAndSettle();
    expect(_sidebarEdge(tester), defaultSidebarWidth);
    expect(prefs.values['sidebar_width'], '$defaultSidebarWidth');
  });

  testWidgets('dragging the review pane edge left widens it', (tester) async {
    final prefs = MemoryPrefsStore({'review_pane_open': 'true'});
    await _pump(tester, prefs: prefs, size: const Size(1600, 900));
    await tester.tap(find.text('Fix login').first);
    await tester.pumpAndSettle();
    final handle = find.bySemanticsLabel('Resize review pane');
    final before = tester.getCenter(handle).dx;
    await tester.drag(handle, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(handle).dx, before - 100);
    expect(prefs.values['review_pane_width'], '480.0');
  });

  testWidgets('the sidebar opens at its saved width', (tester) async {
    await _pump(tester, prefs: MemoryPrefsStore({'sidebar_width': '320'}));
    expect(_sidebarEdge(tester), 320);
  });

  testWidgets('a phone session page has one bar: back, title and "…"', (
    tester,
  ) async {
    await _pump(tester, prefs: MemoryPrefsStore(), size: const Size(400, 800));
    await tester.tap(find.text('Fix login').first);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    final back = find.byType(BackButton);
    expect(back, findsOneWidget);
    final title = find.descendant(
      of: find.byType(SessionDetailView),
      matching: find.text('Fix login'),
    );
    final more = find.byTooltip('Session actions');
    // One row, back first and "…" last.
    expect(tester.getCenter(title).dy, tester.getCenter(back).dy);
    expect(tester.getCenter(more).dy, tester.getCenter(back).dy);
    expect(tester.getCenter(back).dx, lessThan(tester.getCenter(title).dx));
    expect(tester.getCenter(title).dx, lessThan(tester.getCenter(more).dx));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SessionDetailView), findsNothing);
  });

  testWidgets(
    'jump to latest lines up with the content column, not the '
    "pane's corner",
    // Desktop: no padding around the button for touch.
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      reduceMotion(tester);
      await _pump(
        tester,
        prefs: MemoryPrefsStore(),
        size: const Size(1800, 900),
      );
      await tester.tap(find.text('Fix login').first);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SuperListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      final pane = tester.getRect(find.byType(SuperListView));
      final button = tester.getRect(find.byTooltip('Jump to latest'));
      expect(button.right, pane.right - timelineEndInset(pane.width));
      // The column is narrower than the pane, so that is well inside it.
      expect(pane.right - button.right, greaterThan(100));
      // The user's bubbles end at the column's edge too.
      final bubble = find
          .ancestor(of: find.text('Question 3'), matching: find.byType(Align))
          .first;
      expect(tester.getRect(bubble).right, closeTo(button.right, 1));
    },
  );
}
