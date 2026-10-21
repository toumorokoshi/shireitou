import 'package:xterm/xterm.dart';

/// A link in a string: the URL and the `[start, end)` code units it covers.
typedef TextLink = ({Uri uri, int start, int end});

/// A link on the terminal's screen: the URL and the cells from [start]
/// up to (not including) [end], which may span wrapped lines.
typedef TerminalLink = ({Uri uri, CellOffset start, CellOffset end});

final _url = RegExp(r'''https?://[^\s<>"'`]+''', caseSensitive: false);

const _trailingPunctuation = '.,;:!?';

const _closingBrackets = {')': '(', ']': '[', '}': '{'};

/// The `http` or `https` link in [text] that covers code unit [index],
/// if any. Trailing punctuation and unbalanced closing brackets are left
/// out, so `(see https://x.io/a.)` links `https://x.io/a`.
TextLink? linkAt(String text, int index) {
  for (final match in _url.allMatches(text)) {
    if (index < match.start) return null;
    final end = match.start + _trimmedLength(match[0]!);
    if (index >= end) continue;
    final uri = Uri.tryParse(text.substring(match.start, end));
    if (uri == null || uri.host.isEmpty) return null;
    return (uri: uri, start: match.start, end: end);
  }
  return null;
}

int _trimmedLength(String url) {
  int count(String char, int end) =>
      url.substring(0, end).split('').where((c) => c == char).length;
  bool trims(int end) {
    final last = url[end - 1];
    if (_trailingPunctuation.contains(last)) return true;
    final opener = _closingBrackets[last];
    return opener != null && count(opener, end) < count(last, end);
  }

  var end = url.length;
  while (end > 0 && trims(end)) {
    end--;
  }
  return end;
}

/// The link in [buffer] under [cell], if any. A line the terminal
/// wrapped is read with the lines it continues, so a long URL that runs
/// onto the next line is one link.
TerminalLink? terminalLinkAt(Buffer buffer, CellOffset cell) {
  final lines = buffer.lines;
  if (cell.y < 0 || cell.y >= lines.length) return null;
  var first = cell.y;
  while (first > 0 && lines[first].isWrapped) {
    first--;
  }
  var last = cell.y;
  while (last + 1 < lines.length && lines[last + 1].isWrapped) {
    last++;
  }

  final text = StringBuffer();
  // The cell of each UTF-16 code unit of `text`.
  final cells = <CellOffset>[];
  for (var y = first; y <= last; y++) {
    final line = lines[y];
    final length = line.getTrimmedLength();
    for (var x = 0; x < length; x++) {
      final codePoint = line.getCodePoint(x);
      // The second half of a wide character has no text of its own.
      if (codePoint == 0 && x > 0 && line.getWidth(x - 1) == 2) continue;
      final char = String.fromCharCode(codePoint == 0 ? 0x20 : codePoint);
      text.write(char);
      cells.addAll(List.filled(char.length, CellOffset(x, y)));
    }
  }

  final index = cells.indexOf(cell);
  if (index < 0) return null;
  final link = linkAt(text.toString(), index);
  if (link == null) return null;
  final lastCell = cells[link.end - 1];
  final width = lines[lastCell.y].getWidth(lastCell.x);
  return (
    uri: link.uri,
    start: cells[link.start],
    end: CellOffset(lastCell.x + (width < 1 ? 1 : width), lastCell.y),
  );
}
