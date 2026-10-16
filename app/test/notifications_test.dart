/// Local notifications for sessions that need attention (AV-121).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/hosts/open_hosts.dart';
import 'package:shireitou/src/notifications/attention_events.dart';
import 'package:shireitou/src/notifications/notifications.dart';
import 'package:shireitou/src/prefs.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

HostSession _s(String id, int status, {String host = 'h'}) =>
    HostSession(host, session(id, status: status, title: 'session $id'));

/// Status bits: idle 1, error 2, in progress 8, input needed 8|16, read
/// 32, archived 64.
const _working = 8 | 32;
const _input = 8 | 16 | 32;
const _idle = 1 | 32;
const _failed = 1 | 2 | 32;

class _RecordingNotifier implements OsNotifier {
  final shown = <({int id, String title, String body, String payload})>[];

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async => shown.add((id: id, title: title, body: body, payload: payload));
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('attention events', () {
    test('input, finished and failed transitions', () {
      final before = [
        _s('1', _working),
        _s('2', _working),
        _s('3', _working),
        _s('4', _idle),
      ];
      final after = [
        _s('1', _input),
        _s('2', _idle),
        _s('3', _failed),
        _s('4', _idle),
        _s('5', _input), // new: not notified
      ];
      expect(
        [
          for (final e in attentionEvents(before, after))
            (e.session.session, e.kind),
        ],
        [
          ('pi:/1', AttentionKind.needsInput),
          ('pi:/2', AttentionKind.finished),
          ('pi:/3', AttentionKind.failed),
        ],
      );
    });

    test('answering, archived sessions and other hosts are quiet', () {
      // Answering the input request goes back to working: no event.
      expect(attentionEvents([_s('1', _input)], [_s('1', _working)]), isEmpty);
      expect(
        attentionEvents([_s('1', _working)], [_s('1', _idle | 64)]),
        isEmpty,
      );
      // The same session URI on another host is another session.
      expect(
        attentionEvents([_s('1', _working)], [_s('1', _idle, host: 'other')]),
        isEmpty,
      );
    });

    test('settings, filtering and text', () {
      const settings = NotificationSettings();
      final event = attentionEvents(
        [_s('1', _working)],
        [_s('1', _idle)],
      ).single;
      expect(shouldNotify(event, settings, focused: false), isTrue);
      expect(
        shouldNotify(event, settings, focused: true, visible: event.session),
        isFalse,
      );
      expect(
        shouldNotify(event, settings, focused: false, visible: event.session),
        isTrue,
      );
      final off = settings.toggled(AttentionKind.finished, on: false);
      expect(shouldNotify(event, off, focused: false), isFalse);
      expect(NotificationSettings.fromJson(off.toJson()), off);
      expect(NotificationSettings.fromJson('garbage'), settings);
      expect(notificationText(event), (title: 'Finished', body: 'session 1'));
      expect(notificationText(event, hostLabel: 'box').body, 'session 1 · box');
      expect(
        sessionOfPayload(notificationPayload(event.session)),
        event.session,
      );
      expect(sessionOfPayload('{}'), isNull);
      expect(sessionOfPayload(null), isNull);
      expect(notificationId(event), notificationId(event));
    });
  });

  testWidgets('status changes notify, a click opens the session, and the '
      'menu turns events off', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notifier = _RecordingNotifier();
    final prefs = MemoryPrefsStore();
    HostState host(int status) => HostState(
      status: ConnectionStatus.connected,
      sessions: catalogueFromSummaries([
        session('1', title: 'Fix login', status: status),
        session('2', title: 'Deploy', status: _idle),
      ]),
      chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(chatFixture())},
    );
    final connection = FakeHostConnection(host(_working));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...hostOverrides(connection: connection),
          notifierProvider.overrideWithValue(notifier),
          prefsStoreProvider.overrideWithValue(prefs),
        ],
        child: const ShireitouApp(),
      ),
    );
    await tester.pumpAndSettle();

    connection.state = host(_input);
    await tester.pump();
    expect(notifier.shown.single.title, 'Needs your input');
    expect(notifier.shown.single.body, 'Fix login');

    // Clicking it opens the session.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container
        .read(openSessionRequestsProvider)
        .add(sessionOfPayload(notifier.shown.single.payload)!);
    await tester.pumpAndSettle();
    expect(find.textContaining('Queue a follow-up'), findsOneWidget);
    expect(container.read(visibleSessionProvider)?.session, 'pi:/1');

    // While it is on screen and the window has focus, nothing is posted.
    connection.state = host(_working);
    await tester.pump();
    connection.state = host(_input);
    await tester.pump();
    expect(notifier.shown, hasLength(1));

    // The menu turns "finishes its turn" off, and it is saved.
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('finishes its turn'));
    await tester.pumpAndSettle();
    expect(
      NotificationSettings.fromJson(prefs.values['notification_settings'])
          .enabled(AttentionKind.finished),
      isFalse,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
