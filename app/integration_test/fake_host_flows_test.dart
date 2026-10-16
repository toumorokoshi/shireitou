/// Drives the real app against the scripted fake host (in this process):
/// connect, open a session, approve and deny tool calls (AV-083), answer
/// and decline input requests (AV-084), answer a request from another chat
/// in the "Waiting for you" panel, and sign in to an MCP server; then code
/// blocks, grouped tool calls, live terminal output, inline diffs and the
/// review pane, a subagent chat and the chat switcher, queued messages,
/// drafts and paging in a windowed chat.
///
/// ```sh
/// flutter test integration_test/fake_host_flows_test.dart -d linux
/// ```
library;

import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/desktop/desktop_window.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_detail/code_highlight.dart';
import 'package:shireitou/src/session_detail/session_status_widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Keeps remembered hosts in memory. Secure storage is covered by the
/// desktop smoke test; here it would only add keychain prompts (macOS
/// asks before another build of the app reads the smoke test's item).
class _MemoryHostStore extends HostStore {
  _MemoryHostStore() : super(secureStorage);

  List<SavedHost> _hosts = const [];

  @override
  Future<List<SavedHost>> loadHosts() async => _hosts;

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async => _hosts = hosts;
}

/// The app connected to a fresh fake host, with helpers that let real
/// I/O run between frames.
class _Harness {
  _Harness(this.tester, this.host);

  final WidgetTester tester;
  final FakeAhpHost host;

