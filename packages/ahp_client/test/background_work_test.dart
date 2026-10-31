import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

const _shell = {
  'kind': 'shell',
  'id': 'w1',
  'label': 'npm test',
  'startedAt': '2026-01-01T00:00:00.000Z',
  'command': 'npm test',
};

ChannelMirror<ChatState> _chat(String uri, {bool busy = false}) =>
    ChannelMirror.snapshot(
      ChatState.fromJson({
        'resource': uri,
        'title': 't',
        'status': 1,
        'modifiedAt': '2026-01-01T00:00:00Z',
        'turns': <Object?>[],
        if (busy) 'backgroundWork': [_shell],
      }),
    );

ChannelMirror<SessionState> _session(List<String> chats) =>
    ChannelMirror.snapshot(
      SessionState.fromJson({
        'provider': 'pi',
        'title': 't',
        'status': 1,
        'lifecycle': 'ready',
        'activeClients': <Object?>[],
        'chats': [
          for (final chat in chats)
            {
              'resource': chat,
              'title': 't',
              'status': 1,
              'modifiedAt': '2026-01-01T00:00:00Z',
            },
        ],
      }),
    );

SessionSummary _summary(
  String resource, {
  String? defaultChat,
  Object? backgroundWork,
}) => SessionSummary.fromJson({
  'resource': resource,
  'provider': 'pi',
  'title': 't',
  'status': 33,
  'createdAt': '2026-01-01T00:00:00Z',
  'modifiedAt': '2026-01-01T00:00:00Z',
  'defaultChat': ?defaultChat,
  if (backgroundWork != null) '_meta': {backgroundWorkMetaKey: backgroundWork},
});

void main() {
  group('sessionsWithBackgroundWork', () {
    test('finds a session through its mirror or its catalogue entry', () {
      final state = HostState(
        sessions: {
          'pi:/a': _summary('pi:/a'),
          'pi:/b': _summary('pi:/b', defaultChat: 'ahp-chat:/b'),
          'pi:/c': _summary('pi:/c', defaultChat: 'ahp-chat:/c'),
        },
        sessionChannels: {
          'pi:/a': _session(['ahp-chat:/a', 'ahp-chat:/a-sub']),
        },
        chatChannels: {
          'ahp-chat:/a-sub': _chat('ahp-chat:/a-sub', busy: true),
          'ahp-chat:/b': _chat('ahp-chat:/b', busy: true),
          'ahp-chat:/c': _chat('ahp-chat:/c'),
        },
      );
      expect(sessionsWithBackgroundWork(state), {'pi:/a', 'pi:/b'});
    });

    test('finds a session its summary reports, without any chat', () {
      final state = HostState(
        sessions: {
          'pi:/a': _summary('pi:/a', backgroundWork: 2),
          'pi:/b': _summary('pi:/b', backgroundWork: 0),
          'pi:/c': _summary('pi:/c', backgroundWork: 'yes'),
          'pi:/d': _summary('pi:/d'),
        },
      );
      expect(sessionsWithBackgroundWork(state), {'pi:/a'});
    });

    test('a summary change with an empty _meta clears it', () {
      final catalogue = applySessionSummaryChanged(
        {'pi:/a': _summary('pi:/a', backgroundWork: 1)},
        'pi:/a',
        const {'_meta': <String, Object?>{}},
      );
      expect(summaryReportsBackgroundWork(catalogue['pi:/a']!), isFalse);
      expect(
        sessionsWithBackgroundWork(HostState(sessions: catalogue)),
        isEmpty,
      );
    });

    test('is empty when no mirrored chat has background work', () {
      final state = HostState(
        sessions: {'pi:/a': _summary('pi:/a', defaultChat: 'ahp-chat:/a')},
        chatChannels: {'ahp-chat:/a': _chat('ahp-chat:/a')},
      );
      expect(sessionsWithBackgroundWork(state), isEmpty);
    });
  });

  test('holdsBackgroundWork covers the busy chat and its session', () {
    final state = HostState(
      sessionChannels: {
        'pi:/a': _session(['ahp-chat:/a']),
      },
      chatChannels: {'ahp-chat:/a': _chat('ahp-chat:/a', busy: true)},
    );
    expect(holdsBackgroundWork(state, 'ahp-chat:/a'), isTrue);
    expect(holdsBackgroundWork(state, 'pi:/a'), isTrue);
    expect(holdsBackgroundWork(state, 'pi:/other'), isFalse);
  });

  group('withBackgroundWork', () {
    test('marks an idle session in progress, keeping its flags', () {
      final status = withBackgroundWork(const SessionStatus(33), busy: true);
      expect(status.isInProgress, isTrue);
      expect(status.isIdle, isFalse);
      expect(status.isReadFlag, isTrue);
    });

    test('keeps the status when not busy or already in progress', () {
      expect(withBackgroundWork(const SessionStatus(33), busy: false).bits, 33);
      expect(
        withBackgroundWork(SessionStatus.inputNeeded, busy: true),
        SessionStatus.inputNeeded,
      );
    });

    test('keeps the error bit', () {
      expect(
        withBackgroundWork(SessionStatus.error, busy: true).isError,
        isTrue,
      );
    });
  });
}
