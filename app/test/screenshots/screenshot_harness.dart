/// Shared by the screenshot tests: real fonts, screen sizes, pumping the
/// app on a fixed host and writing PNGs. Widget tests draw text with a box
/// font by default, so the macOS system fonts are loaded; elsewhere the
/// tests skip themselves ([screenshotSkip]).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/prefs.dart';

import '../fake_connection.dart';
import '../fixtures.dart';

typedef Screen = ({Size size, double pixelRatio});

/// The reference screenshot's size: 3562×2224 pixels at 2× is 1781×1112
/// points, drawn at 120% zoom (its 13 px text measures 15.6 points), so
/// the app is rendered at 1484×927 logical pixels with a 1.2 pixel
/// ratio. The PNG is then half the reference's size, pixel for pixel.
const Screen desktop = (size: Size(1781, 1112), pixelRatio: 1.2);

/// A phone in portrait.
const Screen phone = (size: Size(390, 844), pixelRatio: 1.0);

const _systemFonts = '/System/Library/Fonts';

/// Without the macOS fonts the text would be boxes.
final screenshotSkip = !Directory(_systemFonts).existsSync();

final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);
final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

/// Loads [path] as the font [families], so text renders with real glyphs.
Future<void> _loadFont(String path, List<String> families) async {
  final bytes = File(path).readAsBytesSync();
  for (final family in families) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// Loads the system text and monospace fonts under the names the theme
/// asks for, the Material icons from the Flutter SDK and the codicons.
Future<void> loadScreenshotFonts() async {
  if (screenshotSkip) return;
  await _loadFont('$_systemFonts/SFNS.ttf', [
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.AppleSystemUIFont',
    'Roboto',
  ]);
  await _loadFont('$_systemFonts/SFNSMono.ttf', ['monospace', 'Menlo']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await _loadFont(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ['MaterialIcons'],
  );
  // The codicons (AppIcons) come with the app's assets.
  final codicons = await rootBundle.load(
    'packages/vscode_codicons/assets/codicon.ttf',
  );
  await (FontLoader(
    'packages/vscode_codicons/Codicon',
  )..addFont(Future.value(codicons))).load();
}

/// An ISO 8601 time [elapsed] ago.
String timeAgo(Duration elapsed) =>
    DateTime.now().toUtc().subtract(elapsed).toIso8601String();

/// Pumps the app connected to [host] on [screen] in [brightness], with
/// [prefs] as the stored settings, and, when [open] is given, taps the
/// first session row containing it. [chats] maps sessions to the chat
/// they open (else `ahp-chat:/1`).
Future<void> pumpApp(
  WidgetTester tester, {
  required HostState host,
  required Screen screen,
  required Brightness brightness,
  Map<String, String> prefs = const {},
  Map<String, String> chats = const {},
  String? open,
}) async {
  tester.view.physicalSize = screen.size;
  tester.view.devicePixelRatio = screen.pixelRatio;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  reduceMotion(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...hostOverrides(connection: FakeHostConnection(host, chats: chats)),
        prefsStoreProvider.overrideWithValue(MemoryPrefsStore(prefs)),
      ],
      child: const ShireitouApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (open == null) return;
  await tester.tap(find.textContaining(open).first);
  await tester.pumpAndSettle();
}

/// Writes the screen to `[dir]/[name].png`.
Future<void> capture(WidgetTester tester, Directory dir, String name) async {
  final element = tester.element(find.byType(ShireitouApp));
  await tester.runAsync(() async {
    final image = await captureImage(element);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    dir.createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
