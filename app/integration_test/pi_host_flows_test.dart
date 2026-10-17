/// Drives the real app against a real pi-agent-host-protocol host whose
/// model is pi's scripted faux provider (`scripts/pi-faux-host.ts`; no API
/// key): the composer (folder browser, model, start session), streamed
/// replies, reasoning, a tool call, follow-ups, stop, queued messages,
/// drafts, search, archive and the list filters; then reconnecting through
/// a [TcpRelay] after a dropped connection (replay of a running turn), a
/// message lost with the connection (rolled back) and a host restart.
///
/// Needs `node` and a pi-agent-host-protocol checkout with `npm ci`
/// (`PI_AHP_HOST_DIR`, default a sibling of this repo); skipped without
/// one. Runs on a desktop device or headless:
///
/// ```sh
/// just test-pi-app            # linux (needs a display)
/// just test-pi-app flutter-tester
/// ```
library;

import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shireitou/src/session_list/session_list_view.dart';
import 'package:shireitou/src/shortcuts.dart';

import 'harness.dart';

const _longTimeout = Duration(seconds: 60);

/// The app connected to [url] (a fresh pi), on its empty session list.
Future<AppHarness> _connect(WidgetTester tester, Uri url) async {
  final h = await AppHarness.launch(tester);
  await h.connect(url, find.text('No sessions yet.'));
  return h;
}

/// Starts pi with the faux model and a `greet` skill in its agent
/// directory (written first: pi reads its global skills at start). The
/// caller stops it; its state is deleted when the test ends.
Future<PiFauxHost> _startPi(WidgetTester tester) async {
  final pi = (await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('shireitou-pi-');
    final skill = File('${dir.path}/agent/skills/greet/SKILL.md');
    await skill.create(recursive: true);
    await skill.writeAsString(
      '---\nname: greet\ndescription: Says hello\n---\nSay hello.\n',
    );
    return PiFauxHost.start(stateDir: dir);
  }))!;
  addTearDown(() => tester.runAsync(() => pi.stateDir.delete(recursive: true)));
  return pi;
}

/// Starts a session from the composer in [folder] (picked with the folder
/// browser) with [prompt], and waits for pi's reply.
Future<void> _startSession(
  AppHarness h,
  String prompt, {
  String? folder,
}) async {
  final tester = h.tester;
  await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
  await h.waitFor(find.byTooltip('Start session'));
  if (folder != null) {
    // pi lists the host's folders (resourceList).
    await h.tapVisible(find.byTooltip('Browse…'));
    await h.waitFor(find.text(folder));
    await tester.tap(find.text(folder));
    await h.waitFor(find.text('No sub-folders'));
    await tester.tap(find.text('Choose this folder'));
    await h.settle();
  }
  await tester.enterText(h.composer, prompt);
  await h.tapVisible(find.byTooltip('Start session'));
  await h.waitFor(find.text('pi faux reply: $prompt'));
  // Let the draft turn into the session.
  await h.settle();
}

