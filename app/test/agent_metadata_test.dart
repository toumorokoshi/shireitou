/// Todo lists and plans (AV-070, AV-046), plan reviews with free-form
/// answers, and pull request / branch links (AV-105).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/session_detail/chat_commands.dart';
import 'package:shireitou/src/session_detail/source_links.dart';
import 'package:shireitou/src/session_detail/timeline_items.dart';
import 'package:shireitou/src/session_detail/todo_list.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _chat = 'ahp-chat:/1';

const _claudeTodos =
    '{"todos":['
    '{"content":"Read the test","activeForm":"Reading the test","status":"completed"},'
    '{"content":"Fix the parser","activeForm":"Fixing the parser","status":"in_progress"},'
    '{"content":"Run the tests","activeForm":"Running the tests","status":"pending"}]}';

ToolCallState _todoCall(String id, String input, {String name = 'TodoWrite'}) =>
    ToolCallCompletedState(
      toolCallId: id,
      toolName: name,
      displayName: 'Update todo list',
      invocationMessage: const PlainString('Update todo list'),
      pastTenseMessage: const PlainString('Updated todo list'),
      toolInput: InlineToolInput(input),
      confirmed: ToolCallConfirmationReason.notNeeded,
      success: true,
    );

ChatState _chatWith(List<ResponsePart> parts, {bool active = false}) =>
    ChatState(
      resource: _chat,
      title: 'Fix login',
      status: SessionStatus(active ? 8 : 33),
      modifiedAt: '2026-10-01T00:00:00Z',
      turns: [
        if (!active)
          Turn(
            id: 't1',
            message: userMessage('go'),
            state: TurnState.complete,
            responseParts: parts,
          ),
      ],
      activeTurn: active
          ? ActiveTurn(
              id: 't1',
              startedAt: '2026-10-01T00:00:00Z',
              message: userMessage('go'),
              responseParts: parts,
            )
          : null,
    );

