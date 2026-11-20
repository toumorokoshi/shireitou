/// The root widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/sign_in_dialog.dart';
import 'desktop/app_menu.dart';
import 'desktop/desktop_window.dart';
import 'desktop/tray_menu.dart';
import 'hosts/open_hosts.dart';
import 'notifications/notifications.dart';
import 'screens/connect_screen.dart';
import 'screens/sessions_screen.dart';
import 'session_list/session_filter.dart';
import 'shortcuts.dart';
import 'theme/app_theme.dart';
import 'theme/appearance.dart';
import 'theme/font_scale.dart';

/// The shireitou app: in the user's appearance (AV-097; by default the
/// system light/dark setting), and shows
/// the attention count in the window or tab title (AV-120).
class ShireitouApp extends ConsumerStatefulWidget {
  /// Creates the app.
  const ShireitouApp({super.key});

  @override
  ConsumerState<ShireitouApp> createState() => _ShireitouAppState();
}

class _ShireitouAppState extends ConsumerState<ShireitouApp> {
  String? _windowTitle;
  StreamSubscription<AppCommand>? _commands;

  @override
  void initState() {
    super.initState();
    _commands = ref.read(appCommandsProvider).stream.listen(_onCommand);
  }

  void _onCommand(AppCommand command) {
    final notifier = ref.read(fontScaleProvider.notifier);
    switch (command) {
      case AppCommand.increaseFontSize:
        unawaited(notifier.increase());
      case AppCommand.decreaseFontSize:
        unawaited(notifier.decrease());
      case AppCommand.resetFontSize:
        unawaited(notifier.reset());
      case AppCommand.newSession ||
          AppCommand.searchSessions ||
          AppCommand.nextSession ||
          AppCommand.previousSession ||
          AppCommand.stop ||
          AppCommand.focusComposer ||
          AppCommand.previousTurn ||
          AppCommand.nextTurn ||
          AppCommand.toggleReviewPane ||
          AppCommand.toggleTerminal:
        break;
    }
  }

  @override
  void dispose() {
    unawaited(_commands?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = windowTitle(ref.watch(attentionCountProvider));
    // MaterialApp's title is the browser tab's title on the web; native
    // windows need their own call.
    if (title != _windowTitle) {
      _windowTitle = title;
      unawaited(setWindowTitle(title));
    }
    final appearance = ref.watch(appearanceProvider);
    final fontScale = ref.watch(fontScaleProvider);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: title,
      theme: buildTheme(appearance.light),
      darkTheme: buildTheme(appearance.dark),
      themeMode: appearance.mode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: scaledTextScaler(media.textScaler, fontScale),
          ),
          child: TrayMenu(
            child: AttentionNotifications(
              child: AppShortcuts(
                enabled: !hasNativeMenuBar,
                child: AppMenuBar(child: child!),
              ),
            ),
          ),
        );
      },
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
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    ref.read(openHostsProvider.notifier).restore();
    // A device that slept may have dead sockets, or a backoff at its cap.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(openHostsProvider.notifier).checkConnections(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(
      hostInfosProvider.select((hosts) => hosts.any((h) => h.live)),
    );
    return live ? const SessionsScreen() : const ConnectScreen();
  }
}
