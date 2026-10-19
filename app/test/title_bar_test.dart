import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/review/changes_pane.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/theme/app_theme.dart';
import 'package:shireitou/src/title_bar/title_bar.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

Finder _appNameLabel() => find.byKey(const ValueKey('title-bar-app-name'));

Future<void> _pumpTitleBar(
  WidgetTester tester, {
  required String title,
  bool isWorkspace = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(
        defaultTheme(Brightness.dark),
        platform: TargetPlatform.macOS,
      ),
      home: Scaffold(
        body: TitleBar(
          title: title,
          isWorkspace: isWorkspace,
          searchTooltip: 'Search sessions',
          onSearch: () {},
        ),
      ),
    ),
  );
}

HostState _state() => HostState(
  status: ConnectionStatus.connected,
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  protocolVersion: '1.0.0',
  sessions: catalogueFromSummaries([
    session(
      '1',
      directory: 'file:///src/app',
      project: 'file:///src/repo',
      title: 'Fix login',
    ),
    session('2', title: 'Explain'),
  ]),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(chatFixture())},
);

Future<MemoryPrefsStore> _pump(
  WidgetTester tester, {
  Size size = const Size(1400, 900),
  MemoryPrefsStore? prefs,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = prefs ?? MemoryPrefsStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...hostOverrides(connection: FakeHostConnection(_state())),
        prefsStoreProvider.overrideWithValue(store),
      ],
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _open(WidgetTester tester, String title) async {
  await tester.tap(find.text(title).first);
  await tester.pump(const Duration(milliseconds: 500));
}

Finder _centreBox() => find.byKey(const ValueKey('title-bar-search'));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('workspaceTitle is "folder [repo]", the folder, or null', () {
    expect(
      workspaceTitle(
        session('1', directory: 'file:///src/app', project: 'cruise'),
      ),
      'app [cruise]',
    );
    expect(workspaceTitle(session('1', directory: 'file:///src/app')), 'app');
    expect(workspaceTitle(session('1')), isNull);
    expect(workspaceTitle(null), isNull);
  });

  testWidgets('the app name label is always beside the navigation buttons', (
    tester,
  ) async {
    await _pumpTitleBar(tester, title: 'test host');
    expect(_appNameLabel(), findsOneWidget);
    expect(tester.widget<Text>(_appNameLabel()).data, appName);

    await _pumpTitleBar(tester, title: 'app [cruise]', isWorkspace: true);
    expect(_appNameLabel(), findsOneWidget);
    expect(find.text(appName), findsOneWidget);
    expect(
      find.descendant(of: _centreBox(), matching: find.text('app [cruise]')),
      findsOneWidget,
    );
  });

  testWidgets('wide layouts show the title bar instead of an app bar', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(TitleBar), findsOneWidget);
    expect(_appNameLabel(), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.getSize(find.byType(TitleBar)).height, titleBarHeight);
    // No session open: the host's name.
    expect(
      find.descendant(of: _centreBox(), matching: find.text('test host')),
      findsOneWidget,
    );
    await _open(tester, 'Fix login');
    expect(_appNameLabel(), findsOneWidget);
    expect(
      find.descendant(
        of: _centreBox(),
        matching: find.text('app [file:///src/repo]'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ReviewPaneToggle), findsOneWidget);
  });

  testWidgets('compact layouts keep an app bar', (tester) async {
    await _pump(tester, size: const Size(500, 900));
    expect(find.byType(TitleBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byTooltip(RegExp(r'^New session \(')), findsOneWidget);
    expect(find.byTooltip('More actions'), findsOneWidget);
  });

  testWidgets('the sidebar toggle hides the list and is remembered', (
    tester,
  ) async {
    final prefs = await _pump(tester);
    expect(find.text('Explain'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Explain'), findsNothing);
    expect(prefs.values['sidebar_hidden'], 'true');

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, prefs: prefs);
    expect(find.text('Explain'), findsNothing);
    await tester.tap(find.byTooltip('Show sidebar'));
    await tester.pumpAndSettle();
    expect(find.text('Explain'), findsOneWidget);
  });

  testWidgets('clicking the centre box shows the sidebar and focuses search', (
    tester,
  ) async {
    await _pump(tester, prefs: MemoryPrefsStore({'sidebar_hidden': 'true'}));
    await tester.tap(_centreBox());
    await tester.pumpAndSettle();
    // The session search is the only text field while no session is open.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);
    expect(find.text('Explain'), findsOneWidget);
  });

  testWidgets('back and forward step through the opened sessions', (
    tester,
  ) async {
    await _pump(tester);
    IconButton button(String tooltip) => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );
    SessionDetailView detail() =>
        tester.widget<SessionDetailView>(find.byType(SessionDetailView));
    expect(button('Back').onPressed, isNull);
    expect(button('Forward').onPressed, isNull);

    await _open(tester, 'Fix login');
    await _open(tester, 'Explain');
    expect(detail().session, 'pi:/2');
    expect(button('Forward').onPressed, isNull);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(detail().session, 'pi:/1');
    expect(button('Back').onPressed, isNull);

    await tester.tap(find.byTooltip('Forward'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(detail().session, 'pi:/2');
  });

  testWidgets('the review pane toggle sits in the title bar', (tester) async {
    final prefs = await _pump(tester);
    await _open(tester, 'Fix login');
    expect(
      find.descendant(
        of: find.byType(TitleBar),
        matching: find.byType(ReviewPaneToggle),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(ReviewPaneToggle));
    await tester.pumpAndSettle();
    expect(prefs.values['review_pane_open'], 'true');
  });

  testWidgets('the sidebar\'s "…" menu holds Disconnect', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Connect to a host'), findsOneWidget);
  });
}
