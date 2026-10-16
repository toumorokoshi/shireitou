import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

SessionState _reduce(SessionState state, JsonMap action) =>
    reduceSession(state, SessionAction.fromJson(action));

void main() {
  final state = SessionState.fromJson({
    'provider': 'pi',
    'title': 'New session',
    'status': 1,
    'lifecycle': 'creating',
    'activeClients': <Object?>[],
    'chats': [
      {'resource': 'ahp-chat:/a', 'title': 'New session', 'status': 1},
    ],
  });

  test('ready and creationFailed set the lifecycle', () {
    expect(_reduce(state, {'type': 'session/ready'}).lifecycle, 'ready');
    final failed = _reduce(state, {
      'type': 'session/creationFailed',
      'error': {'errorType': 'x', 'message': 'no model'},
    });
    expect(failed.lifecycle, 'failed');
    expect(failed.creationError?.message, 'no model');
  });

  test('chatUpdated merges partial summaries', () {
    final next = _reduce(state, {
      'type': 'session/chatUpdated',
      'chat': 'ahp-chat:/a',
      'changes': {'status': 8, 'activity': 'Thinking'},
    });
    expect(next.chats.single.status!.isInProgress, isTrue);
    expect(next.chats.single.activity, 'Thinking');
    expect(next.chats.single.title, 'New session');
  });

  test('chat added, default chat and removal', () {
    final added = _reduce(state, {
      'type': 'session/chatAdded',
      'summary': {'resource': 'ahp-chat:/b', 'title': 'side'},
    });
    final defaulted = _reduce(added, {
      'type': 'session/defaultChatChanged',
      'defaultChat': 'ahp-chat:/b',
    });
    expect(defaultChatOf(defaulted), 'ahp-chat:/b');
    final removed = _reduce(defaulted, {
      'type': 'session/chatRemoved',
      'chat': 'ahp-chat:/b',
    });
    expect(defaultChatOf(removed), 'ahp-chat:/a');
  });

  test('title, read, archived and activity', () {
    var next = _reduce(state, {'type': 'session/titleChanged', 'title': 'T'});
    next = _reduce(next, {'type': 'session/isReadChanged', 'isRead': true});
    next = _reduce(next, {
      'type': 'session/isArchivedChanged',
      'isArchived': true,
    });
    next = _reduce(next, {
      'type': 'session/activityChanged',
      'activity': 'Running ls',
    });
    expect(next.title, 'T');
    expect(next.status.isReadFlag, isTrue);
    expect(next.status.isArchivedFlag, isTrue);
    expect(next.status.isIdle, isTrue);
    expect(next.activity, 'Running ls');
  });

  test('unknown actions are ignored', () {
    expect(_reduce(state, {'type': 'session/customizationsChanged'}), state);
  });

  test('resolveSessionResource matches the host URI by trailing ID', () {
    final catalogue = catalogueFromSummaries([
      _summary('pi:/abc'),
      _summary('pi:/def'),
    ]);
    expect(resolveSessionResource(catalogue, 'ahp-session:/abc'), 'pi:/abc');
    expect(resolveSessionResource(catalogue, 'pi:/def'), 'pi:/def');
    expect(resolveSessionResource(catalogue, 'ahp-session:/x'), isNull);
  });
}

SessionSummary _summary(String resource) => SessionSummary(
  resource: resource,
  provider: 'pi',
  title: 't',
  status: SessionStatus.idle,
  createdAt: '2026-01-01T00:00:00Z',
  modifiedAt: '2026-01-01T00:00:00Z',
);
