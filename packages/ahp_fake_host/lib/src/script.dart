/// Pure pieces of the fake host's script: which flows a message asks for,
/// and the states, requests and replies each flow uses.
library;

import 'dart:convert';

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

  /// A file edit with an inline diff (`fileEdit` content) that adds the
  /// file to the session's changesets and change counts (AV-065, AV-100).
  edit('edit'),

  /// A shell tool call that streams its output through a terminal channel
  /// (AV-065, AHP-028).
  shell('shell'),

  /// Three consecutive `read` tool calls, which clients may group (AV-064).
  read('read'),

  /// A subagent: a tool call whose result links to a new, read-only worker
  /// chat that runs its own turn (AV-069).
  subagent('subagent'),

  /// A canvas reference on the chat (1.0.0 canvas channel).
  canvas('canvas'),

  /// A markdown reply with a fenced Dart code block (AV-061).
  code('code'),

  /// A reply streamed with `chat/delta` that keeps the turn running for
  /// `slowDuration`, so messages can be queued, edited and reordered
  /// (AV-081).
  slow('slow'),

  /// Adds a working directory to the session and the chat.
  cd('cd'),

  /// Replies with the message's model and options and the session's
  /// settings (AV-041).
  settings('settings'),

  /// A tool call executed by another client ([otherClientId]), listed as
  /// a `toolClientExecution` entry until that client completes it.
  client('client'),

  /// A tool call delegated to the client that sent the message; waits
  /// for its `chat/toolCallComplete`.
  delegate('delegate'),

  /// Three `TodoWrite` calls (Claude's todo tool) that create a todo list
  /// and work through it (AV-070).
  todo('todo'),

  /// A plan in markdown, then a plan review: a single-select question
  /// with described options and free-form feedback, as VS Code's agent
  /// host asks it (AV-046).
  plan('plan'),

  /// Opens a pull request for the session's branch and publishes it in
  /// the session's `_meta` (`copilot.githubReferences`, AV-105).
  pr('pr'),

  /// Expires this client's Example Docs token and sends `auth/required`
  /// (`expired`), then waits for a new token (AHP-061).
  expire('expire'),

  /// A tool call with host-provided confirmation options in two groups and
  /// a risk assessment that loads, then completes (AV-083).
  choose('choose'),

  /// A tool call whose input the user may edit before approving
  /// (`editable`, `editedToolInput`).
  command('command'),

  /// A tool call whose result waits for the user's confirmation
  /// (`requiresResultConfirmation`, `pending-result-confirmation`).
  result('result'),

  /// An input request that another client starts answering: the host
  /// relays its draft (`chat/inputAnswerChanged`) and reports the drafts
  /// this client synced.
  draft('draft');

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

/// The `clientId` of the other client the `client` flow delegates to.
const otherClientId = 'fake-ide';

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
    ChatInputSelectedAnswerValue(:final value, :final freeformValues) => [
      value,
      ...?freeformValues,
    ].join(' + '),
    ChatInputSelectedManyAnswerValue(:final value, :final freeformValues) => [
      ...value,
      ...?freeformValues,
    ].join('+'),
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

/// The protected resource of the `auth` flow's MCP server.
const docsResource = 'https://mcp.example.com';

/// The protected resource the secured agent ([securedProvider]) requires.
const agentResource = 'https://agent.example.com';

/// The agent that requires a token for [agentResource] before
/// `createSession` (otherwise `-32007 AuthRequired`).
const securedProvider = 'fake-secure';

/// A token the host accepts for any resource without OAuth, like a
/// personal access token pasted by hand.
const fakePersonalToken = 'mcp-token';

/// The scope the `auth` flow's challenge requires.
const docsScope = 'docs.search';

/// The RFC 9728 metadata of [docsResource], naming [issuer] as its
/// authorization server when the host runs one.
ProtectedResourceMetadata docsMetadata(Uri? issuer) =>
    ProtectedResourceMetadata(
      resource: docsResource,
      resourceName: 'Example Docs',
      authorizationServers: issuer == null ? null : ['$issuer'],
      scopesSupported: const ['docs.read', docsScope],
      resourceDocumentation: 'https://docs.example.com/tokens',
    );

/// The RFC 9728 metadata of [agentResource] (required, the default).
ProtectedResourceMetadata agentMetadata(Uri? issuer) =>
    ProtectedResourceMetadata(
      resource: agentResource,
      resourceName: 'Fake agent service',
      authorizationServers: issuer == null ? null : ['$issuer'],
      scopesSupported: const ['agent'],
      required: true,
    );

/// The MCP sign-in the `auth` flow needs.
McpAuthRequirement docsAuth([Uri? issuer]) => McpAuthRequirement(
  reason: McpAuthRequiredReason.required,
  resource: docsMetadata(issuer),
  requiredScopes: const [docsScope],
  description: 'Sign in to Example Docs to search it.',
);

