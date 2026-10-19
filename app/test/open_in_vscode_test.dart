import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/ssh/ssh_settings.dart';
import 'package:shireitou/src/ssh/ssh_store.dart';
import 'package:shireitou/src/vscode/open_in_vscode.dart';
import 'package:shireitou/src/vscode/vscode_link.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

void main() {
  group('isLocalHost', () {
    test('is true for loopback addresses', () {
      expect(isLocalHost('ws://127.0.0.1:63877?tkn=x'), isTrue);
      expect(isLocalHost('ws://localhost:1'), isTrue);
      expect(isLocalHost('ws://LOCALHOST:1'), isTrue);
      expect(isLocalHost('ws://[::1]:1'), isTrue);
    });

    test('is false for other hosts and bad URLs', () {
      expect(isLocalHost('ws://10.0.0.5:63877'), isFalse);
      expect(isLocalHost('wss://box.example.com'), isFalse);
      expect(isLocalHost('::not a url'), isFalse);
    });
  });

  group('remoteSshAuthority', () {
    test('is user@host on port 22', () {
      expect(
        remoteSshAuthority(const SshSettings(host: 'box', user: 'me')),
        'me@box',
      );
    });

    test('is the host alone without a user', () {
      expect(remoteSshAuthority(const SshSettings(host: 'box')), 'box');
    });

    test('is hex-encoded JSON with another port', () {
      final authority = remoteSshAuthority(
        const SshSettings(host: 'box', user: 'me', port: 2222),
      );
      final bytes = [
        for (var i = 0; i < authority.length; i += 2)
          int.parse(authority.substring(i, i + 2), radix: 16),
      ];
      expect(jsonDecode(utf8.decode(bytes)), {
        'hostName': 'box',
        'user': 'me',
        'port': 2222,
      });
    });
  });

  group('vscodeFolderUri', () {
    test('opens the local folder for a host on this machine', () {
      expect(
        vscodeFolderUri(
          directory: '/src/my app',
          hostUrl: 'ws://127.0.0.1:1?tkn=x',
        ).toString(),
        'vscode://file/src/my%20app',
      );
    });

    test('opens the folder over SSH with the host settings', () {
      expect(
        vscodeFolderUri(
          directory: '/src/app',
          hostUrl: 'ws://10.0.0.5:1',
          ssh: const SshSettings(host: 'box', user: 'me'),
        ).toString(),
        'vscode://vscode-remote/ssh-remote+me@box/src/app',
      );
    });

    test("uses the AHP URL's host without SSH settings", () {
      expect(
        vscodeFolderUri(
          directory: '/src/app',
          hostUrl: 'ws://10.0.0.5:1',
        ).toString(),
        'vscode://vscode-remote/ssh-remote+10.0.0.5/src/app',
      );
    });
  });

  const remoteHost = SavedHost(url: 'ws://10.0.0.5:1', name: 'remote');

  Widget app({required List<Uri> opened, bool opens = true}) => ProviderScope(
    overrides: [
      ...hostOverrides(
        connections: {
          remoteHost: FakeHostConnection(
            HostState(
              status: ConnectionStatus.connected,
              serverInfo: const Implementation(name: 'pi'),
              sessions: catalogueFromSummaries([
                session('1', directory: 'file:///src/app'),
                session('2'),
              ]),
            ),
            host: remoteHost.key,
          ),
        },
      ),
      vscodeLauncherProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return opens;
      }),
    ],
    child: const ShireitouApp(),
  );

  void wideWindow(WidgetTester tester) {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

  testWidgets('the header button opens the session folder over SSH', (
    tester,
  ) async {
    wideWindow(tester);
    FlutterSecureStorage.setMockInitialValues({});
    await const SshStore(
      FlutterSecureStorage(),
    ).saveSettings(remoteHost.key, const SshSettings(host: 'box', user: 'me'));
    final opened = <Uri>[];
    await tester.pumpWidget(app(opened: opened));
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(openInVsCodeLabel));
    await tester.pumpAndSettle();
    expect(opened, [
      Uri.parse('vscode://vscode-remote/ssh-remote+me@box/src/app'),
    ]);

    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(openInVsCodeLabel));
    await tester.pumpAndSettle();
    expect(opened, hasLength(2));
  }, variant: desktop);

  testWidgets('a session without a folder has no button', (tester) async {
    wideWindow(tester);
    await tester.pumpWidget(app(opened: []));
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 2'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(openInVsCodeLabel), findsNothing);
  }, variant: desktop);

  testWidgets('there is no button on mobile', (tester) async {
    wideWindow(tester);
    await tester.pumpWidget(app(opened: []));
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(openInVsCodeLabel), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('says so when VS Code does not open', (tester) async {
    wideWindow(tester);
    await tester.pumpWidget(app(opened: [], opens: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(openInVsCodeLabel));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not open VS Code'), findsOneWidget);
  }, variant: desktop);
}
