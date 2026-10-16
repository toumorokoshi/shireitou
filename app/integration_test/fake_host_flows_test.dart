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

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shireitou/src/session_detail/code_highlight.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_detail/session_status_widgets.dart';
import 'package:shireitou/src/shortcuts.dart';

import 'harness.dart';

/// The app connected through the connect screen to a fresh fake host.
Future<(AppHarness, FakeAhpHost)> _start(WidgetTester tester) async {
  final host = FakeAhpHost(
    token: 'integration',
    stepDelay: const Duration(milliseconds: 20),
    slowDuration: const Duration(seconds: 30),
  );
  final url = (await tester.runAsync(host.start))!;
  addTearDown(() => tester.runAsync(host.close));
  final h = await AppHarness.launch(
    tester,
    describeHost: () => [
      for (final r in host.received) '${r.channel} ${r.action}',
      for (final r in host.rejected) 'REJECTED ${r.channel} ${r.action}',
    ],
  );
  await h.connect(url, find.text('Scripted session'));
  return (h, host);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tool approvals, input requests and MCP sign-in against a '
      'host that asks', (tester) async {
    final (h, host) = await _start(tester);
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

    // MCP sign-in with a pasted token (the fallback to OAuth).
    debugPrint('fake host flows: MCP sign-in');
    await send('auth');
    await waitFor(find.text('Sign in'));
    await tapVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use an access token instead'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Access token'),
      fakePersonalToken,
    );
    await tester.tap(find.text('Use token'));
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

  testWidgets('OAuth sign-in, re-authentication, and host-provided '
      'confirmation options, risk, edited input, result confirmation and '
      'input drafts', (tester) async {
    final (h, host) = await _start(tester);
    browsed.clear();
    await tester.tap(find.text('Scripted session'));
    await h.waitFor(find.text('No messages yet. Say something.'));

    // Sign in with the browser: discovery, registration, PKCE, the
    // loopback redirect and the token exchange (AHP-060).
    debugPrint('fake host flows: OAuth sign-in');
    await h.send('auth');
    await h.waitFor(find.text('Sign in'));
    await h.tapVisible(find.text('Sign in'));
    await h.settle();
    expect(find.text('Access requested: $docsScope'), findsOneWidget);
    await tester.tap(find.text('Sign in with browser'));
    await h.waitFor(find.text('Signed in. I found 2 pages.'));
    expect(
      browsed.single.queryParameters,
      containsPair('resource', docsResource),
    );
    final pushed = host.received
        .where((r) => r.action['type'] == '#authenticate')
        .single
        .action;
    expect(pushed['token'], startsWith('at-'));
    expect(pushed['scopes'], [docsScope]);
    expect(host.oauthServer.log, [
      startsWith('register '),
      startsWith('authorize '),
      startsWith('token '),
    ]);

    // The host says the token expired: it is refreshed without asking
    // (AHP-061).
    debugPrint('fake host flows: expired token');
    await h.send('expire');
    await h.waitFor(find.text('Signed in to Example Docs again.'));
    expect(find.text('Sign in with browser'), findsNothing);
    expect(host.oauthServer.log.last, startsWith('refresh '));

    // Host-provided options in groups and a risk assessment (AV-083).
    debugPrint('fake host flows: options and risk');
    await h.send('choose');
    await h.waitFor(find.textContaining('High risk (safety 35%)'));
    expect(find.text('Approve'), findsNothing);
    await h.tapAndFollow(find.text('Allow in this session'));
    await h.waitFor(
      find.text(
        'You chose "Allow in this session", so I deleted build/.',
        skipOffstage: false,
      ),
    );

    // Edit the input before approving.
    debugPrint('fake host flows: edited input');
    await h.send('command');
    await h.waitFor(find.text('Edit input'));
    await h.tapVisible(find.text('Edit input'));
    await h.settle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Input'),
      '{"command": "git push origin feature"}',
    );
    await tester.tap(find.text('Save'));
    await h.settle();
    await h.tapAndFollow(find.text('Approve edited'));
    // Markdown drops the backticks around the command.
    await h.waitFor(
      find.textContaining(
        'Ran your edited command: git push origin feature.',
        skipOffstage: false,
      ),
    );

    // A result that waits for confirmation.
    debugPrint('fake host flows: result confirmation');
    await h.send('result');
    await h.waitFor(find.text('Use result'));
    expect(find.text('Status: all systems operational'), findsWidgets);
    await h.tapAndFollow(find.text('Use result'));
    await h.waitFor(
      find.text(
        'Using the result: all systems are operational.',
        skipOffstage: false,
      ),
    );

    // Input drafts: another client's draft fills a field, this client's
    // typing is synced (chat/inputAnswerChanged).
    debugPrint('fake host flows: input drafts');
    await h.send('draft');
    await h.waitFor(find.text(otherClientDraft));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Summary *'),
      'Faster builds',
    );
    await h.waitUntil(
      'the draft to reach the host',
      () => host.received.any(
        (r) => r.action['type'] == 'chat/inputAnswerChanged',
      ),
    );
    await h.tapAndFollow(find.widgetWithText(FilledButton, 'Submit'));
    await h.waitFor(
      find.textContaining(
        'summary=Faster builds, notes=$otherClientDraft. Drafts synced: 1.',
      ),
    );

    // An agent that needs sign-in: the composer says so, and starting a
    // session answers -32007 with a sign-in, then retries (AHP-061).
    debugPrint('fake host flows: -32007');
    await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
    await h.waitFor(find.text('Start session'));
    await h.pick(find.text('Fake agent'), 'Secured agent');
    expect(
      find.text('Secured agent needs you to sign in to Fake agent service.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Working directory'),
      '/workspace',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Prompt'), 'hi');
    await h.tapVisible(find.text('Start session'));
    await h.waitFor(find.text('Sign in to Fake agent service'));
    await tester.tap(find.text('Sign in with browser'));
    await h.waitFor(find.textContaining('You said: hi'));
    expect(
      host.received.where(
        (r) =>
            r.action['type'] == '#authenticate' &&
            r.action['resource'] == agentResource,
      ),
      hasLength(1),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('terminals, diffs, review, subagents, queued messages, drafts '
      'and paging against the fake host', (tester) async {
    final (h, host) = await _start(tester);
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
      if (DateTime.now().isAfter(deadline)) h.timedOut('Question 1');
      await tester.drag(timeline.first, const Offset(0, 3000));
      await h.idle(100);
    }
    expect(host.chat(longChat)!.turnsNextCursor, isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('two hosts, the composer, session settings and a session '
      'that fails to start', (tester) async {
    final (h, _) = await _start(tester);
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
    await h.pick(find.text('Host default'), 'Scripted');
    await h.pick(find.text('Medium'), 'High');
    await h.pick(find.text('Interactive'), 'Plan');

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
    final (h, host) = await _start(tester);
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

  testWidgets('reconnecting after a dropped connection: a replay, a lost '
      'action rolled back, a running turn kept and a session the host '
      'lost', (tester) async {
    final (h, host) = await _start(tester);
    await tester.tap(find.text('Scripted session'));
    await h.waitFor(find.text('No messages yet. Say something.'));
    final reconnecting = find.text('Reconnecting…');

    /// Drops the connection, runs [whileDown] while the app is kept out,
    /// then lets it back in and waits until it is connected again.
    Future<void> outage([Future<void> Function()? whileDown]) async {
      host.refuseConnections = true;
      await tester.runAsync(host.dropConnections);
      await h.waitFor(reconnecting);
      if (whileDown != null) await tester.runAsync(whileDown);
      host.refuseConnections = false;
      await h.waitForNone(reconnecting);
    }

    // Another client's turn while the app is away arrives in the replay.
    debugPrint('fake host flows: replay');
    await outage(() async {
      final other = AhpClient(
        uri: host.url!,
        connector: host.connectInMemory,
        pingInterval: Duration.zero,
      );
      await other.connect();
      final chat = (await other.openSession(seededSession))!;
      other.dispatch(
        chat,
        ChatTurnStartedAction(
          turnId: 'other-client',
          startedAt: DateTime.now().toUtc().toIso8601String(),
          message: userMessage('greetings from elsewhere'),
        ).toJson(),
      );
      await other.states.firstWhere(
        (s) => s.chatChannels[chat]!.state.turns.isNotEmpty,
      );
      await other.close();
    });
    await h.followTimeline();
    await h.waitFor(find.textContaining('You said: greetings from elsewhere'));

    // A message the host never received is rolled back after the
    // reconnect, with a notice.
    debugPrint('fake host flows: lost action');
    host.loseActions = true;
    await h.send('this one is lost');
    await h.waitFor(find.text('this one is lost'));
    await outage(() async => host.loseActions = false);
    await h.waitFor(
      find.textContaining('The connection dropped before the host confirmed'),
    );
    await h.waitForNone(find.text('this one is lost'));

    // A running turn survives the outage and can still be stopped.
    debugPrint('fake host flows: running turn');
    await h.send('slow');
    await h.waitFor(find.byTooltip('Queue'));
    await outage();
    await h.waitFor(find.byTooltip('Queue'));
    await h.clearSnackBars();
    await tester.tap(find.text('Stop'));
    await h.waitFor(find.byTooltip('Send'));

    // A session removed while the app was away is reported as gone.
    debugPrint('fake host flows: missing session');
    await tester.tap(find.text('Long session'));
    await h.waitFor(find.text('Question $longTurnCount'));
    await outage(() async => host.removeSession(longSession));
    await h.waitFor(
      find.text('This session is no longer available on the host.'),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
