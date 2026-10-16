/// The root widget.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'host_connection.dart';
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
    home: const HomeScreen(),
  );
}

/// Shows the session list once connected, otherwise the connect screen.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hostConnectionProvider.select((s) => s.status));
    return switch (status) {
      ConnectionStatus.connected ||
      ConnectionStatus.reconnecting => const SessionsScreen(),
      _ => const ConnectScreen(),
    };
  }
}
