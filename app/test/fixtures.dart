import 'package:ahp_client/ahp_client.dart';

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
