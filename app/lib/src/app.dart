/// The root widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/sign_in_dialog.dart';
import 'desktop/app_menu.dart';
import 'desktop/desktop_window.dart';
import 'hosts/open_hosts.dart';
import 'notifications/notifications.dart';
import 'screens/connect_screen.dart';
import 'screens/sessions_screen.dart';
import 'session_list/session_filter.dart';
import 'shortcuts.dart';
import 'theme/app_theme.dart';

/// The shireitou app: follows the system light/dark setting, and shows
/// the attention count in the window or tab title (AV-120).
class ShireitouApp extends ConsumerStatefulWidget {
  /// Creates the app.
  const ShireitouApp({super.key});

  @override
  ConsumerState<ShireitouApp> createState() => _ShireitouAppState();
}

class _ShireitouAppState extends ConsumerState<ShireitouApp> {
  String? _windowTitle;

  @override
  Widget build(BuildContext context) {
    final title = windowTitle(ref.watch(attentionCountProvider));
    // MaterialApp's title is the browser tab's title on the web; native
    // windows need their own call.
    if (title != _windowTitle) {
      _windowTitle = title;
      unawaited(setWindowTitle(title));
    }
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: title,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) => AttentionNotifications(
        child: AppShortcuts(
          enabled: !hasNativeMenuBar,
          child: AppMenuBar(child: child!),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Shows the session list while any host is connected (or reconnecting),
/// otherwise the connect screen. On start it reconnects the hosts that
/// were open when the app last ran.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(openHostsProvider.notifier).restore();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(
      hostInfosProvider.select((hosts) => hosts.any((h) => h.live)),
    );
    return live ? const SessionsScreen() : const ConnectScreen();
  }
}
