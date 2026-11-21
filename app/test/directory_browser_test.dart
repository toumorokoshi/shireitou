/// Tests for [DirectoryBrowser] and its path input helpers.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/directory_browser.dart';
import 'package:shireitou/src/host_connection.dart';

import 'fake_connection.dart';

FakeHostConnection _connection(Map<String, List<String>> folders) =>
    FakeHostConnection(const HostState(status: ConnectionStatus.connected))
      ..folders.addAll(folders);

Future<void> _openBrowser(
  WidgetTester tester, {
  required FakeHostConnection connection,
  required ValueSetter<String?> onResult,
  String initial = '/src/app',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hostConnectionProvider('h').overrideWith(() => connection)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  onResult(
                    await showDirectoryBrowser(
                      context,
                      host: 'h',
                      initial: initial,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  test('normalizeFolderInput trims, decodes file URIs, and strips slashes', () {
    expect(normalizeFolderInput(''), isNull);
    expect(normalizeFolderInput('   '), isNull);
    expect(normalizeFolderInput('/'), '/');
    expect(normalizeFolderInput('  /src/app/  '), '/src/app');
    expect(normalizeFolderInput('file:///src/app/'), '/src/app');
    expect(normalizeFolderInput('file:///src/my%20app'), '/src/my app');
  });

  testWidgets('pasting a path and choosing it returns the pasted path', (
    tester,
  ) async {
    String? chosen;
    await _openBrowser(
      tester,
      connection: _connection(const {
        '/src/app': ['lib'],
      }),
      onResult: (value) => chosen = value,
    );

    final field = find.byType(TextField);
    expect(find.widgetWithText(TextField, '/src/app'), findsOneWidget);

    await tester.enterText(field, '  /Users/me/other-repo/  ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Choose this folder'));
    await tester.pumpAndSettle();

    expect(chosen, '/Users/me/other-repo');
  });

  testWidgets(
    'submitting or tapping Open folder navigates to the pasted path',
    (tester) async {
      String? chosen;
      await _openBrowser(
        tester,
        connection: _connection(const {
          '/src/app': ['lib'],
          '/opt/work': ['backend', 'frontend'],
          '/opt/work/backend': [],
        }),
        onResult: (value) => chosen = value,
      );

      await tester.enterText(find.byType(TextField), 'file:///opt/work/');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '/opt/work'), findsOneWidget);
      expect(find.text('backend'), findsOneWidget);
      expect(find.text('frontend'), findsOneWidget);

      await tester.tap(find.text('backend'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextField, '/opt/work/backend'),
        findsOneWidget,
      );

      await tester.tap(find.text('..'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '/opt/work'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Choose this folder'));
      await tester.pumpAndSettle();
      expect(chosen, '/opt/work');
    },
  );

  testWidgets('empty path disables Open folder and Choose this folder', (
    tester,
  ) async {
    await _openBrowser(
      tester,
      connection: _connection(const {'/src/app': []}),
      onResult: (_) {},
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final chooseButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Choose this folder'),
    );
    final openButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_forward),
    );
    expect(chooseButton.onPressed, isNull);
    expect(openButton.onPressed, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
