/// Pure logic for the desktop window's size and position.
library;

import 'dart:convert';
import 'dart:ui';

/// The smallest window that still fits the compact layout.
const minimumWindowSize = Size(480, 360);

/// The window size on first launch.
const defaultWindowSize = Size(1280, 800);

/// How much of a saved window's title area must be on a display for it to
/// be restored there; otherwise it opens centered at its saved size.
const _minimumVisible = Size(100, 40);

/// A remembered window: its normal (unmaximized) [bounds] and whether it
/// was [maximized].
typedef WindowPlacement = ({Rect bounds, bool maximized});

/// Encodes [placement] for storage.
String encodePlacement(WindowPlacement placement) => jsonEncode({
  'left': placement.bounds.left,
  'top': placement.bounds.top,
  'width': placement.bounds.width,
  'height': placement.bounds.height,
  'maximized': placement.maximized,
});

/// Decodes a placement written by [encodePlacement]; null if malformed.
WindowPlacement? decodePlacement(String? encoded) {
  if (encoded == null) return null;
  try {
    final json = jsonDecode(encoded);
    if (json is! Map) return null;
    final [left, top, width, height] = [
      for (final key in ['left', 'top', 'width', 'height'])
        (json[key] as num).toDouble(),
    ];
    if (width <= 0 || height <= 0) return null;
    return (
      bounds: Rect.fromLTWH(left, top, width, height),
      maximized: json['maximized'] == true,
    );
  } on Object {
    return null;
  }
}

/// [size] grown to at least [minimum] in each dimension.
Size atLeast(Size size, Size minimum) => Size(
  size.width < minimum.width ? minimum.width : size.width,
  size.height < minimum.height ? minimum.height : size.height,
);

/// Whether enough of the top of [bounds] (where the title bar is) lies on
/// one of [displays] for the user to grab it.
bool isReachable(Rect bounds, List<Rect> displays) {
  final titleArea = Rect.fromLTWH(
    bounds.left,
    bounds.top,
    bounds.width,
    _minimumVisible.height,
  );
  return displays.any((display) {
    final overlap = titleArea.intersect(display);
    return overlap.width >= _minimumVisible.width &&
        overlap.height >= _minimumVisible.height / 2;
  });
}

/// Where to open the window, given the [saved] placement and the current
/// [displays]. The size is never below [minimum]. The position is null
/// (center the window) when nothing was saved, when [displays] is unknown,
/// or when the saved position is off every display, e.g. after a monitor
/// was unplugged.
({Size size, Offset? position, bool maximized}) initialPlacement(
  WindowPlacement? saved,
  List<Rect> displays, {
  Size minimum = minimumWindowSize,
  Size fallback = defaultWindowSize,
}) {
  if (saved == null) {
    return (size: atLeast(fallback, minimum), position: null, maximized: false);
  }
  final size = atLeast(saved.bounds.size, minimum);
  final reachable = isReachable(saved.bounds.topLeft & size, displays);
  return (
    size: size,
    position: reachable ? saved.bounds.topLeft : null,
    maximized: saved.maximized,
  );
}