/// The `rm` call of the `choose` flow, waiting with host-provided options
/// and [risk].
ChatToolCallReadyAction chooseReady(
  String turnId,
  String toolCallId,
  ToolCallRiskAssessment risk,
) => ChatToolCallReadyAction(
  turnId: turnId,
  toolCallId: toolCallId,
  invocationMessage: const PlainString('Run `rm -rf build`'),
  toolInput: const InlineToolInput('{"command":"rm -rf build"}'),
  confirmationTitle: const PlainString('Allow Bash to delete build/?'),
  riskAssessment: risk,
  options: confirmationOptions,
);

/// The options the `choose` flow offers: approvals, then denials.
const confirmationOptions = [
  ConfirmationOption(
    id: 'allow-once',
    label: 'Allow once',
    kind: ConfirmationOptionKind.approve,
    group: 1,
  ),
  ConfirmationOption(
    id: 'allow-session',
    label: 'Allow in this session',
    kind: ConfirmationOptionKind.approve,
    group: 1,
  ),
  ConfirmationOption(
    id: 'skip',
    label: 'Skip this step',
    kind: ConfirmationOptionKind.deny,
    group: 2,
  ),
  ConfirmationOption(
    id: 'never',
    label: 'Deny',
    kind: ConfirmationOptionKind.deny,
    group: 2,
  ),
];

/// The judge's verdict in the `choose` flow.
const chooseRisk = ToolCallRiskAssessmentCompleteState(
  kind: ToolCallRiskAssessmentKind.judge,
  safety: 0.35,
  reason: PlainString('Deletes files that are not under version control.'),
);

/// The reply to the `choose` flow's answer: which option was picked.
String chooseReply(ChatToolCallConfirmedAction action) {
  final (approved, optionId) = switch (action) {
    ChatToolCallApprovedAction(:final selectedOptionId) => (
      true,
      selectedOptionId,
    ),
    ChatToolCallDeniedAction(:final selectedOptionId) => (
      false,
      selectedOptionId,
    ),
  };
  final label =
      confirmationOptions.where((o) => o.id == optionId).firstOrNull?.label ??
      'no option';
  return approved
      ? 'You chose "$label", so I deleted build/.'
      : 'You chose "$label", so I kept build/.';
}

/// The `bash` call of the `command` flow, whose input may be edited.
ChatToolCallReadyAction commandReady(String turnId, String toolCallId) =>
    ChatToolCallReadyAction(
      turnId: turnId,
      toolCallId: toolCallId,
      invocationMessage: const PlainString('Run `git push origin main`'),
      toolInput: const InlineToolInput('{"command":"git push origin main"}'),
      confirmationTitle: const PlainString('Allow Bash to push?'),
      editable: true,
    );

/// The command in a `bash` tool input (`{"command": …}`), or the input
/// itself when it is not that JSON.
String commandOf(String input) {
  try {
    final json = jsonDecode(input);
    if (json is Map && json['command'] is String) {
      return json['command'] as String;
    }
  } on FormatException {
    // Not JSON: the input is the command.
  }
  return input;
}

/// The result the `result` flow asks the user to confirm.
const fetchResult = ToolCallResult(
  success: true,
  pastTenseMessage: PlainString('Fetched the status page'),
  content: [ToolResultTextContent(text: 'Status: all systems operational')],
);

/// The input request of the `draft` flow, with ID [id].
ChatInputRequest releaseNotesRequest(String id) => ChatInputRequest(
  id: id,
  message: 'Describe the release',
  questions: const [
    ChatInputTextQuestion(
      id: 'summary',
      title: 'Summary',
      message: 'One line for the changelog',
      required: true,
    ),
    ChatInputTextQuestion(
      id: 'notes',
      title: 'Notes',
      message: 'Anything else',
    ),
  ],
);

/// The draft the `draft` flow's other client ([otherClientId]) types.
const otherClientDraft = 'Drafted on fake-ide';