/// [text] in the session list (not the open session's header or timeline).
Finder _inList(String text) => find.descendant(
  of: find.byType(SessionListView),
  matching: find.text(text),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final skip = PiFauxHost.unavailable;
  if (skip != null) debugPrint('pi host flows skipped: $skip');

  testWidgets(
    'pi: the composer, streamed replies, a tool call, stop, '
    'queued messages, drafts, search, archive and filters',
    (tester) async {
      final pi = await _startPi(tester);
      addTearDown(() => tester.runAsync(pi.stop));
      final h = await _connect(tester, pi.url);

      // A client of its own checks what pi recorded.
      final observer = AhpClient(uri: pi.url, pingInterval: Duration.zero);
      await tester.runAsync(observer.connect);
      addTearDown(() => tester.runAsync(observer.close));

      debugPrint('pi host flows: start a session');
      await _startSession(h, 'hello pi', folder: 'src');
      final session = observer.state.sessions.keys.single;
      expect(observer.state.sessions[session]!.workingDirectories, [
        endsWith('/workspace/src'),
      ]);
      await h.waitFor(_inList('hello pi'));

      debugPrint('pi host flows: reasoning and a tool call');
      await h.send('think about it');
      await h.waitFor(find.text('Thought about: think about it'));
      await h.send('run a tool');
      await h.waitFor(find.text('The bash tool printed: hello from pi'));

      debugPrint('pi host flows: / completions in a new session');
      await tester.tap(find.byTooltip(RegExp(r'^New session \(')));
      await h.waitFor(find.byTooltip('Start session'));
      await tester.enterText(h.composer, '/gre');
      await h.waitFor(find.text('/greet'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await h.waitForNone(find.text('Says hello'));
      await tester.enterText(h.composer, '/greet the team');
      await h.tapVisible(find.byTooltip('Start session'));
      // The faux model echoes its prompt, which holds the skill's body.
      await h.waitFor(find.textContaining('Say hello.'));
      await h.settle();
      await tester.tap(_inList('hello pi'));
      await h.waitFor(find.text('pi faux reply: hello pi'));

      debugPrint('pi host flows: / completions in a follow-up');
      await h.type('/gre');
      await h.waitFor(find.text('/skill:greet'));
      expect(find.text('Says hello'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await h.waitForNone(find.text('Says hello'));
      expect(find.text('/skill:greet '), findsOneWidget);
      await h.type('');

      debugPrint('pi host flows: stop');
      await h.send('slow, then stop');
      await h.waitFor(find.textContaining('Counting slowly'));
      await tester.tap(find.byTooltip('Stop'));
      await h.waitFor(find.byTooltip('Send'));
      await h.waitFor(find.textContaining('Cancelled'));

      debugPrint('pi host flows: queued message');
      await h.send('slow again');
      await h.waitFor(find.byTooltip('Stop'));
      await h.clearSnackBars();
      await h.type('queued behind it');
      await tester.tap(find.byTooltip('Queue'));
      await h.followTimeline();
      await h.waitFor(
        find.text('pi faux reply: queued behind it', skipOffstage: false),
        timeout: _longTimeout,
      );

      debugPrint('pi host flows: draft');
      final chat = (await tester.runAsync(
        () => observer.openSession(session),
      ))!;
      await h.type('a draft for pi');
      await h.waitUntil(
        'the draft to reach pi',
        () =>
            observer.state.chatChannels[chat]?.state.draft?.text ==
            'a draft for pi',
      );
      await h.type('');

      debugPrint('pi host flows: search');
      await h.shortcut(AppCommand.searchSessions);
      await h.settle();
      final search = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText ?? '').startsWith('Search'),
      );
      await tester.enterText(search, 'nothing like it');
      await h.waitForNone(_inList('hello pi'));
      await tester.enterText(search, 'hello');
      await h.waitFor(_inList('hello pi'));
      await tester.tap(find.byTooltip('Close search'));
      await h.settle();

      debugPrint('pi host flows: archive and filters');
      await tester.tap(_inList('hello pi'), buttons: kSecondaryButton);
      await h.settle();
      await tester.tap(find.text('Archive').last);
      await h.waitForNone(_inList('hello pi'));
      await h.waitUntil(
        'pi to archive the session',
        () => observer.state.sessions[session]!.status.isArchivedFlag,
      );
      await h.pickFilter('Archived');
      await h.waitFor(_inList('hello pi'));
      await tester.drag(_inList('hello pi'), const Offset(-600, 0));
      await h.waitForNone(_inList('hello pi'));
      await h.waitUntil(
        'pi to unarchive the session',
        () => !observer.state.sessions[session]!.status.isArchivedFlag,
      );
      await h.pickFilter('All');
      await h.waitFor(_inList('hello pi'));
    },
    skip: skip != null,
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'pi: reconnecting after a dropped connection, a message lost '
    'with it, and a host restart',
    (tester) async {
      var pi = await _startPi(tester);
      addTearDown(() => tester.runAsync(() => pi.stop()));
      final relay = TcpRelay(target: pi.port);
      await tester.runAsync(relay.start);
      addTearDown(() => tester.runAsync(relay.close));
      final h = await _connect(tester, relay.relayed(pi.url));
      final reconnecting = find.text('Reconnecting…');
      await _startSession(h, 'hello pi');

      // The link drops in the middle of a reply; pi keeps streaming, and the
      // replay fills in what the app missed.
      debugPrint('pi host flows: dropped connection');
      await h.send('slow, across a reconnect');
      await h.waitFor(find.textContaining('Counting slowly'));
      relay
        ..refusing = true
        ..drop();
      await h.waitFor(reconnecting);
      await h.idle(1500);
      relay.refusing = false;
      await h.waitForNone(reconnecting);
      await h.followTimeline();
      await h.waitFor(
        find.textContaining('word3000 done.', skipOffstage: false),
        timeout: _longTimeout,
      );
      expect(find.textContaining('Done', skipOffstage: false), findsWidgets);

      // A message that never reached pi is rolled back, with a notice.
      debugPrint('pi host flows: lost message');
      relay.hold();
      await h.send('lost on the way');
      await h.waitFor(find.text('lost on the way'));
      relay.drop();
      await h.waitFor(
        find.textContaining('The connection dropped before the host confirmed'),
      );
      await h.waitForNone(find.text('lost on the way'));
      await h.waitForNone(reconnecting);

      // pi restarts: it no longer knows the app, which initializes again;
      // the session was saved and keeps its history.
      debugPrint('pi host flows: host restart');
      pi = (await tester.runAsync(pi.restart))!;
      relay.target = pi.port;
      await h.waitForNone(reconnecting, timeout: _longTimeout);
      await h.waitFor(
        find.textContaining('word3000 done.', skipOffstage: false),
      );
      await h.clearSnackBars();
      await h.send('after the restart');
      await h.waitFor(find.text('pi faux reply: after the restart'));
    },
    skip: skip != null,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
