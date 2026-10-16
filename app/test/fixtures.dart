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
        ResponsePart.reasoning(id: 'r', content: 'I should run ls.'),
        ResponsePart.toolCall(
          toolCall: ToolCall(
            toolCallId: 'ls',
            toolName: 'bash',
            displayName: 'Bash',
            status: ToolCallStatus.completed,
            invocationMessage: 'Running `ls`',
            pastTenseMessage: 'Ran `ls`',
            toolInput: '{"command":"ls"}',
            success: true,
            content: [
              {'type': 'text', 'text': 'a.txt\n'},
            ],
          ),
        ),
        ResponsePart.markdown(id: 'm', content: 'There is **one** file.'),
      ],
    ),
  ],
  activeTurn: active
      ? ActiveTurn(
          id: 'turn-2',
          startedAt: '2026-10-01T00:00:00Z',
          message: userMessage('Delete it'),
          responseParts: const [
            ResponsePart.toolCall(
              toolCall: ToolCall(
                toolCallId: 'rm',
                toolName: 'bash',
                displayName: 'Bash',
                status: ToolCallStatus.pendingConfirmation,
                invocationMessage: 'Run `rm a.txt`',
                toolInput: '{"command":"rm a.txt"}',
              ),
            ),
            ResponsePart.inputRequest(
              request: ChatInputRequest(
                id: 'req',
                message: 'Which branch?',
                questions: [
                  ChatInputQuestion(
                    id: 'branch',
                    kind: 'text',
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
