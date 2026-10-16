import 'dart:convert';
import 'dart:io';

import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

/// Recorded traffic: two turns (a plain reply and a `bash` tool call), a
/// rejected `chat/turnCancelled`, and `session/isReadChanged`.
List<JsonMap> recordedEntries() => (jsonDecode(
  File('../../examples/ahp/pi-host-chat-turns.json').readAsStringSync(),
) as List<Object?>).cast<JsonMap>();

const _clientId = 'recorder';

/// Replays [entries] the way [AhpClient] would: host messages through the
/// pure functions, and the client's own `dispatchAction`s as write-ahead
/// actions. Calls [onStep] after each entry.
HostState replay(
  List<JsonMap> entries, {
  void Function(HostState state, JsonMap entry)? onStep,
}) {
  var state = const HostState();
  for (final entry in entries) {
    final message = entry['message']! as JsonMap;
    final params = message['params'] as JsonMap?;
    final result = message['result'];
    if (entry['dir'] == 'client->host') {
      if (message['method'] == 'dispatchAction') {
        state = applyDispatchedAction(state, params!['channel']! as String, (
          clientSeq: params['clientSeq']! as int,
          action: params['action']! as JsonMap,
        ));
      }
    } else if (result is JsonMap && result.containsKey('protocolVersion')) {
      state = applyInitializeResult(state, InitializeResult.fromJson(result));
    } else if (result is JsonMap && result['snapshot'] is JsonMap) {
      final snapshot = Snapshot.fromJson(result['snapshot']! as JsonMap);
      final kind = snapshot.state.containsKey('turns')
          ? ChannelKind.chat
          : ChannelKind.session;
      state = applySnapshot(state, snapshot, kind);
    } else if (message['method'] == 'action') {
      state = applyEnvelope(
        state,
        ActionEnvelope.fromJson(params!),
        clientId: _clientId,
      );
    } else if (message['method'] case final String method
        when method.startsWith('root/')) {
      state = state.copyWith(
        sessions: applyRootNotification(state.sessions, method, params!),
      );
    }
    onStep?.call(state, entry);
  }
  return state;
}

ChatState _chat(Iterable<ResponsePart> parts, {List<Turn> turns = const []}) =>
    ChatState(
      resource: 'ahp-chat:/c',
      title: 't',
      status: SessionStatus(SessionStatus.inProgress.bits),
      modifiedAt: '2026-01-01T00:00:00.000Z',
      turns: turns,
      activeTurn: ActiveTurn(
        id: 't1',
        startedAt: '2026-01-01T00:00:00.000Z',
        message: userMessage('hi'),
        responseParts: [...parts],
      ),
    );

ChatState _reduce(ChatState state, JsonMap action) =>
    reduceChat(state, ChatAction.fromJson(action));

ToolCallState _toolCall(ChatState state) =>
    (state.activeTurn!.responseParts.single as ToolCallResponsePart).toolCall;

