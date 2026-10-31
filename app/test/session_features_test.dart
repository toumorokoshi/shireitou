/// Widget tests for the timeline features and mirrored session state:
/// code blocks, grouping, terminals, diffs, the chat switcher, queued
/// messages, drafts, paging, the review pane and session details.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/clipboard/rich_clipboard.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/files/file_viewer.dart';
import 'package:shireitou/src/prefs.dart';
import 'package:shireitou/src/theme/app_colors.dart';
import 'package:shireitou/src/review/changes_pane.dart';
import 'package:shireitou/src/review/review_logic.dart';
import 'package:shireitou/src/review/review_pane_store.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';
import 'package:shireitou/src/session_detail/code_highlight.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';
import 'package:shireitou/src/session_detail/turn_rail.dart';
import 'package:shireitou/src/session_list/session_list_view.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'fake_connection.dart';
import 'fixtures.dart';

const _chat = 'ahp-chat:/1';
const _worker = 'ahp-chat:/worker';
const _terminal = 'ahp-terminal:/t1';
const _changeset = 'ahp-changeset:/1/session';

Future<FakeHostConnection> _pump(
  WidgetTester tester,
  HostState state, {
  Size size = const Size(1400, 1000),
  bool settle = true,
  PrefsStore? prefs,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...hostOverrides(connection: connection),
        prefsStoreProvider.overrideWithValue(prefs ?? MemoryPrefsStore()),
      ],
      child: const ShireitouApp(),
    ),
  );
  await tester.tap(find.text('Fix login').first);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Spinners never settle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  return connection;
}

HostState _state({
  required ChatState chat,
  SessionState? sessionState,
  String version = '1.0.0',
  Map<String, ChannelMirror<ChatState>> otherChats = const {},
  Map<String, ChannelMirror<TerminalState>> terminals = const {},
  Map<String, ChannelMirror<ChangesetState>> changesets = const {},
  Map<String, ChannelMirror<CanvasState>> canvases = const {},
  RootState? root,
}) => HostState(
  status: ConnectionStatus.connected,
  protocolVersion: version,
  root: root,
  sessions: catalogueFromSummaries([
    session('1', directory: 'file:///src/app', title: 'Fix login'),
  ]),
  chatChannels: {_chat: ChannelMirror.snapshot(chat), ...otherChats},
  sessionChannels: {
    if (sessionState != null) 'pi:/1': ChannelMirror.snapshot(sessionState),
  },
  terminalChannels: terminals,
  changesetChannels: changesets,
  canvasChannels: canvases,
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
            message: userMessage('Do it'),
            state: TurnState.complete,
            responseParts: parts,
          ),
      ],
      activeTurn: active
          ? ActiveTurn(
              id: 't1',
              startedAt: '2026-10-01T00:00:00Z',
              message: userMessage('Do it'),
              responseParts: parts,
            )
          : null,
    );

ToolCallState _call(
  String id,
  String tool, {
  bool running = false,
  List<ToolResultContent>? content,
}) => running
    ? ToolCallRunningState(
        toolCallId: id,
        toolName: tool,
        displayName: tool,
        invocationMessage: PlainString('$tool $id'),
        confirmed: ToolCallConfirmationReason.notNeeded,
        content: content,
      )
    : ToolCallCompletedState(
        toolCallId: id,
        toolName: tool,
        displayName: tool == 'read' ? 'Read' : tool,
        invocationMessage: PlainString('$tool $id'),
        pastTenseMessage: PlainString('Did $tool $id'),
        confirmed: ToolCallConfirmationReason.notNeeded,
        success: true,
        content: content,
      );

SessionState _session({
  List<ChatSummary>? chats,
  List<Changeset>? changesets,
}) => SessionState(
  provider: 'pi',
  title: 'Fix login',
  status: SessionStatus.idle,
  lifecycle: SessionLifecycle.ready,
  activeClients: const [
    SessionActiveClient(clientId: 'vscode', displayName: 'VS Code', tools: []),
  ],
  defaultChat: _chat,
  workingDirectories: const ['file:///src/app'],
  serverTools: const [
    ToolDefinition(name: 'bash', title: 'Bash', description: 'Runs a shell'),
  ],
  customizations: const [
    McpServerCustomization(
      id: 'docs',
      uri: 'file:///src/app/.mcp.json',
      name: 'Example Docs',
      state: McpServerStartingState(blocking: true),
    ),
  ],
  changesets: changesets,
  chats:
      chats ??
      const [
        ChatSummary(
          resource: _chat,
          title: 'Fix login',
          status: SessionStatus.idle,
          modifiedAt: '2026-10-01T00:00:00Z',
        ),
      ],
);

const _workerSummary = ChatSummary(
  resource: _worker,
  title: 'Explorer',
  status: SessionStatus.idle,
  modifiedAt: '2026-10-01T00:00:00Z',
  origin: ChatOriginTool(chat: _chat, toolCallId: 'task'),
  interactivity: ChatInteractivity.readOnly,
  movable: true,
);

const _mainSummary = ChatSummary(
  resource: _chat,
  title: 'Fix login',
  status: SessionStatus.idle,
  modifiedAt: '2026-10-01T00:00:00Z',
);

