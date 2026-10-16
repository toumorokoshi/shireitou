/// Mobile smoke test: runs the real Android or iOS app, stores a host and
/// its tokens in platform secure storage (Android Keystore, iOS keychain),
/// and drives the compact (phone) layout against the scripted fake host
/// (in this process): connect, open a session, approve a tool call and
/// answer an input request.
///
/// ```sh
/// flutter test integration_test/mobile_smoke_test.dart -d emulator-5554
/// ```
///
/// Headless (`flutter test` without `-d`) it runs the layout part at a
/// phone's size and skips secure storage.
library;

import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';

import 'harness.dart';

final _onDevice = Platform.isAndroid || Platform.isIOS;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hosts and tokens survive in secure storage', (tester) async {
    const store = HostStore(secureStorage);
    const host = SavedHost(
      url: 'ws://192.168.1.20:63877',
      token: 't',
      name: 'lan',
    );
    final token = ResourceToken(
      token: 'access',
      obtainedAt: DateTime.utc(2026),
      refreshToken: 'refresh',
    );
    await tester.runAsync(() async {
      await store.saveHosts([host]);
      await store.saveTokens(host.key, {'https://mcp.example': token});
    });
    final hosts = await tester.runAsync(store.loadHosts);
    final tokens = await tester.runAsync(() => store.loadTokens(host.key));
    expect(hosts!.single.label, 'lan');
    expect(tokens!['https://mcp.example']?.token, 'access');
    await tester.runAsync(() async {
      await store.saveTokens(host.key, const {});
      await store.saveHosts(const []);
    });
  }, skip: !_onDevice);

  testWidgets('the phone layout against a host that asks', (tester) async {
    final host = FakeAhpHost(
      token: 'mobile',
      stepDelay: const Duration(milliseconds: 20),
    );
    final url = (await tester.runAsync(host.start))!;
    addTearDown(() => tester.runAsync(host.close));
    final h = await AppHarness.launch(
      tester,
      size: const Size(400, 860),
      describeHost: () => [
        for (final r in host.received) '${r.channel} ${r.action}',
      ],
    );
    // The on-screen keyboard takes half a phone's screen, so it is closed
    // after typing, and the timeline is followed to its newest row while
    // waiting (rows off screen are not built).
    Future<void> send(String text) async {
      await h.send(text);
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await h.settle();
    }

    Future<void> waitShown(Finder finder) async {
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (finder.evaluate().isEmpty) {
        if (DateTime.now().isAfter(deadline)) h.timedOut('$finder');
        await h.followTimeline();
        await h.idle();
      }
    }

    debugPrint('mobile flows: connect');
    await h.connect(url, find.text('Scripted session'));
    await h.tapVisible(find.text('Scripted session'));
    await h.waitFor(find.text('No messages yet. Say something.'));

    debugPrint('mobile flows: approve');
    await send('run the tool');
    await waitShown(find.text('Approve'));
    await h.tapAndFollow(find.text('Approve'));
    await waitShown(find.text('The folder has 3 entries.'));

    debugPrint('mobile flows: decline');
    await send('ask once more');
    await waitShown(find.widgetWithText(OutlinedButton, 'Decline'));
    await h.tapAndFollow(find.widgetWithText(OutlinedButton, 'Decline'));
    await waitShown(find.text('You declined, so I stopped.'));
  });
}
