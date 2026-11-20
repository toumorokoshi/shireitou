import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/session_cache.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

SessionState _sessionState(
  String uri,
  String defaultChat, {
  List<String> extra = const [],
}) => SessionState.fromJson({
  'lifecycle': 'ready',
  'title': 'Title $uri',
  'status': 33,
  'provider': 'pi',
  'defaultChat': defaultChat,
  'chats': [
    {
      'resource': defaultChat,
      'title': 'Chat',
      'status': 33,
      'modifiedAt': '2026-11-20T00:00:00Z',
    },
    for (final chat in extra)
      {
        'resource': chat,
        'title': 'Chat $chat',
        'status': 33,
        'modifiedAt': '2026-11-20T00:00:00Z',
      },
  ],
});

ChatState _chatState(String uri, String reply) => ChatState.fromJson({
  'resource': uri,
  'title': 'Chat $uri',
  'status': 33,
  'modifiedAt': '2026-11-20T00:00:00Z',
  'turns': [
    {
      'id': 't1',
      'state': 'complete',
      'message': userMessage('Hello').toJson(),
      'responseParts': [
        {'kind': 'markdown', 'id': 'm1', 'content': reply},
      ],
    },
  ],
});

class _PendingOpenConnection extends FakeHostConnection {
  _PendingOpenConnection(super.initial);

  final openCompleter = Completer<String?>();
  int openCalls = 0;

  @override
  Future<String?> openSession(String session) {
    openCalls++;
    return openCompleter.future;
  }
}

