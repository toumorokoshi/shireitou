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
          LoadOlderItem() => 'older',
          WorkingItem() => 'working',
        },
    ];
    // The empty markdown part pi opens before streaming is hidden.
    expect(kinds, [
      'user',
      'ReasoningResponsePart',
      'ToolCallResponsePart',
      'MarkdownResponsePart',
      'footer',
      'user',
    ]);
    // Pending messages are listed above the input instead.
    expect(pendingMessages(chat).map((p) => (p.kind, p.pending.id)), [
      (PendingMessageKind.queued, 'q'),
    ]);
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
      'Done · 1.5 s · 1,200 in · 30 out · m1',
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
    expect(next.indexOfKey('turn-1/footer'), 4);
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
    expect(timelineItems(working).indexOfKey('working'), 5);
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
