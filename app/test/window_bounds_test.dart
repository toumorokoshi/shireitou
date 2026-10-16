import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/desktop/window_bounds.dart';

void main() {
  const screen = Rect.fromLTWH(0, 0, 1920, 1080);

  test('placement round-trips; malformed input is null', () {
    const placement = (
      bounds: Rect.fromLTWH(10, 20, 900, 700),
      maximized: true,
    );
    expect(decodePlacement(encodePlacement(placement)), placement);
    expect(decodePlacement(null), isNull);
    expect(decodePlacement('{"left": 1}'), isNull);
    expect(decodePlacement('nope'), isNull);
    expect(decodePlacement('{"left":0,"top":0,"width":0,"height":10}'), isNull);
  });

  test('first launch opens centered at the default size', () {
    final p = initialPlacement(null, [screen]);
    expect(p.size, defaultWindowSize);
    expect(p.position, isNull);
    expect(p.maximized, isFalse);
  });

  test('restores a saved placement that is on a display', () {
    final p = initialPlacement(
      (bounds: const Rect.fromLTWH(100, 50, 900, 700), maximized: true),
      [screen],
    );
    expect(p.size, const Size(900, 700));
    expect(p.position, const Offset(100, 50));
    expect(p.maximized, isTrue);
  });

  test('centers a window whose saved position is off every display', () {
    final p = initialPlacement(
      (bounds: const Rect.fromLTWH(2500, 100, 900, 700), maximized: false),
      [screen],
    );
    expect(p.position, isNull);
    expect(p.size, const Size(900, 700));
  });

  test('a window on a second display is restored there', () {
    const right = Rect.fromLTWH(1920, 0, 2560, 1440);
    final p = initialPlacement(
      (bounds: const Rect.fromLTWH(2500, 100, 900, 700), maximized: false),
      [screen, right],
    );
    expect(p.position, const Offset(2500, 100));
  });

  test('the size is never below the minimum', () {
    final p = initialPlacement(
      (bounds: const Rect.fromLTWH(0, 0, 200, 100), maximized: false),
      [screen],
    );
    expect(p.size, minimumWindowSize);
  });

  test('isReachable needs part of the title area on a display', () {
    expect(
      isReachable(const Rect.fromLTWH(1880, 0, 800, 600), [screen]),
      isFalse,
    );
    expect(
      isReachable(const Rect.fromLTWH(1700, 0, 800, 600), [screen]),
      isTrue,
    );
    expect(
      isReachable(const Rect.fromLTWH(0, 1070, 800, 600), [screen]),
      isFalse,
    );
    expect(isReachable(const Rect.fromLTWH(0, 0, 800, 600), const []), isFalse);
  });
}
