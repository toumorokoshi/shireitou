/// The root widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop/app_menu.dart';
import 'hosts/open_hosts.dart';
import 'screens/connect_screen.dart';
import 'screens/sessions_screen.dart';
import 'theme.dart';

/// The shireitou app: follows the system light/dark setting.
class ShireitouApp extends StatelessWidget {
  /// Creates the app.
  const ShireitouApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'shireitou',
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    builder: (context, child) => AppMenuBar(child: child!),
    home: const HomeScreen(),
  );
}

/// Shows the session list while any host is connected (or reconnecting),
/// otherwise the connect screen.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(
      hostInfosProvider.select((hosts) => hosts.any((h) => h.live)),
    );
    return live ? const SessionsScreen() : const ConnectScreen();
  }
}
