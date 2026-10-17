import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ahp_client/ahp_client.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/ssh/ssh_settings.dart';
import 'package:shireitou/src/ssh/ssh_shell.dart';
import 'package:shireitou/src/ssh/ssh_store.dart';
import 'package:shireitou/src/ssh/ssh_terminal.dart';
import 'package:shireitou/src/ssh/ssh_terminal_screen.dart';
import 'package:xterm/xterm.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

/// A shell that records what is written and lets the test write output
/// and end it.
class FakeShell implements SshShell {
  final _output = StreamController<Uint8List>();
  final _done = Completer<void>();

  /// What the terminal sent, decoded.
  final written = StringBuffer();

  /// The sizes the pty was given.
  final sizes = <(int, int)>[];
  var closed = false;

  void emit(String text) => _output.add(utf8.encode(text));

  void end([Object? error]) =>
      error == null ? _done.complete() : _done.completeError(error);

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  void write(Uint8List data) => written.write(utf8.decode(data));

  @override
  void resize(int columns, int rows) => sizes.add((columns, rows));

  @override
  Future<void> get done => _done.future;

  @override
  void close() => closed = true;
}

/// A connector that presents [hostKey] and then opens [shells] in turn,
/// or throws [error].
class FakeConnector {
  FakeConnector({this.error});

  final Object? error;
  final shells = <FakeShell>[];
  final requests = <SshSettings>[];
  var hostKey = (type: 'ssh-ed25519', fingerprint: 'SHA256:first');

  Future<SshShell> call(
    SshSettings settings, {
    required int columns,
    required int rows,
    required HostKeyCheck verifyHostKey,
  }) async {
    requests.add(settings);
    if (!await verifyHostKey(hostKey)) {
      throw SSHHostkeyError('Hostkey verification failed');
    }
    if (error case final error?) throw error;
    final shell = FakeShell();
    shells.add(shell);
    return shell;
  }
}

const _settings = SshSettings(
  host: 'build.example.com',
  user: 'me',
  password: 'secret',
);

String screenText(Terminal terminal) => terminal.buffer.getText();

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('SshTerminal', () {
    late FakeConnector connector;
    const store = SshStore(FlutterSecureStorage());

    SshTerminal terminal({String? directory}) => SshTerminal(
      settings: _settings,
      connector: connector.call,
      store: store,
      directory: directory,
    );

    setUp(() => connector = FakeConnector());

    test('trusts and remembers a new host key, then opens the shell in the '
        'folder', () async {
      final ssh = terminal(directory: '/src/my app');
      await ssh.connect();
      expect(ssh.status, SshStatus.connected);
      expect(screenText(ssh.terminal), contains('SHA256:first'));
      expect(await store.loadKnownHosts(), {
        'build.example.com:22': connector.hostKey,
      });
      final shell = connector.shells.single;
      expect(shell.written.toString(), "cd '/src/my app' && clear\n");

      shell.emit('hello\r\n');
      await pumpEventQueue();
      expect(screenText(ssh.terminal), contains('hello'));

      ssh.terminal.textInput('ls');
      expect(shell.written.toString(), endsWith('ls'));
      ssh.ctrlLatched = true;
      ssh.terminal.textInput('c');
      expect(shell.written.toString(), endsWith('\x03'));
      expect(ssh.ctrlLatched, isFalse);

      ssh.terminal.resize(100, 30);
      expect(shell.sizes.last, (100, 30));
      ssh.close();
      expect(shell.closed, isTrue);
    });

    test('refuses a changed host key and says why', () async {
      await store.saveKnownHost('build.example.com:22', (
        type: 'ssh-ed25519',
        fingerprint: 'SHA256:old',
      ));
      final ssh = terminal();
      await ssh.connect();
      expect(ssh.status, SshStatus.disconnected);
      expect(ssh.error, contains('has changed'));
      expect(ssh.error, contains('SHA256:old'));
      expect(connector.shells, isEmpty);
      expect(
        (await store.loadKnownHosts())['build.example.com:22']?.fingerprint,
        'SHA256:old',
      );
    });

    test('shows a disconnect and reconnects', () async {
      final ssh = terminal();
      await ssh.connect();
      connector.shells.single.end(SSHSocketError('reset by peer'));
      await pumpEventQueue();
      expect(ssh.status, SshStatus.disconnected);
      expect(ssh.error, contains('reset by peer'));

      await ssh.connect();
      expect(ssh.status, SshStatus.connected);
      expect(connector.shells, hasLength(2));
      connector.shells.last.end();
      await pumpEventQueue();
      expect(ssh.status, SshStatus.disconnected);
      expect(ssh.error, isNull);
      expect(screenText(ssh.terminal), contains('closed'));
    });

    test('describes authentication failures', () async {
      connector = FakeConnector(error: SSHAuthFailError('no more methods'));
      final ssh = terminal();
      await ssh.connect();
      expect(ssh.error, contains('Authentication as me'));
      expect(ssh.error, contains('password'));
    });
  });

  test('closing a tab shows its neighbour', () {
    final connector = FakeConnector();
    final container = ProviderContainer(
      overrides: [sshConnectorProvider.overrideWithValue(connector.call)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(sshTerminalsProvider.notifier);
    final a = notifier.open(_settings);
    final b = notifier.open(_settings);
    final c = notifier.open(_settings);
    expect(container.read(sshTerminalsProvider).selected, 2);
    notifier.close(c);
    expect(container.read(sshTerminalsProvider).terminals, [a, b]);
    expect(container.read(sshTerminalsProvider).selected, 1);
    notifier
      ..select(0)
      ..close(a);
    expect(container.read(sshTerminalsProvider).terminals, [b]);
    expect(container.read(sshTerminalsProvider).selected, 0);
  });

  testWidgets('opens a terminal from the host menu after asking for the '
      'settings', (tester) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final connector = FakeConnector();
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
          sshConnectorProvider.overrideWithValue(connector.call),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('test host actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(openSshTerminalLabel));
    await tester.pumpAndSettle();

    // No settings yet: the host defaults to the AHP host's address.
    expect(find.text('SSH to test host'), findsOneWidget);
    expect(find.widgetWithText(TextField, '127.0.0.1'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the user to log in as.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'User'), 'me');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('SSH terminals'), findsOneWidget);
    expect(find.text('Connected to me@127.0.0.1'), findsOneWidget);
    expect(connector.requests.single.password, 'secret');
    expect(
      await const SshStore(FlutterSecureStorage()).loadSettings(testHost.key),
      connector.requests.single,
    );

    connector.shells.single.end();
    await tester.pumpAndSettle();
    expect(find.text('Reconnect'), findsOneWidget);
    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();
    expect(connector.shells, hasLength(2));
    expect(find.text('Connected to me@127.0.0.1'), findsOneWidget);

    // A second terminal from the session's menu opens in its folder,
    // in another tab, without asking for the settings again.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(openSshTerminalLabel));
    await tester.pumpAndSettle();
    expect(connector.shells, hasLength(3));
    expect(
      connector.shells.last.written.toString(),
      "cd '/src/app' && clear\n",
    );
    expect(find.byType(InputChip), findsNWidgets(2));
    expect(find.text('app · 127.0.0.1'), findsOneWidget);

    await tester.tap(find.byTooltip('Close terminal').first);
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    expect(connector.shells[1].closed, isTrue);
  });
}
