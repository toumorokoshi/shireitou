/// Drives the real app against the scripted fake host (in this process):
/// connect, open a session, approve and deny tool calls (AV-083), answer
/// and decline input requests (AV-084), answer a request from another chat
/// in the "Waiting for you" panel, and sign in to an MCP server.
///
/// ```sh
/// flutter test integration_test/fake_host_flows_test.dart -d linux
/// ```
library;

import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/session_detail/session_status_widgets.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tool approvals, input requests and MCP sign-in against a '
      'host that asks', (tester) async {
    final host = FakeAhpHost(
      token: 'integration',
      stepDelay: const Duration(milliseconds: 20),
    );
    final url = (await tester.runAsync(host.start))!;
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

    /// Pumps until [finder] finds something, letting real I/O run.
    Future<void> waitFor(Finder finder) async {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (finder.evaluate().isEmpty) {
        if (DateTime.now().isAfter(deadline)) {
          final texts = [
            for (final e in find.byType(Text).evaluate())
              (e.widget as Text).data,
          ];
          final received = [
            for (final r in host.received) '${r.channel} ${r.action}',
            for (final r in host.rejected) 'REJECTED ${r.channel} ${r.action}',
          ];
          fail(
            'timed out waiting for $finder; texts: $texts; '
            'host received: $received',
          );
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      await tester.pump();
    }

    Future<void> send(String text) async {
      // Wait for the previous turn to end, so this starts a new one.
      await waitFor(find.byTooltip('Send'));
      // The box keeps focus after sending, and enterText only attaches the
      // test keyboard when the focused field changes.
      FocusManager.instance.primaryFocus?.unfocus();
      tester.binding.focusedEditable = null;
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, text);
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
    }

    // Connect through the connect screen.
    await tester.enterText(
      find.widgetWithText(TextField, 'Host URL'),
      url.toString(),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await waitFor(find.text('Scripted session'));
    await tester.tap(find.text('Scripted session'));
    await waitFor(find.text('No messages yet. Say something.'));

    // Approve a tool call.
    await send('run the tool');
    await waitFor(find.text('Approve'));
    expect(find.text('Allow Bash to run `ls -la`?'), findsOneWidget);
    expect(find.text('Needs input'), findsWidgets);
    await tester.tap(find.text('Approve'));
    await waitFor(find.text('The folder has 3 entries.'));
    expect(find.text('Ran `ls -la`'), findsOneWidget);

    // Deny one.
    await send('tool again');
    await waitFor(find.text('Deny'));
    await tester.tap(find.text('Deny'));
    await waitFor(find.text('OK, I did not run it.'));

    // Answer an elicitation.
    await send('ask me');
    await waitFor(find.text('Where should I deploy?'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Release name *'),
      'v1',
    );
    await tester.tap(find.text('Environment *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staging').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await waitFor(find.textContaining('name=v1, env=staging'));

    // Decline one.
    await send('ask once more');
    await waitFor(find.widgetWithText(OutlinedButton, 'Decline'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Decline'));
    await waitFor(find.text('You declined, so I stopped.'));

    // A request from another chat, answered in the session panel.
    await send('side');
    final panel = find.byType(SessionInputPanel);
    await waitFor(panel);
    expect(find.text('In Reviewer'), findsOneWidget);
    await tester.tap(find.descendant(of: panel, matching: find.text('Submit')));
    await waitFor(find.textContaining('merge=yes'));
    expect(panel, findsNothing);

    // MCP sign-in with a pasted token.
    await send('auth');
    await waitFor(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
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
}
