import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

const _summaryJson = <String, Object?>{
  'resource': 'pi:/a',
  'provider': 'pi',
  'title': 'first',
  'status': 33,
  'createdAt': '2026-01-01T00:00:00Z',
  'modifiedAt': '2026-01-01T00:00:00Z',
};

const _initializeResult = <String, Object?>{
  'protocolVersion': '1.0.0',
  'serverSeq': 5,
  'serverInfo': {'name': 'fake-host'},
  'snapshots': [
    {
      'resource': 'ahp-root://',
      'state': {'agents': <Object?>[], 'activeSessions': 0},
      'fromSeq': 5,
    },
  ],
};

const _sessionState = <String, Object?>{
  'provider': 'pi',
  'title': 'first',
  'status': 1,
  'lifecycle': 'ready',
  'activeClients': <Object?>[],
  'chats': [
    {'resource': 'ahp-chat:/a', 'title': 'first'},
  ],
};

const _chatState = <String, Object?>{
  'resource': 'ahp-chat:/a',
  'title': 'first',
  'status': 33,
  'modifiedAt': '2026-01-01T00:00:00Z',
  'turns': <Object?>[],
};

const _snapshots = <String, Object?>{
  'pi:/a': {'resource': 'pi:/a', 'state': _sessionState, 'fromSeq': 5},
  'ahp-chat:/a': {'resource': 'ahp-chat:/a', 'state': _chatState, 'fromSeq': 5},
};

/// An in-memory AHP host. Each connection gets a fresh host-side [Peer].
class FakeHost {
  /// Requests received, as (method, params).
  final requests = <(String, JsonMap)>[];

  /// Host-side peers, one per connection.
  final peers = <Peer>[];

  /// Overrides the `initialize` handler.
  Object? Function(JsonMap params)? onInitialize;

  /// Overrides the `reconnect` handler.
  Object? Function(JsonMap params)? onReconnect;

  /// Overrides the `ping` handler; return a never-completing future to
  /// simulate a dead socket.
  Object? Function()? onPing;

