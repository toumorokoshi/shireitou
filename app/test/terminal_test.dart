import 'dart:async';
import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/editor/editor_store.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/terminal/pty_process.dart';
import 'package:shireitou/src/terminal/ssh_command.dart';
import 'package:shireitou/src/terminal/terminal_panel.dart';
import 'package:shireitou/src/terminal/terminal_session.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

/// A process that records what it is sent and exits when told.
class FakePty implements PtyProcess {
  FakePty(this.executable, this.arguments, this.environment);

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final _output = StreamController<Uint8List>();
  final _exit = Completer<int>();
  final typed = StringBuffer();
  final resizes = <(int, int)>[];
  var killed = false;

  void emit(String text) => _output.add(utf8.encode(text));

  void exit(int code) => _exit.complete(code);

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  void write(Uint8List data) => typed.write(utf8.decode(data));

  @override
  void resize(int rows, int columns) => resizes.add((rows, columns));

  @override
  void kill() => killed = true;
}

/// Starts [FakePty]s and keeps them.
class FakeSpawner {
  final started = <FakePty>[];
  Object? failure;

  PtyProcess call(
    String executable,
    List<String> arguments, {
    required Map<String, String> environment,
    required int rows,
    required int columns,
  }) {
    if (failure case final failure?) throw failure;
    final pty = FakePty(executable, arguments, environment);
    started.add(pty);
    return pty;
  }
}

String screenOf(TerminalSession session) => session.terminal.buffer.getText();

