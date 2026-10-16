import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/terminal_text.dart';

void main() {
  test('plainTerminalText drops escapes and applies carriage returns', () {
    expect(
      plainTerminalText('\x1B[32mok\x1B[0m\r\n10%\r50%\r100%\ndone'),
      'ok\n100%\ndone',
    );
    expect(plainTerminalText('\x1B]0;title\x07x'), 'x');
  });

  test('tailLines keeps the last lines', () {
    expect(tailLines('a\nb\nc\n', maxLines: 2), 'b\nc');
    expect(tailLines('a\nb\n'), 'a\nb');
  });

  test('terminal text and status', () {
    const terminal = TerminalState(
      title: 't',
      content: [
        TerminalCommandPart(
          commandId: 'c',
          commandLine: 'ls',
          output: '\x1B[1ma\x1B[0m\n',
          timestamp: 0,
          isComplete: true,
        ),
      ],
      lifecycle: TerminalExitedLifecycleState(exitCode: 1),
      claim: TerminalClientClaim(clientId: 'x'),
    );
    expect(terminalPlainText(terminal), '\$ ls\na\n');
    expect(terminalStatusLabel(terminal), 'Exited (1)');
  });
}