  static Future<_Harness> start(WidgetTester tester) async {
    final host = FakeAhpHost(
      token: 'integration',
      stepDelay: const Duration(milliseconds: 20),
      slowDuration: const Duration(seconds: 30),
    );
    final url = (await tester.runAsync(host.start))!;
    // The macOS runner starts with the window hidden (main() shows it), and
    // a hidden window renders no frames, so pumping would wait forever.
    // Then make room for the list, the panel, a whole input form and the
    // review pane (wide layout).
    final windowed = await tester.runAsync(() async {
      try {
        await setUpDesktopWindow();
        await windowManager.setSize(const Size(1400, 1000));
        return true;
      } on MissingPluginException {
        // The headless flutter-tester device (`flutter test` without -d)
        // has no window plugin.
        return false;
      }
    });
    if (windowed != true) {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final container = ProviderContainer(
      overrides: [hostStoreProvider.overrideWithValue(_MemoryHostStore())],
    );
    addTearDown(() async {
      await tester.runAsync(
        () => container.read(hostConnectionProvider.notifier).disconnect(),
      );
      container.dispose();
      await tester.runAsync(host.close);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
    final harness = _Harness(tester, host);
    // Connect through the connect screen.
    await tester.enterText(
      find.widgetWithText(TextField, 'Host URL'),
      url.toString(),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await harness.waitFor(find.text('Scripted session'));
    return harness;
  }

  /// Fails with what the screen shows and what the host received.
  Never _timedOut(String what) {
    final texts = [
      for (final e in find.byType(Text).evaluate()) (e.widget as Text).data,
    ];
    final received = [
      for (final r in host.received) '${r.channel} ${r.action}',
      for (final r in host.rejected) 'REJECTED ${r.channel} ${r.action}',
    ];
    fail(
      'timed out waiting for $what; texts: $texts; host received: $received',
    );
  }

  /// Lets real I/O and timers run, then pumps a frame.
  Future<void> idle([int ms = 50]) async {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: ms)),
    );
    await tester.pump();
  }

  /// Pumps until [finder] finds something, letting real I/O run.
  Future<void> waitFor(Finder finder) async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) _timedOut('$finder');
      await idle();
    }
    await tester.pump();
  }

  /// Pumps until [test] holds, letting real I/O run.
  Future<void> waitUntil(String what, bool Function() test) async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (!test()) {
      if (DateTime.now().isAfter(deadline)) _timedOut(what);
      await idle();
    }
  }

  /// A few frames apart, for menus and dialogs to open (spinners mean
  /// pumpAndSettle may never return).
  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls [finder] into view (small windows), then taps it.
  Future<void> tapVisible(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  /// Types [text] into the follow-up box.
  Future<void> type(String text) async {
    // The box keeps focus after sending, and enterText only attaches the
    // test keyboard when the focused field changes.
    FocusManager.instance.primaryFocus?.unfocus();
    tester.binding.focusedEditable = null;
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, text);
    await tester.pump();
  }

  /// Hides snackbars, which cover the follow-up box's buttons.
  Future<void> clearSnackBars() async {
    for (final messenger in tester.stateList<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    )) {
      messenger.clearSnackBars();
    }
    await settle();
  }

  Future<void> send(String text) async {
    // Wait for the previous turn to end, so this starts a new one.
    await waitFor(find.byTooltip('Send'));
    await clearSnackBars();
    await type(text);
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tool approvals, input requests and MCP sign-in against a '
      'host that asks', (tester) async {
    final h = await _Harness.start(tester);
    final host = h.host;
    final waitFor = h.waitFor;
    final tapVisible = h.tapVisible;
    final send = h.send;
    await tester.tap(find.text('Scripted session'));
    await waitFor(find.text('No messages yet. Say something.'));
    // Approve a tool call.
    debugPrint('fake host flows: approve');
    await send('run the tool');
    await waitFor(find.text('Approve'));
    expect(find.text('Allow Bash to run `ls -la`?'), findsOneWidget);
    expect(find.text('Needs input'), findsWidgets);
    await tapVisible(find.text('Approve'));
    await waitFor(find.text('The folder has 3 entries.'));
    expect(find.text('Ran `ls -la`'), findsOneWidget);

    // Deny one.
    debugPrint('fake host flows: deny');
    await send('tool again');
    await waitFor(find.text('Deny'));
    await tapVisible(find.text('Deny'));
    await waitFor(find.text('OK, I did not run it.'));

    // Answer an elicitation.
    debugPrint('fake host flows: answer');
    await send('ask me');
    await waitFor(find.text('Where should I deploy?'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Release name *'),
      'v1',
    );
    await tapVisible(find.text('Environment *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staging').last);
    await tester.pumpAndSettle();
    await tapVisible(find.widgetWithText(FilledButton, 'Submit'));
    await waitFor(find.textContaining('name=v1, env=staging'));

    // Decline one.
    debugPrint('fake host flows: decline');
    await send('ask once more');
    await waitFor(find.widgetWithText(OutlinedButton, 'Decline'));
    await tapVisible(find.widgetWithText(OutlinedButton, 'Decline'));
    await waitFor(find.text('You declined, so I stopped.'));

    // A request from another chat, answered in the session panel.
    debugPrint('fake host flows: side chat');
    await send('side');
    final panel = find.byType(SessionInputPanel);
    await waitFor(panel);
    expect(find.text('In Reviewer'), findsOneWidget);
    await tapVisible(find.descendant(of: panel, matching: find.text('Submit')));
    await waitFor(find.textContaining('merge=yes'));
    expect(panel, findsNothing);

    // MCP sign-in with a pasted token.
    debugPrint('fake host flows: MCP sign-in');
    await send('auth');
    await waitFor(find.text('Sign in'));
    await tapVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Access token'),
      'mcp-token',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in').last);
    await waitFor(find.text('Signed in. I found 2 pages.'));
    expect(
      host.received.where((r) => r.action['type'] == '#authenticate'),
      hasLength(1),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('terminals, diffs, review, subagents, queued messages, drafts '
      'and paging against the fake host', (tester) async {
    final h = await _Harness.start(tester);
    final host = h.host;
    await tester.tap(find.text('Scripted session'));
    await h.waitFor(find.text('No messages yet. Say something.'));

    // Syntax-highlighted code with a copy button (AV-061), and grouped
    // reads (AV-064).
    debugPrint('fake host flows: code and grouping');
    await h.send('read code');
    await h.waitFor(find.byTooltip('Copy code'));
    expect(find.byType(CodeBlock), findsOneWidget);
    await h.waitFor(find.text('Read · 3 calls'));

    // Live terminal output (AV-065, AHP-028).
    debugPrint('fake host flows: shell');
    await h.send('shell');
    await h.waitFor(find.textContaining('00:02 +3: All tests passed!'));
    await h.waitFor(find.text('All 3 tests passed.'));

    // An inline diff, then the review pane: review, revert, commit
    // (AV-065, AV-100 to AV-103).
    debugPrint('fake host flows: edit and review');
    await h.send('edit');
    await h.waitFor(find.text('Edited README.md.'));
    await h.waitFor(find.text('A scripted host for tests.'));
    await h.waitFor(find.text('Reviewed 0 of 1'));
    expect(find.text('1 file · +3 −1'), findsOneWidget);
    await h.tapVisible(find.byType(Checkbox));
    await h.waitFor(find.text('Reviewed 1 of 1'));
    await h.waitUntil(
      'the host to record the review',
      () =>
          host
              .changeset('ahp-changeset:/scripted/session')
              ?.files
              .single
              .reviewed ??
          false,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Commit'));
    await h.settle();
    await tester.tap(find.widgetWithText(FilledButton, 'Commit').last);
    await h.waitFor(find.text('Committed 1 file.'));
    await h.waitFor(find.text('No changed files.'));

    // A subagent's chat, opened from its card, then moved (AV-069).
    debugPrint('fake host flows: subagent');
    await h.send('subagent');
    await h.waitFor(find.text('The explorer found 3 modules.'));
    await h.tapVisible(find.text('Open chat'));
    await h.waitFor(find.text('Found 3 modules: api, core and ui.'));
    expect(find.text('This chat is read-only.'), findsOneWidget);
    await tester.tap(find.byTooltip('Chat actions'));
    await h.settle();
    await tester.tap(find.text('Move left'));
    await h.waitUntil(
      'the explorer chat to move first',
      () => host.session(seededSession)!.chats.first.title == 'Explorer',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Scripted session'));
    await h.waitFor(find.byTooltip('Send'));

    // Queued messages during a slow turn: edit and reorder (AV-081).
    debugPrint('fake host flows: queued messages');
    await h.send('slow');
    await h.waitFor(find.byTooltip('Queue'));
    await h.clearSnackBars();
    for (final text in ['first', 'second']) {
      await h.type(text);
      await tester.tap(find.byTooltip('Queue'));
      await h.waitFor(find.text(text));
    }
    await tester.tap(find.byTooltip('Message actions').last);
    await h.settle();
    await tester.tap(find.text('Move up'));
    await h.settle();
    await tester.tap(find.byTooltip('Message actions').last);
    await h.settle();
    await tester.tap(find.text('Edit'));
    await h.settle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Message'),
      'first, edited',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await h.waitUntil(
      'the host to reorder and edit the queue',
      () =>
          (host.chat(seededChat)!.queuedMessages ?? const [])
              .map((m) => m.message.text)
              .join('|') ==
          'second|first, edited',
    );
    await tester.tap(find.text('Stop'));
    await h.waitFor(find.byTooltip('Send'));

    // Drafts are synced to the host (chat/draftChanged).
    debugPrint('fake host flows: draft');
    await h.type('a draft');
    await h.waitUntil(
      'the draft to reach the host',
      () => host.chat(seededChat)!.draft?.text == 'a draft',
    );

    // A long, windowed chat pages in older turns on scroll (AV-068).
    debugPrint('fake host flows: paging');
    await tester.tap(find.text('Long session'));
    await h.waitFor(find.text('Question $longTurnCount'));
    final timeline = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.up,
    );
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (find.text('Question 1').evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) h._timedOut('Question 1');
      await tester.drag(timeline.first, const Offset(0, 3000));
      await h.idle(100);
    }
    expect(host.chat(longChat)!.turnsNextCursor, isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
