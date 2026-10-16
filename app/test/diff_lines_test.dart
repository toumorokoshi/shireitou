import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/diff_lines.dart';

void main() {
  const before = '# Fake project\n\nOld intro.\n\n## Usage\n\nRun it.\n';
  const after =
      '# Fake project\n\nA scripted host for tests.\nIt asks for approvals.\n'
      'It edits this file.\n\n## Usage\n\nRun it.\n';

  test('diffLines marks added and removed lines and numbers them', () {
    final lines = diffLines(before, after);
    expect(lines.map((l) => '$l').toList(), [
      ' # Fake project',
      ' ',
      '-Old intro.',
      '+A scripted host for tests.',
      '+It asks for approvals.',
      '+It edits this file.',
      ' ',
      ' ## Usage',
      ' ',
      ' Run it.',
    ]);
    expect(diffStats(lines), (added: 3, removed: 1));
    expect(lines[2].oldNumber, 3);
    expect(lines[2].newNumber, isNull);
    expect(lines[5].newNumber, 5);
    expect(lines.last.oldNumber, 7);
    expect(lines.last.newNumber, 9);
  });

  test('creations, deletions and identical files', () {
    expect(diffLines('', 'a\nb').map((l) => '$l'), ['+a', '+b']);
    expect(diffLines('a\nb\n', '').map((l) => '$l'), ['-a', '-b']);
    expect(diffStats(diffLines('x\ny', 'x\ny')), (added: 0, removed: 0));
  });

  test('several changes in a long file', () {
    final old = [for (var i = 0; i < 40; i++) 'line $i'];
    final next = [...old]
      ..[5] = 'changed 5'
      ..removeAt(30)
      ..insert(33, 'new line');
    final lines = diffLines(old.join('\n'), next.join('\n'));
    expect(diffStats(lines), (added: 2, removed: 2));
    final chunks = diffChunks(lines);
    expect(chunks.map((c) => c.runtimeType.toString()), [
      'ShownLines',
      'CollapsedLines',
      'ShownLines',
      'CollapsedLines',
    ]);
    expect(chunks.first.lines.first.text, 'line 0');
    // Every line is in exactly one chunk.
    expect(chunks.expand((c) => c.lines).toList(), lines);
  });

  test('sideBySideRows pairs removed and added lines', () {
    final rows = sideBySideRows(diffLines('a\nb\nc', 'a\nB\nX\nc'));
    expect(rows.map((r) => '${r.left?.text}|${r.right?.text}'), [
      'a|a',
      'b|B',
      'null|X',
      'c|c',
    ]);
  });
}