void main() {
  group('ssh command', () {
    test('the SSH host is the AHP URL host', () {
      expect(sshHostOf('ws://10.0.0.5:63877?tkn=x'), '10.0.0.5');
      expect(sshHostOf(' wss://build-box.lan/ahp '), 'build-box.lan');
      expect(sshHostOf('ws://[fe80::1]:1'), 'fe80::1');
      expect(sshHostOf('not a url'), isNull);
      expect(sshHostOf(''), isNull);
    });

    test('refuses hosts ssh would read as options or words', () {
      expect(validSshHost('box'), isTrue);
      expect(validSshHost('-oProxyCommand=evil'), isFalse);
      expect(validSshHost('a b'), isFalse);
      expect(validSshHost('a\nb'), isFalse);
      expect(validSshHost(''), isFalse);
    });

    test('runs a login shell in the folder', () {
      expect(sshArguments('box'), ['--', 'box']);
      expect(sshArguments('box', directory: "/src/it's"), [
        '-t',
        '--',
        'box',
        r"""cd '/src/it'\''s' 2>/dev/null; exec "$SHELL" -l""",
      ]);
    });

    test('passes the environment on with TERM set', () {
      expect(sshEnvironment({'SSH_AUTH_SOCK': '/agent', 'TERM': 'dumb'}), {
        'SSH_AUTH_SOCK': '/agent',
        'TERM': 'xterm-256color',
      });
    });

    test('links and labels', () {
      expect('${sshUri('box')}', 'ssh://box');
      expect('${sshUri('fe80::1')}', 'ssh://[fe80::1]');
      expect(terminalLabel('box', directory: '/src/app/'), 'app · box');
      expect(terminalLabel('box'), 'box');
    });

    test('the panel keeps room for the conversation', () {
      expect(clampedTerminalPanelHeight(50), minTerminalPanelHeight);
      expect(clampedTerminalPanelHeight(900, available: 400), 400);
      expect(
        clampedTerminalPanelHeight(900, available: 10),
        minTerminalPanelHeight,
      );
    });
  });

  group('TerminalSession', () {
    late FakeSpawner spawner;
    late TerminalSession session;

    setUp(() {
      spawner = FakeSpawner();
      session = TerminalSession(
        hostKey: 'h',
        host: 'box',
        directory: '/src/app',
        spawner: spawner.call,
        environment: const {'HOME': '/home/me'},
      );
    });

    test('runs ssh and wires the pty to the emulator', () async {
      session.start();
      final pty = spawner.started.single;
      expect(pty.executable, 'ssh');
      expect(pty.arguments, sshArguments('box', directory: '/src/app'));
      expect(pty.environment['HOME'], '/home/me');
      expect(session.running, isTrue);

      pty.emit('hello from box');
      await pumpEventQueue();
      expect(screenOf(session), contains('hello from box'));

      session.terminal.textInput('ls');
      expect('${pty.typed}', 'ls');

      session.terminal.resize(100, 30);
      expect(pty.resizes.last, (30, 100));
    });

    test('says when ssh exits and restarts it', () async {
      session.start();
      spawner.started.single.exit(255);
      await pumpEventQueue();
      expect(session.running, isFalse);
      expect(session.exitCode, 255);
      expect(screenOf(session), contains('[Process exited with code 255]'));

      session.start();
      expect(spawner.started, hasLength(2));
      expect(session.running, isTrue);
      expect(session.exitCode, isNull);
    });

    test('says when ssh cannot start', () {
      spawner.failure = StateError('no ssh');
      session.start();
      expect(session.running, isFalse);
      expect(screenOf(session), contains('Could not start ssh'));
    });

    test('close kills ssh', () {
      session.start();
      session.close();
      expect(spawner.started.single.killed, isTrue);
    });
  });

  test('terminals are kept per host', () {
    final spawner = FakeSpawner();
    final container = ProviderContainer(
      overrides: [
        ptySpawnerProvider.overrideWithValue(spawner.call),
        processEnvironmentProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(terminalsProvider.notifier);
    final a1 = notifier.open(hostKey: 'a', host: 'box');
    final b1 = notifier.open(hostKey: 'b', host: 'other');
    final a2 = notifier.open(hostKey: 'a', host: 'box');
    var tabs = container.read(terminalsProvider);
    expect(terminalsOf(tabs, 'a'), [a1, a2]);
    expect(tabs.selected, {'a': a2, 'b': b1});

    notifier.select(a1);
    notifier.close(a1);
    tabs = container.read(terminalsProvider);
    expect(terminalsOf(tabs, 'a'), [a2]);
    expect(tabs.selected['a'], a2);
    expect(spawner.started.first.killed, isTrue);

    notifier.close(b1);
    expect(container.read(terminalsProvider).selected.containsKey('b'), false);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    FakeSpawner? spawner,
    Future<bool> Function(Uri)? launcher,
  }) async {
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
                sessions: catalogueFromSummaries([
                  session('1', directory: 'file:///src/app'),
                ]),
              ),
            ),
          ),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
          if (spawner != null) ...[
            ptySpawnerProvider.overrideWithValue(spawner.call),
            processEnvironmentProvider.overrideWithValue(const {}),
          ],
          if (launcher != null)
            editorLauncherProvider.overrideWithValue(launcher),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('session 1'));
    await tester.pumpAndSettle();
  }

  testWidgets('the terminal panel opens ssh in the session folder', (
    tester,
  ) async {
    final spawner = FakeSpawner();
    await pumpApp(tester, spawner: spawner);
    expect(find.byType(TerminalPanel), findsNothing);

    await tester.tap(find.byTooltip(toggleTerminalLabel));
    await tester.pumpAndSettle();
    expect(find.byType(TerminalPanel), findsOneWidget);
    final pty = spawner.started.single;
    expect(pty.arguments, sshArguments('127.0.0.1', directory: '/src/app'));
    expect(find.text('app · 127.0.0.1'), findsOneWidget);
    // The conversation stays above the panel.
    expect(find.text('session 1'), findsWidgets);

    pty.emit('me@box:/src/app\$ ');
    await tester.pumpAndSettle();
    final session = tester
        .widget<TerminalTabView>(find.byType(TerminalTabView))
        .session;
    expect(screenOf(session), contains('me@box:/src/app'));

    // Another terminal from the session menu.
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newTerminalMenuLabel));
    await tester.pumpAndSettle();
    expect(spawner.started, hasLength(2));
    expect(find.text('app · 127.0.0.1'), findsNWidgets(2));

    // Its exit shows Restart.
    spawner.started.last.exit(0);
    await tester.pumpAndSettle();
    expect(find.text('app · 127.0.0.1 (exited)'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pumpAndSettle();
    expect(spawner.started, hasLength(3));

    // Closing a tab kills its ssh.
    await tester.tap(find.byTooltip('Close terminal').last);
    await tester.pumpAndSettle();
    expect(spawner.started.last.killed, isTrue);
    expect(find.text('app · 127.0.0.1'), findsOneWidget);

    // Maximize fills the session pane under the header and hides the
    // conversation; restore gives the panel its height back.
    double panelHeight() => tester.getSize(find.byType(TerminalPanel)).height;
    expect(panelHeight(), defaultTerminalPanelHeight);
    await tester.tap(find.byTooltip('Maximize panel'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Session actions'), findsOneWidget);
    expect(panelHeight(), greaterThan(defaultTerminalPanelHeight * 2));
    expect(
      find.byWidgetPredicate((w) => w is Offstage && w.offstage),
      findsWidgets,
    );
    await tester.tap(find.byTooltip('Restore panel size'));
    await tester.pumpAndSettle();
    expect(panelHeight(), defaultTerminalPanelHeight);

    // Alt+T and Ctrl+` close the panel, even from the terminal (without
    // typing into the shell), and reopen it with the same terminal.
    Future<void> press(
      LogicalKeyboardKey modifier,
      LogicalKeyboardKey key,
    ) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();
    }

    final typed = pty.typed.toString();
    await tester.tap(find.byType(TerminalTabView));
    await press(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyT);
    expect(find.byType(TerminalPanel), findsNothing);
    expect(pty.typed.toString(), typed);
    await press(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyT);
    expect(find.byType(TerminalPanel), findsOneWidget);
    await tester.tap(find.byType(TerminalTabView));
    await press(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.backquote);
    expect(find.byType(TerminalPanel), findsNothing);
    expect(pty.killed, isFalse);
    await press(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.backquote);
    expect(find.byType(TerminalPanel), findsOneWidget);
    await tester.tap(find.byTooltip(toggleTerminalLabel));
    await tester.pumpAndSettle();
    expect(find.byType(TerminalPanel), findsNothing);
    await tester.tap(find.byTooltip(toggleTerminalLabel));
    await tester.pumpAndSettle();
    expect(find.byType(TerminalPanel), findsOneWidget);
    expect(spawner.started, hasLength(3));

    // Hide keeps the terminal running.
    await tester.tap(find.byTooltip('Hide panel'));
    await tester.pumpAndSettle();
    expect(find.byType(TerminalPanel), findsNothing);
    expect(pty.killed, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('without a pty the button opens an ssh link', (tester) async {
    final opened = <Uri>[];
    var installed = true;
    await pumpApp(
      tester,
      launcher: (uri) async {
        opened.add(uri);
        return installed;
      },
    );
    await tester.tap(find.byTooltip(connectWithSshLabel));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('ssh://127.0.0.1')]);
    expect(find.byType(TerminalPanel), findsNothing);

    installed = false;
    await tester.tap(find.byTooltip(connectWithSshLabel));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not open ssh://127.0.0.1. Is an SSH app installed?'),
      findsOneWidget,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