/// A finished chat of [count] turns ("Question i"), each with a long
/// reply, numbered from [from]; [cursor] holds older turns back.
ChatState _longChat(int count, {int from = 0, String? cursor}) => ChatState(
  resource: _chat,
  title: 'Fix login',
  status: SessionStatus.idle,
  modifiedAt: '2026-10-01T00:00:00Z',
  turnsNextCursor: cursor,
  turns: [
    for (var i = from; i < from + count; i++)
      Turn(
        id: 'q$i',
        message: userMessage('Question $i\nwith details'),
        state: i == from + 1 ? TurnState.error : TurnState.complete,
        responseParts: [
          MarkdownResponsePart(
            id: 'a$i',
            content: [for (var l = 0; l < 30; l++) 'Answer $i, line $l']
                .join('\n\n'),
          ),
        ],
      ),
  ],
);

/// Presses Ctrl+Alt+[key] (the turn shortcuts off Apple platforms).
Future<void> _ctrlAlt(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

/// Taps [text] in the one paragraph [paragraph] finds, a third of the way
/// in: the middle of an even number of monospace characters is a glyph
/// boundary, which `tapOnText` can miss.
Future<void> _tapText(
  WidgetTester tester,
  Finder paragraph,
  String text,
) async {
  final box = tester.renderObject<RenderParagraph>(paragraph);
  final start = box.text.toPlainText().indexOf(text);
  final rect = box
      .getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + text.length),
      )
      .first
      .toRect();
  await tester.tapAt(
    box.localToGlobal(Offset(rect.left + rect.width / 3, rect.center.dy)),
  );
}