Future<FakeHostConnection> _pump(
  WidgetTester tester, {
  required ChatState chat,
  SessionSummary? summary,
  SessionState? sessionState,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(
    HostState(
      status: ConnectionStatus.connected,
      protocolVersion: '1.0.0',
      sessions: catalogueFromSummaries([
        summary ??
            session('1', directory: 'file:///src/app', title: 'Fix login'),
      ]),
      chatChannels: {_chat: ChannelMirror.snapshot(chat)},
      sessionChannels: {
        if (sessionState != null) 'pi:/1': ChannelMirror.snapshot(sessionState),
      },
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: hostOverrides(connection: connection),
      child: const ShireitouApp(),
    ),
  );
  await tester.tap(find.text('Fix login').first);
  await tester.pumpAndSettle();
  return connection;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('todo lists (AV-070)', () {
    test("Claude's TodoWrite", () {
      final list = parseTodoInput(_claudeTodos)!;
      expect(list.items.map((i) => i.status), [
        TodoStatus.completed,
        TodoStatus.inProgress,
        TodoStatus.pending,
      ]);
      expect(list.current?.activeTitle, 'Fixing the parser');
      expect(list.progressLabel, '1 of 3 done');
      expect(list.done, isFalse);
    });

    test("Codex's update_plan and VS Code's manage_todo_list", () {
      final plan = parseTodoInput(
        '{"explanation":"Two steps","plan":['
        '{"step":"Write it","status":"completed"},'
        '{"step":"Ship it","status":"in_progress"}]}',
      )!;
      expect(plan.explanation, 'Two steps');
      expect(plan.items.last, const TodoItem('Ship it', TodoStatus.inProgress));
      final vscode = parseTodoInput(
        '{"todoList":[{"id":1,"title":"A","status":"not-started"},'
        '{"id":2,"title":"B","status":"completed"}]}',
      )!;
      expect(vscode.items.map((i) => i.status), [
        TodoStatus.pending,
        TodoStatus.completed,
      ]);
    });

    test("the Copilot CLI's markdown checklist", () {
      final list = parseTodoInput(
        '{"todos":"- [x] Done thing\\n- [ ] Next thing\\n* [~] Doing"}',
      )!;
      expect(list.items, const [
        TodoItem('Done thing', TodoStatus.completed),
        TodoItem('Next thing', TodoStatus.pending),
        TodoItem('Doing', TodoStatus.inProgress),
      ]);
    });

    test('other tools, broken input and empty lists are not todo lists', () {
      expect(todoListOf(_todoCall('a', _claudeTodos, name: 'bash')), isNull);
      expect(parseTodoInput('{"todos":[]}'), isNull);
      expect(parseTodoInput('not json'), isNull);
      expect(isTodoTool('update_todo'), isTrue);
      expect(isTodoTool('manage_todo_list'), isTrue);
    });

    test('the newest list wins, and todo calls are never grouped', () {
      final first = _todoCall('a', _claudeTodos);
      final second = _todoCall(
        'b',
        '{"todos":[{"content":"Only","status":"completed"}]}',
      );
      final chat = _chatWith([
        ToolCallResponsePart(toolCall: first),
        ToolCallResponsePart(toolCall: second),
      ]);
      expect(latestTodoList(chat)!.items.single.title, 'Only');
      expect(latestTodoList(_chatWith(const [])), isNull);
      final rows = partItems('t1', [
        ToolCallResponsePart(toolCall: first),
        ToolCallResponsePart(toolCall: second),
      ], active: false);
      expect(rows.whereType<ToolCallGroupItem>(), isEmpty);
      expect(rows, hasLength(2));
    });

    testWidgets('a todo call is a checklist card, and the open list sits '
        'above the follow-up box', (tester) async {
      reduceMotion(tester);
      await _pump(
        tester,
        chat: _chatWith([
          ToolCallResponsePart(toolCall: _todoCall('a', _claudeTodos)),
        ], active: true),
      );
      expect(find.text('Todo list · 1 of 3 done'), findsNWidgets(2));
      expect(find.text('Read the test'), findsOneWidget);
      expect(find.byIcon(Icons.timelapse), findsWidgets);
      // The panel names the current step and expands to the list.
      expect(find.text('Fixing the parser'), findsNWidgets(2));
      await tester.tap(find.text('Todo list · 1 of 3 done').last);
      await tester.pumpAndSettle();
      expect(find.text('Read the test'), findsNWidgets(2));
    });

    testWidgets('a finished list has no panel', (tester) async {
      await _pump(
        tester,
        chat: _chatWith([
          ToolCallResponsePart(
            toolCall: _todoCall(
              'a',
              '{"todos":[{"content":"Only","status":"completed"}]}',
            ),
          ),
        ]),
      );
      expect(find.text('Todo list · 1 of 1 done'), findsOneWidget);
    });
  });

  group('plan reviews (AV-046)', () {
    const question = ChatInputSingleSelectQuestion(
      id: 'plan',
      title: 'Review Plan',
      message: 'How would you like to proceed?',
      required: true,
      allowFreeformInput: true,
      options: [
        ChatInputOption(
          id: 'interactive',
          label: 'Implement Plan',
          description: 'Ask as needed.',
          recommended: true,
        ),
        ChatInputOption(
          id: 'exit_only',
          label: 'Approve Plan Only',
          description: 'Do not run it.',
        ),
      ],
    );
    const request = ChatInputRequest(id: 'r', questions: [question]);

    test('free-form text goes with the choice, or alone as text', () {
      expect(
        inputAnswer(question, 'interactive', freeform: ' skip docs ')?.toJson(),
        const ChatInputAnswered(
          state: 'submitted',
          value: ChatInputSelectedAnswerValue(
            value: 'interactive',
            freeformValues: ['skip docs'],
          ),
        ).toJson(),
      );
      expect(
        inputAnswer(question, '', freeform: 'do it differently')?.toJson(),
        const ChatInputAnswered(
          state: 'submitted',
          value: ChatInputTextAnswerValue(value: 'do it differently'),
        ).toJson(),
      );
      expect(inputAnswer(question, ''), isNull);
      expect(inputComplete(request, const {}), isFalse);
      expect(
        inputComplete(request, const {}, freeform: const {'plan': 'x'}),
        isTrue,
      );
      // Questions that do not allow it ignore free-form text.
      expect(
        inputAnswer(
          const ChatInputSingleSelectQuestion(
            id: 'q',
            message: 'Q',
            options: [],
          ),
          '',
          freeform: 'x',
        ),
        isNull,
      );
    });

    testWidgets('described options are a list, with a free-form field', (
      tester,
    ) async {
      reduceMotion(tester);
      final connection = await _pump(
        tester,
        chat: _chatWith([
          const MarkdownResponsePart(id: 'm', content: '## Plan\n\n1. Do it'),
          const InputRequestResponsePart(request: request),
        ], active: true),
      );
      expect(find.text('Implement Plan (recommended)'), findsOneWidget);
      expect(find.text('Do not run it.'), findsOneWidget);
      await tester.tap(find.text('Approve Plan Only'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Or write your own answer'),
        'Keep the CLI flag short',
      );
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      final (_, action) = connection.dispatched.last;
      expect(action['type'], 'chat/inputCompleted');
      expect(action['answers'], {
        'plan': {
          'state': 'submitted',
          'value': {
            'kind': 'selected',
            'value': 'exit_only',
            'freeformValues': ['Keep the CLI flag short'],
          },
        },
      });
    });
  });

  group('pull request and branch links (AV-105)', () {
    final meta = <String, Object?>{
      'git': {
        'branchName': 'feature/dry-run',
        'githubOwner': 'example',
        'githubRepo': 'workspace',
      },
      'copilot.githubReferences': [
        {
          'referenceType': 'pr',
          'url': 'https://github.com/example/workspace/pull/7',
          'relations': ['attached'],
        },
        {
          'referenceType': 'pr',
          'repository': 'example/workspace',
          'number': 42,
          'title': 'Add a dry-run flag',
          'state': 'open',
          'url': 'https://github.com/example/workspace/pull/42',
          'relations': ['headBranch'],
        },
      ],
    };

    test('reads the head-branch pull request and the branch', () {
      final links = sourceLinksOf(summary: meta);
      expect(
        links.pullRequest,
        const PullRequestLink(
          url: 'https://github.com/example/workspace/pull/42',
          number: 42,
          title: 'Add a dry-run flag',
          state: 'open',
          repository: 'example/workspace',
        ),
      );
      expect(links.pullRequest!.label, 'PR #42 · open');
      expect(
        links.branch,
        const BranchLink(
          'feature/dry-run',
          url: 'https://github.com/example/workspace/tree/feature/dry-run',
        ),
      );
    });

    test('the session state wins over the summary; junk is ignored', () {
      final links = sourceLinksOf(
        session: const {
          'git': {'branchName': 'main'},
        },
        summary: meta,
      );
      expect(links.branch, const BranchLink('main'));
      expect(links.pullRequest?.number, 42);
      expect(
        pullRequestOf(const {
          'copilot.githubReferences': [
            {
              'referenceType': 'pr',
              'url': 'https://evil.example/x',
              'relations': ['headBranch'],
            },
          ],
        }),
        isNull,
      );
      expect(sourceLinksOf(), (pullRequest: null, branch: null));
    });

    testWidgets('the header links to the pull request and branch', (
      tester,
    ) async {
      await _pump(
        tester,
        chat: _chatWith(const []),
        summary: SessionSummary(
          resource: 'pi:/1',
          provider: 'pi',
          title: 'Fix login',
          status: SessionStatus(33),
          createdAt: '2026-10-01T00:00:00Z',
          modifiedAt: '2026-10-01T00:00:00Z',
          workingDirectories: const ['file:///src/app'],
          meta: meta,
        ),
      );
      expect(find.widgetWithText(ActionChip, 'PR #42 · open'), findsOneWidget);
      expect(
        find.widgetWithText(ActionChip, 'feature/dry-run'),
        findsOneWidget,
      );
    });
  });
}
