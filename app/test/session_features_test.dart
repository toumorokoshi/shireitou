/// Widget tests for the timeline features and mirrored session state:
/// code blocks, grouping, terminals, diffs, the chat switcher, queued
/// messages, drafts, paging, the review pane and session details.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/app.dart';
import 'package:shireitou/src/session_detail/code_highlight.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';

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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connection = FakeHostConnection(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: hostOverrides(connection: connection),
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
}) => HostState(
  status: ConnectionStatus.connected,
  protocolVersion: version,
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
      brightness: Brightness.light,
    );
    expect(span.children, isNotEmpty);
    await tester.tap(find.byTooltip('Copy code'));
    await tester.pump();
    expect(copied, 'void main() {}');
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
    expect(find.text('app/README.md'), findsOneWidget);
    expect(find.text('+1 −1'), findsOneWidget);
    expect(find.text('old'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
    await tester.tap(find.byTooltip('Open diff'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unified view'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
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
      find.widgetWithText(TextField, 'Message'),
      'first, edited',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
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
    expect(find.text('App preview'), findsOneWidget);
  });

  testWidgets('a 0.9.0 host shows no canvases', (tester) async {
    final chat = _chatWith(const [])
        .copyWith(canvases: const [CanvasReference(resource: 'ahp-canvas:/c')]);
    await _pump(tester, _state(chat: chat, version: '0.9.0'));
    expect(find.byIcon(Icons.web_asset), findsNothing);
  });
}
