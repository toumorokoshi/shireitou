/// Drives [AhpClient] against the scripted fake host over a real
/// WebSocket: tool approvals (AV-083), input requests (AV-084),
/// session-level input requests, MCP sign-in (AHP-062) and background work.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
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

  test('unknown client actions are rejected', () async {
    final failures = client.failures.first;
    client.dispatch(seededSession, {
      'type': 'session/serverToolsChanged',
      'tools': <Object?>[],
    });
    final failure = await failures.timeout(_timeout);
    expect(failure.kind, ActionFailureKind.rejected);
  });

  test('scenariosFor picks flows by keyword', () {
    expect(scenariosFor('Please ASK, then use the tool.'), [
      Scenario.tool,
      Scenario.ask,
    ]);
    expect(scenariosFor('toolbox'), isEmpty);
  });
}
