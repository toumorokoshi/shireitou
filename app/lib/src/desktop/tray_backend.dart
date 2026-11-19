/// Platform interface for the desktop system tray icon and dropdown menu.
library;

import 'package:flutter/foundation.dart';

import '../hosts/open_hosts.dart';
import 'tray_backend_web.dart' if (dart.library.io) 'tray_backend_io.dart';
import 'tray_menu_items.dart';

/// Creates the platform's [TrayBackend], or null where no tray exists
/// (web, mobile, or tests).
TrayBackend? createTrayBackend() => createPlatformTrayBackend();

/// Drives the native system tray icon and its context menu.
abstract class TrayBackend {
  /// Updates the tray icon's dropdown menu and tooltip to [model].
  void update(
    TrayMenuModel model, {
    required ValueChanged<SessionRef> onSelectSession,
    required VoidCallback onShowWindow,
    required VoidCallback onQuit,
  });

  /// Releases the tray icon and any native menu resources.
  void dispose();
}
