/// Drives the real app against the scripted fake host (in this process):
/// connect, open a session, approve and deny tool calls (AV-083), answer
/// and decline input requests (AV-084), answer a request from another chat
/// in the "Waiting for you" panel, and sign in to an MCP server; then code
/// blocks, grouped tool calls, live terminal output, inline diffs and the
/// review pane, a subagent chat and the chat switcher, queued messages,
/// drafts and paging in a windowed chat; then a second host, the merged
/// session list and host switcher, and the composer (host picker, folder
/// browser, model options, session settings, a session that fails to
/// start) and the follow-up mode picker; then the session list (search,
/// filters, archiving from the list, multi-select), keyboard shortcuts,
/// a rejected answer in the "Waiting for you" panel, client tool
/// executions, and the open hosts coming back after a restart.
///
/// ```sh
/// flutter test integration_test/fake_host_flows_test.dart -d linux
/// ```
library;

import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/desktop/app_menu.dart';
import 'package:shireitou/src/desktop/desktop_window.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/notifications/notifications.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/code_highlight.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_detail/session_status_widgets.dart';
import 'package:shireitou/src/shortcuts.dart';
import 'package:window_manager/window_manager.dart';

/// Keeps remembered hosts in memory. Secure storage is covered by the
/// desktop smoke test; here it would only add keychain prompts (macOS
/// asks before another build of the app reads the smoke test's item).
class _MemoryHostStore extends HostStore {
  _MemoryHostStore() : super(secureStorage);

  List<SavedHost> _hosts = const [];
  List<String> _open = const [];

  @override
  Future<List<SavedHost>> loadHosts() async => _hosts;

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async => _hosts = hosts;

  @override
  Future<List<String>> loadOpenHosts() async => _open;

  @override
  Future<void> saveOpenHosts(List<String> keys) async => _open = keys;
}

/// The app connected to a fresh fake host, with helpers that let real
/// I/O run between frames.
class _Harness {
  _Harness(this.tester, this.host, this.store, this.container);

  final WidgetTester tester;
  final FakeAhpHost host;
  final _MemoryHostStore store;

  /// The app's providers; [restart] replaces them.
  ProviderContainer container;

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
    final store = _MemoryHostStore();
    final harness = _Harness(tester, host, store, _container(store));
    addTearDown(() async {
      final container = harness.container;
      await tester.runAsync(
        () => container.read(openHostsProvider.notifier).disconnectAll(),
      );
      container.dispose();
      await tester.runAsync(host.close);
    });
    await harness._pumpApp();
    // Connect through the connect screen.
    await tester.enterText(
      find.widgetWithText(TextField, 'Host URL'),
      url.toString(),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await harness.waitFor(find.text('Scripted session'));
    return harness;
  }

  static ProviderContainer _container(_MemoryHostStore store) =>
      ProviderContainer(
        overrides: [
          hostStoreProvider.overrideWithValue(store),
          // No OS notifications (or permission prompts) from the tests.
          notifierProvider.overrideWithValue(null),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
        ],
      );

