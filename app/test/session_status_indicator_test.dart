import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_list/session_status_indicator.dart';
import 'package:shireitou/src/theme/app_theme.dart';

import 'fixtures.dart';

ThemeData _theme() => buildTheme(defaultTheme(Brightness.dark));

void main() {
  group('isSessionWorking', () {
    test('in progress without input', () {
      expect(isSessionWorking(status: const SessionStatus(8 | 32)), isTrue);
    });

    test('input needed is not working', () {
      expect(isSessionWorking(status: SessionStatus.inputNeeded), isFalse);
    });

    test('active turn counts when status is not in progress', () {
      expect(
        isSessionWorking(status: const SessionStatus(33), hasActiveTurn: true),
        isTrue,
      );
    });

    test('background work counts after the turn ended', () {
      expect(
        isSessionWorking(
          status: const SessionStatus(33),
          hasBackgroundWork: true,
        ),
        isTrue,
      );
      expect(
        isSessionWorking(
          status: SessionStatus.inputNeeded,
          hasBackgroundWork: true,
        ),
        isFalse,
      );
    });

    test('idle with no active turn', () {
      expect(isSessionWorking(status: const SessionStatus(33)), isFalse);
    });
  });

  testWidgets('working status shows a spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionStatusLeading(status: const SessionStatus(8 | 32)),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('idle status shows the dot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionStatusLeading(status: const SessionStatus(33)),
        ),
      ),
    );
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('with reduced motion the spinner is a static icon', (
    tester,
  ) async {
    reduceMotion(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionStatusLeading(status: const SessionStatus(8 | 32)),
        ),
      ),
    );
    expect(find.byIcon(Icons.autorenew), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('header icon announces Working', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionWorkingIcon(
            size: 18,
            color: _theme().extension<AppColors>()!.statusColors.running,
            semanticLabel: 'Working',
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(SessionWorkingIcon)),
      matchesSemantics(label: 'Working'),
    );
  });

  group('workingStatusTooltip', () {
    ChatState chatWith({
      SessionStatus status = const SessionStatus(8 | 32),
      String? activity,
      ActiveTurn? activeTurn,
      List<BackgroundWork>? backgroundWork,
    }) => chatFixture(active: false).copyWith(
      status: status,
      activity: activity,
      activeTurn: activeTurn,
      backgroundWork: backgroundWork,
    );

    ActiveTurn turnWith(List<ResponsePart> parts) => ActiveTurn(
      id: 't1',
      message: userMessage('hi'),
      startedAt: '2026-11-21T00:00:00Z',
      responseParts: parts,
    );

    test('falls back to Working when no details are available', () {
      expect(workingStatusTooltip(), 'Working');
    });

    test('shows Thinking when active turn has reasoning or is empty', () {
      expect(
        workingStatusTooltip(
          chats: [
            chatWith(
              activeTurn: turnWith([
                const ReasoningResponsePart(id: 'r1', content: 'hmm...'),
              ]),
            ),
          ],
        ),
        'Thinking',
      );
      expect(
        workingStatusTooltip(chats: [chatWith(activeTurn: turnWith(const []))]),
        'Thinking',
      );
    });

    test('shows Responding when active turn is streaming markdown', () {
      expect(
        workingStatusTooltip(
          chats: [
            chatWith(
              activeTurn: turnWith([
                const ReasoningResponsePart(id: 'r1', content: 'hmm...'),
                const MarkdownResponsePart(id: 'm1', content: 'Here is...'),
              ]),
            ),
          ],
        ),
        'Responding',
      );
    });

    test('lists foreground running tools', () {
      const running = ToolCallResponsePart(
        toolCall: ToolCallRunningState(
          toolCallId: 'tc1',
          toolName: 'bash',
          displayName: 'Bash',
          invocationMessage: PlainString('Running npm test'),
          confirmed: ToolCallConfirmationReason.notNeeded,
        ),
      );
      const completed = ToolCallResponsePart(
        toolCall: ToolCallCompletedState(
          toolCallId: 'tc0',
          toolName: 'read',
          displayName: 'Read',
          invocationMessage: PlainString('Read a.dart'),
          pastTenseMessage: PlainString('Read a.dart'),
          confirmed: ToolCallConfirmationReason.notNeeded,
          success: true,
        ),
      );
      expect(
        workingStatusTooltip(
          chats: [
            chatWith(activeTurn: turnWith([completed, running])),
          ],
        ),
        'Running npm test',
      );
    });

    test('lists multiple foreground tools and background tasks together', () {
      const tool1 = ToolCallResponsePart(
        toolCall: ToolCallRunningState(
          toolCallId: 'tc1',
          toolName: 'read',
          displayName: 'Read',
          invocationMessage: PlainString('Reading a.dart'),
          confirmed: ToolCallConfirmationReason.notNeeded,
        ),
      );
      const tool2 = ToolCallResponsePart(
        toolCall: ToolCallStreamingState(
          toolCallId: 'tc2',
          toolName: 'bash',
          displayName: 'Bash',
        ),
      );
      const bg1 = BackgroundShellWork(
        id: 'w1',
        label: 'dev server',
        startedAt: '2026-11-21T00:00:00Z',
        command: 'npm run dev',
      );
      const bg2 = BackgroundSubagentWork(
        id: 'w2',
        label: 'Explore',
        startedAt: '2026-11-21T00:00:00Z',
        chat: 'ahp-chat:/sub',
      );
      expect(
        workingStatusTooltip(
          chats: [
            chatWith(
              activeTurn: turnWith([tool1, tool2]),
              backgroundWork: const [bg1, bg2],
            ),
          ],
        ),
        'Foreground:\n'
        '• Reading a.dart\n'
        '• Bash\n'
        'Background:\n'
        '• Shell: dev server\n'
        '• Subagent: Explore',
      );
    });

    test('lists background tasks when foreground is idle', () {
      const bg = BackgroundShellWork(
        id: 'w1',
        label: 'npm test',
        startedAt: '2026-11-21T00:00:00Z',
        command: 'npm test',
      );
      expect(
        workingStatusTooltip(
          chats: [
            chatWith(
              status: const SessionStatus(33),
              backgroundWork: const [bg],
            ),
          ],
        ),
        'Background:\n• Shell: npm test',
      );
    });

    test('uses summary activity and background count when unmirrored', () {
      final summary = SessionSummary(
        provider: 'pi',
        title: 'Test',
        status: const SessionStatus(8 | 32),
        activity: 'Running tests',
        resource: 'pi:/1',
        createdAt: '2026-11-21T00:00:00Z',
        modifiedAt: '2026-11-21T00:00:00Z',
        meta: const {backgroundWorkMetaKey: 2},
      );
      expect(
        workingStatusTooltip(summary: summary),
        'Foreground:\n'
        '• Running tests\n'
        'Background:\n'
        '• 2 background tasks',
      );
    });
  });

  test('workingStatusTooltipForSession reads mirrored chats in HostState', () {
    final summary = SessionSummary(
      provider: 'pi',
      title: 'Test',
      status: const SessionStatus(8 | 32),
      resource: 'pi:/1',
      defaultChat: 'ahp-chat:/1',
      createdAt: '2026-11-21T00:00:00Z',
      modifiedAt: '2026-11-21T00:00:00Z',
    );
    final state = HostState(
      sessions: {'pi:/1': summary},
      chatChannels: {
        'ahp-chat:/1': ChannelMirror.snapshot(
          chatFixture(active: false).copyWith(
            status: const SessionStatus(8 | 32),
            activeTurn: ActiveTurn(
              id: 't1',
              message: userMessage('hi'),
              startedAt: '2026-11-21T00:00:00Z',
              responseParts: const [
                ReasoningResponsePart(id: 'r1', content: 'thinking'),
              ],
            ),
            backgroundWork: const [
              BackgroundShellWork(
                id: 'w1',
                label: 'watch',
                startedAt: '2026-11-21T00:00:00Z',
                command: 'npm run watch',
              ),
            ],
          ),
        ),
      },
    );
    expect(
      workingStatusTooltipForSession(state, summary),
      'Foreground:\n• Thinking\nBackground:\n• Shell: watch',
    );
  });

  testWidgets('SessionStatusLeading uses custom workingTooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: const Scaffold(
          body: SessionStatusLeading(
            status: SessionStatus(8 | 32),
            workingTooltip: 'Background:\n• Shell: dev',
          ),
        ),
      ),
    );
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Background:\n• Shell: dev');
  });
}
