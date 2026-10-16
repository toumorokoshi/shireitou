import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/screens/new_session_screen.dart';
import 'package:shireitou/src/session_detail/chat_commands.dart';
import 'package:shireitou/src/session_list/session_filter.dart';

import 'fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 0, 0, 2);
  final active = chatFixture();
  final idle = chatFixture(active: false);
  final pendingTool =
      (active.activeTurn!.responseParts.first as ToolCallResponsePart).toolCall;

  group('sendMessageAction', () {
    test('starts a turn when idle', () {
      final action = sendMessageAction(idle, text: 'hi', id: 't', now: now);
      expect(action['type'], 'chat/turnStarted');
      expect(action['turnId'], 't');
      expect(action['startedAt'], '2026-10-01T00:00:02.000Z');
      expect(action['message'], {
        'text': 'hi',
        'origin': {'kind': 'user'},
      });
    });

    test('queues, or steers, while a turn runs', () {
      final queued = sendMessageAction(active, text: 'a', id: 'q', now: now);
      expect(queued['type'], 'chat/pendingMessageSet');
      expect(queued['kind'], 'queued');
      final steering = sendMessageAction(
        active,
        text: 'a',
        id: 's',
        now: now,
        steer: true,
      );
      expect(steering['kind'], 'steering');
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
}
