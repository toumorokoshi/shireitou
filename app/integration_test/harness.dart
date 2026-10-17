/// Shared driver for the app-level integration tests (the fake host and
/// pi flows): the app with in-memory hosts and preferences, a window big
/// enough for the wide layout, and helpers that let real I/O run between
/// frames.
library;

import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/auth/oauth_browser.dart';
import 'package:shireitou/src/desktop/app_menu.dart';
import 'package:shireitou/src/desktop/desktop_window.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/notifications/notifications.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/shortcuts.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:window_manager/window_manager.dart';

/// Keeps remembered hosts in memory. Secure storage is covered by the
/// desktop smoke test; here it would only add keychain prompts (macOS
/// asks before another build of the app reads the smoke test's item).
class MemoryHostStore extends HostStore {
  /// An empty store.
  MemoryHostStore() : super(secureStorage);

  List<SavedHost> _hosts = const [];
  List<String> _open = const [];

  @override
  Future<List<SavedHost>> loadHosts() async => _hosts;

  @override
  Future<void> saveHosts(List<SavedHost> hosts) async => _hosts = hosts;

  @override
  Future<List<String>> loadOpenHosts() async => _open;

  @override
  Future<void> saveOpenHosts(List<String> keys) async => _open = keys;

  final _tokens = <String, Map<String, ResourceToken>>{};

  @override
  Future<Map<String, ResourceToken>> loadTokens(String hostKey) async =>
      _tokens[hostKey] ?? const {};

  @override
  Future<void> saveTokens(
    String hostKey,
    Map<String, ResourceToken> tokens,
  ) async => _tokens[hostKey] = tokens;
}

/// URLs the test's "browser" opened.
final browsed = <Uri>[];

/// The system browser, played by the test: it loads the authorization
/// URL; the fake authorization server approves at once and redirects to
/// the app's loopback receiver, which `http` follows.
final testBrowser = OAuthBrowser(
  receiver: LoopbackRedirectReceiver.start,
  open: (url) async {
    browsed.add(url);
    await http.get(url);
  },
);

/// The app under test, with helpers that let real I/O run between frames.
class AppHarness {
  AppHarness._(this.tester, this.store, this.container, this.describeHost);

  /// The running test.
  final WidgetTester tester;

  /// Where the app keeps its hosts; survives [restart].
  final MemoryHostStore store;

  /// What the host saw, added to timeout failures.
  final List<String> Function() describeHost;

  /// The app's providers; [restart] replaces them.
  ProviderContainer container;

  /// Sizes the window (to [size]), pumps the app and disconnects every
  /// host when the test ends. On a phone or tablet the app keeps the
  /// device's screen; headless (`flutter-tester`) it gets [size].
  static Future<AppHarness> launch(
    WidgetTester tester, {
    List<String> Function()? describeHost,
    Size size = const Size(1400, 1000),
  }) async {
    // The macOS runner starts with the window hidden (main() shows it), and
    // a hidden window renders no frames, so pumping would wait forever.
    // Then make room for the list, the panel, a whole input form and the
    // review pane (wide layout).
    final windowed = await tester.runAsync(() async {
      try {
        await setUpDesktopWindow();
        await windowManager.setSize(size);
        // A window cannot be larger than the screen (Windows), and a
        // smaller one gets a narrower layout.
        debugPrint('window size: ${await windowManager.getSize()}');
        return true;
      } on MissingPluginException {
        // The headless flutter-tester device (`flutter test` without -d)
        // and mobile devices have no window plugin.
        return false;
      }
    });
    if (windowed != true && !Platform.isAndroid && !Platform.isIOS) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final store = MemoryHostStore();
    final harness = AppHarness._(
      tester,
      store,
      _container(store),
      describeHost ?? () => const [],
    );
    addTearDown(() async {
      final container = harness.container;
      await tester.runAsync(
        () => container.read(openHostsProvider.notifier).disconnectAll(),
      );
      container.dispose();
    });
    await harness._pumpApp();
    return harness;
  }

