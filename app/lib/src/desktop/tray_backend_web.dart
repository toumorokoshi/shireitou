/// Web stub for [TrayBackend] (browsers have no system tray).
library;

import 'tray_backend.dart';

/// Returns null on the web.
TrayBackend? createPlatformTrayBackend() => null;
