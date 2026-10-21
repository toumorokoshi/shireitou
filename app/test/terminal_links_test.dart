import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/terminal/terminal_links.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('linkAt', () {
    String? linked(String text, int index) =>
        linkAt(text, index)?.uri.toString();

    test('finds the http or https URL under the index', () {
      const text = 'see https://example.com/a?b=1#c and http://x.io';
      expect(linked(text, 4), 'https://example.com/a?b=1#c');
      expect(linked(text, 20), 'https://example.com/a?b=1#c');
      expect(linked(text, text.length - 1), 'http://x.io');
      expect(linkAt(text, 20)?.start, 4);
      expect(linkAt(text, 20)?.end, 31);
    });

    test('is null off a link', () {
      const text = 'see https://example.com now';
      expect(linkAt(text, 0), isNull);
      expect(linkAt(text, 3), isNull);
      expect(linkAt(text, text.length - 1), isNull);
      expect(linkAt('ftp://example.com', 2), isNull);
      expect(linkAt('https://', 2), isNull);
    });

    test('leaves out trailing punctuation and unbalanced brackets', () {
      expect(linked('go to https://x.io/a.', 8), 'https://x.io/a');
      expect(linked('(see https://x.io/a),', 8), 'https://x.io/a');
      expect(linked('https://x.io/wiki/A_(b)', 0), 'https://x.io/wiki/A_(b)');
      expect(linked('"https://x.io/a"', 3), 'https://x.io/a');
      expect(linked('<https://x.io/a>', 3), 'https://x.io/a');
      expect(linkAt('go to https://x.io/a.', 20), isNull);
    });
  });

  group('terminalLinkAt', () {
    Terminal terminal(String text, {int columns = 40}) => Terminal()
      ..resize(columns, 10)
      ..write(text);

    test('finds the link under a cell', () {
      final t = terminal('\$ open https://example.com/docs.\r\n');
      final link = terminalLinkAt(t.buffer, const CellOffset(10, 0));
      expect(link?.uri, Uri.parse('https://example.com/docs'));
      expect(link?.start, const CellOffset(7, 0));
      expect(link?.end, const CellOffset(31, 0));
      expect(terminalLinkAt(t.buffer, const CellOffset(3, 0)), isNull);
      expect(terminalLinkAt(t.buffer, const CellOffset(35, 0)), isNull);
      expect(terminalLinkAt(t.buffer, const CellOffset(3, 5)), isNull);
    });

    test('joins a URL the terminal wrapped onto the next line', () {
      const url = 'https://example.com/a/very/long/path';
      final t = terminal('x $url y', columns: 20);
      expect(t.buffer.lines[1].isWrapped, isTrue);
      for (final cell in const [CellOffset(5, 0), CellOffset(3, 1)]) {
        final link = terminalLinkAt(t.buffer, cell);
        expect(link?.uri, Uri.parse(url));
        expect(link?.start, const CellOffset(2, 0));
        expect(link?.end, const CellOffset(18, 1));
      }
    });

    test('counts wide characters as two cells', () {
      final t = terminal('日本 https://x.io/a');
      final link = terminalLinkAt(t.buffer, const CellOffset(6, 0));
      expect(link?.uri, Uri.parse('https://x.io/a'));
      expect(link?.start, const CellOffset(5, 0));
      expect(link?.end, const CellOffset(19, 0));
    });
  });
}