/// The `chat/inputAnswerChanged` that relays [otherClientDraft] for the
/// `notes` question of request [requestId].
ChatInputAnswerChangedAction otherClientDraftAction(String requestId) =>
    ChatInputAnswerChangedAction(
      requestId: requestId,
      questionId: 'notes',
      answer: const ChatInputAnswered(
        state: 'draft',
        value: ChatInputTextAnswerValue(value: otherClientDraft),
      ),
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

/// The README before the `edit` flow changes it.
const readmeBefore = '# Fake project\n\nOld intro.\n\n## Usage\n\nRun it.\n';

/// The README after the `edit` flow: three lines added, one removed.
const readmeAfter =
    '# Fake project\n\nA scripted host for tests.\nIt asks for approvals.\n'
    'It edits this file.\n\n## Usage\n\nRun it.\n';

/// The file the `edit` flow changes, under [directory].
String readmeUri(String directory) => 'file://$directory/README.md';

/// The output lines of the `shell` flow's `npm test`.
const shellOutput = [
  '> fake@1.0.0 test',
  '> dart test',
  '00:01 +1: parses the config',
  '00:01 +2: renders the timeline',
  '00:02 +3: All tests passed!',
];

/// The files the `read` flow reads.
const readFiles = ['lib/main.dart', 'lib/app.dart', 'pubspec.yaml'];

/// The markdown reply of the `code` flow.
const codeReply = """Here is the entry point:

```dart
void main() {
  final greeting = 'Hello';
  print('\$greeting, world!');
}
```
""";

/// The changesets every session advertises: the whole session (with
/// per-file review) and one turn (`{turnId}`).
List<Changeset> sessionChangesets(String session) {
  final key = changesetKey(session);
  return [
    Changeset(
      label: 'Session changes',
      uriTemplate: 'ahp-changeset:/$key/session',
      changeKind: 'session',
      capabilities: const ChangesetCapabilities(review: {}),
    ),
    Changeset(
      label: 'Turn changes',
      uriTemplate: 'ahp-changeset:/$key/turn/{turnId}',
      changeKind: 'turn',
    ),
  ];
}

/// The part of a session URI used in its changeset URIs.
String changesetKey(String session) =>
    session.substring(session.lastIndexOf('/') + 1);

/// The operations the session changeset offers.
const changesetOperations = [
  ChangesetOperation(
    id: 'commit',
    label: 'Commit',
    description: 'Commit every change',
    scopes: [ChangesetOperationScope.changeset],
    confirmation: PlainString('Commit all changes?'),
    icon: 'check',
    status: ChangesetOperationStatus.idle,
  ),
  ChangesetOperation(
    id: 'revert',
    label: 'Revert',
    description: 'Revert this file',
    scopes: [ChangesetOperationScope.resource],
    icon: 'trash',
    status: ChangesetOperationStatus.idle,
  ),
];

/// How many turns a windowed chat state holds, and each `fetchTurns` page
/// loads (AHP-029).
const turnWindow = 20;

/// The seeded long session's history: [count] finished turns, oldest
/// first. Every fifth reply has a code block.
List<Turn> longHistory(int count, DateTime start) => [
  for (var i = 1; i <= count; i++)
    Turn(
      id: 'long-$i',
      startedAt: start.add(Duration(minutes: i)).toUtc().toIso8601String(),
      duration: 1200,
      state: TurnState.complete,
      message: userMessage('Question $i'),
      responseParts: [
        MarkdownResponsePart(
          id: 'long-md-$i',
          content: i % 5 == 0
              ? 'Answer $i, with code:\n\n```python\nprint($i)\n```'
              : 'Answer $i.',
        ),
      ],
    ),
];

/// The todo lists the `todo` flow writes, as `TodoWrite` input: three
/// steps, worked through one at a time.
List<String> todoInputs() {
  const steps = [
    ('Read the failing test', 'Reading the failing test'),
    ('Fix the parser', 'Fixing the parser'),
    ('Run the tests', 'Running the tests'),
  ];
  String list(int done) => jsonEncode({
    'todos': [
      for (final (i, (content, active)) in steps.indexed)
        {
          'content': content,
          'activeForm': active,
          'status': i < done
              ? 'completed'
              : i == done
              ? 'in_progress'
              : 'pending',
        },
    ],
  });
  return [list(0), list(1), list(3)];
}

/// The plan the `plan` flow proposes.
const planMarkdown = '''## Plan

1. Add a `--dry-run` flag to the CLI.
2. Print the changes instead of writing them.
3. Cover both modes with tests.''';

/// The plan review of the `plan` flow, with ID [id] and question
/// [questionId]: VS Code's agent host asks it like this (described
/// options, free-form feedback).
ChatInputRequest planReviewRequest(String id) => ChatInputRequest(
  id: id,
  message: 'Review the plan',
  questions: const [
    ChatInputSingleSelectQuestion(
      id: 'plan',
      title: 'Review Plan',
      message: 'How would you like to proceed?',
      required: true,
      allowFreeformInput: true,
      options: [
        ChatInputOption(
          id: 'interactive',
          label: 'Implement Plan',
          description: 'Implement the plan, asking for approval as needed.',
          recommended: true,
        ),
        ChatInputOption(
          id: 'exit_only',
          label: 'Approve Plan Only',
          description: 'Approve the plan without executing it.',
        ),
      ],
    ),
  ],
);

/// The GitHub repository the fake host's repository sessions report.
const fakeGitHubOwner = 'example';

/// See [fakeGitHubOwner].
const fakeGitHubRepo = 'workspace';

/// The pull request the `pr` flow opens.
const fakePullRequestUrl =
    'https://github.com/$fakeGitHubOwner/$fakeGitHubRepo/pull/42';

/// `_meta.git` of a session on [branch] in the fake repository (VS Code's
/// shape).
JsonMap gitMeta(String branch) => {
  'branchName': branch,
  'githubOwner': fakeGitHubOwner,
  'githubRepo': fakeGitHubRepo,
};

/// [meta] with the `copilot.githubReferences` entry for the pull request
/// of the session's branch.
JsonMap withPullRequestMeta(JsonMap? meta) => {
  ...?meta,
  'copilot.githubReferences': [
    {
      'referenceType': 'pr',
      'repository': '$fakeGitHubOwner/$fakeGitHubRepo',
      'number': 42,
      'title': 'Add a dry-run flag',
      'state': 'open',
      'url': fakePullRequestUrl,
      'relations': ['headBranch'],
    },
  ],
};
