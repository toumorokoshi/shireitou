import 'package:flutter_pty/src/command_line.dart';
import 'package:test/test.dart';

void main() {
  test('quotes Windows arguments', () {
    expect(windowsQuote('ssh'), 'ssh');
    expect(windowsQuote(''), '""');
    expect(windowsQuote('a b'), '"a b"');
    expect(windowsQuote('say "hi"'), r'"say \"hi\""');
    expect(windowsQuote(r'C:\my dir\'), r'"C:\my dir\\"');
    expect(windowsQuote(r'a\"b c'), r'"a\\\"b c"');
    expect(
      windowsQuote(r"""cd '/src/my app' 2>/dev/null; exec "$SHELL" -l"""),
      r'''"cd '/src/my app' 2>/dev/null; exec \"$SHELL\" -l"''',
    );
  });
}
