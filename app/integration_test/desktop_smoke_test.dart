/// Desktop smoke test: runs the real Linux, macOS or Windows app, checks the
/// window setup, the minimum size (Linux and Windows) and placement saving, and, when `AHP_URL` is defined, connects to
/// that host (token in the `Authorization` header and `tkn`) and checks the
/// host is remembered in platform secure storage.
///
/// ```sh
/// flutter test integration_test -d linux --dart-define=AHP_URL='ws://…?tkn=…'
/// ```
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/desktop/desktop_window.dart';
import 'package:shireitou/src/desktop/window_bounds.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:window_manager/window_manager.dart';

const _url = String.fromEnvironment('AHP_URL');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Logger.root.onRecord.listen(
    (r) => debugPrint('${r.level.name} ${r.loggerName}: ${r.message}'),
  );

  testWidgets('the window opens at least at the minimum size and its '
      'placement is saved', (tester) async {
    await setUpDesktopWindow();
    final size = await windowManager.getSize();
    expect(size.width, greaterThanOrEqualTo(minimumWindowSize.width));
    expect(size.height, greaterThanOrEqualTo(minimumWindowSize.height));

    await windowManager.setSize(const Size(900, 640));
    if (defaultTargetPlatform == TargetPlatform.windows) {
      // Windows reports the user's resizing (WM_SIZING, WM_EXITSIZEMOVE),
      // not a size the app sets, so send the end of a drag ourselves.
      for (final listener in windowManager.listeners) {
        listener.onWindowResized();
      }
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    final saved = decodePlacement(
      await SharedPreferencesAsync().getString('window_placement'),
    );
    expect(saved?.bounds.size, const Size(900, 640));
  });

  testWidgets('the window cannot be made smaller than the minimum size', (
    tester,
  ) async {
    await setUpDesktopWindow();
    await windowManager.setSize(const Size(200, 150));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    final size = await windowManager.getSize();
    expect(size.width, greaterThanOrEqualTo(minimumWindowSize.width));
    expect(size.height, greaterThanOrEqualTo(minimumWindowSize.height));
    await windowManager.setSize(const Size(900, 640));
    // On macOS, AppKit applies the minimum to the user's resizing only, not
    // to frames the app sets; GTK and Win32 apply it to both.
  }, skip: defaultTargetPlatform == TargetPlatform.macOS);

  testWidgets('connects and remembers the host in secure storage', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShireitouApp(),
      ),
    );
    final host = SavedHost(url: _url, name: 'smoke');
    final open = container.read(openHostsProvider.notifier);
    await tester.runAsync(() => open.connect(host));
    expect(
      container.read(hostConnectionProvider(host.key)).status,
      ConnectionStatus.connected,
    );
    expect(container.read(hostStorageProblemProvider), isNull);
    final hosts = await tester.runAsync(
      () => container.read(hostStoreProvider).loadHosts(),
    );
    expect(hosts!.first.label, 'smoke');
    await tester.runAsync(open.disconnectAll);
  }, skip: _url.isEmpty);
}
