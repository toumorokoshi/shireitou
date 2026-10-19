import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/timeline_selection.dart';

SelectedPiece _piece(double top, double bottom, String text) =>
    (bounds: Rect.fromLTRB(0, top, 100, bottom), text: text);

void main() {
  group('joinSelectedLines', () {
    test('starts a new line for a piece below the previous one', () {
      expect(
        joinSelectedLines([
          _piece(0, 20, 'Here:'),
          _piece(30, 50, 'print("hi")'),
          _piece(60, 80, 'Done.'),
        ]),
        'Here:\nprint("hi")\nDone.',
      );
    });

    test('joins pieces on the same line, such as a bullet and its text', () {
      expect(
        joinSelectedLines([_piece(0, 10, '•'), _piece(0, 40, 'two lines')]),
        '•two lines',
      );
    });

    test('adds no newline after one, or for empty pieces', () {
      expect(
        joinSelectedLines([
          _piece(0, 20, 'out\n'),
          _piece(30, 40, ''),
          _piece(50, 60, 'next'),
        ]),
        'out\nnext',
      );
    });
  });

  group('rowWiseEdge', () {
    const size = Size(100, 50);

    test('moves a point below the box, even left of it, past its end', () {
      expect(rowWiseEdge(const Offset(-20, 80), size), const Offset(101, 51));
    });

    test('moves a point above the box, even right of it, before it', () {
      expect(rowWiseEdge(const Offset(140, -5), size), const Offset(-1, -1));
    });

    test('keeps a point beside or inside the box', () {
      expect(rowWiseEdge(const Offset(-20, 10), size), const Offset(-20, 10));
      expect(rowWiseEdge(const Offset(40, 10), size), const Offset(40, 10));
    });
  });
}
