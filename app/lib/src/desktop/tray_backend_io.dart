/// Native desktop [TrayBackend] using `tray_manager` (macOS, Linux, Windows).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:tray_manager/tray_manager.dart';

import '../hosts/open_hosts.dart';
import 'desktop_window.dart';
import 'tray_backend.dart';
import 'tray_menu_items.dart';

final _log = Logger('tray_menu');

/// Returns a [NativeTrayBackend] on desktop platforms, or null on mobile.
TrayBackend? createPlatformTrayBackend() =>
    isDesktop ? NativeTrayBackend() : null;

/// System tray icon and dropdown menu backed by `tray_manager`.
class NativeTrayBackend implements TrayBackend {
  TrayIcon? _trayIcon;
  Image? _icon;
  Menu? _menu;
  List<MenuItem> _items = const [];
  ListenerId? _trayListenerId;
  TrayMenuModel? _lastModel;
  bool _unavailable = false;
  final List<(Timer, Menu?, List<MenuItem>)> _pendingDisposals = [];

  TrayIcon? _ensureTrayIcon() {
    if (_unavailable) return null;
    if (_trayIcon case final existing?) return existing;
    try {
      if (!TrayManager.instance.isSupported()) {
        _unavailable = true;
        return null;
      }
      final trayIcon = TrayIcon.create();
      if (trayIcon == null) {
        _unavailable = true;
        return null;
      }
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      final iconPath = isMac
          ? 'assets/icon/icon-foreground.png'
          : 'assets/icon/icon-rounded.png';
      final icon = ImageAsset.fromAsset(iconPath);
      if (icon != null) {
        trayIcon.isIconTemplate = isMac;
        trayIcon.icon = icon;
        _icon = icon;
      } else {
        _log.warning('tray icon asset not found: $iconPath');
      }
      trayIcon.setContextMenuTrigger(ContextMenuTrigger.clicked);
      _trayListenerId = trayIcon.addListener((event) {
        if (event is TrayIconRightClickedEvent &&
            defaultTargetPlatform != TargetPlatform.linux) {
          trayIcon.openContextMenu();
        }
      });
      trayIcon.setVisible(true);
      _trayIcon = trayIcon;
      return trayIcon;
    } on Object catch (error) {
      _log.warning('system tray is not available: $error');
      _unavailable = true;
      return null;
    }
  }

  @override
  void update(
    TrayMenuModel model, {
    required ValueChanged<SessionRef> onSelectSession,
    required VoidCallback onShowWindow,
    required VoidCallback onQuit,
  }) {
    if (_lastModel == model) return;
    final trayIcon = _ensureTrayIcon();
    if (trayIcon == null) return;
    try {
      final menu = Menu.create();
      if (menu == null) return;
      final items = <MenuItem>[];

      void addHeader(String label) {
        final item = MenuItem.createWithLabelAndType(
          label,
          MenuItemType.normal,
        );
        if (item == null) return;
        item.isEnabled = false;
        items.add(item);
        menu.addItem(item);
      }

      void addAction(String label, VoidCallback onTap, {String? tooltip}) {
        final item = MenuItem.createWithLabelAndType(
          label,
          MenuItemType.normal,
        );
        if (item == null) return;
        if (tooltip != null && tooltip.isNotEmpty) {
          item.tooltip = tooltip;
        }
        item.addListener((event) {
          if (event is MenuItemClickedEvent) {
            onTap();
          }
        });
        items.add(item);
        menu.addItem(item);
      }

      if (model.active.isNotEmpty) {
        addHeader('Active');
        for (final conv in model.active) {
          addAction(
            conv.label,
            () => onSelectSession(conv.ref),
            tooltip: conv.tooltip,
          );
        }
      }

      if (model.active.isNotEmpty && model.pinned.isNotEmpty) {
        menu.addSeparator();
      }

      if (model.pinned.isNotEmpty) {
        addHeader('Pinned');
        for (final conv in model.pinned) {
          addAction(
            conv.label,
            () => onSelectSession(conv.ref),
            tooltip: conv.tooltip,
          );
        }
      }

      if (model.isEmpty) {
        addHeader('No active or pinned conversations');
      }

      menu.addSeparator();
      addAction('Show shireitou', onShowWindow);
      addAction('Quit shireitou', onQuit);

      trayIcon.setContextMenu(menu);
      trayIcon.setTooltip(model.tooltip);

      final oldMenu = _menu;
      final oldItems = _items;
      _menu = menu;
      _items = items;
      _lastModel = model;

      // Defer disposing the old menu so a click handler currently unwinding
      // on an old MenuItem outlives its own native callback.
      if (oldMenu != null || oldItems.isNotEmpty) {
        late final (Timer, Menu?, List<MenuItem>) entry;
        final timer = Timer(Duration.zero, () {
          _pendingDisposals.remove(entry);
          for (final item in oldItems) {
            item.dispose();
          }
          oldMenu?.dispose();
        });
        entry = (timer, oldMenu, oldItems);
        _pendingDisposals.add(entry);
      }
    } on Object catch (error) {
      _log.warning('could not update tray menu: $error');
    }
  }

  @override
  void dispose() {
    final trayIcon = _trayIcon;
    final listenerId = _trayListenerId;
    if (trayIcon != null && listenerId != null) {
      try {
        trayIcon.removeListener(listenerId);
      } on Object catch (error) {
        _log.fine('could not remove tray listener: $error');
      }
    }
    _trayListenerId = null;
    for (final (timer, oldMenu, oldItems) in _pendingDisposals) {
      timer.cancel();
      for (final item in oldItems) {
        item.dispose();
      }
      oldMenu?.dispose();
    }
    _pendingDisposals.clear();
    for (final item in _items) {
      item.dispose();
    }
    _items = const [];
    _menu?.dispose();
    _menu = null;
    _icon?.dispose();
    _icon = null;
    _trayIcon?.dispose();
    _trayIcon = null;
    _lastModel = null;
  }
}
