import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/editor/editor_store.dart';
import 'package:shireitou/src/editor/editor_target.dart';
import 'package:shireitou/src/prefs.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

/// The JSON of a hex-encoded Remote - SSH authority.
Object? decodeAuthority(String hex) => jsonDecode(
  utf8.decode([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]),
);

const _ssh = EditorTarget(location: EditorLocation.ssh, host: 'box');

void main() {
  group('defaultEditorTarget', () {
    test('a loopback host is this computer', () {
      for (final url in [
        'ws://127.0.0.1:63877?tkn=x',
        'ws://localhost:1',
        'ws://[::1]:1',
      ]) {
        expect(
          defaultEditorTarget(url),
          const EditorTarget(location: EditorLocation.thisComputer),
          reason: url,
        );
      }
    });

    test("another host is SSH to the URL's host", () {
      expect(
        defaultEditorTarget('wss://10.0.0.5:63877?tkn=x'),
        const EditorTarget(location: EditorLocation.ssh, host: '10.0.0.5'),
      );
    });
  });

  test('editorTargetProblem', () {
    expect(
      editorTargetProblem(
        const EditorTarget(location: EditorLocation.thisComputer),
      ),
      isNull,
    );
    expect(editorTargetProblem(_ssh), isNull);
    expect(
      editorTargetProblem(const EditorTarget(location: EditorLocation.ssh)),
      'Enter the SSH host.',
    );
    expect(
      editorTargetProblem(
        const EditorTarget(location: EditorLocation.ssh, host: 'b', port: 0),
      ),
      'Enter a port from 1 to 65535.',
    );
  });

  group('sshRemoteAuthority', () {
    test('is user@host when it is lowercase on port 22', () {
      expect(sshRemoteAuthority('box'), 'box');
      expect(sshRemoteAuthority('box', user: 'me'), 'me@box');
    });

    test('is hex-encoded JSON for another port, capitals or IPv6', () {
      expect(
        decodeAuthority(sshRemoteAuthority('box', user: 'me', port: 2222)),
        {'hostName': 'box', 'user': 'me', 'port': 2222},
      );
      expect(decodeAuthority(sshRemoteAuthority('Box')), {'hostName': 'Box'});
      expect(decodeAuthority(sshRemoteAuthority('fe80::1')), {
        'hostName': 'fe80::1',
      });
    });
  });

  group('openInEditorUri', () {
    test('opens a folder on this computer', () {
      expect(
        openInEditorUri(
          CodeEditor.vscode,
          const EditorTarget(location: EditorLocation.thisComputer),
          '/src/my app',
        ).toString(),
        'vscode://file/src/my%20app',
      );
    });

    test("opens a folder over SSH in the editor's scheme", () {
      expect(
        openInEditorUri(
          CodeEditor.cursor,
          const EditorTarget(
            location: EditorLocation.ssh,
            host: 'box',
            user: 'me',
          ),
          '/src/app',
        ).toString(),
        'cursor://vscode-remote/ssh-remote+me@box/src/app',
      );
      expect(
        openInEditorUri(CodeEditor.vscodeInsiders, _ssh, '/src').toString(),
        'vscode-insiders://vscode-remote/ssh-remote+box/src',
      );
    });
  });

  test('editorFolder takes absolute paths only', () {
    expect(editorFolder('/src/app'), '/src/app');
    expect(editorFolder('vscode-remote://x/y'), isNull);
    expect(editorFolder(null), isNull);
  });

  group('EditorTarget JSON', () {
    test('round-trips', () {
      const target = EditorTarget(
        location: EditorLocation.ssh,
        host: 'box',
        port: 2222,
        user: 'me',
      );
      expect(EditorTarget.fromJson(target.toJson()), target);
    });

    test("reads the SSH terminal's former settings", () {
      expect(
        EditorTarget.fromJson({
          'host': 'box',
          'port': 22,
          'user': 'me',
          'auth': 'password',
          'password': 'secret',
        }),
        const EditorTarget(
          location: EditorLocation.ssh,
          host: 'box',
          user: 'me',
        ),
      );
      expect(EditorTarget.fromJson({'host': ''}), isNull);
      expect(EditorTarget.fromJson('x'), isNull);
    });
  });

  group('EditorTargetStore', () {
    test('saves and loads a target', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = EditorTargetStore(
        MemoryPrefsStore(),
        const FlutterSecureStorage(),
      );
      expect(await store.load('h'), isNull);
      await store.save('h', _ssh);
      expect(await store.load('h'), _ssh);
    });

    test('moves SSH terminal settings out of secure storage', () async {
      FlutterSecureStorage.setMockInitialValues({
        'ssh:h': jsonEncode({
          'host': 'box',
          'user': 'me',
          'password': 'secret',
        }),
        'ssh_known_hosts': '{}',
      });
      final prefs = MemoryPrefsStore();
      const secure = FlutterSecureStorage();
      final store = EditorTargetStore(prefs, secure);
      const moved = EditorTarget(
        location: EditorLocation.ssh,
        host: 'box',
        user: 'me',
      );
      expect(await store.load('h'), moved);
      expect(await secure.read(key: 'ssh:h'), isNull);
      expect(await secure.read(key: 'ssh_known_hosts'), isNull);
      expect(prefs.values['editor_target:h'], isNot(contains('secret')));
      expect(await store.load('h'), moved);
    });
  });

  testWidgets('opens a session and a folder in the chosen editor', (
    tester,
  ) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    final opened = <String>[];
    var installed = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...hostOverrides(
            connection: FakeHostConnection(
              HostState(
                status: ConnectionStatus.connected,
                serverInfo: const Implementation(name: 'pi'),
                sessions: catalogueFromSummaries([
                  session('1', directory: 'file:///src/app'),
                ]),
              ),
            ),
          ),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
          editorLauncherProvider.overrideWithValue((uri) async {
            opened.add('$uri');
            return installed;
          }),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The test host is on 127.0.0.1, so its folders are on this computer
    // and nothing is asked.
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open in VS Code'));
    await tester.pumpAndSettle();
    expect(opened, ['vscode://file/src/app']);

    // The host menu picks Cursor and an SSH host.
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('test host · Connected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editor settings…'));
    await tester.pumpAndSettle();
    expect(find.text('Open test host in an editor'), findsOneWidget);
    await tester.tap(find.text('Cursor'));
    await tester.tap(find.text('An SSH host'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the SSH host.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Host'), 'box');
    await tester.enterText(
      find.widgetWithText(TextField, 'User (optional)'),
      'me',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in Cursor'));
    await tester.pumpAndSettle();
    expect(opened.last, 'cursor://vscode-remote/ssh-remote+me@box/src/app');

    // The folder's header opens it too, from its menu.
    // The title bar names the folder too; the sidebar's header is last.
    await tester.tap(find.text('app').last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in Cursor'));
    await tester.pumpAndSettle();
    expect(opened, hasLength(3));
    expect(opened.last, opened[1]);

    installed = false;
    await tester.tap(find.byTooltip('Open in Cursor'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not open Cursor. Is it installed, with the Remote - SSH '
        'extension?',
      ),
      findsOneWidget,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a session without a folder has no editor button', (
    tester,
  ) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...hostOverrides(
            connection: FakeHostConnection(
              HostState(
                status: ConnectionStatus.connected,
                serverInfo: const Implementation(name: 'pi'),
                sessions: catalogueFromSummaries([session('1')]),
              ),
            ),
          ),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open in VS Code'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('phones and tablets have no editor', (tester) async {
    reduceMotion(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...hostOverrides(
            connection: FakeHostConnection(
              HostState(
                status: ConnectionStatus.connected,
                serverInfo: const Implementation(name: 'pi'),
                sessions: catalogueFromSummaries([
                  session('1', directory: 'file:///src/app'),
                ]),
              ),
            ),
          ),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open in VS Code'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
