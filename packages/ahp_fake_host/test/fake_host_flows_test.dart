/// Drives [AhpClient] against the scripted fake host over a real
/// WebSocket: tool approvals (AV-083), input requests (AV-084),
/// session-level input requests, MCP sign-in (AHP-062) and background work.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';

const _timeout = Duration(seconds: 10);

void main() {
  late FakeAhpHost host;
  late AhpClient client;
  late String chat;

  setUp(() async {
    host = FakeAhpHost(
      token: 'secret',
      stepDelay: const Duration(milliseconds: 5),
      backgroundDuration: const Duration(milliseconds: 300),
    );
    final url = await host.start();
    client = AhpClient(uri: url, pingInterval: Duration.zero);
    await client.connect();
    expect(client.state.status, ConnectionStatus.connected);
    chat = (await client.openSession(seededSession))!;
  });

  tearDown(() async {
    await client.close();
    await host.close();
  });

  ChatState chatState([String? uri]) =>
      client.state.chatChannels[uri ?? chat]!.state;

  SessionState sessionState() =>
      client.state.sessionChannels[seededSession]!.state;

  /// Waits until [test] holds for the client's state.
  Future<void> until(bool Function(HostState state) test) async {
    if (test(client.state)) return;
    await client.states.firstWhere(test).timeout(_timeout);
  }

  Future<void> send(String text) async {
    client.dispatch(
      chat,
      ChatTurnStartedAction(
        turnId: 'turn-$text',
        startedAt: DateTime.now().toUtc().toIso8601String(),
        message: userMessage(text),
      ).toJson(),
    );
  }

  List<ResponsePart> parts() => [
    ...?chatState().activeTurn?.responseParts,
    if (chatState().activeTurn == null) ...chatState().turns.last.responseParts,
  ];

  String replies() => [
    for (final p in parts())
      if (p is MarkdownResponsePart) p.content,
  ].join('\n');

  ToolCallState toolCall() =>
      parts().whereType<ToolCallResponsePart>().single.toolCall;

  Future<void> turnDone() => until(
    (_) => chatState().activeTurn == null && chatState().turns.isNotEmpty,
  );

  test('rejects a connection without the token', () async {
    final url = await FakeAhpHost(token: 'other').start();
    final stranger = AhpClient(
      uri: url.replace(query: ''),
      pingInterval: Duration.zero,
    );
    await stranger.connect();
    expect(stranger.state.status, ConnectionStatus.failed);
    await stranger.close();
  });

  test('a message without a flow is echoed', () async {
    await send('hello');
    await turnDone();
    expect(replies(), contains('You said: hello'));
    expect(chatState().turns.single.state, TurnState.complete);
  });

  test('the client times every call it sees run (AHP-032)', () async {
    var timings = const <String, Map<String, ToolCallTiming>>{};
    final watch = client.states.listen(
      (s) => timings = observeToolCalls(timings, s, DateTime.now()),
    );
    await send('read');
    await turnDone();
    await watch.cancel();
    final calls = parts().whereType<ToolCallResponsePart>().toList();
    expect(calls, hasLength(3));
    for (final ToolCallResponsePart(:toolCall) in calls) {
      final timing = timings[chat]![toolCall.toolCallId]!;
      expect(timing.running, isFalse);
      expect(timing.partial, isFalse);
      expect(timing.elapsed(DateTime.now()), isNotNull);
    }
  });

  group('tool approvals (AV-083)', () {
    Future<ToolCallPendingConfirmationState> pending() async {
      await send('run the tool');
      await until(
        (_) =>
            chatState().activeTurn?.responseParts.any(
              (p) => p is ToolCallResponsePart && p.toolCall.isBlocking,
            ) ??
            false,
      );
      await until((_) => sessionState().inputNeeded != null);
      return toolCall() as ToolCallPendingConfirmationState;
    }

    test('approving runs the tool and finishes the turn', () async {
      final call = await pending();
      expect(call.confirmationTitle?.text, 'Allow Bash to run `ls -la`?');
      expect(chatState().status.isInputNeeded, isTrue);
      expect(
        sessionState().inputNeeded!.single,
        isA<SessionToolConfirmationRequest>(),
      );
      expect(sessionState().status.isInputNeeded, isTrue);
      await until((s) => s.sessions[seededSession]!.status.isInputNeeded);

      client.dispatch(
        chat,
        ChatToolCallApprovedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          confirmed: ToolCallConfirmationReason.userAction,
        ).toJson(),
      );
      // Write-ahead: running at once, before the host echoes.
      expect(toolCall(), isA<ToolCallRunningState>());
      await turnDone();
      final done = toolCall() as ToolCallCompletedState;
      expect(done.success, isTrue);
      expect(done.content!.single, isA<ToolResultTextContent>());
      expect(replies(), contains('3 entries'));
      expect(sessionState().inputNeeded, isNull);
      expect(client.state.chatChannels[chat]!.pending, isEmpty);
      await until((s) => !s.sessions[seededSession]!.status.isInProgress);
    });

    test('denying cancels the tool and the agent says so', () async {
      final call = await pending();
      client.dispatch(
        chat,
        ChatToolCallDeniedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          reason: ToolCallCancellationReason.denied,
        ).toJson(),
      );
      await turnDone();
      final cancelled = toolCall() as ToolCallCancelledState;
      expect(cancelled.reason, ToolCallCancellationReason.denied);
      expect(replies(), contains('did not run it'));
      expect(sessionState().inputNeeded, isNull);
    });

    test('stopping the turn while it waits ends it', () async {
      await pending();
      final active = chatState().activeTurn!;
      client.dispatch(
        chat,
        ChatTurnCancelledAction(turnId: active.id, duration: 1).toJson(),
      );
      await until((_) => sessionState().inputNeeded == null);
      expect(chatState().turns.single.state, TurnState.cancelled);
      expect(toolCall(), isA<ToolCallCancelledState>());
    });
  });

  group('host-provided confirmation details (AV-083)', () {
    Future<ToolCallState> blocked(String text) async {
      await send(text);
      await until(
        (_) => parts().any(
          (p) => p is ToolCallResponsePart && p.toolCall.isBlocking,
        ),
      );
      return toolCall();
    }

    test('options in groups and a risk assessment that completes', () async {
      final call = await blocked('choose');
      final pending = call as ToolCallPendingConfirmationState;
      expect(
        [for (final o in pending.options!) o.label],
        ['Allow once', 'Allow in this session', 'Skip this step', 'Deny'],
      );
      expect([for (final o in pending.options!) o.group], [1, 1, 2, 2]);
      await until(
        (_) =>
            (toolCall() as ToolCallPendingConfirmationState).riskAssessment
                is ToolCallRiskAssessmentCompleteState,
      );
      final risk =
          (toolCall() as ToolCallPendingConfirmationState).riskAssessment!
              as ToolCallRiskAssessmentCompleteState;
      expect(risk.safety, 0.35);
      await until(
        (_) => switch (sessionState().inputNeeded?.single) {
          SessionToolConfirmationRequest(
            toolCall: ToolCallPendingConfirmationState(
              riskAssessment: ToolCallRiskAssessmentCompleteState(),
            ),
          ) =>
            true,
          _ => false,
        },
      );
      client.dispatch(
        chat,
        ChatToolCallApprovedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          confirmed: ToolCallConfirmationReason.userAction,
          selectedOptionId: 'allow-session',
        ).toJson(),
      );
      await turnDone();
      expect(replies(), contains('You chose "Allow in this session"'));
      final done = toolCall() as ToolCallCompletedState;
      expect(done.selectedOption?.id, 'allow-session');
    });

    test('a denial option is reported', () async {
      final call = await blocked('choose');
      client.dispatch(
        chat,
        ChatToolCallDeniedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          reason: ToolCallCancellationReason.skipped,
          selectedOptionId: 'skip',
        ).toJson(),
      );
      await turnDone();
      expect(replies(), contains('You chose "Skip this step", so I kept'));
    });

    test('an editable input is run as edited', () async {
      final call = await blocked('command');
      expect((call as ToolCallPendingConfirmationState).editable, isTrue);
      client.dispatch(
        chat,
        ChatToolCallApprovedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          confirmed: ToolCallConfirmationReason.userAction,
          editedToolInput: '{"command":"git push origin feature"}',
        ).toJson(),
      );
      await turnDone();
      expect(
        replies(),
        contains('Ran your edited command: `git push origin feature`.'),
      );
      expect(
        toolCall().toolInput,
        const InlineToolInput('{"command":"git push origin feature"}'),
      );
    });

    test('a result waits for confirmation, and can be discarded', () async {
      final call = await blocked('result');
      expect(call, isA<ToolCallPendingResultConfirmationState>());
      await until((_) => sessionState().inputNeeded != null);
      expect(
        (sessionState().inputNeeded!.single as SessionToolConfirmationRequest)
            .toolCall,
        isA<ToolCallPendingResultConfirmationState>(),
      );
      client.dispatch(
        chat,
        ChatToolCallResultConfirmedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          approved: false,
        ).toJson(),
      );
      await turnDone();
      expect(replies(), contains('I discarded the fetched page.'));
      expect(
        (toolCall() as ToolCallCancelledState).reason,
        ToolCallCancellationReason.resultDenied,
      );
    });

    test('an accepted result is used', () async {
      final call = await blocked('result');
      client.dispatch(
        chat,
        ChatToolCallResultConfirmedAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          approved: true,
        ).toJson(),
      );
      await turnDone();
      expect(replies(), contains('Using the result'));
      expect(toolCall(), isA<ToolCallCompletedState>());
    });
  });

  test('input drafts are relayed with chat/inputAnswerChanged', () async {
    await send('draft');
    await until(
      (_) => parts().any(
        (p) =>
            p is InputRequestResponsePart &&
            p.request.answers?['notes'] != null,
      ),
    );
    final request = parts()
        .whereType<InputRequestResponsePart>()
        .single
        .request;
    expect(
      request.answers!['notes'],
      const ChatInputAnswered(
        state: 'draft',
        value: ChatInputTextAnswerValue(value: otherClientDraft),
      ),
    );
    // A cleared draft, then a new one.
    client.dispatch(
      chat,
      ChatInputAnswerChangedAction(
        requestId: request.id,
        questionId: 'summary',
      ).toJson(),
    );
    client.dispatch(
      chat,
      ChatInputAnswerChangedAction(
        requestId: request.id,
        questionId: 'summary',
        answer: const ChatInputAnswered(
          state: 'draft',
          value: ChatInputTextAnswerValue(value: 'Faster'),
        ),
      ).toJson(),
    );
    await until(
      (_) =>
          host
              .chat(chat)
              ?.activeTurn
              ?.responseParts
              .whereType<InputRequestResponsePart>()
              .single
              .request
              .answers?['summary'] !=
          null,
    );
    client.dispatch(
      chat,
      ChatInputCompletedAction(
        requestId: request.id,
        response: ChatInputResponseKind.accept,
        answers: const {
          'summary': ChatInputAnswered(
            state: 'submitted',
            value: ChatInputTextAnswerValue(value: 'Faster builds'),
          ),
          'notes': ChatInputAnswered(
            state: 'submitted',
            value: ChatInputTextAnswerValue(value: otherClientDraft),
          ),
        },
      ).toJson(),
    );
    await turnDone();
    expect(
      replies(),
      contains(
        'summary=Faster builds, notes=$otherClientDraft. Drafts synced: 2.',
      ),
    );
  });

  group('input requests (AV-084)', () {
    Future<ChatInputRequest> asked() async {
      await send('ask me');
      await until((_) => parts().any((p) => p is InputRequestResponsePart));
      return parts().whereType<InputRequestResponsePart>().single.request;
    }

    test('answers are sent and read back by the agent', () async {
      final request = await asked();
      expect(request.questions, hasLength(4));
      expect(chatState().status.isInputNeeded, isTrue);
      client.dispatch(
        chat,
        ChatInputCompletedAction(
          requestId: request.id,
          response: ChatInputResponseKind.accept,
          answers: const {
            'name': ChatInputAnswered(
              state: 'submitted',
              value: ChatInputTextAnswerValue(value: 'v1'),
            ),
            'env': ChatInputAnswered(
              state: 'submitted',
              value: ChatInputSelectedAnswerValue(value: 'staging'),
            ),
            'notify': ChatInputAnswered(
              state: 'submitted',
              value: ChatInputBooleanAnswerValue(value: true),
            ),
            'replicas': ChatInputAnswered(
              state: 'submitted',
              value: ChatInputNumberAnswerValue(value: 3),
            ),
          },
        ).toJson(),
      );
      await turnDone();
      expect(
        replies(),
        contains('name=v1, env=staging, notify=yes, replicas=3'),
      );
      final part = parts().whereType<InputRequestResponsePart>().single;
      expect(part.response, ChatInputResponseKind.accept);
    });

    test('declining tells the agent to stop', () async {
      final request = await asked();
      client.dispatch(
        chat,
        ChatInputCompletedAction(
          requestId: request.id,
          response: ChatInputResponseKind.decline,
        ).toJson(),
      );
      await turnDone();
      expect(replies(), contains('You declined'));
    });
  });

  test('an input request in another chat arrives through the session and '
      'is answered without subscribing to that chat', () async {
    await send('side');
    await until((_) => sessionState().inputNeeded != null);
    final entry = sessionState().inputNeeded!.single as SessionChatInputRequest;
    expect(entry.chat, isNot(chat));
    expect(sessionState().chats, hasLength(2));
    expect(client.state.chatChannels.containsKey(entry.chat), isFalse);
    client.dispatch(
      entry.chat,
      ChatInputCompletedAction(
        requestId: entry.request.id,
        response: ChatInputResponseKind.accept,
        answers: const {
          'merge': ChatInputAnswered(
            state: 'submitted',
            value: ChatInputBooleanAnswerValue(value: true),
          ),
        },
      ).toJson(),
    );
    await turnDone();
    expect(sessionState().inputNeeded, isNull);
    expect(replies(), contains('merge=yes'));
    expect(host.chat(entry.chat)!.turns.single.state, TurnState.complete);
  });

  test('a rejected answer to another chat leaves the request open', () async {
    host.rejectTypes.add('chat/inputCompleted');
    await send('side');
    await until((_) => sessionState().inputNeeded != null);
    final entry = sessionState().inputNeeded!.single as SessionChatInputRequest;
    final failure = client.failures.first;
    final seq = client.dispatch(
      entry.chat,
      ChatInputCompletedAction(
        requestId: entry.request.id,
        response: ChatInputResponseKind.decline,
      ).toJson(),
    );
    final undone = await failure.timeout(_timeout);
    expect(undone.kind, ActionFailureKind.rejected);
    expect((undone.channel, undone.clientSeq), (entry.chat, seq));
    expect(sessionState().inputNeeded, hasLength(1));
    host.rejectTypes.clear();
    client.dispatch(
      entry.chat,
      ChatInputCompletedAction(
        requestId: entry.request.id,
        response: ChatInputResponseKind.decline,
      ).toJson(),
    );
    await turnDone();
    expect(sessionState().inputNeeded, isNull);
  });

  group('client tool execution', () {
    test('another client runs the tool; the session is not waiting for '
        'input', () async {
      await send('client');
      await until((_) => sessionState().inputNeeded != null);
      final entry =
          sessionState().inputNeeded!.single
              as SessionToolClientExecutionRequest;
      expect(entry.clientId, otherClientId);
      expect(entry.toolCall.toolName, 'open_browser');
      expect(
        client.state.sessions[seededSession]!.status.isInputNeeded,
        isFalse,
      );
      await turnDone();
      expect(sessionState().inputNeeded, isNull);
      expect(replies(), contains('$otherClientId opened the preview.'));
    });

    test('a tool delegated to this client waits for its result', () async {
      await send('delegate');
      await until((_) => sessionState().inputNeeded != null);
      final entry =
          sessionState().inputNeeded!.single
              as SessionToolClientExecutionRequest;
      expect(entry.clientId, client.clientId);
      client.dispatch(
        entry.chat,
        ChatToolCallCompleteAction(
          turnId: entry.turnId,
          toolCallId: entry.toolCall.toolCallId,
          result: const ToolCallResult(
            success: false,
            pastTenseMessage: PlainString('Not run'),
            error: ToolCallError(message: 'no tools here'),
          ),
        ).toJson(),
      );
      await turnDone();
      expect(sessionState().inputNeeded, isNull);
      expect(replies(), contains('could not open the preview: no tools here'));
    });
  });

  group('MCP sign-in (AHP-062)', () {
    Future<ToolCallAuthRequiredState> waiting() async {
      await send('auth');
      await until(
        (_) => parts().whereType<ToolCallResponsePart>().any(
          (p) => p.toolCall is ToolCallAuthRequiredState,
        ),
      );
      return toolCall() as ToolCallAuthRequiredState;
    }

    test('a pushed token resumes the tool call', () async {
      final call = await waiting();
      expect(call.auth.resource.resource, 'https://mcp.example.com');
      expect(chatState().status.isInputNeeded, isTrue);
      await until((_) => sessionState().inputNeeded != null);
      expect(
        sessionState().inputNeeded!.single,
        isA<SessionToolAuthenticationRequest>(),
      );
      await client.authenticate(
        resource: call.auth.resource.resource,
        token: 'mcp-token',
      );
      await turnDone();
      expect((toolCall() as ToolCallCompletedState).success, isTrue);
      expect(replies(), contains('Signed in'));
      expect(host.received.last.action, containsPair('token', 'mcp-token'));
    });

    test('cancelling completes the call as failed', () async {
      final call = await waiting();
      client.dispatch(
        chat,
        ChatToolCallCompleteAction(
          turnId: chatState().activeTurn!.id,
          toolCallId: call.toolCallId,
          result: const ToolCallResult(
            success: false,
            pastTenseMessage: PlainString('Sign-in cancelled'),
          ),
        ).toJson(),
      );
      await turnDone();
      expect((toolCall() as ToolCallCompletedState).success, isFalse);
      expect(replies(), contains('cancelled'));
    });
  });

  test('background work outlives the turn, then goes away', () async {
    await send('background');
    await turnDone();
    expect(chatState().backgroundWork!.single, isA<BackgroundShellWork>());
    await until((_) => chatState().backgroundWork?.isEmpty ?? true);
  });

  test('an edit updates the session change counts', () async {
    await send('edit');
    await turnDone();
    await until((s) => s.sessions[seededSession]!.changes != null);
    expect(client.state.sessions[seededSession]!.changes!.additions, 3);
  });

  test('queued messages start the next turn', () async {
    await send('tool');
    await until((_) => sessionState().inputNeeded != null);
    client.dispatch(
      chat,
      ChatPendingMessageSetAction(
        kind: PendingMessageKind.queued,
        id: 'q1',
        message: userMessage('hello again'),
      ).toJson(),
    );
    client.dispatch(
      chat,
      ChatToolCallApprovedAction(
        turnId: chatState().activeTurn!.id,
        toolCallId: toolCall().toolCallId,
        confirmed: ToolCallConfirmationReason.userAction,
      ).toJson(),
    );
    await until(
      (_) => chatState().turns.length == 2 && chatState().activeTurn == null,
    );
    expect(chatState().queuedMessages, isNull);
    expect(replies(), contains('hello again'));
  });

  test('truncating restarts from an edited message (AV-088)', () async {
    await send('tool');
    await until((_) => sessionState().inputNeeded != null);
    // Editing the running message: drop it, then send the edit.
    client.dispatch(chat, const ChatTruncatedAction().toJson());
    await send('hello');
    await until(
      (_) => chatState().turns.length == 1 && chatState().activeTurn == null,
    );
    expect(chatState().turns.single.message.text, 'hello');
    expect(replies(), contains('You said: hello'));
    expect(sessionState().inputNeeded, isNull);

    // Editing the latest finished message keeps the turns before it.
    await send('second');
    await until((_) => chatState().turns.length == 2);
    await turnDone();
    client.dispatch(
      chat,
      ChatTruncatedAction(turnId: chatState().turns.first.id).toJson(),
    );
    await send('second, edited');
    await until(
      (_) =>
          chatState().activeTurn == null &&
          chatState().turns.last.message.text == 'second, edited',
    );
    expect(
      [for (final t in chatState().turns) t.message.text],
      ['hello', 'second, edited'],
    );
  });

  test('truncating to an unknown turn is rejected', () async {
    final failures = client.failures.first;
    client.dispatch(chat, const ChatTruncatedAction(turnId: 'nope').toJson());
    final failure = await failures.timeout(_timeout);
    expect(failure.kind, ActionFailureKind.rejected);
  });

  test('a rename updates the session and the catalogue (AV-073)', () async {
    client.dispatch(
      seededSession,
      const SessionTitleChangedAction(title: 'Renamed').toJson(),
    );
    // Write-ahead: the session channel shows it before the echo.
    expect(sessionState().title, 'Renamed');
    await until((s) => s.sessions[seededSession]!.title == 'Renamed');
    expect(client.state.sessionChannels[seededSession]!.pending, isEmpty);
  });

  test('a refused rename is rolled back', () async {
    host.rejectTypes.add('session/titleChanged');
    final original = sessionState().title;
    final failures = client.failures.first;
    client.dispatch(
      seededSession,
      const SessionTitleChangedAction(title: 'Refused').toJson(),
    );
    expect(sessionState().title, 'Refused');
    final failure = await failures.timeout(_timeout);
    expect(failure.kind, ActionFailureKind.rejected);
    expect(sessionState().title, original);
    expect(client.state.sessions[seededSession]!.title, original);
  });

  test('unknown client actions are rejected', () async {
    final failures = client.failures.first;
    client.dispatch(seededSession, {
      'type': 'session/serverToolsChanged',
      'tools': <Object?>[],
    });
    final failure = await failures.timeout(_timeout);
    expect(failure.kind, ActionFailureKind.rejected);
  });

  test('a shell call streams its output through a terminal channel', () async {
    await send('shell');
    await until(
      (_) => parts().whereType<ToolCallResponsePart>().any(
        (p) => (p.toolCall.content ?? const []).any(
          (c) => c is ToolResultTerminalContent,
        ),
      ),
    );
    final terminal = toolCall().content!
        .whereType<ToolResultTerminalContent>()
        .single;
    await client.subscribe(terminal.resource, kind: ChannelKind.terminal);
    await turnDone();
    await until(
      (s) =>
          s.terminalChannels[terminal.resource]?.state.lifecycle
              is TerminalExitedLifecycleState,
    );
    final state = client.state.terminalChannels[terminal.resource]!.state;
    expect(terminalTranscript(state), contains('All tests passed!'));
    expect((state.content.single as TerminalCommandPart).exitCode, 0);
    final result = toolCall().content!
        .whereType<ToolResultTerminalContent>()
        .single
        .result!;
    expect(result.preview, contains('All tests passed!'));
    expect(replies(), contains('All 3 tests passed.'));
  });

  test('a background shell has a terminal', () async {
    await send('background');
    await turnDone();
    final work = chatState().backgroundWork!.single as BackgroundShellWork;
    await client.subscribe(work.terminal!, kind: ChannelKind.terminal);
    await until(
      (s) =>
          terminalTranscript(s.terminalChannels[work.terminal!]!.state)
              .contains('Run 1'),
    );
  });

  test('an edit carries a diff and fills the changesets', () async {
    await send('edit');
    await turnDone();
    final edit = toolCall().content!
        .whereType<ToolResultFileEditContent>()
        .single;
    expect(edit.diff, const FileEditDiffStats(added: 3, removed: 1));
    final before = await client.readResource(edit.before!.content.uri);
    final after = await client.readResource(edit.after!.content.uri);
    expect(before.data, readmeBefore);
    expect(after.data, readmeAfter);

    final changesets = sessionState().changesets!;
    final sessionUri = expandChangesetUri(changesets.first)!;
    final turnUri = expandChangesetUri(
      changesets.last,
      turnId: chatState().turns.last.id,
    )!;
    await client.subscribe(sessionUri, kind: ChannelKind.changeset);
    await client.subscribe(turnUri, kind: ChannelKind.changeset);
    ChangesetState changeset(String uri) =>
        client.state.changesetChannels[uri]!.state;
    expect(changeset(sessionUri).files.single.id, endsWith('README.md'));
    expect(changeset(turnUri).files, hasLength(1));

    // Review is written ahead and echoed.
    final file = changeset(sessionUri).files.single.id;
    client.dispatch(
      sessionUri,
      ChangesetFilesReviewChangedAction(files: [file], reviewed: true).toJson(),
    );
    expect(changeset(sessionUri).files.single.reviewed, isTrue);
    await until((s) => s.changesetChannels[sessionUri]!.pending.isEmpty);
    expect(host.changeset(sessionUri)!.files.single.reviewed, isTrue);

    // Operations: revert one file, then commit (nothing left).
    final reverted = await client.invokeChangesetOperation(
      turnUri,
      'revert',
      target: ChangesetOperationTargetResource(resource: file),
    );
    expect(reverted.message?.text, 'Reverted README.md.');
    await until((s) => s.changesetChannels[turnUri]!.state.files.isEmpty);
    final committed = await client.invokeChangesetOperation(
      sessionUri,
      'commit',
    );
    expect(committed.message?.text, 'Committed 1 file.');
    await until((s) => s.changesetChannels[sessionUri]!.state.files.isEmpty);
    expect(
      changeset(sessionUri).operations!.first.status,
      ChangesetOperationStatus.idle,
    );
  });

  test(
    'a subagent runs in a read-only chat linked from its tool call',
    () async {
      await send('subagent');
      await turnDone();
      final link = toolCall().content!
          .whereType<ToolResultSubagentContent>()
          .single;
      final summary = sessionState().chats.singleWhere(
        (c) => c.resource == link.resource,
      );
      expect(summary.interactivity, ChatInteractivity.readOnly);
      expect(summary.origin, isA<ChatOriginTool>());
      await client.subscribe(link.resource, kind: ChannelKind.chat);
      final worker = chatState(link.resource);
      expect(
        (worker.turns.single.responseParts.single as MarkdownResponsePart)
            .content,
        contains('3 modules'),
      );
      expect(chatState().backgroundWork, isEmpty);
      expect(replies(), contains('The explorer found 3 modules.'));
    },
  );

  test('movable chats are reordered with moveChat', () async {
    await send('subagent');
    await turnDone();
    final worker = sessionState().chats.last.resource;
    expect(sessionState().chats.first.resource, chat);
    final result = await client.moveChat(
      worker,
      const ChatMoveToSessionDestination(session: seededSession),
    );
    expect(result.session, seededSession);
    await until((_) => sessionState().chats.first.resource == worker);
    await expectLater(
      client.moveChat(
        chat,
        ChatMoveToSessionDestination(session: seededSession, after: worker),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('a canvas is referenced from the chat and subscribable', () async {
    await send('canvas');
    await turnDone();
    final canvas = chatState().canvases!.single.resource;
    await client.subscribe(canvas, kind: ChannelKind.canvas);
    final state = client.state.canvasChannels[canvas]!.state;
    expect(state.title, 'App preview');
    expect(state.url, 'http://127.0.0.1:8080/');
  });

  test('read calls, code replies and working directories', () async {
    await send('read code cd');
    await turnDone();
    final calls = parts().whereType<ToolCallResponsePart>();
    expect(calls.map((c) => c.toolCall.toolName), ['read', 'read', 'read']);
    expect(replies(), contains('```dart'));
    expect(sessionState().workingDirectories, hasLength(2));
    expect(chatState().workingDirectories, hasLength(1));
  });

  test(
    'queued messages can be edited and reordered during a slow turn',
    () async {
      await send('slow');
      await until(
        (_) =>
            chatState().activeTurn?.responseParts
                .whereType<MarkdownResponsePart>()
                .any((p) => p.content.contains('slowly')) ??
            false,
      );
      for (final (id, text) in [('q1', 'first'), ('q2', 'second')]) {
        client.dispatch(
          chat,
          ChatPendingMessageSetAction(
            kind: PendingMessageKind.queued,
            id: id,
            message: userMessage(text),
          ).toJson(),
        );
      }
      client.dispatch(
        chat,
        ChatPendingMessageSetAction(
          kind: PendingMessageKind.queued,
          id: 'q1',
          message: userMessage('first, edited'),
        ).toJson(),
      );
      client.dispatch(
        chat,
        const ChatQueuedMessagesReorderedAction(order: ['q2', 'q1']).toJson(),
      );
      await until((s) => s.chatChannels[chat]!.pending.isEmpty);
      expect(
        [for (final m in host.chat(chat)!.queuedMessages!) m.message.text],
        ['second', 'first, edited'],
      );
    },
  );

  test('a windowed chat pages in older turns (AHP-029)', () async {
    final long = (await client.openSession(longSession))!;
    expect(chatState(long).turns, hasLength(turnWindow));
    expect(chatState(long).turnsNextCursor, isNotNull);
    expect(
      chatState(long).turns.first.id,
      'long-${longTurnCount - turnWindow + 1}',
    );
    expect(await client.loadOlderTurns(long), isTrue);
    expect(chatState(long).turns, hasLength(turnWindow * 2));
    expect(await client.loadOlderTurns(long), isTrue);
    expect(chatState(long).turns, hasLength(longTurnCount));
    expect(chatState(long).turns.first.id, 'long-1');
    expect(chatState(long).turnsNextCursor, isNull);
    expect(await client.loadOlderTurns(long), isFalse);
  });

  test(
    'todo: TodoWrite calls carry the whole list each time (AV-070)',
    () async {
      await send('todo');
      await turnDone();
      final calls = [
        for (final p in parts())
          if (p case ToolCallResponsePart(:final toolCall)) toolCall,
      ];
      expect(calls, hasLength(3));
      expect(calls.map((c) => c.toolName).toSet(), {'TodoWrite'});
      final last = (calls.last.toolInput! as InlineToolInput).value;
      expect(last, contains('"status":"completed"'));
      expect(last, isNot(contains('in_progress')));
      expect(replies(), contains('All 3 steps are done.'));
    },
  );

  test(
    'plan: a plan review takes a choice and free-form feedback (AV-046)',
    () async {
      await send('plan');
      await until(
        (_) =>
            chatState().activeTurn?.responseParts.any(
              (p) => p is InputRequestResponsePart,
            ) ??
            false,
      );
      expect(replies(), contains('## Plan'));
      final request = parts()
          .whereType<InputRequestResponsePart>()
          .single
          .request;
      final question =
          request.questions!.single as ChatInputSingleSelectQuestion;
      expect(question.allowFreeformInput, isTrue);
      expect(question.options.first.description, isNotNull);
      client.dispatch(
        chat,
        ChatInputCompletedAction(
          requestId: request.id,
          response: ChatInputResponseKind.accept,
          answers: {
            'plan': const ChatInputAnswered(
              state: 'submitted',
              value: ChatInputSelectedAnswerValue(
                value: 'interactive',
                freeformValues: ['skip the docs'],
              ),
            ),
          },
        ).toJson(),
      );
      await turnDone();
      expect(replies(), contains('plan=interactive + skip the docs'));
    },
  );

  test('pr: the pull request is published in _meta (AV-105)', () async {
    await send('open a pr');
    await turnDone();
    await until(
      (s) =>
          s.sessions[seededSession]!.meta?['copilot.githubReferences'] != null,
    );
    final references =
        sessionState().meta!['copilot.githubReferences']! as List<Object?>;
    expect((references.single! as Map)['url'], fakePullRequestUrl);
    expect(
      (client.state.sessions[seededSession]!.meta!['git']!
          as Map)['githubRepo'],
      fakeGitHubRepo,
    );
  });

  test('scenariosFor picks flows by keyword', () {
    expect(scenariosFor('Please ASK, then use the tool.'), [
      Scenario.tool,
      Scenario.ask,
    ]);
    expect(scenariosFor('toolbox'), isEmpty);
  });

  group('starting sessions', () {
    test('lists folders on the host (resourceList)', () async {
      final entries = await client.listDirectory('file:///workspace');
      expect(
        [for (final e in entries) '${e.type.wireValue}:${e.name}'],
        ['directory:packages', 'file:README.md'],
      );
      await expectLater(
        client.listDirectory('file:///nowhere'),
        throwsA(isA<RpcException>()),
      );
    });

    test('completes the session\'s skills and prompts after /', () async {
      expect(client.state.completionTriggerCharacters, ['/']);
      final items = await client.completions(
        chat: chat,
        text: 'please /re',
        offset: 10,
      );
      expect([for (final i in items) i.insertText], ['/review ']);
      expect((items.single.rangeStart, items.single.rangeEnd), (7, 10));
      expect(
        items.single.attachment.meta?['description'],
        'Review the changes on this branch',
      );
      final all = await client.completions(chat: chat, text: '/', offset: 1);
      expect(
        [for (final i in all) i.attachment.label],
        ['/review', '/explain'],
      );
      expect(
        await client.completions(chat: chat, text: 'src/re', offset: 6),
        isEmpty,
      );
      expect(slashCommands(sessionState().customizations).map((c) => c.name), [
        'review',
        'explain',
      ]);
    });

    test('a host without completions answers method not found', () async {
      final bare = FakeAhpHost(completionTriggers: const []);
      addTearDown(bare.close);
      final other = AhpClient(
        uri: await bare.start(),
        pingInterval: Duration.zero,
      );
      addTearDown(other.close);
      await other.connect();
      expect(other.state.completionTriggerCharacters, isEmpty);
      final otherChat = (await other.openSession(seededSession))!;
      await expectLater(
        other.completions(chat: otherChat, text: '/', offset: 1),
        throwsA(predicate(isMethodNotFound)),
      );
    });

    test('resolves session settings and completes branches', () async {
      final inRepo = await client.resolveSessionConfig(
        provider: fakeProvider,
        workingDirectory: 'file:///workspace',
        config: {'mode': 'plan'},
      );
      expect(inRepo.schema.properties.keys, ['mode', 'branch']);
      expect(inRepo.values, {'mode': 'plan', 'branch': 'main'});
      expect(inRepo.schema.properties['mode']!.sessionMutable, isTrue);
      final outside = await client.resolveSessionConfig(
        provider: fakeProvider,
        workingDirectory: 'file:///srv/scratch',
      );
      expect(outside.schema.properties.keys, ['mode']);
      final branches = await client.sessionConfigCompletions(
        property: 'branch',
        query: 'fix',
      );
      expect([for (final b in branches) b.value], ['fix/crash']);
    });

    test('creates a session with settings, a model and its options', () async {
      final session = await client.createSession(
        provider: fakeProvider,
        workingDirectories: ['file:///workspace/packages/api'],
        config: {'mode': 'plan', 'branch': 'feature/login'},
      );
      final summary = client.state.sessions[session]!;
      expect(summary.project?.displayName, 'workspace');
      expect((summary.meta?['git'] as Map?)?['branchName'], 'feature/login');
      final newChat = (await client.openSession(session))!;
      client.dispatch(
        newChat,
        ChatTurnStartedAction(
          turnId: 'turn-settings',
          startedAt: DateTime.now().toUtc().toIso8601String(),
          message: userMessage(
            'settings',
            model: const ModelSelection(
              id: scriptedModel,
              config: {'thinkingLevel': 'high'},
            ),
          ),
        ).toJson(),
      );
      await until((s) => s.chatChannels[newChat]!.state.turns.isNotEmpty);
      final reply = client
          .state
          .chatChannels[newChat]!
          .state
          .turns
          .last
          .responseParts
          .whereType<MarkdownResponsePart>()
          .single
          .content;
      expect(reply, contains('Model: scripted'));
      expect(reply, contains('thinkingLevel: high'));
      expect(reply, contains('mode: plan'));
      expect(reply, contains('branch: feature/login'));

      // The mode may change mid-session; the branch may not.
      client.dispatch(
        session,
        const SessionConfigChangedAction(config: {'mode': 'autopilot'})
            .toJson(),
      );
      client.dispatch(
        session,
        const SessionConfigChangedAction(config: {'branch': 'main'}).toJson(),
      );
      await until((s) => s.sessionChannels[session]!.pending.isEmpty);
      expect(client.state.sessionChannels[session]!.state.config!.values, {
        'mode': 'autopilot',
        'branch': 'feature/login',
      });
      expect(host.rejected.single.action['config'], {'branch': 'main'});
    });

    test('a session that fails to start throws at once', () async {
      final started = DateTime.now();
      await expectLater(
        client.createSession(
          provider: fakeProvider,
          workingDirectories: ['file:///missing'],
        ),
        throwsA(
          isA<SessionCreationFailedError>().having(
            (e) => e.error?.message,
            'message',
            'No such folder: /missing',
          ),
        ),
      );
      expect(DateTime.now().difference(started), lessThan(_timeout));
      expect(client.state.sessions.keys, isNot(contains(endsWith('missing'))));
    });
  });
}
