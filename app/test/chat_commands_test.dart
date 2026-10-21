import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/directory_browser.dart';
import 'package:shireitou/src/session_detail/chat_commands.dart';
import 'package:shireitou/src/session_list/session_filter.dart';

import 'fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 0, 0, 2);
  final active = chatFixture();
  final idle = chatFixture(active: false);
  final pendingTool =
      (active.activeTurn!.responseParts.first as ToolCallResponsePart).toolCall;

  group('sendMessageActions', () {
    test('starts a turn when idle', () {
      final action = sendMessageActions(
        idle,
        text: 'hi',
        id: 't',
        now: now,
      ).single;
      expect(action['type'], 'chat/turnStarted');
      expect(action['turnId'], 't');
      expect(action['startedAt'], '2026-10-01T00:00:02.000Z');
      expect(action['message'], {
        'text': 'hi',
        'origin': {'kind': 'user'},
      });
    });

    test('queues while a turn runs', () {
      final queued = sendMessageActions(
        active,
        text: 'a',
        id: 'q',
        now: now,
      ).single;
      expect(queued['type'], 'chat/pendingMessageSet');
      expect(queued['kind'], 'queued');
    });

    test('send now stops the running turn and starts the message', () {
      final actions = sendMessageActions(
        active,
        text: 'a',
        id: 's',
        now: now,
        sendNow: true,
      );
      expect(actions.first, {
        'type': 'chat/turnCancelled',
        'turnId': 'turn-2',
        'duration': 2000,
      });
      expect(actions.last['type'], 'chat/turnStarted');
      expect(actions.last['turnId'], 's');
      expect((actions.last['message']! as JsonMap)['text'], 'a');
      expect(actions, hasLength(2));
    });

    test('send now with no turn running just starts it', () {
      final actions = sendMessageActions(
        idle,
        text: 'a',
        id: 's',
        now: now,
        sendNow: true,
      );
      expect([for (final a in actions) a['type']], ['chat/turnStarted']);
    });
  });

  group('editing the latest message (AV-088)', () {
    test('the running turn, else the latest, is editable', () {
      expect(editableTurnId(active), 'turn-2');
      expect(editableTurnId(idle), 'turn-1');
      expect(editableTurnId(idle.copyWith(turns: const [])), isNull);
      // Truncating before the oldest loaded turn would drop unloaded ones.
      expect(editableTurnId(idle.copyWith(turnsNextCursor: 'c')), isNull);
      expect(editableTurnId(active.copyWith(turnsNextCursor: 'c')), 'turn-2');
    });

    test('a running message is dropped and sent again edited', () {
      final actions = restartActions(
        active,
        turnId: 'turn-2',
        text: ' Delete it, carefully ',
        id: 't3',
        now: now,
      )!;
      expect(actions.first, {'type': 'chat/truncated', 'turnId': 'turn-1'});
      expect(actions.last['type'], 'chat/turnStarted');
      expect(actions.last['turnId'], 't3');
      expect(
        (actions.last['message']! as JsonMap)['text'],
        'Delete it, carefully',
      );
    });

    test('the first message truncates every turn', () {
      final actions = restartActions(
        idle,
        turnId: 'turn-1',
        text: 'List all files',
        id: 't2',
        now: now,
      )!;
      expect(actions.first, {'type': 'chat/truncated'});
    });

    test('blank text or another turn sends nothing', () {
      expect(
        restartActions(active, turnId: 'turn-2', text: ' ', id: 'x', now: now),
        isNull,
      );
      expect(
        restartActions(active, turnId: 'turn-1', text: 'a', id: 'x', now: now),
        isNull,
      );
    });
  });

  test('stopAction cancels the active turn with its duration', () {
    expect(stopAction(active, now), {
      'type': 'chat/turnCancelled',
      'turnId': 'turn-2',
      'duration': 2000,
    });
    expect(stopAction(idle, now), isNull);
  });

  group('savePendingEditAction', () {
    final queued = PendingMessage(id: 'q1', message: userMessage('first'));
    const kind = PendingMessageKind.queued;

    test('send now unqueues the message, stops the turn and starts it', () {
      final withModel = PendingMessage(
        id: 'q1',
        message: userMessage('first', model: const ModelSelection(id: 'fast')),
      );
      final actions = sendQueuedNowActions(
        active,
        withModel,
        id: 't3',
        now: now,
      );
      expect(actions, [
        {'type': 'chat/pendingMessageRemoved', 'kind': 'queued', 'id': 'q1'},
        {'type': 'chat/turnCancelled', 'turnId': 'turn-2', 'duration': 2000},
        {
          'type': 'chat/turnStarted',
          'turnId': 't3',
          'startedAt': '2026-10-01T00:00:02.000Z',
          'message': withModel.message.toJson(),
        },
      ]);
      // With no turn running there is nothing to stop.
      expect(
        [
          for (final a in sendQueuedNowActions(idle, queued, id: 't', now: now))
            a['type'],
        ],
        ['chat/pendingMessageRemoved', 'chat/turnStarted'],
      );
    });

    test('sets the trimmed text', () {
      final action = savePendingEditAction(kind, queued, ' first, edited ')!;
      expect(action['type'], 'chat/pendingMessageSet');
      expect(action['id'], 'q1');
      expect((action['message']! as JsonMap)['text'], 'first, edited');
    });

    test('removes the message when the text is blank', () {
      expect(savePendingEditAction(kind, queued, '  '), {
        'type': 'chat/pendingMessageRemoved',
        'kind': 'queued',
        'id': 'q1',
      });
    });

    test('sends nothing when unchanged or no longer pending', () {
      expect(savePendingEditAction(kind, queued, 'first '), isNull);
      expect(savePendingEditAction(kind, null, 'edited'), isNull);
    });
  });

  group('confirmToolCallAction', () {
    test('approve and deny', () {
      expect(confirmToolCallAction('turn-2', pendingTool, approve: true), {
        'type': 'chat/toolCallConfirmed',
        'turnId': 'turn-2',
        'toolCallId': 'rm',
        'approved': true,
        'confirmed': 'user-action',
      });
      final denied = confirmToolCallAction(
        'turn-2',
        pendingTool,
        approve: false,
      );
      expect(denied['reason'], 'denied');
      expect(denied.containsKey('confirmed'), isFalse);
    });

    test('a host option is sent as selectedOptionId', () {
      const option = ConfirmationOption(
        id: 'always',
        label: 'Always',
        kind: ConfirmationOptionKind.approve,
      );
      final action = confirmToolCallAction(
        'turn-2',
        pendingTool,
        approve: true,
        option: option,
      );
      expect(action['selectedOptionId'], 'always');
    });

    test('results waiting for review use toolCallResultConfirmed', () {
      final action = confirmToolCallAction(
        'turn-2',
        ToolCallPendingResultConfirmationState(
          toolCallId: pendingTool.toolCallId,
          toolName: pendingTool.toolName,
          displayName: pendingTool.displayName,
          invocationMessage: pendingTool.invocationMessage!,
          confirmed: ToolCallConfirmationReason.userAction,
          success: true,
          pastTenseMessage: const PlainString('Ran it'),
        ),
        approve: false,
      );
      expect(action['type'], 'chat/toolCallResultConfirmed');
      expect(action['approved'], isFalse);
    });
  });

  group('input answers', () {
    ChatInputQuestion q(String kind, {bool required = false}) =>
        ChatInputQuestion.fromJson({
          'id': kind,
          'kind': kind,
          'message': kind,
          'required': required,
          if (kind.endsWith('select')) 'options': <Object?>[],
        });

    test('values become submitted answers by question kind', () {
      expect(inputAnswer(q('text'), 'x')!.toJson()['value'], {
        'kind': 'text',
        'value': 'x',
      });
      expect(inputAnswer(q('integer'), '3')!.toJson()['value'], {
        'kind': 'number',
        'value': 3,
      });
      expect(inputAnswer(q('number'), 'x'), isNull);
      expect(inputAnswer(q('boolean'), false)!.toJson()['value'], {
        'kind': 'boolean',
        'value': false,
      });
      expect(inputAnswer(q('single-select'), 'a')!.toJson()['value'], {
        'kind': 'selected',
        'value': 'a',
      });
      expect(inputAnswer(q('multi-select'), {'a', 'b'})!.toJson()['value'], {
        'kind': 'selected-many',
        'value': ['a', 'b'],
      });
      expect(inputAnswer(q('text'), ''), isNull);
    });

    test('required questions gate completion; decline sends no answers', () {
      final request = ChatInputRequest(
        id: 'r',
        questions: [q('text', required: true)],
      );
      expect(inputComplete(request, {'text': ''}), isFalse);
      expect(inputComplete(request, {'text': 'x'}), isTrue);
      expect(
        inputCompletedAction(request, accept: false, values: {'text': 'x'}),
        {
          'type': 'chat/inputCompleted',
          'requestId': 'r',
          'response': 'decline',
        },
      );
    });
  });

  test('matchesFilter uses the archived and attention bits', () {
    const archived = SessionStatus(97);
    const read = SessionStatus(33);
    expect(matchesFilter(archived, SessionFilter.active), isFalse);
    expect(matchesFilter(archived, SessionFilter.archived), isTrue);
    expect(matchesFilter(read, SessionFilter.attention), isFalse);
    expect(
      matchesFilter(SessionStatus.inputNeeded, SessionFilter.attention),
      isTrue,
    );
    expect(matchesFilter(archived, SessionFilter.all), isTrue);
  });

  test('directoryUri keeps file URIs and converts paths', () {
    expect(directoryUri('file:///a/b/'), 'file:///a/b/');
    expect(directoryUri(' /a/b c '), 'file:///a/b%20c');
  });

  test('folder browser paths', () {
    expect(parentFolder('/a/b'), '/a');
    expect(parentFolder('/a'), '/');
    expect(parentFolder('/'), isNull);
    expect(childFolder('/', 'a'), '/a');
    expect(childFolder('/a', 'b'), '/a/b');
    expect(
      folderNames(const [
        DirectoryEntry(name: 'b', type: DirectoryEntryType.directory),
        DirectoryEntry(name: 'README', type: DirectoryEntryType.file),
        DirectoryEntry(name: 'A', type: DirectoryEntryType.directory),
      ]),
      ['A', 'b'],
    );
  });
}
