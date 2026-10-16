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

void main() {
  late FakeHost host;
  late AhpClient client;

  setUp(() {
    host = FakeHost();
    client = AhpClient(
      uri: Uri.parse('ws://fake'),
      clientId: 'test-client',
      connector: host.connect,
    );
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
}
