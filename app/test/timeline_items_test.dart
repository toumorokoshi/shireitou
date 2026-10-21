import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/timeline_items.dart';

import 'fixtures.dart';

void main() {
  groupingTests();

  test('timelineItems orders turns, parts, footers and the active turn', () {
    final chat = chatFixture().copyWith(
      queuedMessages: [PendingMessage(id: 'q', message: userMessage('next'))],
      activeTurn: chatFixture().activeTurn!.copyWith(
        responseParts: const [MarkdownResponsePart(id: 'empty', content: '')],
      ),
    );
    final kinds = [
      for (final item in timelineItems(chat))
        switch (item) {
          UserMessageItem() => 'user',
          ResponsePartItem(:final part, :final active) =>
            '${part.runtimeType}${active ? '*' : ''}',
          TurnFooterItem() => 'footer',
          ToolCallGroupItem() => 'group',
          StepsItem() => 'steps',
          LoadOlderItem() => 'older',
          WorkingItem() => 'working',
        },
    ];
    // The empty markdown part pi opens before streaming is hidden.
    // Reasoning and the tool call fold into the steps row (AV-095).
    expect(kinds, ['user', 'steps', 'MarkdownResponsePart', 'footer', 'user']);
    // Pending messages are listed above the input instead.
    expect(pendingMessages(chat).map((p) => (p.kind, p.pending.id)), [
      (PendingMessageKind.queued, 'q'),
    ]);
    expect(
      timelineItems(chat).whereType<UserMessageItem>().map((i) => i.startedAt),
      ['2026-10-01T00:00:00Z', '2026-10-01T00:00:00Z'],
    );
  });

  test('tool call summary, input and output', () {
    final call =
        (chatFixture().turns.single.responseParts[1] as ToolCallResponsePart)
            .toolCall;
    expect(toolCallSummary(call), 'Ran `ls`');
    expect(toolCallInputText(call), '{\n  "command": "ls"\n}');
    expect(toolCallOutputText(call), 'a.txt\n');
    expect(toolCallStatusLabel(call), 'Done');
    final streaming = ToolCallStreamingState(
      toolCallId: call.toolCallId,
      toolName: call.toolName,
      displayName: call.displayName,
      partialInput: '{"comm',
    );
    expect(toolCallSummary(streaming), 'Bash');
    expect(toolCallInputText(streaming), '{"comm');
    expect(toolCallOutputText(streaming), isNull);
  });

  test('footer, usage and model', () {
    final chat = chatFixture();
    expect(
      turnFooterText(chat.turns.single),
      'Done · 2s · 1,200 in · 30 out · m1',
    );
    expect(sessionUsage(chat), (input: 1200, output: 30));
    expect(lastModelOf(chat), 'm1');
    expect(lastModelSelection(chat), isNull);
    final picked = chat.copyWith(
      turns: [
        chat.turns.first.copyWith(
          message: userMessage(
            'hi',
            model: const ModelSelection(
              id: 'm2',
              config: {'thinkingLevel': 'high'},
            ),
          ),
        ),
      ],
      activeTurn: null,
    );
    expect(lastModelSelection(picked)?.config, {'thinkingLevel': 'high'});
  });
}

ToolCallState _done(
  String id,
  String tool, {
  List<ToolResultContent>? content,
}) => ToolCallCompletedState(
  toolCallId: id,
  toolName: tool,
  displayName: tool == 'read' ? 'Read' : 'Bash',
  invocationMessage: PlainString('$tool $id'),
  pastTenseMessage: PlainString('Did $tool $id'),
  confirmed: ToolCallConfirmationReason.notNeeded,
  success: true,
  content: content,
);

