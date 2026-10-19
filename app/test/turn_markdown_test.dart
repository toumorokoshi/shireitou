import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/turn_markdown.dart';

import 'fixtures.dart';

Turn _turn(List<ResponsePart> parts) => Turn(
  id: 't',
  message: userMessage('hi'),
  state: TurnState.complete,
  responseParts: parts,
);

void main() {
  test('a turn copies as markdown without its reasoning (AV-071)', () {
    expect(
      turnMarkdown(chatFixture().turns.single),
      'Ran `ls`\n\nThere is **one** file.',
    );
  });

  test('failed and cancelled calls, errors, notes and resources', () {
    final markdown = turnMarkdown(
      _turn(const [
        MarkdownResponsePart(id: 'a', content: 'Trying.\n'),
        MarkdownResponsePart(id: 'empty', content: '  '),
        ToolCallResponsePart(
          toolCall: ToolCallCompletedState(
            toolCallId: 'x',
            toolName: 'bash',
            displayName: 'Bash',
            invocationMessage: PlainString('Running `make`'),
            pastTenseMessage: PlainString('Ran `make`'),
            confirmed: ToolCallConfirmationReason.notNeeded,
            success: false,
            error: ToolCallError(message: 'exit code 2'),
          ),
        ),
        ToolCallResponsePart(
          toolCall: ToolCallCancelledState(
            toolCallId: 'y',
            toolName: 'read',
            displayName: 'Read',
            invocationMessage: PlainString('Reading a.txt'),
            reason: ToolCallCancellationReason.denied,
          ),
        ),
        ErrorResponsePart(
          error: ErrorInfo(errorType: 'model', message: 'Rate limited'),
        ),
        SystemNotificationResponsePart(content: PlainString('Compacted')),
        ResourceResponsePart(uri: 'file:///work/src/main.dart'),
        ResourceResponsePart(uri: 'https://example.com/a'),
        InputRequestResponsePart(
          request: ChatInputRequest(id: 'q', message: 'Which?'),
        ),
      ]),
    );
    expect(
      markdown,
      'Trying.\n\n'
      'Ran `make`\nexit code 2\n\n'
      'Reading a.txt\nCancelled\n\n'
      'Rate limited\n\n'
      'Compacted\n\n'
      '`main.dart`\n\n'
      'https://example.com/a',
    );
  });

  group('portableMarkdown', () {
    test('keeps web, mail and relative links', () {
      const kept =
          '[a](https://x.dev) [b](mailto:a@b.c) [c](docs/a.md) [d](#top)';
      expect(portableMarkdown(kept), kept);
    });

    test('reduces host-only links and images to their label', () {
      expect(
        portableMarkdown(
          'See [main.dart](/work/main.dart#L3), '
          '[x](file:///a "t"), [*y*](C:\\a.txt), '
          '![shot](vscode-file://a.png) and [](/empty).',
        ),
        'See `main.dart`, `x`, `*y*`, `shot` and .',
      );
    });

    test('leaves code spans and fenced code alone', () {
      const code =
          '`[a](/x)` and\n\n```md\n[a](/x)\n```\n\n~~~\n[b](/y)\n~~~\nafter [c](/z)';
      expect(
        portableMarkdown(code),
        '`[a](/x)` and\n\n```md\n[a](/x)\n```\n\n~~~\n[b](/y)\n~~~\nafter `c`',
      );
    });
  });

  test('inlineCode fences past the longest backtick run', () {
    expect(inlineCode('a'), '`a`');
    expect(inlineCode('a`b'), '``a`b``');
    expect(inlineCode('`a'), '`` `a ``');
  });
}