  Future<StreamChannel<String>> connect(Uri uri) async {
    final controller = StreamChannelController<String>(sync: true);
    final peer = Peer(controller.foreign);
    const methods = [
      'initialize',
      'reconnect',
      'listSessions',
      'ping',
      'subscribe',
      'createSession',
      'dispatchAction',
      'unsubscribe',
    ];
    for (final method in methods) {
      peer.registerMethod(method, (Parameters p) {
        final params = p.value as JsonMap;
        requests.add((method, params));
        return switch (method) {
          'initialize' => (onInitialize ?? (_) => _initializeResult)(params),
          'ping' => onPing?.call(),
          'reconnect' when onReconnect != null => onReconnect!(params),
          'reconnect' => {
            'type': 'replay',
            'actions': [
              {
                'channel': 'ahp-root://',
                'action': {
                  'type': 'root/activeSessionsChanged',
                  'activeSessions': 4,
                },
                'serverSeq': 9,
              },
            ],
            'missing': <Object?>[],
          },
          'listSessions' =>
            params['cursor'] == null
                ? {
                    'items': [_summaryJson],
                    'nextCursor': '1',
                  }
                : {
                    'items': [
                      {..._summaryJson, 'resource': 'pi:/b', 'title': 'second'},
                    ],
                  },
          'subscribe' => {'snapshot': _snapshots[params['channel']]},
          'createSession' => () {
            // Publish the session under pi's `pi:/<id>` form, like pi does.
            final id = (params['channel']! as String).split('/').last;
            Timer.run(
              () => peer.sendNotification('root/sessionAdded', {
                'channel': rootChannel,
                'summary': {..._summaryJson, 'resource': 'pi:/$id'},
              }),
            );
            return null;
          }(),
          _ => null,
        };
      });
    }
    unawaited(peer.listen());
    peers.add(peer);
    return controller.local;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

JsonMap _turnStarted(String id) => ChatAction.turnStarted(
  turnId: id,
  startedAt: '2026-01-01T00:00:00.000Z',
  message: userMessage('hi'),
).toJson();

void main() {
  late FakeHost host;
  late AhpClient client;

  AhpClient newClient({
    Duration pingInterval = Duration.zero,
    Duration pingTimeout = const Duration(seconds: 1),
    Duration pendingActionTimeout = Duration.zero,
  }) => AhpClient(
    uri: Uri.parse('ws://fake'),
    clientId: 'test-client',
    connector: host.connect,
    pingInterval: pingInterval,
    pingTimeout: pingTimeout,
    pendingActionTimeout: pendingActionTimeout,
  );

  setUp(() {
    host = FakeHost();
    client = newClient();
  });

  tearDown(() => client.close());

  test('initialize offers versions and loads every catalogue page', () async {
    await client.connect();
    expect(client.state.status, ConnectionStatus.connected);
    final (method, params) = host.requests.first;
    expect(method, 'initialize');
    expect(params['protocolVersions'], offeredProtocolVersions);
    expect(params['clientId'], 'test-client');
    expect(params['initialSubscriptions'], [rootChannel]);
    expect(client.state.serverSeq, 5);
    expect(client.state.serverInfo?.name, 'fake-host');
    expect(client.state.sessions.keys, ['pi:/a', 'pi:/b']);
  });

  test('applies root notifications and actions', () async {
    await client.connect();
    final peer = host.peers.single;
    peer.sendNotification('root/sessionSummaryChanged', {
      'channel': rootChannel,
      'session': 'pi:/a',
      'changes': {'title': 'renamed'},
    });
    peer.sendNotification('action', {
      'channel': rootChannel,
      'action': {'type': 'root/activeSessionsChanged', 'activeSessions': 1},
      'serverSeq': 6,
    });
    peer.sendNotification('root/sessionRemoved', {
      'channel': rootChannel,
      'session': 'pi:/b',
    });
    await _settle();
    expect(client.state.sessions['pi:/a']!.title, 'renamed');
    expect(client.state.sessions.keys, ['pi:/a']);
    expect(client.state.root!.activeSessions, 1);
    expect(client.state.serverSeq, 6);
  });

  test('answers host ping requests', () async {
    await client.connect();
    expect(await host.peers.single.sendRequest('ping', {}), isNull);
  });

  test('reports an unsupported protocol version as failed', () async {
    host.onInitialize = (_) => throw RpcException(
      AhpErrorCodes.unsupportedProtocolVersion,
      'Unsupported protocol version',
      data: {
        'supportedVersions': ['2.0.0'],
      },
    );
    await client.connect();
    expect(client.state.status, ConnectionStatus.failed);
    expect(client.state.error, contains('host supports 2.0.0'));
  });

  test('reconnects with lastSeenServerSeq and applies the replay', () async {
    await client.connect();
    final reconnected = client.states.firstWhere(
      (s) => s.status == ConnectionStatus.connected,
    );
    await host.peers.single.close();
    await _settle();
    expect(client.state.status, ConnectionStatus.reconnecting);
    await reconnected;
    final (_, params) = host.requests.firstWhere((r) => r.$1 == 'reconnect');
    expect(params['lastSeenServerSeq'], 5);
    expect(params['subscriptions'], [rootChannel]);
    expect(client.state.root!.activeSessions, 4);
    expect(client.state.serverSeq, 9);
  });

  test('openSession subscribes to the session and its default chat', () async {
    await client.connect();
    final chat = await client.openSession('pi:/a');
    expect(chat, 'ahp-chat:/a');
    expect(
      host.requests
          .where((r) => r.$1 == 'subscribe')
          .map((r) => r.$2['channel']),
      ['pi:/a', 'ahp-chat:/a'],
    );
    expect(client.state.sessionChannels['pi:/a']!.state.title, 'first');
    expect(client.state.chatChannels['ahp-chat:/a']!.state.turns, isEmpty);

    client.closeSession('pi:/a', chat);
    await _settle();
    expect(client.state.chatChannels, isEmpty);
    expect(client.state.sessionChannels, isEmpty);
    expect(host.requests.where((r) => r.$1 == 'unsubscribe'), hasLength(2));
  });

  test('dispatch applies optimistically and the echo confirms it', () async {
    await client.connect();
    await client.openSession('pi:/a');
    final action = ChatAction.turnStarted(
      turnId: 't1',
      startedAt: '2026-01-01T00:00:00.000Z',
      message: userMessage('hi'),
    ).toJson();
    final seq = client.dispatch('ahp-chat:/a', action);
    final mirror = client.state.chatChannels['ahp-chat:/a']!;
    expect(mirror.state.activeTurn?.message.text, 'hi');
    expect(mirror.pending.single.clientSeq, seq);

    await _settle();
    final (_, params) = host.requests.lastWhere(
      (r) => r.$1 == 'dispatchAction',
    );
    expect(params['clientSeq'], seq);
    expect((params['action']! as JsonMap)['type'], 'chat/turnStarted');

    host.peers.single.sendNotification('action', {
      'channel': 'ahp-chat:/a',
      'action': action,
      'serverSeq': 6,
      'origin': {'clientId': 'test-client', 'clientSeq': seq},
    });
    await _settle();
    final confirmed = client.state.chatChannels['ahp-chat:/a']!;
    expect(confirmed.pending, isEmpty);
    expect(confirmed.confirmed.activeTurn?.id, 't1');
  });

  test('createSession returns the URI the host lists', () async {
    await client.connect();
    final session = await client.createSession(provider: 'pi');
    expect(session, startsWith('pi:/'));
    final (_, params) = host.requests.lastWhere((r) => r.$1 == 'createSession');
    expect(params['channel'], 'ahp-session:/${session.substring(4)}');
  });

  Future<void> dropAndReconnect() async {
    final reconnected = client.states.firstWhere(
      (s) => s.status == ConnectionStatus.connected,
    );
    await host.peers.last.close();
    await _settle();
    await reconnected;
  }

  test('a ping timeout drops the socket and reconnects', () async {
    client = newClient(
      pingInterval: const Duration(milliseconds: 10),
      pingTimeout: const Duration(milliseconds: 10),
    );
    await client.connect();
    host.onPing = () => Completer<void>().future;
    final reconnecting = client.states.firstWhere(
      (s) => s.status == ConnectionStatus.reconnecting,
    );
    await reconnecting;
    host.onPing = null;
    await client.states.firstWhere(
      (s) => s.status == ConnectionStatus.connected,
    );
    expect(host.requests.map((r) => r.$1), contains('reconnect'));
  });

  test('answered pings, even with an error, keep the connection', () async {
    client = newClient(
      pingInterval: const Duration(milliseconds: 5),
      pingTimeout: const Duration(milliseconds: 50),
    );
    await client.connect();
    host.onPing = () => throw RpcException.methodNotFound('ping');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(client.state.status, ConnectionStatus.connected);
    expect(host.requests.where((r) => r.$1 == 'ping'), isNotEmpty);
    expect(host.requests.map((r) => r.$1), isNot(contains('reconnect')));
  });

  test('missing channels are dropped and reported', () async {
    await client.connect();
    await client.openSession('pi:/a');
    host.onReconnect = (_) => {
      'type': 'replay',
      'actions': <Object?>[],
      'missing': ['pi:/a', 'ahp-chat:/a'],
    };
    await dropAndReconnect();
    expect(client.state.missingChannels, {'pi:/a', 'ahp-chat:/a'});
    expect(client.state.sessionChannels, isEmpty);
    expect(client.state.chatChannels, isEmpty);

    // Releasing a missing channel sends nothing; subscribing again clears
    // it.
    client.closeSession('pi:/a', 'ahp-chat:/a');
    await _settle();
    expect(host.requests.where((r) => r.$1 == 'unsubscribe'), isEmpty);
    await client.openSession('pi:/a');
    expect(client.state.missingChannels, isEmpty);

    // The next reconnect no longer asks for channels it dropped... until
    // they were subscribed again.
    host.onReconnect = null;
    await dropAndReconnect();
    final (_, params) = host.requests.lastWhere((r) => r.$1 == 'reconnect');
    expect(params['subscriptions'], [rootChannel, 'pi:/a', 'ahp-chat:/a']);
  });

  test(
    'after a host restart, channels it has no snapshot for are missing',
    () async {
      await client.connect();
      await client.openSession('pi:/a');
      host.onReconnect = (_) =>
          throw RpcException(AhpErrorCodes.notFound, 'unknown client');
      await dropAndReconnect();
      expect(host.requests.where((r) => r.$1 == 'initialize'), hasLength(2));
      expect(client.state.missingChannels, {'pi:/a', 'ahp-chat:/a'});
      expect(client.state.sessionChannels, isEmpty);
    },
  );

  test('a reconnect replay rolls back actions the host never got', () async {
    await client.connect();
    await client.openSession('pi:/a');
    final failures = <ActionFailure>[];
    client.failures.listen(failures.add);
    final echoed = client.dispatch('ahp-chat:/a', _turnStarted('t1'));
    final lost = client.dispatch(
      'pi:/a',
      SessionAction.isArchivedChanged(isArchived: true).toJson(),
    );
    host.onReconnect = (_) => {
      'type': 'replay',
      'actions': [
        {
          'channel': 'ahp-chat:/a',
          'action': _turnStarted('t1'),
          'serverSeq': 6,
          'origin': {'clientId': 'test-client', 'clientSeq': echoed},
        },
      ],
    };
    await dropAndReconnect();
    await _settle();
    expect(
      client.state.chatChannels['ahp-chat:/a']!.confirmed.activeTurn?.id,
      't1',
    );
    expect(client.state.sessionChannels['pi:/a']!.pending, isEmpty);
    expect(
      client.state.sessionChannels['pi:/a']!.state.status.isArchivedFlag,
      isFalse,
    );
    expect(failures.single.clientSeq, lost);
    expect(failures.single.kind, ActionFailureKind.connectionLost);
  });

  test('a reconnect snapshot reports pending actions it replaces', () async {
    await client.connect();
    await client.openSession('pi:/a');
    final failures = <ActionFailure>[];
    client.failures.listen(failures.add);
    client.dispatch('ahp-chat:/a', _turnStarted('t1'));
    host.onReconnect = (_) => {
      'type': 'snapshot',
      'snapshots': [_snapshots['ahp-chat:/a'], _snapshots['pi:/a']],
    };
    await dropAndReconnect();
    await _settle();
    final chat = client.state.chatChannels['ahp-chat:/a']!;
    expect(chat.pending, isEmpty);
    expect(chat.state.activeTurn, isNull);
    expect(failures.single.kind, ActionFailureKind.connectionLost);
  });

  test('an action the host never echoes times out and rolls back', () async {
    client = newClient(pendingActionTimeout: const Duration(milliseconds: 10));
    await client.connect();
    await client.openSession('pi:/a');
    final failure = client.failures.first;
    final seq = client.dispatch('ahp-chat:/a', _turnStarted('t1'));
    expect(
      client.state.chatChannels['ahp-chat:/a']!.state.activeTurn,
      isNotNull,
    );
    final failed = await failure;
    expect(failed.clientSeq, seq);
    expect(failed.kind, ActionFailureKind.timedOut);
    final chat = client.state.chatChannels['ahp-chat:/a']!;
    expect(chat.pending, isEmpty);
    expect(chat.state.activeTurn, isNull);
  });

  test('host rejections are reported as failures', () async {
    await client.connect();
    await client.openSession('pi:/a');
    final failure = client.failures.first;
    final seq = client.dispatch('ahp-chat:/a', _turnStarted('t1'));
    host.peers.single.sendNotification('action', {
      'channel': 'ahp-chat:/a',
      'action': _turnStarted('t1'),
      'serverSeq': 6,
      'origin': {'clientId': 'test-client', 'clientSeq': seq},
      'rejectionReason': 'busy',
    });
    final failed = await failure;
    expect(failed.kind, ActionFailureKind.rejected);
    expect(failed.reason, 'busy');
  });

  group('protocol 0.9.0', () {
    setUp(() {
      host.onInitialize = (_) => {
        ..._initializeResult,
        'protocolVersion': '0.9.0',
      };
    });

    test('dispatch refuses actions 0.9.0 does not know', () async {
      await client.connect();
      await client.openSession('pi:/a');
      expect(client.state.protocolVersion, '0.9.0');
      expect(
        () => client.dispatch('ahp-chat:/a', {
          'type': 'chat/isArchivedChanged',
          'isArchived': true,
        }),
        throwsA(isA<UnsupportedActionError>()),
      );
      expect(client.state.chatChannels['ahp-chat:/a']!.pending, isEmpty);
      client.dispatch('ahp-chat:/a', _turnStarted('t1'));
    });

    test('actions 0.9.0 does not know are ignored', () async {
      await client.connect();
      await client.openSession('pi:/a');
      final before = client.state.chatChannels['ahp-chat:/a'];
      host.peers.single.sendNotification('action', {
        'channel': 'ahp-chat:/a',
        'action': {'type': 'chat/movableChanged', 'movable': true},
        'serverSeq': 7,
      });
      await _settle();
      expect(client.state.chatChannels['ahp-chat:/a'], same(before));
      expect(client.state.serverSeq, 7);
    });
  });
}