void main() {
  group('recorded pi traffic', () {
    final entries = recordedEntries();
    final state = replay(entries);
    final chat = state.chatChannels.values.single;
    final session = state.sessionChannels.values.single;

    test('rebuilds both finished turns', () {
      expect(chat.pending, isEmpty);
      final turns = chat.state.turns;
      expect(turns, hasLength(2));
      expect(turns.map((t) => t.state), everyElement(TurnState.complete));
      expect(chat.state.activeTurn, isNull);
      expect(turns[0].message.text, 'Reply with just the word ok.');
      expect(turns[0].responseParts.first, isA<ReasoningResponsePart>());
      expect(
        turns[0].responseParts.whereType<MarkdownResponsePart>().single.content,
        'ok',
      );
      expect(turns[0].usage?.outputTokens, 73);
      expect(turns[0].duration, 12280);
    });

    test('rebuilds the tool call from start to completion', () {
      final call = chat.state.turns[1].responseParts
          .whereType<ToolCallResponsePart>()
          .single
          .toolCall;
      expect(call, isA<ToolCallCompletedState>());
      call as ToolCallCompletedState;
      expect(call.displayName, 'Bash');
      expect(call.toolInput, const InlineToolInput('{"command":"ls"}'));
      expect(call.confirmed, ToolCallConfirmationReason.notNeeded);
      expect(call.invocationMessage.text, 'Running `ls`');
      expect(call.pastTenseMessage.text, 'Ran `ls`');
      expect(call.success, isTrue);
      expect((call.content!.single as ToolResultTextContent).text, 'a.txt\n');
      expect(
        chat.state.turns[1].responseParts
            .whereType<MarkdownResponsePart>()
            .last
            .content,
        'done',
      );
    });

    test('tracks session title, read flag and idle status', () {
      expect(session.state.title, 'Reply with just the word ok.');
      expect(session.state.lifecycle, SessionLifecycle.ready);
      expect(session.state.status.isReadFlag, isTrue);
      expect(chat.state.status.isIdle, isTrue);
      expect(chat.state.status.isReadFlag, isTrue);
      expect(chat.state.activity, isNull);
      expect(defaultChatOf(session.state), chat.state.resource);
    });

    test('shows the optimistic turn before the echo and streams deltas', () {
      final seen = <String>[];
      replay(
        entries,
        onStep: (state, entry) {
          final mirror = state.chatChannels.values.firstOrNull;
          final active = mirror?.state.activeTurn;
          if (entry['dir'] == 'client->host' && active != null) {
            seen.add('optimistic:${mirror!.pending.length}');
          }
          final markdown = active?.responseParts
              .whereType<MarkdownResponsePart>();
          if (markdown != null && markdown.isNotEmpty) {
            seen.add('text:${markdown.last.content}');
          }
        },
      );
      expect(seen.first, 'optimistic:1');
      expect(seen, contains('text:ok'));
      expect(seen, contains('text:done'));
    });

    test('a rejected action leaves the confirmed state unchanged', () {
      final rejected = entries.indexWhere(
        (e) => jsonEncode(e).contains('"rejectionReason"'),
      );
      final before = replay(entries.sublist(0, rejected));
      final after = replay(entries.sublist(0, rejected + 1));
      expect(before.chatChannels.values.single.pending, hasLength(1));
      expect(after.chatChannels.values.single.pending, isEmpty);
      expect(
        after.chatChannels.values.single.state,
        before.chatChannels.values.single.confirmed,
      );
    });
  });

  group('tool confirmations (AHP-041)', () {
    final ready = _reduce(
      _chat([
        const ToolCallResponsePart(
          toolCall: ToolCallStreamingState(
            toolCallId: 'x',
            toolName: 'bash',
            displayName: 'Bash',
            partialInput: '{"command":"rm',
          ),
        ),
      ]),
      {
        'type': 'chat/toolCallReady',
        'turnId': 't1',
        'toolCallId': 'x',
        'invocationMessage': 'Run rm',
        'toolInput': '{"command":"rm"}',
        'options': [
          {'id': 'once', 'label': 'Allow once', 'kind': 'approve'},
        ],
      },
    );

    test('toolCallReady without confirmed waits for the user', () {
      final call = _toolCall(ready) as ToolCallPendingConfirmationState;
      expect(call.toolInput, const InlineToolInput('{"command":"rm"}'));
      expect(call.options!.single.id, 'once');
      expect(ready.status.isInputNeeded, isTrue);
    });

    test('approving runs the tool and records the option', () {
      final approved = _reduce(ready, {
        'type': 'chat/toolCallConfirmed',
        'turnId': 't1',
        'toolCallId': 'x',
        'approved': true,
        'confirmed': 'user-action',
        'selectedOptionId': 'once',
      });
      final call = _toolCall(approved);
      expect(call, isA<ToolCallRunningState>());
      expect(call.selectedOption?.label, 'Allow once');
      expect(approved.status.isInputNeeded, isFalse);
      expect(approved.status.isInProgress, isTrue);
    });

    test('denying cancels the tool', () {
      final denied = _reduce(ready, {
        'type': 'chat/toolCallConfirmed',
        'turnId': 't1',
        'toolCallId': 'x',
        'approved': false,
        'reason': 'denied',
      });
      final call = _toolCall(denied) as ToolCallCancelledState;
      expect(call.reason, ToolCallCancellationReason.denied);
    });

    test('result confirmation completes or rejects the result', () {
      final running = _reduce(ready, {
        'type': 'chat/toolCallConfirmed',
        'turnId': 't1',
        'toolCallId': 'x',
        'approved': true,
        'confirmed': 'user-action',
      });
      final finished = _reduce(running, {
        'type': 'chat/toolCallComplete',
        'turnId': 't1',
        'toolCallId': 'x',
        'requiresResultConfirmation': true,
        'result': {'success': true, 'pastTenseMessage': 'Ran rm'},
      });
      expect(
        _toolCall(finished),
        isA<ToolCallPendingResultConfirmationState>(),
      );
      expect(finished.status.isInputNeeded, isTrue);
      final approved = _reduce(finished, {
        'type': 'chat/toolCallResultConfirmed',
        'turnId': 't1',
        'toolCallId': 'x',
        'approved': true,
      });
      expect(_toolCall(approved), isA<ToolCallCompletedState>());
      final rejected = _reduce(finished, {
        'type': 'chat/toolCallResultConfirmed',
        'turnId': 't1',
        'toolCallId': 'x',
        'approved': false,
      });
      expect(
        (_toolCall(rejected) as ToolCallCancelledState).reason,
        ToolCallCancellationReason.resultDenied,
      );
    });

    test('ending the turn cancels unfinished tool calls as skipped', () {
      final ended = _reduce(ready, {
        'type': 'chat/turnCancelled',
        'turnId': 't1',
        'duration': 5,
      });
      final call =
          (ended.turns.single.responseParts.single as ToolCallResponsePart)
              .toolCall;
      expect(
        (call as ToolCallCancelledState).reason,
        ToolCallCancellationReason.skipped,
      );
      expect(ended.turns.single.state, TurnState.cancelled);
      expect(ended.status.isIdle, isTrue);
      expect(ended.modifiedAt, '2026-01-01T00:00:00.005Z');
    });
  });

  group('input requests (AHP-042)', () {
    final requested = _reduce(_chat(const []), {
      'type': 'chat/inputRequested',
      'request': {
        'id': 'r',
        'questions': [
          {'id': 'q', 'kind': 'text', 'message': 'Name?'},
        ],
      },
    });

    test('an open request needs input and clears IsRead', () {
      expect(requested.status.isInputNeeded, isTrue);
      expect(requested.status.isReadFlag, isFalse);
      final part = requested.activeTurn!.responseParts.single;
      expect(
        (part as InputRequestResponsePart).request.questions!.single.id,
        'q',
      );
    });

    test('answer changes and completion record the answers', () {
      final answer = {
        'state': 'submitted',
        'value': {'kind': 'text', 'value': 'pi'},
      };
      final drafted = _reduce(requested, {
        'type': 'chat/inputAnswerChanged',
        'requestId': 'r',
        'questionId': 'q',
        'answer': answer,
      });
      final done = _reduce(drafted, {
        'type': 'chat/inputCompleted',
        'requestId': 'r',
        'response': 'accept',
      });
      final part =
          done.activeTurn!.responseParts.single as InputRequestResponsePart;
      expect(part.response, ChatInputResponseKind.accept);
      expect(part.request.answers, {'q': ChatInputAnswer.fromJson(answer)});
      expect(done.status.isInputNeeded, isFalse);
      expect(done.status.isInProgress, isTrue);
    });
  });

  group('turns', () {
    test('turnStarted consumes the queued message it names', () {
      final idle = _chat(const []).copyWith(
        activeTurn: null,
        queuedMessages: [PendingMessage(id: 'q1', message: userMessage('a'))],
      );
      final started = _reduce(idle, {
        'type': 'chat/turnStarted',
        'turnId': 't2',
        'startedAt': '2026-01-02T00:00:00.000Z',
        'message': userMessage('a').toJson(),
        'queuedMessageId': 'q1',
      });
      expect(started.queuedMessages, isNull);
      expect(started.activeTurn!.id, 't2');
      expect(started.status.isInProgress, isTrue);
    });

    test('pending messages are set and removed by kind', () {
      final idle = _chat(const []);
      final set = _reduce(idle, {
        'type': 'chat/pendingMessageSet',
        'kind': 'steering',
        'id': 's',
        'message': userMessage('now').toJson(),
      });
      expect(set.steeringMessage?.id, 's');
      final removed = _reduce(set, {
        'type': 'chat/pendingMessageRemoved',
        'kind': 'steering',
        'id': 's',
      });
      expect(removed.steeringMessage, isNull);
    });

    test('an error ends the turn; a resumable one can resume', () {
      final failed = _reduce(_chat(const []), {
        'type': 'chat/error',
        'turnId': 't1',
        'duration': 1,
        'part': {
          'kind': 'error',
          'error': {'errorType': 'model', 'message': 'boom'},
          'resumable': true,
        },
      });
      expect(failed.status.isError, isTrue);
      expect(failed.turns.single.state, TurnState.error);
      final resumed = _reduce(failed, {
        'type': 'chat/turnResume',
        'turnId': 't1',
      });
      expect(resumed.turns, isEmpty);
      expect(
        resumed.activeTurn!.responseParts.single,
        isA<ErrorResponsePart>(),
      );
    });

    test('turnsLoaded prepends older turns without duplicates', () {
      final turn = Turn(
        id: 'old',
        message: userMessage('x'),
        responseParts: const [],
        state: TurnState.complete,
      );
      final loaded = _reduce(_chat(const [], turns: [turn]), {
        'type': 'chat/turnsLoaded',
        'turns': [turn.copyWith(id: 'older').toJson(), turn.toJson()],
      });
      expect(loaded.turns.map((t) => t.id), ['older', 'old']);
    });

    test('unknown actions and part kinds are ignored', () {
      final state = _chat(const []);
      expect(_reduce(state, {'type': 'chat/x-future'}), state);
      final part = ResponsePart.fromJson({'kind': 'x-future'});
      expect(part, isA<ResponsePartUnknown>());
    });
  });

  group('MCP authentication (AHP-062)', () {
    ToolCallRunningState running({ToolCallContributor? contributor}) =>
        ToolCallRunningState(
          toolCallId: 'x',
          toolName: 'search',
          displayName: 'Search',
          contributor: contributor,
          invocationMessage: const PlainString('Search docs'),
          confirmed: ToolCallConfirmationReason.notNeeded,
          content: const [ToolResultTextContent(text: 'partial')],
        );
    const mcp = ToolCallMcpContributor(customizationId: 'm1');
    const authRequired = {
      'type': 'chat/toolCallAuthRequired',
      'turnId': 't1',
      'toolCallId': 'x',
      'auth': {
        'reason': 'required',
        'resource': {'resource': 'https://mcp.example.com'},
        'description': 'Sign in to Docs',
      },
    };

    test('an MCP tool call pauses for auth and needs input', () {
      final paused = _reduce(
        _chat([ToolCallResponsePart(toolCall: running(contributor: mcp))]),
        authRequired,
      );
      final call = _toolCall(paused) as ToolCallAuthRequiredState;
      expect(call.auth.description, 'Sign in to Docs');
      expect(call.content, hasLength(1));
      expect(paused.status.isInputNeeded, isTrue);

      final resumed = _reduce(paused, {
        'type': 'chat/toolCallAuthResolved',
        'turnId': 't1',
        'toolCallId': 'x',
      });
      expect(_toolCall(resumed), isA<ToolCallRunningState>());
      expect(_toolCall(resumed).content, hasLength(1));
      expect(resumed.status.isInputNeeded, isFalse);
      expect(resumed.status.isInProgress, isTrue);
    });

    test('only failures complete a call waiting for auth', () {
      final paused = _reduce(
        _chat([ToolCallResponsePart(toolCall: running(contributor: mcp))]),
        authRequired,
      );
      JsonMap complete({required bool success}) => {
        'type': 'chat/toolCallComplete',
        'turnId': 't1',
        'toolCallId': 'x',
        'requiresResultConfirmation': true,
        'result': {'success': success, 'pastTenseMessage': 'Searched'},
      };
      expect(_reduce(paused, complete(success: true)), same(paused));
      final cancelled = _reduce(paused, complete(success: false));
      final call = _toolCall(cancelled) as ToolCallCompletedState;
      expect(call.success, isFalse);
      expect(call.content, hasLength(1));
    });

    test('calls not from an MCP server never need auth', () {
      final state = _chat([ToolCallResponsePart(toolCall: running())]);
      expect(_reduce(state, authRequired), same(state));
    });
  });

  group('chat metadata (1.0.0)', () {
    final state = _chat(const []);

    test('background work is upserted and removed', () {
      var next = _reduce(state, {
        'type': 'chat/backgroundWorkSet',
        'work': {
          'kind': 'shell',
          'id': 'w1',
          'label': 'npm test',
          'startedAt': '2026-01-01T00:00:00Z',
          'command': 'npm test',
        },
      });
      next = _reduce(next, {
        'type': 'chat/backgroundWorkSet',
        'work': {
          'kind': 'subagent',
          'id': 'w2',
          'label': 'Explore',
          'startedAt': '2026-01-01T00:00:00Z',
          'chat': 'ahp-chat:/sub',
        },
      });
      next = _reduce(next, {
        'type': 'chat/backgroundWorkSet',
        'work': {
          'kind': 'shell',
          'id': 'w1',
          'label': 'npm test (watch)',
          'startedAt': '2026-01-01T00:00:00Z',
          'command': 'npm test -- --watch',
        },
      });
      expect(next.backgroundWork!.map((w) => w.label), [
        'npm test (watch)',
        'Explore',
      ]);
      expect(next.backgroundWork![1], isA<BackgroundSubagentWork>());
      final removed = _reduce(next, {
        'type': 'chat/backgroundWorkRemoved',
        'id': 'w1',
      });
      expect(removed.backgroundWork!.single.id, 'w2');
      expect(
        _reduce(removed, {'type': 'chat/backgroundWorkRemoved', 'id': 'w1'}),
        same(removed),
      );
    });

    test('changesets, canvases, movable and draft are replaced', () {
      var next = _reduce(state, {
        'type': 'chat/changesetsChanged',
        'changesets': [
          {
            'label': 'Chat',
            'uriTemplate': 'ahp-changeset:/c',
            'changeKind': 'chat',
          },
        ],
      });
      next = _reduce(next, {
        'type': 'chat/canvasesChanged',
        'canvases': [
          {'resource': 'ahp-canvas:/1'},
        ],
      });
      next = _reduce(next, {'type': 'chat/movableChanged', 'movable': true});
      next = _reduce(next, {
        'type': 'chat/draftChanged',
        'draft': userMessage('half a thought').toJson(),
      });
      expect(next.changesets!.single.label, 'Chat');
      expect(next.canvases!.single.resource, 'ahp-canvas:/1');
      expect(next.movable, isTrue);
      expect(next.draft?.text, 'half a thought');
      next = _reduce(next, {'type': 'chat/changesetsChanged'});
      next = _reduce(next, {'type': 'chat/canvasesChanged'});
      next = _reduce(next, {'type': 'chat/draftChanged'});
      expect(next.changesets, isNull);
      expect(next.canvases, isNull);
      expect(next.draft, isNull);
    });

    test('working directories are added once and removed', () {
      var next = _reduce(state, {
        'type': 'chat/workingDirectorySet',
        'directory': '/a',
      });
      expect(
        _reduce(next, {'type': 'chat/workingDirectorySet', 'directory': '/a'}),
        same(next),
      );
      next = _reduce(next, {
        'type': 'chat/workingDirectoryRemoved',
        'directory': '/a',
      });
      expect(next.workingDirectories, isEmpty);
      expect(
        _reduce(next, {
          'type': 'chat/workingDirectoryRemoved',
          'directory': '/a',
        }),
        same(next),
      );
    });

    test('queued messages are reordered; unnamed ones keep their order', () {
      final queued = state.copyWith(
        queuedMessages: [
          for (final id in ['a', 'b', 'c'])
            PendingMessage(id: id, message: userMessage(id)),
        ],
      );
      final next = _reduce(queued, {
        'type': 'chat/queuedMessagesReordered',
        'order': ['c', 'x', 'c', 'a'],
      });
      expect(next.queuedMessages!.map((m) => m.id), ['c', 'a', 'b']);
      expect(
        _reduce(state, {
          'type': 'chat/queuedMessagesReordered',
          'order': ['a'],
        }),
        same(state),
      );
    });
  });
}
