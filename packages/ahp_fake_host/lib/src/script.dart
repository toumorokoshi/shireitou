/// Pure pieces of the fake host's script: which flows a message asks for,
/// and the states, requests and replies each flow uses.
library;

import 'package:ahp_client/ahp_client.dart';

/// A scripted flow, chosen by a keyword in the user's message.
enum Scenario {
  /// A `bash` tool call that waits for approval (AV-083).
  tool('tool'),

  /// An elicitation with text, select, boolean and integer questions
  /// (AV-084).
  ask('ask'),

  /// An input request in a second chat, so it only reaches the client
  /// through the session's `inputNeeded` list.
  side('side'),

  /// An MCP tool call that pauses for sign-in (AHP-062).
  auth('auth'),

  /// A background shell that outlives the turn.
  background('background'),

  /// A file edit that changes the session's change counts.
  edit('edit');

  const Scenario(this.keyword);

  /// The word in a message that runs this flow.
  final String keyword;
}

/// The flows [text] asks for, in [Scenario] order.
List<Scenario> scenariosFor(String text) {
  final words = RegExp(r'[a-z]+').allMatches(text.toLowerCase()).map((m) {
    return m.group(0)!;
  }).toSet();
  return [
    for (final s in Scenario.values)
      if (words.contains(s.keyword)) s,
  ];
}

/// The reply to a message that names no flow.
String echoReply(String text) =>
    'You said: $text\n\nSay ${[for (final s in Scenario.values) '"${s.keyword}"'].join(', ')} '
    'to try a scripted flow.';

/// The `bash` call the `tool` flow asks to run.
ChatToolCallReadyAction toolReady(String turnId, String toolCallId) =>
    ChatToolCallReadyAction(
      turnId: turnId,
      toolCallId: toolCallId,
      invocationMessage: const PlainString('Run `ls -la`'),
      toolInput: const InlineToolInput('{"command":"ls -la"}'),
      confirmationTitle: const PlainString('Allow Bash to run `ls -la`?'),
    );

/// The result of the approved `bash` call.
ToolCallResult toolResult() => const ToolCallResult(
  success: true,
  pastTenseMessage: PlainString('Ran `ls -la`'),
  content: [ToolResultTextContent(text: 'README.md\nlib\ntest')],
);

/// The elicitation of the `ask` flow, with ID [id].
ChatInputRequest deploymentRequest(String id) => ChatInputRequest(
  id: id,
  message: 'Where should I deploy?',
  questions: const [
    ChatInputTextQuestion(
      id: 'name',
      title: 'Release name',
      message: 'A name for this release',
      required: true,
    ),
    ChatInputSingleSelectQuestion(
      id: 'env',
      title: 'Environment',
      message: 'Target environment',
      required: true,
      options: [
        ChatInputOption(id: 'staging', label: 'Staging'),
        ChatInputOption(id: 'prod', label: 'Production'),
      ],
    ),
    ChatInputBooleanQuestion(
      id: 'notify',
      title: 'Notify the team',
      message: 'Post in the team channel',
      defaultValue: false,
    ),
    ChatInputNumberQuestion(
      id: 'replicas',
      title: 'Replicas',
      message: 'How many replicas',
      kind: 'integer',
      defaultValue: 2,
    ),
  ],
);

/// The question the `side` flow asks in its second chat, with ID [id].
ChatInputRequest sideRequest(String id) => ChatInputRequest(
  id: id,
  message: 'The reviewer chat needs a decision',
  questions: const [
    ChatInputBooleanQuestion(
      id: 'merge',
      title: 'Merge the branch',
      message: 'Merge once checks pass',
      defaultValue: true,
    ),
  ],
);

/// A readable value of [answer].
String describeAnswer(ChatInputAnswer answer) => switch (answer) {
  ChatInputAnswered(:final value) => switch (value) {
    ChatInputTextAnswerValue(:final value) => value,
    ChatInputNumberAnswerValue(:final value) => '$value',
    ChatInputBooleanAnswerValue(:final value) => value ? 'yes' : 'no',
    ChatInputSelectedAnswerValue(:final value) => value,
    ChatInputSelectedManyAnswerValue(:final value) => value.join('+'),
    ChatInputAnswerValueUnknown() => '?',
  },
  ChatInputSkipped() => 'skipped',
  ChatInputAnswerUnknown() => '?',
};

/// The reply after an input request was answered with [action].
String answerReply(ChatInputCompletedAction action) {
  if (action.response != ChatInputResponseKind.accept) {
    return 'You declined, so I stopped.';
  }
  final answers = action.answers ?? const <String, ChatInputAnswer>{};
  final described = [
    for (final MapEntry(:key, :value) in answers.entries)
      '$key=${describeAnswer(value)}',
  ];
  return 'Thanks. Answers: ${described.join(', ')}.';
}

/// The MCP sign-in the `auth` flow needs.
McpAuthRequirement docsAuth() => const McpAuthRequirement(
  reason: McpAuthRequiredReason.required,
  resource: ProtectedResourceMetadata(
    resource: 'https://mcp.example.com',
    resourceName: 'Example Docs',
  ),
  description: 'Sign in to Example Docs to search it.',
);

/// The MCP server customization behind the `auth` flow's tool.
const docsCustomizationId = 'docs-mcp';

/// The change counts the `edit` flow reports.
const editChanges = ChangesSummary(additions: 3, deletions: 1, files: 1);

/// The session status a catalogue entry shows: [chat]'s activity bits, or
/// `InputNeeded` while [inputNeeded] holds a user-blocking request, with
/// [session]'s read and archived flags.
SessionStatus summaryStatus(
  SessionStatus session,
  SessionStatus chat,
  List<SessionInputRequest> inputNeeded,
) {
  const activityMask = (1 << 5) - 1;
  final blocking = inputNeeded.any(
    (r) => r is! SessionToolClientExecutionRequest,
  );
  final activity = blocking
      ? SessionStatus.inputNeeded.bits
      : chat.bits & activityMask;
  return SessionStatus((session.bits & ~activityMask) | activity);
}