/// Whether [text] shows near the top of the timeline.
bool _atTop(WidgetTester tester, String text) {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return false;
  final dy = tester.getTopLeft(finder).dy;
  final top = tester.getTopLeft(find.byType(SuperListView)).dy;
  return dy >= top && dy < top + 80;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('code blocks are highlighted and copyable (AV-061)', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await _pump(
      tester,
      _state(
        chat: _chatWith(const [
          MarkdownResponsePart(
            id: 'm',
            content: 'Here:\n\n```dart\nvoid main() {}\n```\n',
          ),
        ]),
      ),
    );
    final block = tester.widget<CodeBlock>(find.byType(CodeBlock));
    expect(block.language, 'dart');
    expect(block.code, 'void main() {}');
    final span = highlightCode(
      'void main() {}',
      language: 'dart',
      base: const TextStyle(),
      theme: AppColors.light.syntax,
    );
    expect(span.children, isNotEmpty);
    await tester.tap(find.byTooltip('Copy code'));
    await tester.pump();
    expect(copied, 'void main() {}');
  });

  testWidgets('selected code pastes as written, on its own lines (AV-061)', (
    tester,
  ) async {
    String? copied;
    String? html;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      richClipboardChannel,
      (call) async {
        copied = (call.arguments as Map)['text'] as String?;
        html = (call.arguments as Map)['html'] as String?;
        return null;
      },
    );
    await _pump(
      tester,
      _state(
        chat: _chatWith(const [
          ToolCallResponsePart(
            toolCall: ToolCallCompletedState(
              toolCallId: 'echo',
              toolName: 'bash',
              displayName: 'Bash',
              invocationMessage: PlainString('Running echo'),
              pastTenseMessage: PlainString('Ran echo'),
              toolInput: InlineToolInput('{"command":"echo"}'),
              confirmed: ToolCallConfirmationReason.notNeeded,
              success: true,
              content: [ToolResultTextContent(text: 'said "hi"')],
            ),
          ),
          MarkdownResponsePart(
            id: 'm',
            content: 'Here:\n\n```python\nprint("hi")\n```\n\nDone.',
          ),
        ]),
      ),
    );
    await tester.tap(find.text('Completed 1 step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ran echo'));
    await tester.pumpAndSettle();

    Rect at(String text) =>
        tester.getRect(find.textContaining(text, findRichText: true).last);
    Future<String?> dragCopy(Offset from, Offset to) async {
      copied = null;
      final gesture = await tester.startGesture(
        from,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(to);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      return copied;
    }

    // The code and the paragraph below it start left of the indented
    // tool output and code above them, which stay out of the selection.
    final code = at('print');
    expect(
      await dragCopy(code.topLeft + const Offset(1, 2), code.bottomRight),
      'print("hi")',
    );
    final done = at('Done.');
    expect(
      await dragCopy(done.topLeft + const Offset(1, 2), done.bottomRight),
      'Done.',
    );
    // From the paragraph above, over the block's "python" label, to the
    // one below: the label stays out and each block keeps its own line.
    expect(
      await dragCopy(
        at('Here:').topLeft + const Offset(1, 2),
        at('Done.').bottomRight,
      ),
      'Here:\nprint("hi")\nDone.',
    );
    expect(html, '<meta charset="utf-8">Here:<pre>print("hi")</pre>Done.');
    // The tool call's "Input" and "Output" labels stay out too.
    final output = at('said');
    expect(
      await dragCopy(
        at('"command"').topLeft + const Offset(1, 2),
        output.bottomRight,
      ),
      '{\n  "command": "echo"\n}\nsaid "hi"',
    );
  });

  testWidgets('a finished turn copies its reply as markdown or as HTML '
      '(AV-071, AV-076)', (tester) async {
    final plain = <String>[];
    final rich = <Map<Object?, Object?>>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          plain.add((call.arguments as Map)['text'] as String);
        }
        return null;
      })
      ..setMockMethodCallHandler(richClipboardChannel, (call) async {
        rich.add(call.arguments as Map<Object?, Object?>);
        return null;
      });
    await _pump(tester, _state(chat: chatFixture()));
    // Only the finished turn has a footer.
    expect(find.byTooltip('Copy as markdown'), findsOneWidget);
    expect(find.byTooltip('Copy as HTML'), findsOneWidget);

    // Markdown is plain text only.
    await tester.tap(find.byTooltip('Copy as markdown'));
    await tester.pump();
    expect(plain, ['Ran `ls`\n\nThere is **one** file.']);
    expect(rich, isEmpty);
    expect(find.byTooltip('Copied'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byTooltip('Copy as markdown'), findsOneWidget);

    // HTML is a rich copy, with the markdown for plain-text targets.
    await tester.tap(find.byTooltip('Copy as HTML'));
    await tester.pump();
    expect(plain, hasLength(1));
    expect(rich, [
      {
        'text': 'Ran `ls`\n\nThere is **one** file.',
        'html':
            '<meta charset="utf-8"><p>Ran <code>ls</code></p>\n'
            '<p>There is <strong>one</strong> file.</p>\n',
      },
    ]);
    expect(find.byTooltip('Copied'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byTooltip('Copy as HTML'), findsOneWidget);
  });

  testWidgets('the latest message is edited in place to restart from it '
      '(AV-088)', (tester) async {
    final connection = await _pump(tester, _state(chat: chatFixture()));
    // Only the running message has the button.
    expect(find.byTooltip('Edit and restart from here'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit and restart from here'));
    await tester.pumpAndSettle();
    final editor = find.widgetWithText(TextField, 'Edit message');
    expect(editor, findsOneWidget);
    await tester.enterText(editor, 'Delete it, carefully');
    await tester.tap(find.byTooltip('Restart from here'));
    await tester.pumpAndSettle();

    final [truncated, started] = [
      for (final (_, action) in connection.dispatched.reversed.take(2)) action,
    ].reversed.toList();
    expect(truncated, {'type': 'chat/truncated', 'turnId': 'turn-1'});
    expect(started['type'], 'chat/turnStarted');
    expect((started['message']! as JsonMap)['text'], 'Delete it, carefully');
    expect(editor, findsNothing);
  });

  testWidgets('user bubbles sit on the right; steps collapse but calls that '
      'need attention stay expanded (AV-095)', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _state(chat: chatFixture()));
    final list = tester.getRect(find.byType(SuperListView));
    final bubble = tester.getRect(
      find
          .descendant(
            of: find.widgetWithText(UserMessageBubble, 'List the files'),
            matching: find.byType(Container),
          )
          .first,
    );
    // The timeline and the composer share one centred column.
    final composerBox = tester.getRect(
      find
          .descendant(
            of: find.byType(FollowUpInput),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(bubble.right, moreOrLessEquals(composerBox.right, epsilon: 1));
    expect(bubble.left, greaterThan(list.center.dx));
    // The reasoning and the finished call fold into one muted line.
    expect(find.text('Completed 2 steps in 2s'), findsOneWidget);
    expect(find.text('Ran `ls`'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Completed 2 steps in 2s')),
      isSemantics(isButton: true, hasExpandedState: true, isExpanded: false),
    );
    // The call waiting for approval and the input request stay in view.
    expect(find.text('Run `rm a.txt`'), findsOneWidget);
    expect(find.text('Which branch?'), findsOneWidget);
    // The reply after the steps is full width, with no bubble.
    expect(
      find.ancestor(
        of: find.textContaining('one'),
        matching: find.byType(UserMessageBubble),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Completed 2 steps in 2s'));
    await tester.pumpAndSettle();
    expect(find.text('Ran `ls`'), findsOneWidget);
    expect(find.text('Thinking'), findsOneWidget);
    await tester.tap(find.text('Completed 2 steps in 2s'));
    await tester.pumpAndSettle();
    expect(find.text('Ran `ls`'), findsNothing);
    semantics.dispose();
  });

  testWidgets('user bubbles show the turn start timestamp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserMessageBubble(
            message: userMessage('Hello'),
            startedAt: '2026-10-01T15:16:17',
          ),
        ),
      ),
    );

    final tooltip = find.byTooltip('2026-10-01T15:16:17');
    expect(tooltip, findsOneWidget);
    final label = tester
        .widget<Text>(find.descendant(of: tooltip, matching: find.byType(Text)))
        .data!;
    expect(label, contains('10/01/2026'));
    expect(label, contains('3:16'));
    expect(label, contains('PM'));
  });

  testWidgets('markdown tables have bordered cells (AV-095)', (tester) async {
    await _pump(
      tester,
      _state(
        chat: _chatWith(const [
          MarkdownResponsePart(
            id: 'm',
            content: '| Name | Calls |\n| --- | --- |\n| bazel test | 260 |',
          ),
        ]),
      ),
    );
    expect(find.text('bazel test'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    final table = tester.widget<Table>(find.byType(Table));
    final context = tester.element(find.byType(Table));
    expect(table.border?.top.color, Theme.of(context).colorScheme.outline);
    expect(table.border?.horizontalInside.style, BorderStyle.solid);
    // Header cells start where the body's do.
    expect(
      tester.getTopLeft(find.text('Name')).dx,
      tester.getTopLeft(find.text('bazel test')).dx,
    );
  });

  testWidgets('jump to latest is a small round button (AV-095)', (
    tester,
  ) async {
    reduceMotion(tester);
    await _pump(tester, _state(chat: _longChat(4)));
    expect(find.byTooltip('Jump to latest'), findsNothing);
    await tester.drag(find.byType(SuperListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    final button = find.byTooltip('Jump to latest');
    expect(button, findsOneWidget);
    expect(tester.getSize(button), const Size(32, 32));
    expect(find.byType(JumpToLatestButton), findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Jump to latest'), findsNothing);
  });

  testWidgets('similar tool calls are grouped (AV-064)', (tester) async {
    await _pump(
      tester,
      _state(
        chat: _chatWith([
          for (final id in ['a', 'b', 'c'])
            ToolCallResponsePart(toolCall: _call(id, 'read')),
        ]),
      ),
    );
    // The calls are steps of the turn, collapsed until expanded (AV-095).
    expect(find.text('Read · 3 calls'), findsNothing);
    await tester.tap(find.text('Completed 3 steps'));
    await tester.pumpAndSettle();
    expect(find.text('Read · 3 calls'), findsOneWidget);
    expect(find.text('Did read a'), findsNothing);
    await tester.tap(find.text('Read · 3 calls'));
    await tester.pumpAndSettle();
    expect(find.text('Did read a'), findsOneWidget);
  });

  testWidgets('a running shell shows live terminal output (AV-065)', (
    tester,
  ) async {
    final connection = await _pump(
      tester,
      _state(
        chat: _chatWith([
          ToolCallResponsePart(
            toolCall: _call(
              'sh',
              'bash',
              running: true,
              content: const [
                ToolResultTerminalContent(
                  resource: _terminal,
                  title: 'npm test',
                ),
              ],
            ),
          ),
        ], active: true),
        terminals: {
          _terminal: ChannelMirror.snapshot(
            const TerminalState(
              title: 'npm test',
              content: [
                TerminalCommandPart(
                  commandId: 'c',
                  commandLine: 'npm test',
                  output: '\x1B[32mok 1\x1B[0m\n',
                  timestamp: 0,
                  isComplete: false,
                ),
              ],
              lifecycle: TerminalRunningLifecycleState(),
              claim: TerminalClientClaim(clientId: 'x'),
            ),
          ),
        },
      ),
      settle: false,
    );
    await tester.tap(find.text('Working… 1 step'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(connection.subscribed, contains(_terminal));
    expect(find.text('\$ npm test\nok 1'), findsOneWidget);
    expect(find.text('Running'), findsWidgets);
  });

  testWidgets('a file edit shows an inline diff (AV-065)', (tester) async {
    final state = _state(
      chat: _chatWith([
        ToolCallResponsePart(
          toolCall: _call(
            'e',
            'edit',
            content: const [
              ToolResultFileEditContent(
                before: FileEditSide(
                  uri: 'file:///src/app/README.md',
                  content: ContentRef(uri: 'c:/before'),
                ),
                after: FileEditSide(
                  uri: 'file:///src/app/README.md',
                  content: ContentRef(uri: 'c:/after'),
                ),
                diff: FileEditDiffStats(added: 1, removed: 1),
              ),
            ],
          ),
        ),
      ]),
    );
    final connection = FakeHostConnection(state)
      ..contents.addAll({'c:/before': 'a\nold\n', 'c:/after': 'a\nnew\n'});
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: hostOverrides(connection: connection),
        child: const ShireitouApp(),
      ),
    );
    await tester.tap(find.text('Fix login').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed 1 step'));
    await tester.pumpAndSettle();
    expect(find.text('app/README.md'), findsOneWidget);
    expect(find.text('+1 −1'), findsOneWidget);
    expect(find.text('old'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
    await tester.tap(find.byTooltip('Open diff'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unified view'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);

    // The diff page's code is selectable and copies without the line
    // numbers and markers, one line each.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      richClipboardChannel,
      (call) async {
        copied = (call.arguments as Map)['text'] as String?;
        return null;
      },
    );
    await tester.tap(find.byTooltip('Unified view'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getTopLeft(find.text('a')) + const Offset(1, 2),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveTo(tester.getBottomRight(find.text('new')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(copied, 'a\nold\nnew');
  });

  testWidgets('the chat switcher opens and moves chats (AV-069)', (
    tester,
  ) async {
    final connection = await _pump(
      tester,
      _state(
        chat: _chatWith([
          ToolCallResponsePart(
            toolCall: _call(
              'task',
              'task',
              content: const [
                ToolResultSubagentContent(
                  resource: _worker,
                  title: 'Explorer',
                  description: 'Explore the repository',
                ),
              ],
            ),
          ),
        ]),
        sessionState: _session(chats: const [_mainSummary, _workerSummary]),
        otherChats: {
          _worker: ChannelMirror.snapshot(
            ChatState(
              resource: _worker,
              title: 'Explorer',
              status: SessionStatus.idle,
              modifiedAt: '2026-10-01T00:00:00Z',
              interactivity: ChatInteractivity.readOnly,
              turns: [
                Turn(
                  id: 'w1',
                  message: userMessage('Explore the repository'),
                  state: TurnState.complete,
                  responseParts: const [
                    MarkdownResponsePart(id: 'm', content: 'Found 3 modules.'),
                  ],
                ),
              ],
            ),
          ),
        },
      ),
    );
    expect(find.widgetWithText(ChoiceChip, 'Explorer (read-only)'), findsOne);
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    expect(connection.subscribed, contains(_worker));
    expect(find.text('Found 3 modules.'), findsOneWidget);
    expect(find.text('This chat is read-only.'), findsOneWidget);
    expect(find.byTooltip('Send'), findsNothing);

    await tester.tap(find.byTooltip('Chat actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move left'));
    await tester.pumpAndSettle();
    final (chat, destination) = connection.moved.single;
    expect(chat, _worker);
    expect(destination, const ChatMoveToSessionDestination(session: 'pi:/1'));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Fix login'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send'), findsOneWidget);
  });

  testWidgets('a completed turn forks the chat into a new one (AV-144)', (
    tester,
  ) async {
    const forking = RootState(
      agents: [
        AgentInfo(
          provider: 'pi',
          displayName: 'Pi',
          description: 'Pi',
          models: [],
          capabilities: AgentCapabilities(
            multipleChats: MultipleChatsCapability(fork: true),
          ),
        ),
      ],
    );
    final reply = _chatWith(const [
      MarkdownResponsePart(id: 'm', content: 'Done.'),
    ]);
    final session = _session(chats: const [_mainSummary]);
    final connection = await _pump(
      tester,
      _state(chat: reply, sessionState: session, root: forking),
    );
    connection.forkedState = (fork) => _state(
      chat: reply,
      root: forking,
      sessionState: session.copyWith(
        chats: [
          _mainSummary,
          ChatSummary(
            resource: fork,
            title: 'Fix login (fork)',
            status: SessionStatus.idle,
            modifiedAt: '2026-10-01T00:00:00Z',
            origin: const ChatOriginFork(chat: _chat, turnId: 't1'),
          ),
        ],
      ),
      otherChats: {
        fork: ChannelMirror.snapshot(
          reply.copyWith(resource: fork, title: 'Fix login (fork)'),
        ),
      },
    );
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.byTooltip(forkTooltip));
    await tester.pumpAndSettle();

    final (sessionUri, fork, source, turn) = connection.forked.single;
    expect((sessionUri, source, turn), ('pi:/1', _chat, 't1'));
    expect(fork, startsWith('ahp-chat:/'));
    // The fork is open, with the source's turns.
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Fix login (fork)'),
    );
    expect(chip.selected, isTrue);
    expect(connection.subscribed, contains(fork));
    expect(find.text('Done.'), findsOneWidget);
  });

  testWidgets('no fork button when the agent cannot fork (AV-144)', (
    tester,
  ) async {
    await _pump(
      tester,
      _state(
        chat: _chatWith(const [MarkdownResponsePart(id: 'm', content: 'Ok')]),
        sessionState: _session(),
        root: const RootState(
          agents: [
            AgentInfo(
              provider: 'pi',
              displayName: 'Pi',
              description: 'Pi',
              models: [],
            ),
          ],
        ),
      ),
    );
    expect(find.byTooltip('Copy as markdown'), findsOneWidget);
    expect(find.byTooltip(forkTooltip), findsNothing);
  });

  testWidgets('a 0.9.0 host cannot move chats', (tester) async {
    await _pump(
      tester,
      _state(
        chat: _chatWith(const []),
        version: '0.9.0',
        sessionState: _session(chats: const [_mainSummary, _workerSummary]),
        otherChats: {
          _worker: ChannelMirror.snapshot(
            const ChatState(
              resource: _worker,
              title: 'Explorer',
              status: SessionStatus.idle,
              modifiedAt: '2026-10-01T00:00:00Z',
              turns: [],
            ),
          ),
        },
      ),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Explorer (read-only)'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Chat actions'), findsNothing);
  });

  testWidgets('queued messages are edited, reordered and removed (AV-081)', (
    tester,
  ) async {
    reduceMotion(tester);
    final connection = await _pump(
      tester,
      _state(
        chat: _chatWith(const [], active: true).copyWith(
          queuedMessages: [
            PendingMessage(id: 'q1', message: userMessage('first')),
            PendingMessage(id: 'q2', message: userMessage('second')),
          ],
        ),
      ),
    );
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);

    await tester.tap(find.byTooltip('Message actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move up'));
    await tester.pumpAndSettle();
    expect(connection.dispatched.last.$2, {
      'type': 'chat/queuedMessagesReordered',
      'order': ['q2', 'q1'],
    });

    await tester.tap(find.byTooltip('Message actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Edit message'),
      'first, edited',
    );
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    final edited = connection.dispatched.last.$2;
    expect(edited['type'], 'chat/pendingMessageSet');
    expect(edited['id'], 'q1');
    expect((edited['message']! as JsonMap)['text'], 'first, edited');

    await tester.tap(find.byTooltip('Message actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(connection.dispatched.last.$2, {
      'type': 'chat/pendingMessageRemoved',
      'kind': 'queued',
      'id': 'q1',
    });
  });

  testWidgets('"Send now" stops the turn and runs a queued message (AV-081)', (
    tester,
  ) async {
    reduceMotion(tester);
    final connection = await _pump(
      tester,
      _state(
        chat: _chatWith(const [], active: true).copyWith(
          queuedMessages: [
            PendingMessage(id: 'q1', message: userMessage('first')),
          ],
        ),
      ),
    );
    await tester.tap(find.byTooltip('Send now'));
    await tester.pumpAndSettle();
    final actions = [for (final (_, action) in connection.dispatched) action];
    expect(
      [for (final a in actions) a['type']],
      ['chat/pendingMessageRemoved', 'chat/turnCancelled', 'chat/turnStarted'],
    );
    expect(actions[0], {
      'type': 'chat/pendingMessageRemoved',
      'kind': 'queued',
      'id': 'q1',
    });
    expect(actions[1]['turnId'], 't1');
    expect(actions[2]['message'], {
      'text': 'first',
      'origin': {'kind': 'user'},
    });
  });

  testWidgets('drafts are shown, synced and cleared on send', (tester) async {
    final connection = await _pump(
      tester,
      _state(
        chat: _chatWith(const []).copyWith(draft: userMessage('half typed')),
      ),
    );
    expect(find.widgetWithText(TextField, 'half typed'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'half typed, more');
    await tester.pump(const Duration(seconds: 1));
    final synced = connection.dispatched.last.$2;
    expect(synced['type'], 'chat/draftChanged');
    expect((synced['draft']! as JsonMap)['text'], 'half typed, more');

    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(connection.types.reversed.take(2), [
      'chat/draftChanged',
      'chat/turnStarted',
    ]);
    expect(connection.dispatched.last.$2.containsKey('draft'), isFalse);
  });

  testWidgets('a working chat ends the timeline with a typing indicator', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final working = _chatWith(const [
      MarkdownResponsePart(id: 'm', content: 'Looking'),
    ], active: true).copyWith(activity: 'Reading files');
    final connection = await _pump(
      tester,
      _state(chat: working),
      settle: false,
    );
    expect(find.byType(WorkingIndicatorRow), findsOneWidget);
    expect(find.text('Reading files'), findsWidgets);
    expect(
      find.bySemanticsLabel('Agent is working: Reading files'),
      findsOneWidget,
    );
    // It is the newest row, so it shows below the streamed reply.
    expect(
      tester.getTopLeft(find.byType(WorkingIndicatorRow)).dy,
      greaterThan(tester.getTopLeft(find.text('Looking')).dy),
    );
    // The dots pulse.
    final firstDot = find.descendant(
      of: find.byType(WorkingIndicatorRow),
      matching: find.byType(Opacity),
    );
    final before = tester.widget<Opacity>(firstDot.first).opacity;
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<Opacity>(firstDot.first).opacity, isNot(before));

    // The turn ends: the indicator goes away.
    connection.state = _state(chat: chatFixture(active: false));
    await tester.pumpAndSettle();
    expect(find.byType(WorkingIndicatorRow), findsNothing);
    semantics.dispose();
  });

  testWidgets('with reduced motion the indicator is a static ellipsis', (
    tester,
  ) async {
    reduceMotion(tester);
    await _pump(tester, _state(chat: _chatWith(const [], active: true)));
    expect(find.text('…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WorkingIndicatorRow),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Agent is working'), findsOneWidget);
  });

  testWidgets('older turns are paged in from the top (AV-068)', (tester) async {
    final connection = await _pump(
      tester,
      _state(chat: chatFixture(active: false).copyWith(turnsNextCursor: 'c1')),
    );
    expect(connection.loadedOlder, [_chat]);
    expect(find.text('Loading older turns…'), findsOneWidget);
  });

  testWidgets('the review pane lists files, reviews and runs operations', (
    tester,
  ) async {
    final connection = await _pump(
      tester,
      _state(
        chat: _chatWith(const []),
        sessionState: _session(
          changesets: const [
            Changeset(
              label: 'Session changes',
              uriTemplate: _changeset,
              changeKind: 'session',
              capabilities: ChangesetCapabilities(review: {}),
            ),
          ],
        ),
        changesets: {
          _changeset: ChannelMirror.snapshot(
            const ChangesetState(
              status: ChangesetStatus.ready,
              files: [
                ChangesetFile(
                  id: 'file:///src/app/README.md',
                  edit: FileEdit(
                    before: FileEditSide(
                      uri: 'file:///src/app/README.md',
                      content: ContentRef(uri: 'c:/b'),
                    ),
                    after: FileEditSide(
                      uri: 'file:///src/app/README.md',
                      content: ContentRef(uri: 'c:/a'),
                    ),
                    diff: FileEditDiffStats(added: 3, removed: 1),
                  ),
                ),
              ],
              operations: [
                ChangesetOperation(
                  id: 'commit',
                  label: 'Commit',
                  scopes: [ChangesetOperationScope.changeset],
                  confirmation: PlainString('Commit all changes?'),
                  status: ChangesetOperationStatus.idle,
                ),
                ChangesetOperation(
                  id: 'revert',
                  label: 'Revert',
                  scopes: [ChangesetOperationScope.resource],
                  status: ChangesetOperationStatus.idle,
                ),
              ],
            ),
          ),
        },
      ),
    );
    await tester.tap(find.byType(ReviewPaneToggle));
    await tester.pumpAndSettle();
    expect(connection.subscribed, contains(_changeset));
    expect(find.text('Files changed'), findsOneWidget);
    expect(find.text('1 file · +3 −1'), findsOneWidget);
    expect(find.text('Reviewed 0 of 1'), findsOneWidget);
    expect(find.text('Modified · +3 −1'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(connection.dispatched.last.$1, _changeset);
    expect(connection.dispatched.last.$2, {
      'type': 'changeset/filesReviewChanged',
      'files': ['file:///src/app/README.md'],
      'reviewed': true,
    });

    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();
    expect(find.text('Commit all changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Commit').last);
    await tester.pumpAndSettle();
    expect(connection.invoked.single.$2, 'commit');
    expect(find.text('Ran commit.'), findsOneWidget);

    await tester.tap(find.byTooltip('File actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revert'));
    await tester.pumpAndSettle();
    expect(connection.invoked.last.$2, 'revert');
    expect(
      connection.invoked.last.$3,
      const ChangesetOperationTargetResource(
        resource: 'file:///src/app/README.md',
      ),
    );
  });

  testWidgets('the wide review pane starts closed, toggles from its button '
      'and shortcut, and is remembered', (tester) async {
    reduceMotion(tester);
    final prefs = MemoryPrefsStore();
    final state = _state(
      chat: _chatWith(const []),
      sessionState: _session(
        changesets: const [
          Changeset(
            label: 'Session changes',
            uriTemplate: _changeset,
            changeKind: 'session',
          ),
        ],
      ),
    );
    await _pump(tester, state, prefs: prefs, settle: false);
    expect(find.byType(ChangesPane), findsNothing);
    final showTooltip = reviewToggleTooltip(
      open: false,
      shortcut: 'Ctrl+Alt+B',
    );
    expect(find.byTooltip(showTooltip), findsOneWidget);

    await tester.tap(find.byTooltip(showTooltip));
    // Reduced motion: open at once.
    await tester.pump();
    expect(find.byType(ChangesPane), findsOneWidget);
    expect(
      tester.getSize(find.byType(CollapsibleReviewPane)).width,
      defaultReviewPaneWidth + 1,
    );
    expect(prefs.values['review_pane_open'], 'true');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.byType(ChangesPane), findsNothing);
    expect(prefs.values['review_pane_open'], 'false');

    // Opened again, it is open on the next start.
    await tester.tap(find.byTooltip(showTooltip));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, state, prefs: prefs, settle: false);
    expect(find.byType(ChangesPane), findsOneWidget);
  });

  testWidgets('the wide review pane slides open', (tester) async {
    await _pump(tester, _state(chat: _chatWith(const [])));
    await tester.tap(find.byType(ReviewPaneToggle));
    await tester.pump();
    await tester.pump(reviewPaneAnimation ~/ 2);
    final width = tester.getSize(find.byType(CollapsibleReviewPane)).width;
    expect(width, greaterThan(0));
    expect(width, lessThan(defaultReviewPaneWidth + 1));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(CollapsibleReviewPane)).width,
      defaultReviewPaneWidth + 1,
    );
  });

  testWidgets('medium layouts show the review as a tab', (tester) async {
    await _pump(
      tester,
      _state(
        chat: _chatWith(const []),
        sessionState: _session(
          changesets: const [
            Changeset(
              label: 'Session changes',
              uriTemplate: _changeset,
              changeKind: 'session',
            ),
          ],
        ),
      ),
      size: const Size(1000, 900),
    );
    expect(find.widgetWithText(Tab, 'Files changed'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Files changed'));
    // The changeset is still loading, and its spinner never settles.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  group('file paths in replies (AV-106)', () {
    final reply = _chatWith(const [
      MarkdownResponsePart(
        id: 'm',
        content: 'I fixed the bug in `lib/login.dart:2`.',
      ),
    ]);
    final replyText = find.descendant(
      of: find.byType(MarkdownText),
      matching: find.textContaining('I fixed', findRichText: true),
    );

    testWidgets('open in the wide side pane, relative to the working '
        'directory, and close back to the changes', (tester) async {
      reduceMotion(tester);
      final connection = await _pump(tester, _state(chat: reply));
      connection.contents['file:///src/app/lib/login.dart'] =
          'import "x";\nvoid login() {}\n';
      expect(find.byType(FileViewer), findsNothing);

      await _tapText(tester, replyText, 'lib/login.dart:2');
      await tester.pumpAndSettle();

      expect(find.byType(FileViewer), findsOneWidget);
      expect(find.byType(ChangesPane), findsNothing);
      expect(find.text('lib/login.dart'), findsOneWidget);
      expect(find.text('L2'), findsOneWidget);
      expect(
        find.textContaining('void login()', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close file'));
      await tester.pumpAndSettle();
      expect(find.byType(FileViewer), findsNothing);
      expect(find.byType(ChangesPane), findsOneWidget);
    });

    testWidgets('open on a page of their own on medium layouts', (
      tester,
    ) async {
      final connection = await _pump(
        tester,
        _state(chat: reply),
        size: const Size(1000, 900),
      );
      connection.contents['file:///src/app/lib/login.dart'] = 'void a() {}\n';

      await _tapText(tester, replyText, 'lib/login.dart:2');
      await tester.pumpAndSettle();

      expect(find.byType(FileViewerPage), findsOneWidget);
      expect(
        find.textContaining('void a()', findRichText: true),
        findsOneWidget,
      );
    });
  });

  testWidgets('session details list directories, customizations and tools', (
    tester,
  ) async {
    final connection = await _pump(
      tester,
      _state(chat: _chatWith(const []), sessionState: _session()),
    );
    await tester.tap(find.byTooltip('Session actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Session details'));
    await tester.pumpAndSettle();
    expect(find.text('/src/app'), findsOneWidget);
    expect(find.text('Example Docs'), findsOneWidget);
    expect(find.text('mcpServer · Starting (blocking)'), findsOneWidget);
    expect(find.text('Bash'), findsOneWidget);
    expect(find.text('VS Code'), findsOneWidget);
    await tester.tap(find.text('Continue in background'));
    await tester.pump();
    expect(connection.dispatched.last.$1, 'pi:/1');
    expect(connection.dispatched.last.$2, {
      'type': 'session/mcpServerBackgroundRequested',
      'id': 'docs',
    });
  });

  testWidgets('canvases show as chips on 1.0.0 only', (tester) async {
    final chat = _chatWith(const [])
        .copyWith(canvases: const [CanvasReference(resource: 'ahp-canvas:/c')]);
    final canvas = {
      'ahp-canvas:/c': ChannelMirror.snapshot(
        const CanvasState(
          instanceId: 'c',
          extensionId: 'e',
          canvasId: 'web',
          title: 'App preview',
        ),
      ),
    };
    await _pump(tester, _state(chat: chat, canvases: canvas));
    await openSessionDetails(tester);
    expect(find.text('App preview'), findsOneWidget);
  });

  testWidgets('a 0.9.0 host shows no canvases', (tester) async {
    final chat = _chatWith(const [])
        .copyWith(canvases: const [CanvasReference(resource: 'ahp-canvas:/c')]);
    await _pump(tester, _state(chat: chat, version: '0.9.0'));
    await openSessionDetails(tester);
    expect(find.byIcon(Icons.web_asset), findsNothing);
  });

  testWidgets('the turn rail jumps to turns, follows the scroll and steps '
      'with the keyboard (AV-074)', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _state(chat: _longChat(12)));
    expect(find.byType(TurnRail), findsOneWidget);
    // One button per turn, labelled with the message's first line.
    final first = find.bySemanticsLabel('Turn 1: Question 0');
    expect(first, findsOneWidget);
    expect(
      find.bySemanticsLabel('Turn 2: Question 1 (failed)'),
      findsOneWidget,
    );
    // The oldest turn is far above, never built.
    expect(find.text('Question 0\nwith details'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Turn 12: Question 11')),
      isSemantics(isSelected: true),
    );

    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(_atTop(tester, 'Question 0\nwith details'), isTrue);
    expect(tester.getSemantics(first), isSemantics(isSelected: true));

    await _ctrlAlt(tester, LogicalKeyboardKey.arrowDown);
    expect(_atTop(tester, 'Question 1\nwith details'), isTrue);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Turn 2: Question 1 (failed)')),
      isSemantics(isSelected: true),
    );
    await _ctrlAlt(tester, LogicalKeyboardKey.arrowUp);
    expect(_atTop(tester, 'Question 0\nwith details'), isTrue);

    // Scrolling by hand moves the highlight.
    await tester.drag(find.byType(SuperListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(first), isNot(isSemantics(isSelected: true)));
    semantics.dispose();
  });

  testWidgets('stepping back past the oldest loaded turn pages older turns '
      'in and jumps to them (AV-074)', (tester) async {
    reduceMotion(tester);
    final connection = await _pump(
      tester,
      _state(chat: _longChat(3, from: 3, cursor: 'c1')),
    );
    expect(connection.loadedOlder, isEmpty);
    connection.olderState = _state(chat: _longChat(6));
    await tester.tap(find.byTooltip('Load older turns'));
    await tester.pumpAndSettle();
    expect(connection.loadedOlder, [_chat]);
    // The newest of the paged-in turns is at the top.
    expect(_atTop(tester, 'Question 2\nwith details'), isTrue);
    expect(find.byTooltip('Load older turns'), findsNothing);
  });

  testWidgets(
    'with a pointer the rail is always shown on the left (AV-074)',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _state(chat: _longChat(12)));
      expect(
        find.ancestor(
          of: find.byType(TurnRail),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Turn 1: Question 0'), findsOneWidget);
      expect(tester.getSize(find.byType(TurnRail)).width, 16);
      final list = tester.getRect(find.byType(SuperListView));
      // Clear of the scrollbar on the right.
      expect(tester.getTopLeft(find.byType(TurnRail)).dx, list.left);
      semantics.dispose();
    },
  );

  testWidgets('a chat with one turn has no turn rail (AV-074)', (tester) async {
    await _pump(tester, _state(chat: chatFixture(active: false)));
    expect(find.byType(TurnRail), findsNothing);
  });

  testWidgets('the compact rail scrubs by dragging (AV-074)', (tester) async {
    await _pump(
      tester,
      _state(chat: _longChat(12)),
      size: const Size(400, 800),
    );
    expect(tester.getSize(find.byType(TurnRail)).width, 14);
    final rail = find.byType(TurnRail);
    final top = tester.getTopLeft(rail);
    final bottom = tester.getBottomLeft(rail);
    final center = tester.getCenter(rail);
    // Drag from the bottom of the dots to near the top.
    await tester.dragFrom(
      Offset(center.dx, (top.dy + bottom.dy) / 2 + 100),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(_atTop(tester, 'Question 0\nwith details'), isTrue);
  });

  testWidgets(
    'scrolling past the oldest row pages older turns in, also '
    'with bouncing physics (AV-068)',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      final connection = await _pump(
        tester,
        _state(chat: _longChat(3, from: 3, cursor: 'c1')),
      );
      expect(connection.loadedOlder, isEmpty);
      // Overscrolled far past the top, the "load older" row is never built.
      await tester.drag(find.byType(SuperListView), const Offset(0, 30000));
      await tester.pump();
      expect(connection.loadedOlder, isNotEmpty);
      await tester.pumpAndSettle();
    },
  );

  group('session header (AV-094)', () {
    testWidgets('the title and a "…" menu with the details and actions', (
      tester,
    ) async {
      await _pump(
        tester,
        _state(chat: _chatWith(const []), sessionState: _session()),
      );
      // Only the title shows; the details are in the menu.
      expect(find.text('/src/app'), findsNothing);
      expect(find.byType(StatusBadgeChip), findsNothing);
      await tester.tap(find.byTooltip('Session actions'));
      await tester.pumpAndSettle();
      for (final item in [
        'pi',
        '/src/app',
        'Idle',
        'Details…',
        'Rename…',
        'Archive',
        'Mark unread',
        'Pin to top',
        'Session details',
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      await tester.tap(find.text('Details…'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      expect(find.byType(StatusBadgeChip), findsOneWidget);
    });

    testWidgets('a failed turn and MCP servers that need attention stay in '
        'view', (tester) async {
      final session = _session();
      await _pump(
        tester,
        _state(
          chat: _chatWith(const []).copyWith(status: SessionStatus(33 | 2)),
          sessionState: session.copyWith(
            customizations: const [
              McpServerCustomization(
                id: 'docs',
                uri: 'file:///src/app/.mcp.json',
                name: 'Example Docs',
                state: McpServerErrorState(
                  error: ErrorInfo(errorType: 'crash', message: 'Exited'),
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.byTooltip('The last turn failed'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Example Docs'), findsOneWidget);
    });
  });
}
