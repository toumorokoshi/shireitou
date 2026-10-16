/// Native window setup on macOS, Linux and Windows: minimum size, and the
/// size, position and maximized state remembered across launches.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'window_bounds.dart';

final _log = Logger('desktop_window');

const _placementKey = 'window_placement';

/// Whether the app runs as a native desktop app.
bool get isDesktop =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      _ => false,
    };

/// Sets the minimum size, restores the saved placement, shows the window,
/// and starts saving its placement. Does nothing off desktop. Failures are
/// logged and the window is shown as the runner created it.
Future<void> setUpDesktopWindow() async {
  if (!isDesktop) return;
  try {
    await windowManager.ensureInitialized();
    final prefs = SharedPreferencesAsync();
    final saved = decodePlacement(await prefs.getString(_placementKey));
    final placement = initialPlacement(saved, await _displays());
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        title: 'shireitou',
        minimumSize: minimumWindowSize,
        size: placement.size,
        center: placement.position == null,
      ),
      () async {
        if (placement.position case final position?) {
          await windowManager.setPosition(position);
        }
        if (placement.maximized) await windowManager.maximize();
        await windowManager.show();
        await windowManager.focus();
      },
    );
    windowManager.addListener(_PlacementSaver(prefs));
  } on Object catch (error) {
    _log.warning('window setup failed: $error');
  }
}

/// The visible area of every display, in logical pixels.
Future<List<Rect>> _displays() async {
  try {
    return [
      for (final d in await screenRetriever.getAllDisplays())
        (d.visiblePosition ?? Offset.zero) & (d.visibleSize ?? d.size),
    ];
  } on Object catch (error) {
    _log.warning('could not list displays: $error');
    return const [];
  }
}

/// Saves the window's placement shortly after it stops moving or resizing.
/// While maximized or full screen, the last normal bounds are kept.
class _PlacementSaver with WindowListener {
  _PlacementSaver(this.prefs);

  final SharedPreferencesAsync prefs;
  Timer? _debounce;
  Rect? _normalBounds;

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (await windowManager.isFullScreen()) return;
      if (!maximized) _normalBounds = await windowManager.getBounds();
      final bounds = _normalBounds;
      if (bounds == null) return;
      await prefs.setString(
        _placementKey,
        encodePlacement((bounds: bounds, maximized: maximized)),
      );
    } on Object catch (error) {
      _log.warning('could not save the window placement: $error');
    }
  }

  @override
  void onWindowResize() => _schedule();

  @override
  void onWindowMove() => _schedule();

  @override
  void onWindowMaximize() => _schedule();

  @override
  void onWindowUnmaximize() => _schedule();
}
