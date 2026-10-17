/// Renaming a session (AV-073): the pure title helpers, the header's
/// click-to-rename title and "Rename…" items, and the list's rename dialog.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/session_detail/editable_title.dart';
import 'package:shireitou/src/session_title.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

SessionState _sessionState({String title = 'Fix login'}) => SessionState(
  provider: 'pi',
  title: title,
  status: SessionStatus.idle,
  lifecycle: SessionLifecycle.ready,
  activeClients: const [],
  defaultChat: 'ahp-chat:/1',
  chats: const [
    ChatSummary(
      resource: 'ahp-chat:/1',
      title: 'Fix login',
      status: SessionStatus.idle,
      modifiedAt: '2026-10-01T00:00:00Z',
    ),
  ],
);

HostState _connected({String mirroredTitle = 'Fix login'}) => HostState(
  status: ConnectionStatus.connected,
  protocolVersion: '1.0.0',
  serverInfo: const Implementation(name: 'pi-agent-host-protocol'),
  sessions: catalogueFromSummaries([
    session('1', directory: 'file:///src/app', title: 'Fix login'),
    session('2', directory: 'file:///src/app', title: 'Explain'),
  ]),
  chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(chatFixture())},
  sessionChannels: {
    'pi:/1': ChannelMirror.snapshot(_sessionState(title: mirroredTitle)),
  },
);

/// Shows the app with `pi:/1` open beside the list.
Future<FakeHostConnection> _open(WidgetTester tester) async {
  reduceMotion(tester);
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(_connected());
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

Finder get _headerTitle => find.byType(EditableTitle);

Finder get _field =>
    find.descendant(of: _headerTitle, matching: find.byType(TextField));

Future<void> _startEditing(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: _headerTitle, matching: find.text('Fix login')),
  );
  await tester.pumpAndSettle();
}

List<JsonMap> _renames(FakeHostConnection connection) => [
  for (final (channel, action) in connection.dispatched)
    if (action['type'] == 'session/titleChanged')
      {'channel': channel, ...action},
];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('renameAction', () {
    test('trims the typed title', () {
      expect(renameAction('Old', '  New  '), {
        'type': 'session/titleChanged',
        'title': 'New',
      });
    });

    test('sends nothing for an empty or unchanged title', () {
      expect(renameAction('Old', '   '), isNull);
      expect(renameAction('Old', ' Old '), isNull);
    });
  });

  test('sessionTitleOf prefers the session channel, then the catalogue, '
      'then the chat', () {
    final summary = session('1', title: 'Listed');
    expect(
      sessionTitleOf(
        session: _sessionState(title: 'Pending'),
        summary: summary,
      ),
      'Pending',
    );
    expect(
      sessionTitleOf(
        session: _sessionState(title: ''),
        summary: summary,
      ),
      'Listed',
    );
    expect(sessionTitleOf(chat: chatFixture()), 'Fix login');
    expect(sessionTitleOf(), 'Session');
  });

  test('withMirroredTitle shows a pending rename in the list', () {
    final summary = session('1', title: 'Listed');
    expect(
      withMirroredTitle(summary, _sessionState(title: 'Renamed')).title,
      'Renamed',
    );
    expect(withMirroredTitle(summary, null), same(summary));
    expect(withMirroredTitle(summary, _sessionState(title: '')), same(summary));
  });

  testWidgets('clicking the title edits it in place; Enter saves', (
    tester,
  ) async {
    final connection = await _open(tester);
    await _startEditing(tester);
    final field = tester.widget<TextField>(_field);
    expect(field.controller!.selection, isA<TextSelection>());
    expect(field.controller!.selection.start, 0);
    expect(field.controller!.selection.end, 'Fix login'.length);
    expect(field.focusNode!.hasFocus, isTrue);

    await tester.enterText(_field, 'Fix the login page');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_field, findsNothing);
    expect(_renames(connection), [
      {
        'channel': 'pi:/1',
        'type': 'session/titleChanged',
        'title': 'Fix the login page',
      },
    ]);
  });

  testWidgets('Esc cancels; an empty or unchanged title sends nothing', (
    tester,
  ) async {
    final connection = await _open(tester);
    await _startEditing(tester);
    await tester.enterText(_field, 'Something else');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_field, findsNothing);

    await _startEditing(tester);
    await tester.enterText(_field, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await _startEditing(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_renames(connection), isEmpty);
  });

  testWidgets('losing focus saves', (tester) async {
    final connection = await _open(tester);
    await _startEditing(tester);
    await tester.enterText(_field, 'Blurred');
    await tester.tapAt(const Offset(1000, 600));
    await tester.pumpAndSettle();
    expect(_field, findsNothing);
    expect(_renames(connection).single['title'], 'Blurred');
  });

  testWidgets('a host title change keeps the typed text, and the list shows '
      'the session channel title', (tester) async {
    final connection = await _open(tester);
    await _startEditing(tester);
    await tester.enterText(_field, 'Mine');
    connection.state = _connected(mirroredTitle: 'From the host');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_field).controller!.text, 'Mine');
    // The list row shows the session channel's title.
    expect(find.text('From the host'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_renames(connection).single['title'], 'Mine');
  });

  testWidgets('"Rename…" in the header menu opens the field', (tester) async {
    await _open(tester);
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename…'));
    await tester.pumpAndSettle();
    expect(_field, findsOneWidget);
    expect(tester.widget<TextField>(_field).focusNode!.hasFocus, isTrue);
  });

  testWidgets('the title has a Rename screen reader action', (tester) async {
    await _open(tester);
    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: _headerTitle,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.customSemanticsActions?.keys.any(
                    (a) => a.label == 'Rename',
                  ) ??
                  false),
        ),
      ),
    );
    semantics.properties.customSemanticsActions!.values.single();
    await tester.pumpAndSettle();
    expect(_field, findsOneWidget);
  });

  testWidgets('"Rename…" in the row menu asks for a title', (tester) async {
    final connection = await _open(tester);
    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename…'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Explain the bug',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();
    expect(_renames(connection), [
      {
        'channel': 'pi:/2',
        'type': 'session/titleChanged',
        'title': 'Explain the bug',
      },
    ]);

    // Cancel sends nothing.
    await tester.tap(find.text('Explain'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_renames(connection), hasLength(1));
  });
}
