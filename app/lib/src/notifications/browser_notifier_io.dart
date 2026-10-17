/// No browser notifications outside the web build (see
/// `browser_notifier_web.dart`).
library;

import 'package:flutter/foundation.dart';

import 'os_notifier.dart';

/// The browser's [OsNotifier]; null outside the web build.
OsNotifier? browserNotifier({required ValueChanged<String?> onOpen}) => null;
