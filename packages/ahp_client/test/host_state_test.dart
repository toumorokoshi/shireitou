import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

const _session = 'ahp-session:/s';
const _chat = 'ahp-chat:/c';

const _sessionState = <String, Object?>{
  'provider': 'pi',
  'title': 's',
  'status': 1,
  'lifecycle': 'ready',
  'activeClients': <Object?>[],
  'chats': [
    {
      'resource': _chat,
      'title': 's',
      'status': 1,
      'modifiedAt': '2026-01-01T00:00:00Z',
    },
  ],
};

const _chatState = <String, Object?>{
  'resource': _chat,
  'title': 's',
  'status': 1,
  'modifiedAt': '2026-01-01T00:00:00Z',
  'turns': <Object?>[],
};

JsonMap _turnStarted(String id) => ChatTurnStartedAction(
  turnId: id,
  startedAt: '2026-01-01T00:00:00.000Z',
  message: userMessage('hi'),
).toJson();

HostState _subscribed({String? version}) {
  final state = HostState(protocolVersion: version);
  return applySnapshot(
    applySnapshot(
      state,
      const Snapshot(resource: _session, state: _sessionState, fromSeq: 1),
      ChannelKind.session,
    ),
    const Snapshot(resource: _chat, state: _chatState, fromSeq: 1),
    ChannelKind.chat,
  );
}

void main() {
  group('applyEnvelope under 0.9.0', () {
    test('ignores 1.0.0-only actions but advances serverSeq', () {
      final state = _subscribed(version: '0.9.0');
      final next = applyEnvelope(
        state,
        const ActionEnvelope(
          channel: _chat,
          action: {'type': 'chat/isReadChanged', 'isRead': true},
          serverSeq: 4,
        ),
        clientId: 'me',
      );
      expect(next.chatChannels[_chat], same(state.chatChannels[_chat]));
      expect(next.serverSeq, 4);
    });

    test('applies actions 0.9.0 knows', () {
      final next = applyEnvelope(
        _subscribed(version: '0.9.0'),
        ActionEnvelope(channel: _chat, action: _turnStarted('t'), serverSeq: 4),
        clientId: 'me',
      );
      expect(next.chatChannels[_chat]!.state.activeTurn?.id, 't');
    });
  });

  group('missing channels', () {
    test('are unmirrored and recorded', () {
      final next = applyReconnectResult(
        _subscribed(),
        const ReconnectReplayResult(actions: [], missing: [_session]),
        clientId: 'me',
      );
      expect(next.sessionChannels, isEmpty);
      expect(next.chatChannels.keys, [_chat]);
      expect(next.missingChannels, {_session});
    });

    test('a new snapshot clears the entry', () {
      final missing = applyMissingChannels(_subscribed(), [_session]);
      final next = applySnapshot(
        missing,
        const Snapshot(resource: _session, state: _sessionState, fromSeq: 2),
        ChannelKind.session,
      );
      expect(next.missingChannels, isEmpty);
      expect(next.sessionChannels.keys, [_session]);
    });

    test('a snapshot result drops mirrors it has no snapshot for', () {
      final next = applyReconnectResult(
        _subscribed(),
        const ReconnectSnapshotResult(
          snapshots: [
            Snapshot(resource: _session, state: _sessionState, fromSeq: 9),
          ],
        ),
        clientId: 'me',
      );
      expect(next.sessionChannels.keys, [_session]);
      expect(next.chatChannels, isEmpty);
      expect(next.missingChannels, {_chat});
      expect(next.serverSeq, 9);
    });

    test('unresumedChannels lists uncovered session and chat mirrors', () {
      expect(unresumedChannels(_subscribed(), const []), [_session, _chat]);
      expect(unresumedChannels(const HostState(), const []), isEmpty);
    });

    test('an empty list changes nothing', () {
      final state = _subscribed();
      expect(applyMissingChannels(state, const []), same(state));
    });
  });

  group('pending actions', () {
    final pending = applyDispatchedAction(
      applyDispatchedAction(_subscribed(), _chat, (
        clientSeq: 1,
        action: _turnStarted('t'),
      )),
      _session,
      (
        clientSeq: 2,
        action: SessionIsArchivedChangedAction(isArchived: true).toJson(),
      ),
    );

    test('pendingActionsOf lists them per channel', () {
      final all = pendingActionsOf(pending);
      expect(all.keys, unorderedEquals([_chat, _session]));
      expect(all[_chat]!.single.clientSeq, 1);
    });

    test('expirePendingAction rolls one back and reports it', () {
      final (:state, :failure) = expirePendingAction(pending, _chat, 1);
      expect(state.chatChannels[_chat]!.state.activeTurn, isNull);
      expect(state.sessionChannels[_session]!.pending, hasLength(1));
      expect(failure!.kind, ActionFailureKind.timedOut);
      expect(failure.channel, _chat);
      expect(failure.action['type'], 'chat/turnStarted');
    });

    test('expirePendingAction ignores actions no longer pending', () {
      final (:state, :failure) = expirePendingAction(pending, _chat, 9);
      expect(state, same(pending));
      expect(failure, isNull);
    });

    test('clearAllPendingActions rolls back everything', () {
      final (:state, :failures) = clearAllPendingActions(pending);
      expect(pendingActionsOf(state), isEmpty);
      expect(state.chatChannels[_chat]!.state.activeTurn, isNull);
      expect(failures.map((f) => f.clientSeq), unorderedEquals([1, 2]));
      expect(
        failures.map((f) => f.kind),
        everyElement(ActionFailureKind.connectionLost),
      );
      final again = clearAllPendingActions(state);
      expect(again.failures, isEmpty);
      expect(again.state, same(state));
    });
  });

  test('rejectionOf reports only rejections of our own actions', () {
    const envelope = ActionEnvelope(
      channel: _chat,
      action: {'type': 'chat/turnCancelled'},
      serverSeq: 3,
      origin: ActionOrigin(clientId: 'me', clientSeq: 7),
      rejectionReason: 'no turn',
    );
    final failure = rejectionOf(envelope, clientId: 'me')!;
    expect(failure.kind, ActionFailureKind.rejected);
    expect(failure.reason, 'no turn');
    expect(failure.clientSeq, 7);
    expect(rejectionOf(envelope, clientId: 'other'), isNull);
    expect(
      rejectionOf(envelope.copyWith(rejectionReason: null), clientId: 'me'),
      isNull,
    );
  });
}
