import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

/// Asks for reduced motion for the rest of the test, so the working
/// indicator is static and `pumpAndSettle` returns while a chat works.
void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The composer's text field (the follow-up box, or a new-session
/// draft's prompt).
Finder get composerField => find.descendant(
  of: find.byType(FollowUpInput),
  matching: find.byType(TextField),
);

/// Opens the session header's "…" menu, then its "Details" popover
/// (AV-094).
Future<void> openSessionDetails(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Session actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Details…'));
  await tester.pumpAndSettle();
}

/// Picks [label] (a filter or a sort) in the sidebar header's filter
/// menu.
Future<void> pickFilter(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Filter and sort'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Shows the sidebar's search field with the header's search icon.
Future<void> openSearch(WidgetTester tester) async {
  // The title bar has a search button too on medium and wide layouts.
  await tester.tap(find.byTooltip(RegExp('^Search sessions')).last);
  await tester.pumpAndSettle();
}

/// Builds a [SessionSummary] for tests.
SessionSummary session(
  String id, {
  String? directory,
  String? project,
  String modifiedAt = '2026-10-01T00:00:00Z',
  int status = 33,
  String? title,
}) => SessionSummary(
  resource: 'pi:/$id',
  provider: 'pi',
  title: title ?? 'session $id',
  status: SessionStatus(status),
  createdAt: '2026-10-01T00:00:00Z',
  modifiedAt: modifiedAt,
  workingDirectories: directory == null ? null : [directory],
  project: project == null
      ? null
      : ProjectInfo(uri: project, displayName: project),
);

/// A chat with one finished turn (reasoning, a completed `bash` call and a
/// markdown reply) and an active turn with a tool call waiting for approval
/// and an open input request.
ChatState chatFixture({bool active = true}) => ChatState(
  resource: 'ahp-chat:/1',
  title: 'Fix login',
  status: SessionStatus(active ? 24 : 33),
  modifiedAt: '2026-10-01T00:00:00Z',
  turns: [
    Turn(
      id: 'turn-1',
      message: userMessage('List the files'),
      state: TurnState.complete,
      duration: 1500,
      usage: const UsageInfo(inputTokens: 1200, outputTokens: 30, model: 'm1'),
      responseParts: const [
        ReasoningResponsePart(id: 'r', content: 'I should run ls.'),
        ToolCallResponsePart(
          toolCall: ToolCallCompletedState(
            toolCallId: 'ls',
            toolName: 'bash',
            displayName: 'Bash',
            invocationMessage: PlainString('Running `ls`'),
            pastTenseMessage: PlainString('Ran `ls`'),
            toolInput: InlineToolInput('{"command":"ls"}'),
            confirmed: ToolCallConfirmationReason.notNeeded,
            success: true,
            content: [ToolResultTextContent(text: 'a.txt\n')],
          ),
        ),
        MarkdownResponsePart(id: 'm', content: 'There is **one** file.'),
      ],
    ),
  ],
  activeTurn: active
      ? ActiveTurn(
          id: 'turn-2',
          startedAt: '2026-10-01T00:00:00Z',
          message: userMessage('Delete it'),
          responseParts: const [
            ToolCallResponsePart(
              toolCall: ToolCallPendingConfirmationState(
                toolCallId: 'rm',
                toolName: 'bash',
                displayName: 'Bash',
                invocationMessage: PlainString('Run `rm a.txt`'),
                toolInput: InlineToolInput('{"command":"rm a.txt"}'),
              ),
            ),
            InputRequestResponsePart(
              request: ChatInputRequest(
                id: 'req',
                message: 'Which branch?',
                questions: [
                  ChatInputTextQuestion(
                    id: 'branch',
                    message: 'Branch name',
                    required: true,
                  ),
                ],
              ),
            ),
          ],
        )
      : null,
);

/// The session channel of `pi:/1`: a second chat ("Reviewer") with an
/// open input request, and a confirmation the open chat already shows.
SessionState sessionWithRequests() => SessionState(
  provider: 'pi',
  title: 'Fix login',
  status: SessionStatus.inputNeeded,
  lifecycle: SessionLifecycle.ready,
  activeClients: const [],
  defaultChat: 'ahp-chat:/1',
  chats: const [
    ChatSummary(
      resource: 'ahp-chat:/1',
      title: 'Fix login',
      status: SessionStatus.inputNeeded,
      modifiedAt: '2026-10-01T00:00:00Z',
    ),
    ChatSummary(
      resource: 'ahp-chat:/side',
      title: 'Reviewer',
      status: SessionStatus.inputNeeded,
      modifiedAt: '2026-10-01T00:00:00Z',
    ),
  ],
  inputNeeded: const [
    SessionToolConfirmationRequest(
      id: 'confirm-rm',
      chat: 'ahp-chat:/1',
      turnId: 'turn-2',
      toolCall: ToolCallPendingConfirmationState(
        toolCallId: 'rm',
        toolName: 'bash',
        displayName: 'Bash',
        invocationMessage: PlainString('Run `rm a.txt`'),
      ),
    ),
    SessionChatInputRequest(
      id: 'side',
      chat: 'ahp-chat:/side',
      request: ChatInputRequest(
        id: 'side-req',
        message: 'Merge the branch?',
        questions: [
          ChatInputBooleanQuestion(
            id: 'merge',
            message: 'Merge',
            defaultValue: true,
          ),
        ],
      ),
    ),
  ],
);

/// A chat whose active turn waits for MCP sign-in, with a background
/// shell.
ChatState authChatFixture() => chatFixture().copyWith(
  backgroundWork: const [
    BackgroundShellWork(
      id: 'w',
      label: 'npm test',
      startedAt: '2026-10-01T00:00:00Z',
      command: 'npm test',
    ),
  ],
  activeTurn: ActiveTurn(
    id: 'turn-2',
    startedAt: '2026-10-01T00:00:00Z',
    message: userMessage('Search the docs'),
    responseParts: const [
      ToolCallResponsePart(
        toolCall: ToolCallAuthRequiredState(
          toolCallId: 'search',
          toolName: 'search_docs',
          displayName: 'Search docs',
          contributor: ToolCallMcpContributor(customizationId: 'docs'),
          invocationMessage: PlainString('Search Example Docs'),
          confirmed: ToolCallConfirmationReason.notNeeded,
          auth: McpAuthRequirement(
            reason: McpAuthRequiredReason.required,
            resource: ProtectedResourceMetadata(
              resource: 'https://mcp.example.com',
              resourceName: 'Example Docs',
            ),
          ),
        ),
      ),
    ],
  ),
);

/// A running `open_browser` call delegated to [clientId], as a
/// `toolClientExecution` entry with id [id].
SessionToolClientExecutionRequest clientExecution(String id, String clientId) =>
    SessionToolClientExecutionRequest(
      id: id,
      chat: 'ahp-chat:/1',
      turnId: 'turn-2',
      clientId: clientId,
      toolCall: ToolCallRunningState(
        toolCallId: 'call-$id',
        toolName: 'open_browser',
        displayName: 'Open browser',
        contributor: ToolCallClientContributor(clientId: clientId),
        invocationMessage: const PlainString('Open the preview'),
        confirmed: ToolCallConfirmationReason.notNeeded,
      ),
    );

/// [sessionWithRequests] plus client tool executions for [clientIds].
SessionState sessionWithExecutions(List<String> clientIds) {
  final session = sessionWithRequests();
  return session.copyWith(
    inputNeeded: [
      ...?session.inputNeeded,
      for (final (i, id) in clientIds.indexed) clientExecution('exec-$i', id),
    ],
  );
}
