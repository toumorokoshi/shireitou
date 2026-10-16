/// The native macOS menu bar.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';

/// Whether [AppMenuBar] shows a native menu bar: only macOS has one.
bool get hasNativeMenuBar =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Wraps [child] in a native macOS menu bar (app, Host, View and Window
/// menus). On other platforms it returns [child] unchanged.
class AppMenuBar extends ConsumerWidget {
  /// Creates the menu bar around [child].
  const AppMenuBar({required this.child, super.key});

  /// The app content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasNativeMenuBar) return child;
    final connected =
        ref.watch(hostConnectionProvider.select((s) => s.status)) !=
        ConnectionStatus.disconnected;
    return PlatformMenuBar(
      menus: appMenus(connected: connected, ref: ref),
      child: child,
    );
  }
}

/// The menus for the macOS menu bar. "Disconnect" (⌘⇧D) is enabled while
/// [connected].
List<PlatformMenuItem> appMenus({
  required bool connected,
  required WidgetRef ref,
}) => [
  PlatformMenu(
    label: 'shireitou',
    menus: [
      const PlatformMenuItemGroup(
        members: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
        ],
      ),
      const PlatformMenuItemGroup(
        members: [
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.servicesSubmenu,
          ),
        ],
      ),
      const PlatformMenuItemGroup(
        members: [
          PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.hideOtherApplications,
          ),
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.showAllApplications,
          ),
        ],
      ),
      const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
    ],
  ),
  PlatformMenu(
    label: 'Host',
    menus: [
      PlatformMenuItem(
        label: 'Disconnect',
        shortcut: const SingleActivator(
          LogicalKeyboardKey.keyD,
          meta: true,
          shift: true,
        ),
        onSelected: connected
            ? () => ref.read(hostConnectionProvider.notifier).disconnect()
            : null,
      ),
    ],
  ),
  const PlatformMenu(
    label: 'View',
    menus: [
      PlatformProvidedMenuItem(
        type: PlatformProvidedMenuItemType.toggleFullScreen,
      ),
    ],
  ),
  const PlatformMenu(
    label: 'Window',
    menus: [
      PlatformProvidedMenuItem(
        type: PlatformProvidedMenuItemType.minimizeWindow,
      ),
      PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.zoomWindow),
      PlatformProvidedMenuItem(
        type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
      ),
    ],
  ),
];
