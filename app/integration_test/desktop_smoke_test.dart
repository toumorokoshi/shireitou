/// Desktop smoke test: runs the real Linux or macOS app, checks the window
/// setup and placement saving, and, when `AHP_URL` is defined, connects to
/// that host (token in the `Authorization` header and `tkn`) and checks the
/// host is remembered in platform secure storage.
///
/// ```sh
/// flutter test integration_test -d linux --dart-define=AHP_URL='ws://…?tkn=…'
/// ```
library;

import 'package:ahp_client/ahp_client.dart';
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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    final saved = decodePlacement(
      await SharedPreferencesAsync().getString('window_placement'),
    );
    expect(saved?.bounds.size, const Size(900, 640));
  });

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
    final connection = container.read(hostConnectionProvider.notifier);
    await tester.runAsync(() => connection.connect(_url, name: 'smoke'));
    expect(
      container.read(hostConnectionProvider).status,
      ConnectionStatus.connected,
    );
    final hosts = await tester.runAsync(
      () => container.read(hostStoreProvider).loadHosts(),
    );
    expect(hosts!.first.label, 'smoke');
    await tester.runAsync(connection.disconnect);
  }, skip: _url.isEmpty);
}
