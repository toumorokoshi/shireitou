/// Unit and widget tests for client-side queued messages while disconnected.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/session_detail/client_queued_messages.dart';
import 'package:shireitou/src/session_detail/pending_messages.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/theme/app_theme.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

ClientQueuedMessage _msg(
  String id,
  String text, {
  String chat = 'ahp-chat:/1',
  bool sendNow = false,
}) => ClientQueuedMessage(
  id: id,
  chat: chat,
  message: userMessage(text),
  sendNow: sendNow,
);

class _DroppingFakeHostConnection extends FakeHostConnection {
  _DroppingFakeHostConnection(super.initial, {required this.failAfter});

  final int failAfter;

  @override
  int dispatch(String channel, JsonMap action) {
    if (dispatched.length >= failAfter) {
      throw StateError('dropped');
    }
    return super.dispatch(channel, action);
  }
}

void main() {
  group('pure client queue operations', () {
    test('enqueue, edit, remove, and filter by chat', () {
      var queue = <ClientQueuedMessage>[];
      queue = enqueueClientMessage(queue, _msg('1', 'hello', chat: 'c1'));
      queue = enqueueClientMessage(queue, _msg('2', 'world', chat: 'c2'));
      queue = enqueueClientMessage(queue, _msg('3', 'again', chat: 'c1'));

      expect(clientQueuedForChat(queue, 'c1').map((i) => i.pending.id), [
        '1',
        '3',
      ]);
      expect(
        clientQueuedForChat(queue, 'c1').every((i) => i.clientQueued),
        isTrue,
      );

      queue = editClientMessage(queue, '3', 'edited');
      expect(queue[2].message.text, 'edited');

      queue = removeClientMessage(queue, '1');
      expect(queue.map((m) => m.id), ['2', '3']);
    });

    test('reorderClientMessages only reorders the target chat', () {
      final queue = [
        _msg('1', 'a', chat: 'c1'),
        _msg('2', 'b', chat: 'c2'),
        _msg('3', 'c', chat: 'c1'),
      ];
      final reordered = reorderClientMessages(queue, 'c1', 0, 1);
      expect(reordered.map((m) => m.id), ['3', '2', '1']);
    });
  });

  group('ClientQueuedMessagesNotifier', () {
    test('flushes queued messages in order when host connects', () {
      final connection = FakeHostConnection(
        const HostState(status: ConnectionStatus.reconnecting),
      );
      final container = ProviderContainer(
        overrides: hostOverrides(connection: connection),
      );
      addTearDown(container.dispose);

      // Activate both providers.
      container.read(clientQueuedMessagesProvider(testHost.key));
      final notifier = container.read(
        clientQueuedMessagesProvider(testHost.key).notifier,
      );

      notifier.enqueue(_msg('m1', 'first'));
      notifier.enqueue(_msg('m2', 'second'));
      expect(connection.dispatched, isEmpty);

      // Reconnect with an idle chat: first starts a turn, second queues.
      connection.emit(
        HostState(
          status: ConnectionStatus.connected,
          chatChannels: {
            'ahp-chat:/1': ChannelMirror.snapshot(chatFixture(active: false)),
          },
        ),
      );

      expect(
        container.read(clientQueuedMessagesProvider(testHost.key)),
        isEmpty,
      );
      expect(connection.dispatched, hasLength(2));
      expect(connection.dispatched[0].$2['type'], 'chat/turnStarted');
      expect(connection.dispatched[0].$2['turnId'], 'm1');
      expect(connection.dispatched[1].$2['type'], 'chat/pendingMessageSet');
      expect(connection.dispatched[1].$2['id'], 'm2');
    });

    test('honors sendNow when flushing onto a busy chat', () {
      final connection = FakeHostConnection(
        const HostState(status: ConnectionStatus.reconnecting),
      );
      final container = ProviderContainer(
        overrides: hostOverrides(connection: connection),
      );
      addTearDown(container.dispose);

      container.read(clientQueuedMessagesProvider(testHost.key));
      container
          .read(clientQueuedMessagesProvider(testHost.key).notifier)
          .enqueue(_msg('m1', 'urgent', sendNow: true));

      final busy = chatFixture();
      connection.emit(
        HostState(
          status: ConnectionStatus.connected,
          chatChannels: {'ahp-chat:/1': ChannelMirror.snapshot(busy)},
        ),
      );

      expect(connection.dispatched.map((e) => e.$2['type']), [
        'chat/turnCancelled',
        'chat/turnStarted',
      ]);
      expect(connection.dispatched[0].$2['turnId'], busy.activeTurn!.id);
      expect(connection.dispatched[1].$2['turnId'], 'm1');
    });

    test('keeps unsent messages if connection drops mid-flush', () {
      final connection = _DroppingFakeHostConnection(
        const HostState(status: ConnectionStatus.reconnecting),
        failAfter: 1,
      );
      final container = ProviderContainer(
        overrides: hostOverrides(connection: connection),
      );
      addTearDown(container.dispose);

      container.read(clientQueuedMessagesProvider(testHost.key));
      final notifier = container.read(
        clientQueuedMessagesProvider(testHost.key).notifier,
      );
      notifier.enqueue(_msg('m1', 'first'));
      notifier.enqueue(_msg('m2', 'second'));

      connection.emit(
        HostState(
          status: ConnectionStatus.connected,
          chatChannels: {
            'ahp-chat:/1': ChannelMirror.snapshot(chatFixture(active: false)),
          },
        ),
      );

      expect(connection.dispatched, hasLength(1));
      expect(
        container
            .read(clientQueuedMessagesProvider(testHost.key))
            .map((m) => m.id),
        ['m2'],
      );
    });

    test('disconnect clears locally queued messages', () async {
      final connection = FakeHostConnection(
        const HostState(status: ConnectionStatus.reconnecting),
      );
      final container = ProviderContainer(
        overrides: hostOverrides(connection: connection),
      );
      addTearDown(container.dispose);

      container.read(clientQueuedMessagesProvider(testHost.key));
      container
          .read(clientQueuedMessagesProvider(testHost.key).notifier)
          .enqueue(_msg('m1', 'first'));

      await connection.disconnect();
      expect(
        container.read(clientQueuedMessagesProvider(testHost.key)),
        isEmpty,
      );
    });
  });

  testWidgets(
    'SessionDetailView queues locally when disconnected and flushes on connect',
    (tester) async {
      const chatUri = 'ahp-chat:/1';
      final initialState = HostState(
        status: ConnectionStatus.reconnecting,
        sessions: {'pi:/1': session('1')},
        sessionChannels: {
          'pi:/1': const ChannelMirror.snapshot(
            SessionState(
              provider: 'pi',
              title: 'session 1',
              status: SessionStatus.idle,
              lifecycle: SessionLifecycle.ready,
              activeClients: [],
              defaultChat: chatUri,
              chats: [
                ChatSummary(
                  resource: chatUri,
                  title: 'Main',
                  status: SessionStatus.idle,
                  modifiedAt: '2026-10-01T00:00:00Z',
                ),
              ],
            ),
          ),
        },
        chatChannels: {
          chatUri: ChannelMirror.snapshot(chatFixture(active: false)),
        },
      );
      final connection = FakeHostConnection(initialState);

      await tester.pumpWidget(
        ProviderScope(
          overrides: hostOverrides(connection: connection),
          child: MaterialApp(
            theme: buildTheme(defaultTheme(Brightness.dark)),
            home: HostScope(
              host: testHost.key,
              child: const Scaffold(body: SessionDetailView(session: 'pi:/1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(composerField, 'wait for reconnect');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Nothing dispatched yet, no error snackbar, local-queue UI shown.
      expect(connection.dispatched, isEmpty);
      expect(find.textContaining('Could not send'), findsNothing);
      expect(find.byType(PendingMessagesPanel), findsOneWidget);
      expect(find.text('wait for reconnect'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Queued locally · Waiting to connect'), findsOneWidget);

      // Host reconnects: message is dispatched and local-queue UI clears.
      connection.emit(
        initialState.copyWith(status: ConnectionStatus.connected),
      );
      await tester.pumpAndSettle();

      expect(connection.dispatched, hasLength(1));
      expect(connection.dispatched.single.$1, chatUri);
      expect(connection.dispatched.single.$2['type'], 'chat/turnStarted');
      expect(
        (connection.dispatched.single.$2['message']! as JsonMap)['text'],
        'wait for reconnect',
      );
      expect(find.byType(PendingMessagesPanel), findsNothing);
    },
  );
}
