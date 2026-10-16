import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/timeline_items.dart';

import 'fixtures.dart';

void main() {
  test('timelineItems orders turns, parts, footers, active turn, pending', () {
    final chat = chatFixture().copyWith(
      queuedMessages: [PendingMessage(id: 'q', message: userMessage('next'))],
      activeTurn: chatFixture().activeTurn!.copyWith(
        responseParts: const [ResponsePart.markdown(id: 'empty', content: '')],
      ),
    );
    final kinds = [
      for (final item in timelineItems(chat))
        switch (item) {
          UserMessageItem() => 'user',
          ResponsePartItem(:final part, :final active) =>
            '${part.runtimeType}${active ? '*' : ''}',
          TurnFooterItem() => 'footer',
          PendingMessageItem(:final kind) => kind,
        },
    ];
    // The empty markdown part pi opens before streaming is hidden.
    expect(kinds, [
      'user',
      'ReasoningPart',
      'ToolCallPart',
      'MarkdownPart',
      'footer',
      'user',
      'queued',
    ]);
  });

  test('tool call summary, input and output', () {
    final call =
        (chatFixture().turns.single.responseParts[1] as ToolCallPart).toolCall;
    expect(toolCallSummary(call), 'Ran `ls`');
    expect(toolCallInputText(call), '{\n  "command": "ls"\n}');
    expect(toolCallOutputText(call), 'a.txt\n');
    expect(toolCallStatusLabel(call.status), 'Done');
    final streaming = call.copyWith(
      status: ToolCallStatus.streaming,
      toolInput: null,
      partialInput: '{"comm',
      pastTenseMessage: null,
      invocationMessage: null,
      content: null,
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
  });
}