  Future<void> _pumpApp() async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Quits the app (its connections close without the user disconnecting)
  /// and starts it again with the same stored hosts.
  Future<void> restart() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    container = _container(store);
    await _pumpApp();
  }

  /// Runs [command] as its shortcut would: through the native menu on
  /// macOS (which simulated keys do not reach), else with the keys.
  Future<void> shortcut(AppCommand command) async {
    if (hasNativeMenuBar) {
      container.read(appCommandsProvider).send(command);
    } else {
      final activator = activatorFor(command);
      final modifiers = [
        if (activator.control) LogicalKeyboardKey.controlLeft,
        if (activator.meta) LogicalKeyboardKey.metaLeft,
        if (activator.alt) LogicalKeyboardKey.altLeft,
      ];
      for (final m in modifiers) {
        await tester.sendKeyDownEvent(m);
      }
      await tester.sendKeyEvent(activator.trigger);
      for (final m in modifiers.reversed) {
        await tester.sendKeyUpEvent(m);
      }
    }
    await settle();
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

  /// Pumps until [finder] finds nothing, letting real I/O run.
  Future<void> waitForNone(Finder finder) =>
      waitUntil('no $finder', () => finder.evaluate().isEmpty);

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
    // Not `find.byType(TextField).last`: a dialog that is still closing
    // (headless, frames only come from pumps) is later in the tree, and
    // its field can no longer take focus, so the text would be lost.
    await tester.enterText(
      find.descendant(
        of: find.byType(FollowUpInput),
        matching: find.byType(TextField),
      ),
      text,
    );
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

    // A todo list kept with TodoWrite (AV-070).
    debugPrint('fake host flows: todo list');
    await send('todo');
    await waitFor(find.text('All 3 steps are done.'));
    expect(find.text('Todo list · 3 of 3 done'), findsOneWidget);

    // A plan review: a described choice plus free-form feedback (AV-046).
    debugPrint('fake host flows: plan review');
    await send('plan');
    await waitFor(find.text('Implement Plan (recommended)'));
    await tapVisible(find.text('Approve Plan Only'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Or write your own answer'),
      'short flag',
    );
    await tester.pump();
    await tapVisible(find.widgetWithText(FilledButton, 'Submit'));
    await waitFor(find.textContaining('plan=exit_only + short flag'));

    // The pull request the host publishes in _meta (AV-105).
    debugPrint('fake host flows: pull request');
    await send('open a pr');
    await waitFor(find.widgetWithText(ActionChip, 'PR #42 · open'));
    expect(find.widgetWithText(ActionChip, 'main'), findsOneWidget);
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
      'the edit dialog to close',
      () => find.byType(AlertDialog).evaluate().isEmpty,
    );
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

  testWidgets('two hosts, the composer, session settings and a session '
      'that fails to start', (tester) async {
    final h = await _Harness.start(tester);
    final second = FakeAhpHost(
      token: 'second',
      name: 'second-host',
      titlePrefix: 'Other ',
      stepDelay: const Duration(milliseconds: 20),
    );
    final url = (await tester.runAsync(second.start))!;
    addTearDown(() => tester.runAsync(second.close));

    // Folder labels carry the branch the host reports in `_meta.git`.
    expect(find.textContaining('⎇ main'), findsWidgets);

    // Add the second host from the host switcher.
    await tester.tap(find.byTooltip('Switch host'));
    await h.settle();
    await tester.tap(find.text('Add host…'));
    await h.settle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Host URL'),
      url.toString(),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await h.waitFor(find.text('Other Scripted session'));
    // Let the "Add a host" page close.
    await h.settle();
    expect(find.text('Scripted session'), findsOneWidget);
    expect(find.text('All hosts'), findsOneWidget);
    expect(find.textContaining('second-host · ⎇ main'), findsOneWidget);

    // The switcher narrows the list to one host.
    await tester.tap(find.byTooltip('Switch host'));
    await h.settle();
    await tester.tap(find.text('second-host').last);
    await h.settle();
    expect(find.text('Scripted session'), findsNothing);
    expect(find.text('Other Scripted session'), findsOneWidget);

    // Start a session on the second host from its folder's "+" button.
    await tester.tap(find.byTooltip('New session in workspace'));
    await h.waitFor(find.text('Mode'));
    expect(find.text('second-host'), findsWidgets);
    await tester.tap(find.text('Host default'));
    await h.settle();
    await tester.tap(find.text('Scripted').last);
    await h.settle();
    await tester.tap(find.text('Medium'));
    await h.settle();
    await tester.tap(find.text('High').last);
    await h.settle();
    await tester.tap(find.text('Interactive'));
    await h.settle();
    await tester.tap(find.text('Plan').last);
    await h.settle();

    // Browse to a sub-folder; the repository's branch setting appears.
    await tester.tap(find.text('Browse…'));
    await h.waitFor(find.text('packages'));
    await tester.tap(find.text('packages'));
    await h.waitFor(find.text('api'));
    await tester.tap(find.text('api'));
    await h.waitFor(find.text('No sub-folders'));
    await tester.tap(find.text('Choose this folder'));
    await h.settle();
    await h.waitFor(find.widgetWithText(TextField, 'Branch'));
    await tester.enterText(find.widgetWithText(TextField, 'Branch'), 'fix');
    await h.waitFor(find.text('fix/crash'));
    await tester.tap(find.text('fix/crash'));
    await h.settle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Prompt'),
      'settings',
    );
    // Below the fold on small windows (the parallel runs row adds height).
    await h.tapVisible(find.text('Start session'));
    await h.waitFor(find.textContaining('thinkingLevel: high'));
    // Let the composer close.
    await h.settle();
    expect(find.textContaining('mode: plan'), findsOneWidget);
    expect(find.textContaining('branch: fix/crash'), findsOneWidget);

    // The mode may change mid-session (`session/configChanged`).
    await tester.tap(find.text('Plan'));
    await h.settle();
    await tester.tap(find.text('Autopilot').last);
    await h.waitUntil(
      'the mode change',
      () => second.received.any(
        (r) =>
            r.action['type'] == 'session/configChanged' &&
            (r.action['config'] as Map?)?['mode'] == 'autopilot',
      ),
    );

    // A session in a folder the host does not have fails at once, with
    // the host's error (not after the 30 s creation timeout).
    await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
    await h.waitFor(find.text('Start session'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Working directory'),
      '/missing',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Prompt'), 'hi');
    await h.tapVisible(find.text('Start session'));
    final started = DateTime.now();
    await h.waitFor(
      find.text('The session could not start: No such folder: /missing'),
    );
    expect(
      DateTime.now().difference(started),
      lessThan(const Duration(seconds: 10)),
    );
  });

  testWidgets('the session list, shortcuts, a rejected answer, client '
      'tools and restoring hosts after a restart', (tester) async {
    final h = await _Harness.start(tester);
    final host = h.host;
    final search = find.byWidgetPredicate(
      (w) =>
          w is TextField && (w.decoration?.hintText ?? '').startsWith('Search'),
    );

    // Search (AV-027) and the search shortcut (AV-140).
    debugPrint('fake host flows: search');
    await h.shortcut(AppCommand.searchSessions);
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    await tester.enterText(search, 'long');
    await h.settle();
    expect(find.text('Long session'), findsOneWidget);
    expect(find.text('Scripted session'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await h.settle();

    // Archive from the row menu; the Archived filter shows it, and a
    // swipe unarchives it (AV-022, AV-024).
    debugPrint('fake host flows: archive from the list');
    await tester.tap(find.text('Long session'), buttons: kSecondaryButton);
    await h.settle();
    await tester.tap(find.text('Archive'));
    await h.waitForNone(find.text('Long session'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Archived'));
    await h.waitFor(find.text('Long session'));
    await tester.drag(find.text('Long session'), const Offset(-600, 0));
    await h.waitForNone(find.text('Long session'));
    expect(host.session(longSession)!.status.isArchivedFlag, isFalse);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Done'));
    await h.waitFor(find.text('Long session'));

    // Multi-select marks both sessions unread, which the attention count
    // and the title show (AV-029, AV-120).
    debugPrint('fake host flows: multi-select');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
    await h.settle();
    await tester.longPress(find.text('Long session'));
    await h.settle();
    await tester.tap(find.text('Select'));
    await h.settle();
    await tester.tap(find.text('Scripted session'));
    await h.settle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Mark unread'));
    await h.waitFor(find.text('Needs attention (2)'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      '(2) shireitou',
    );

    // Next session opens the first row, which is marked read again.
    debugPrint('fake host flows: next session');
    await h.shortcut(AppCommand.nextSession);
    await h.waitFor(find.byType(SessionDetailView));
    await h.waitFor(find.text('Needs attention (1)'));
    if (find.text('No messages yet. Say something.').evaluate().isEmpty) {
      await tester.tap(find.text('Scripted session').first);
      await h.waitFor(find.text('No messages yet. Say something.'));
    }

    // A rejected answer from the "Waiting for you" panel comes back.
    debugPrint('fake host flows: rejected answer');
    host.rejectTypes.add('chat/inputCompleted');
    await h.send('side');
    final panel = find.byType(SessionInputPanel);
    await h.waitFor(panel);
    await h.tapVisible(
      find.descendant(of: panel, matching: find.text('Submit')),
    );
    await h.waitFor(find.textContaining('refused by this test host'));
    await h.waitFor(panel);
    host.rejectTypes.clear();
    await h.clearSnackBars();
    await h.tapVisible(
      find.descendant(of: panel, matching: find.text('Submit')),
    );
    await h.waitFor(find.textContaining('merge=yes'));
    expect(panel, findsNothing);

    // A tool another client runs is shown as such, not as a question; one
    // delegated to this app is turned down.
    debugPrint('fake host flows: client tools');
    await h.send('client');
    await h.waitFor(find.text('1 tool running on another client'));
    expect(panel, findsNothing);
    await h.waitFor(find.text('fake-ide opened the preview.'));
    await h.waitForNone(find.text('1 tool running on another client'));
    await h.send('delegate');
    await h.waitFor(find.textContaining('could not open the preview'));

    // Stop (Cmd/Ctrl+.) and focus the composer (Cmd/Ctrl+L).
    debugPrint('fake host flows: stop and focus shortcuts');
    await h.send('slow');
    await h.waitFor(find.byTooltip('Queue'));
    await h.shortcut(AppCommand.stop);
    await h.waitFor(find.byTooltip('Send'));
    FocusManager.instance.primaryFocus?.unfocus();
    await h.shortcut(AppCommand.focusComposer);
    final composer = find.descendant(
      of: find.byType(FollowUpInput),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(composer).focusNode!.hasFocus, isTrue);

    // The open host comes back after a restart, without the connect
    // screen.
    debugPrint('fake host flows: restart');
    await h.restart();
    await h.waitFor(find.text('Scripted session'));
    expect(find.text('Connect to a host'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