void main() {
  test(
    'SessionCache evicts least recently used and updates recency on read',
    () {
      final cache = SessionCache(capacity: 2);
      final s1 = CachedSession(session: _sessionState('pi:/1', 'ahp-chat:/1'));
      final s2 = CachedSession(session: _sessionState('pi:/2', 'ahp-chat:/2'));
      final s3 = CachedSession(session: _sessionState('pi:/3', 'ahp-chat:/3'));

      cache.remember('pi:/1', s1);
      cache.remember('pi:/2', s2);
      // Peek should not change recency.
      expect(cache.peek('pi:/1'), same(s1));
      // Operator [] should mark pi:/1 as most recently used.
      expect(cache['pi:/1'], same(s1));
      // Adding pi:/3 should evict pi:/2 (least recently used).
      cache.remember('pi:/3', s3);

      expect(cache.contains('pi:/1'), isTrue);
      expect(cache.contains('pi:/2'), isFalse);
      expect(cache.contains('pi:/3'), isTrue);
    },
  );

  test(
    'recordSessionCache captures mirrored sessions, chats, and evictions',
    () {
      final cache = SessionCache();
      final empty = const HostState(status: ConnectionStatus.connected);
      final withCatalog = empty.copyWith(
        sessions: catalogueFromSummaries([
          session('1', title: 'One'),
          session('2', title: 'Two'),
        ]),
      );
      final opened = withCatalog.copyWith(
        sessionChannels: {
          'pi:/1': ChannelMirror.snapshot(
            _sessionState(
              'pi:/1',
              'ahp-chat:/1',
              extra: const ['ahp-chat:/1b'],
            ),
          ),
        },
        chatChannels: {
          'ahp-chat:/1': ChannelMirror.snapshot(
            _chatState('ahp-chat:/1', 'First'),
          ),
          'ahp-chat:/1b': ChannelMirror.snapshot(
            _chatState('ahp-chat:/1b', 'Side'),
          ),
        },
      );

      recordSessionCache(cache, withCatalog, opened);
      final cached = cache.peek('pi:/1');
      expect(cached, isNotNull);
      expect(cached!.defaultChat, 'ahp-chat:/1');
      expect(cached.chats.keys, containsAll(['ahp-chat:/1', 'ahp-chat:/1b']));

      // Unsubscribing removes channels from HostState, but cache keeps them.
      final closed = opened.copyWith(
        sessionChannels: const {},
        chatChannels: const {},
      );
      recordSessionCache(cache, opened, closed);
      expect(cache.contains('pi:/1'), isTrue);

      // Marking missing or removing from catalogue evicts from cache.
      final missing = closed.copyWith(missingChannels: const {'pi:/1'});
      recordSessionCache(cache, closed, missing);
      expect(cache.contains('pi:/1'), isFalse);

      // Re-cache pi:/2 and test catalogue removal.
      final opened2 = withCatalog.copyWith(
        sessionChannels: {
          'pi:/2': ChannelMirror.snapshot(
            _sessionState('pi:/2', 'ahp-chat:/2'),
          ),
        },
        chatChannels: {
          'ahp-chat:/2': ChannelMirror.snapshot(
            _chatState('ahp-chat:/2', 'Two'),
          ),
        },
      );
      recordSessionCache(cache, withCatalog, opened2);
      expect(cache.contains('pi:/2'), isTrue);

      final disposed = opened2.copyWith(
        sessions: catalogueFromSummaries([session('1', title: 'One')]),
        sessionChannels: const {},
        chatChannels: const {},
      );
      recordSessionCache(cache, opened2, disposed);
      expect(cache.contains('pi:/2'), isFalse);
    },
  );

  test('pinnedSessionsToWarm filters by host, catalogue, cache, open, and attempted', () {
    final cache = SessionCache()
      ..remember(
        'pi:/cached',
        CachedSession(session: _sessionState('pi:/cached', 'ahp-chat:/c')),
      );
    final state = HostState(
      status: ConnectionStatus.connected,
      sessions: catalogueFromSummaries([
        session('warm', title: 'Warm me'),
        session('cached', title: 'Already cached'),
        session('open', title: 'Already open'),
        session('attempted', title: 'Already attempted'),
        session('missing', title: 'Missing'),
      ]),
      sessionChannels: {
        'pi:/open': ChannelMirror.snapshot(
          _sessionState('pi:/open', 'ahp-chat:/o'),
        ),
      },
      missingChannels: const {'pi:/missing'},
    );

    final toWarm = pinnedSessionsToWarm(
      host: 'ws://127.0.0.1:1',
      pinned: const {
        (host: 'ws://127.0.0.1:1', session: 'pi:/warm'),
        (host: 'ws://127.0.0.1:1', session: 'pi:/cached'),
        (host: 'ws://127.0.0.1:1', session: 'pi:/open'),
        (host: 'ws://127.0.0.1:1', session: 'pi:/attempted'),
        (host: 'ws://127.0.0.1:1', session: 'pi:/missing'),
        (host: 'ws://127.0.0.1:1', session: 'pi:/not-in-catalog'),
        (host: 'ws://other-host:2', session: 'pi:/warm'),
      },
      state: state,
      cache: cache,
      attempted: const {'pi:/attempted'},
    );

    expect(toWarm, ['pi:/warm']);
  });

  testWidgets(
    'SessionDetailView renders cached session immediately while openSession is in flight',
    (tester) async {
      final initialState = HostState(
        status: ConnectionStatus.connected,
        sessions: catalogueFromSummaries([session('1', title: 'Fix login')]),
      );
      final connection = _PendingOpenConnection(initialState);
      connection.sessionCache.remember(
        'pi:/1',
        CachedSession(
          session: _sessionState('pi:/1', 'ahp-chat:/1'),
          defaultChat: 'ahp-chat:/1',
          chats: {'ahp-chat:/1': _chatState('ahp-chat:/1', 'Cached reply')},
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...hostOverrides(connection: connection),
            prefsStoreProvider.overrideWithValue(MemoryPrefsStore()),
          ],
          child: MaterialApp(
            home: HostScope(
              host: testHost.key,
              child: const Scaffold(
                body: SessionDetailView(
                  key: ValueKey('pi:/1'),
                  session: 'pi:/1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(connection.openCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Cached reply'), findsOneWidget);

      // When the live snapshot arrives, it replaces the cached view seamlessly.
      connection.emit(
        initialState.copyWith(
          sessionChannels: {
            'pi:/1': ChannelMirror.snapshot(
              _sessionState('pi:/1', 'ahp-chat:/1'),
            ),
          },
          chatChannels: {
            'ahp-chat:/1': ChannelMirror.snapshot(
              _chatState('ahp-chat:/1', 'Live reply'),
            ),
          },
        ),
      );
      connection.openCompleter.complete('ahp-chat:/1');
      await tester.pumpAndSettle();

      expect(find.text('Live reply'), findsOneWidget);
      expect(find.text('Cached reply'), findsNothing);
    },
  );
}
