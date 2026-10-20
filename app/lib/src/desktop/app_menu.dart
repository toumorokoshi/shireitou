/// The native macOS menu bar.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/open_hosts.dart';
import '../shortcuts.dart';

/// Whether [AppMenuBar] shows a native menu bar: only macOS has one.
bool get hasNativeMenuBar =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Wraps [child] in a native macOS menu bar (app, Session, Host, View and
/// Window menus). The Session menu carries the AV-140 shortcuts, which
/// the native menu handles on macOS; elsewhere [AppShortcuts] handles
/// them and this returns [child] unchanged.
class AppMenuBar extends ConsumerWidget {
  /// Creates the menu bar around [child].
  const AppMenuBar({required this.child, super.key});

  /// The app content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasNativeMenuBar) return child;
    final connected = ref.watch(
      openHostsProvider.select((hosts) => hosts.isNotEmpty),
    );
    return PlatformMenuBar(
      menus: appMenus(
        connected: connected,
        ref: ref,
        onCommand: ref.watch(appCommandsProvider).send,
      ),
      child: child,
    );
  }
}

/// The menu items for the AV-140 shortcuts, in groups, sending each
/// command to [onCommand]; disabled unless [connected].
List<PlatformMenuItem> sessionMenuItems({
  required bool connected,
  required ValueChanged<AppCommand> onCommand,
}) {
  PlatformMenuItem item(AppCommand command) => PlatformMenuItem(
    label: command.label,
    shortcut: activatorFor(command, apple: true),
    onSelected: connected ? () => onCommand(command) : null,
  );
  return [
    PlatformMenuItemGroup(
      members: [item(AppCommand.newSession), item(AppCommand.searchSessions)],
    ),
    PlatformMenuItemGroup(
      members: [item(AppCommand.nextSession), item(AppCommand.previousSession)],
    ),
    PlatformMenuItemGroup(
      members: [item(AppCommand.stop), item(AppCommand.focusComposer)],
    ),
    PlatformMenuItemGroup(
      members: [item(AppCommand.previousTurn), item(AppCommand.nextTurn)],
    ),
    PlatformMenuItemGroup(
      members: [
        item(AppCommand.toggleReviewPane),
        item(AppCommand.toggleTerminal),
      ],
    ),
  ];
}

/// The menus for the macOS menu bar. "Disconnect All" (⌘⇧D) and the
/// Session menu ([sessionMenuItems]) are enabled while [connected] to any
/// host.
List<PlatformMenuItem> appMenus({
  required bool connected,
  required WidgetRef ref,
  required ValueChanged<AppCommand> onCommand,
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
    label: 'Session',
    menus: sessionMenuItems(connected: connected, onCommand: onCommand),
  ),
  PlatformMenu(
    label: 'Host',
    menus: [
      PlatformMenuItem(
        label: 'Disconnect All',
        shortcut: const SingleActivator(
          LogicalKeyboardKey.keyD,
          meta: true,
          shift: true,
        ),
        onSelected: connected
            ? () => ref.read(openHostsProvider.notifier).disconnectAll()
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