  static ProviderContainer _container(MemoryHostStore store) =>
      ProviderContainer(
        overrides: [
          hostStoreProvider.overrideWithValue(store),
          // No OS notifications (or permission prompts) from the tests.
          notifierProvider.overrideWithValue(null),
          prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
          oauthBrowserProvider.overrideWithValue(testBrowser),
        ],
      );

  Future<void> _pumpApp() async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Connects to [url] through the connect screen and waits for [shown].
  Future<void> connect(Uri url, Finder shown) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Host URL'),
      url.toString(),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await waitFor(shown);
  }

  /// Quits the app (its connections close without the user disconnecting)
  /// and starts it again with the same stored hosts.
  Future<void> restart() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    container = _container(store);
    await _pumpApp();
  }

  /// Runs [command] as its shortcut would: through the native menu on
  /// macOS (which simulated keys do not reach), else with the keys.
  Future<void> shortcut(AppCommand command) async {
    if (hasNativeMenuBar) {
      container.read(appCommandsProvider).send(command);
    } else {
      final activator = activatorFor(command);
      final modifiers = [
        if (activator.control) LogicalKeyboardKey.controlLeft,
        if (activator.meta) LogicalKeyboardKey.metaLeft,
        if (activator.alt) LogicalKeyboardKey.altLeft,
      ];
      for (final m in modifiers) {
        await tester.sendKeyDownEvent(m);
      }
      await tester.sendKeyEvent(activator.trigger);
      for (final m in modifiers.reversed) {
        await tester.sendKeyUpEvent(m);
      }
    }
    await settle();
  }

  /// Fails with what the screen shows and what the host received.
  Never timedOut(String what) {
    final texts = [
      for (final e in find.byType(Text).evaluate()) (e.widget as Text).data,
    ];
    fail(
      'timed out waiting for $what; texts: $texts; '
      'host received: ${describeHost()}',
    );
  }

  /// Lets real I/O and timers run, then pumps a frame.
  Future<void> idle([int ms = 50]) async {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: ms)),
    );
    await tester.pump();
  }

  /// Pumps until [finder] finds something, letting real I/O run.
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) timedOut('$finder');
      await idle();
    }
    await tester.pump();
  }

  /// Pumps until [finder] finds nothing, letting real I/O run.
  Future<void> waitForNone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) => waitUntil(
    'no $finder',
    () => finder.evaluate().isEmpty,
    timeout: timeout,
  );

  /// Pumps until [test] holds, letting real I/O run.
  Future<void> waitUntil(
    String what,
    bool Function() test, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!test()) {
      if (DateTime.now().isAfter(deadline)) timedOut(what);
      await idle();
    }
  }

  /// A few frames apart, for menus and dialogs to open (spinners mean
  /// pumpAndSettle may never return).
  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls [finder] into view (small windows), then taps it.
  Future<void> tapVisible(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  /// Taps [finder] after scrolling it into view, then scrolls the
  /// timeline back to the newest row, so replies that arrive next are
  /// built on screen (a tall approval bar can push the list up on a
  /// small window).
  Future<void> tapAndFollow(Finder finder) async {
    await tapVisible(finder);
    await settle();
    await followTimeline();
  }

  /// Expands the newest turn's steps line ("Completed N steps…",
  /// AV-095), so its tool calls, terminals and diffs are built.
  Future<void> expandSteps() async {
    final steps = find.textContaining(
      RegExp(r'^(Completed|Working…) \d+ steps?'),
    );
    await waitFor(steps);
    final newest =
        [for (var i = 0; i < steps.evaluate().length; i++) steps.at(i)].reduce(
          (a, b) => tester.getTopLeft(a).dy >= tester.getTopLeft(b).dy ? a : b,
        );
    await tapVisible(newest);
    await settle();
  }

  /// Scrolls the timeline back to the newest row when it is scrolled up:
  /// with "Jump to latest" when it shows, else directly (it shows only
  /// past 200 px, and rows below that may not be built).
  Future<void> followTimeline() async {
    final jump = find.byTooltip('Jump to latest');
    if (jump.evaluate().isNotEmpty) {
      await tester.tap(jump.first);
      await settle();
    }
    final timeline = find.descendant(
      of: find.byType(SuperListView),
      matching: find.byType(Scrollable),
    );
    if (timeline.evaluate().isEmpty) return;
    final position = tester.state<ScrollableState>(timeline.first).position;
    if (position.pixels != 0) {
      position.jumpTo(0);
      await settle();
    }
  }

  /// Opens the menu of [opener] (a dropdown) and picks [item]. The tap
  /// is repeated when no menu opens within a few seconds (slow CI
  /// runners sometimes drop a tap during a rebuild).
  Future<void> pick(Finder opener, String item) async {
    final choice = find.text(item);
    for (var attempt = 1; choice.evaluate().isEmpty; attempt++) {
      if (attempt > 3) timedOut('the menu item "$item"');
      await tapVisible(opener);
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (choice.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
        await idle(100);
      }
    }
    await settle();
    await tester.tap(choice.last);
    await settle();
  }

  /// Opens the menu of [opener] and picks [item], even when [item]'s
  /// text is also shown outside the menu (a filter named like a status).
  Future<void> pickFromMenu(Finder opener, String item) async {
    final choice = find.text(item);
    final before = choice.evaluate().length;
    await tapVisible(opener);
    await waitUntil(
      'the menu item "$item"',
      () => choice.evaluate().length > before,
    );
    await settle();
    await tester.tap(choice.last);
    await settle();
  }

  /// Picks [item] (a filter or a sort) in the sidebar header's filter
  /// menu (AV-092).
  Future<void> pickFilter(String item) =>
      pickFromMenu(find.byTooltip('Filter and sort'), item);

  /// Picks [item] in the sidebar header's "…" menu (AV-092).
  Future<void> pickMore(String item) =>
      pickFromMenu(find.byTooltip(RegExp(r'^More actions')), item);

  /// Waits until the window title is [title] (it carries the attention
  /// count, AV-120).
  Future<void> waitForTitle(String title) => waitUntil(
    'the title "$title"',
    () => tester.widget<MaterialApp>(find.byType(MaterialApp)).title == title,
  );

  /// Opens the session header's "…" menu, then its "Details" popover
  /// (AV-094), which stays current while open.
  Future<void> openDetails() async {
    await tapVisible(find.byTooltip('Session actions'));
    await settle();
    await tester.tap(find.text('Details…'));
    await settle();
  }

  /// Closes the "Details" popover.
  Future<void> closeDetails() async {
    await tester.tap(find.byTooltip('Close details'));
    await settle();
  }

  /// The follow-up box.
  Finder get composer => find.descendant(
    of: find.byType(FollowUpInput),
    matching: find.byType(TextField),
  );

  /// Types [text] into the follow-up box.
  Future<void> type(String text) async {
    // The box keeps focus after sending, and enterText only attaches the
    // test keyboard when the focused field changes.
    FocusManager.instance.primaryFocus?.unfocus();
    tester.binding.focusedEditable = null;
    await tester.pump();
    // Not `find.byType(TextField).last`: a dialog that is still closing
    // (headless, frames only come from pumps) is later in the tree, and
    // its field can no longer take focus, so the text would be lost.
    await tester.enterText(composer, text);
    await tester.pump();
  }

  /// Hides snackbars, which cover the follow-up box's buttons.
  Future<void> clearSnackBars() async {
    for (final messenger in tester.stateList<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    )) {
      messenger.clearSnackBars();
    }
    await settle();
  }

  /// Sends [text] as a follow-up once the previous turn has ended, with
  /// the timeline at the newest row so the reply is built on screen
  /// (expanded steps can leave it scrolled up).
  Future<void> send(String text) async {
    // Wait for the previous turn to end, so this starts a new one.
    await waitFor(find.byTooltip('Send'));
    await followTimeline();
    await clearSnackBars();
    await type(text);
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
  }
}