void groupingTests() {
  test('a turn folds its steps into one row (AV-095)', () {
    const blocking = ToolCallPendingConfirmationState(
      toolCallId: 'p',
      toolName: 'bash',
      displayName: 'Bash',
      invocationMessage: PlainString('Run rm'),
    );
    final parts = [
      const MarkdownResponsePart(id: 'intro', content: 'Let me look.'),
      const ReasoningResponsePart(id: 'r', content: 'hmm'),
      ToolCallResponsePart(toolCall: _done('a', 'read')),
      const MarkdownResponsePart(id: 'between', content: 'Now the tests.'),
      const ErrorResponsePart(
        error: ErrorInfo(errorType: 'x', message: 'x'),
      ),
      ToolCallResponsePart(toolCall: _done('b', 'read')),
      ToolCallResponsePart(toolCall: _done('c', 'read')),
      const ToolCallResponsePart(toolCall: blocking),
      const MarkdownResponsePart(id: 'reply', content: 'Done.'),
    ];
    final items = turnPartItems('t', parts, active: false, duration: 107000);
    // Text before the first step and after the last stays; the error and
    // the call that needs approval stay in view after the steps row.
    expect(items.map((i) => i.key), [
      't/intro',
      't/steps',
      't/#4',
      't/tool/p',
      't/reply',
    ]);
    final steps = items[1] as StepsItem;
    expect(steps.steps.map((i) => i.key), [
      't/r',
      't/tool/a',
      't/between',
      't/group/b',
    ]);
    expect(steps.count, 5);
    expect(stepsSummary(steps), 'Completed 5 steps in 1m 47s');
    // A turn without steps has no steps row.
    expect(
      turnPartItems('t', parts.sublist(7), active: false).map((i) => i.key),
      ['t/tool/p', 't/reply'],
    );
  });

  test('steps summary while working, without a duration and with failures', () {
    final failed = ToolCallCompletedState(
      toolCallId: 'f',
      toolName: 'bash',
      displayName: 'Bash',
      invocationMessage: const PlainString('false'),
      pastTenseMessage: const PlainString('Ran false'),
      confirmed: ToolCallConfirmationReason.notNeeded,
      success: false,
    );
    final parts = [
      ToolCallResponsePart(toolCall: _done('a', 'bash')),
      ToolCallResponsePart(toolCall: failed),
    ];
    StepsItem stepsOf(List<TimelineItem> items) =>
        items.whereType<StepsItem>().single;
    expect(
      stepsSummary(stepsOf(turnPartItems('t', parts, active: true))),
      'Working… 2 steps · 1 failed',
    );
    expect(
      stepsSummary(
        stepsOf(turnPartItems('t', parts.sublist(0, 1), active: false)),
      ),
      'Completed 1 step',
    );
  });

  test('steps duration is formatted in seconds, minutes and hours', () {
    expect(formatStepsDuration(400), '0s');
    expect(formatStepsDuration(12400), '12s');
    expect(formatStepsDuration(107000), '1m 47s');
    expect(formatStepsDuration(3780000), '1h 3m');
  });

  test('a working chat shows the indicator on the steps row (AV-072)', () {
    final chat = _chatOf([ToolCallResponsePart(toolCall: _done('a', 'bash'))]);
    final rows = timelineItems(chat);
    final steps = rows.last as StepsItem;
    expect(steps.working, isTrue);
    expect(steps.activity, 'Reading');
    expect(rows.whereType<WorkingItem>(), isEmpty);
    // Without steps the working row comes last as before.
    expect(timelineItems(_chatOf(const [])).last, isA<WorkingItem>());
  });

  test('consecutive calls of one tool are grouped (AV-064)', () {
    final parts = [
      for (final id in ['a', 'b', 'c'])
        ToolCallResponsePart(toolCall: _done(id, 'read')),
      ToolCallResponsePart(toolCall: _done('d', 'bash')),
      const MarkdownResponsePart(id: 'm', content: 'ok'),
      ToolCallResponsePart(toolCall: _done('e', 'read')),
      ToolCallResponsePart(
        toolCall: _done(
          'f',
          'read',
          content: const [
            ToolResultTerminalContent(resource: 't:/1', title: 't'),
          ],
        ),
      ),
    ];
    final items = partItems('t', parts, active: false);
    expect(items.map((i) => i.key), [
      't/group/a',
      't/tool/d',
      't/m',
      't/tool/e',
      't/tool/f',
    ]);
    final group = items.first as ToolCallGroupItem;
    expect(toolCallGroupSummary(group.calls), 'Read · 3 calls');
    expect(toolCallGroupStatus(group.calls), 'Done');
  });

  test('finished turns keep their rows while the active turn streams', () {
    final chat = chatFixture();
    final first = timelineItems(chat);
    final next = timelineItems(
      chat.copyWith(
        activeTurn: chat.activeTurn!.copyWith(
          responseParts: const [
            MarkdownResponsePart(id: 'x', content: 'streaming'),
          ],
        ),
      ),
    );
    expect(identical(first[1], next[1]), isTrue);
    expect(next.indexOfKey('turn-2/x'), next.length - 1);
    expect(next.indexOfKey('turn-1/footer'), 3);
    expect(next.indexOfKey('nope'), isNull);
  });

  test('a working chat ends with a working row', () {
    final idle = chatFixture(active: false);
    // In progress (bit 8) with the read flag (bit 32): bitwise, not equal.
    final working = idle.copyWith(
      status: const SessionStatus(8 | 32),
      activity: '  Reading files ',
    );
    expect(isChatWorking(idle), isFalse);
    expect(isChatWorking(working), isTrue);
    final row = timelineItems(working).last as WorkingItem;
    expect(row.activity, 'Reading files');
    expect(timelineItems(working).indexOfKey('working'), 4);
    expect(
      (timelineItems(working.copyWith(activity: ' ')).last as WorkingItem)
          .activity,
      isNull,
    );
    expect(timelineItems(idle).last, isA<TurnFooterItem>());
    // An active turn counts even before the status catches up.
    final started = chatFixture().copyWith(status: const SessionStatus(1));
    expect(timelineItems(started).last, isA<WorkingItem>());
    // Waiting on the user is not working: the request is shown instead.
    expect(isChatWorking(chatFixture()), isFalse);
  });

  test('working label and typing dot opacity', () {
    expect(workingLabel(null), 'Agent is working');
    expect(workingLabel('Reading'), 'Agent is working: Reading');
    expect(typingDotOpacity(0, 0), closeTo(0.3, 1e-9));
    expect(typingDotOpacity(0, 0.5), closeTo(1, 1e-9));
    // Each dot lags the one before it by a third of a cycle.
    expect(typingDotOpacity(1, 0.5 + 1 / 3), closeTo(1, 1e-9));
    for (var t = 0.0; t < 1; t += 0.05) {
      for (var dot = 0; dot < 3; dot++) {
        expect(typingDotOpacity(dot, t), inInclusiveRange(0.3, 1));
      }
    }
  });

  test('a windowed chat starts with a load-older row (AV-068)', () {
    final chat = chatFixture().copyWith(turnsNextCursor: 'c1');
    final rows = timelineItems(chat);
    expect(rows.first, isA<LoadOlderItem>());
    expect(rows.indexOfKey('older/c1'), 0);
    expect(rows.indexOfKey('turn-1/message'), 1);
  });

  test('previews include terminals, edits and pending edits', () {
    const edit = FileEdit(
      after: FileEditSide(
        uri: 'file:///a',
        content: ContentRef(uri: 'c:/a'),
      ),
    );
    const pending = ToolCallPendingConfirmationState(
      toolCallId: 'p',
      toolName: 'edit',
      displayName: 'Edit',
      invocationMessage: PlainString('Edit a'),
      edits: FileEditCollection(items: [edit]),
    );
    expect(toolCallPreviews(pending).single, isA<ToolResultFileEditContent>());
    expect(
      toolCallOutputText(
        _done(
          'x',
          'bash',
          content: const [
            ToolResultTextContent(text: 'out'),
            ToolResultTerminalContent(resource: 't:/1', title: 't'),
          ],
        ),
      ),
      'out',
    );
  });
}

/// A working chat whose active turn has [parts].
ChatState _chatOf(List<ResponsePart> parts) =>
    chatFixture(active: false).copyWith(
      status: const SessionStatus(8),
      activity: 'Reading',
      activeTurn: ActiveTurn(
        id: 'a',
        startedAt: '2026-10-01T00:00:00Z',
        message: userMessage('go'),
        responseParts: parts,
      ),
    );
