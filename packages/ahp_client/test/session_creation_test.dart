import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

SessionSummary _summary(String resource) => SessionSummary(
  resource: resource,
  provider: 'pi',
  title: 't',
  status: SessionStatus.idle,
  createdAt: '2026-01-01T00:00:00Z',
  modifiedAt: '2026-01-01T00:00:00Z',
);

SessionState _session(SessionLifecycle lifecycle, {ErrorInfo? error}) =>
    SessionState(
      provider: 'pi',
      title: 't',
      status: SessionStatus.idle,
      lifecycle: lifecycle,
      creationError: error,
      activeClients: const [],
      chats: const [],
    );

void main() {
  const created = 'ahp-session:/abc';

  test('waits while the session is neither listed nor mirrored', () {
    expect(creationOutcome(const HostState(), created), isNull);
  });

  test('a listed session is created, under the URI the host lists', () {
    final state = HostState(
      sessions: catalogueFromSummaries([_summary('pi:/abc')]),
    );
    final outcome = creationOutcome(state, created);
    expect(outcome, isA<SessionCreated>());
    expect((outcome! as SessionCreated).resource, 'pi:/abc');
  });

  test('a failed lifecycle wins, with the host error', () {
    const error = ErrorInfo(errorType: 'creationFailed', message: 'no dir');
    final state = HostState(
      sessions: catalogueFromSummaries([_summary(created)]),
      sessionChannels: {
        created: ChannelMirror.snapshot(
          _session(SessionLifecycle.failed, error: error),
        ),
      },
    );
    final outcome = creationOutcome(state, created);
    expect(outcome, isA<SessionCreationFailed>());
    expect((outcome! as SessionCreationFailed).error?.message, 'no dir');
    expect(
      SessionCreationFailedError(created, error).toString(),
      'The session could not start: no dir',
    );
  });

  test('keeps waiting while the mirror says creating, even if listed', () {
    final state = HostState(
      sessions: catalogueFromSummaries([_summary(created)]),
      sessionChannels: {
        created: ChannelMirror.snapshot(_session(SessionLifecycle.creating)),
      },
    );
    expect(creationOutcome(state, created), isNull);
    final ready = state.copyWith(
      sessionChannels: {
        created: ChannelMirror.snapshot(_session(SessionLifecycle.ready)),
      },
    );
    expect(creationOutcome(ready, created), isA<SessionCreated>());
  });
}
