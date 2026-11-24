import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';
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

  group('inlineCodeRanges', () {
    test(
      'finds monospace spans, merges adjacent ones, and counts placeholders',
      () {
        final span = TextSpan(
          children: [
            const TextSpan(text: 'Run '),
            const WidgetSpan(child: SizedBox(width: 10, height: 10)),
            const TextSpan(
              text: 'git',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            const TextSpan(
              text: ' status',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            const TextSpan(text: ' and '),
            const TextSpan(
              text: 'ls',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ],
        );
        expect(inlineCodeRanges(span), [
          (start: 5, end: 15),
          (start: 20, end: 22),
        ]);
      },
    );
  });

  group('InlineCodeBackground', () {
    testWidgets(
      'paints inline code background before selection highlight so dragging highlights inline code',
      (tester) async {
        const codeBg = Color(0xFF334455);
        const selectionColor = Color(0x6600AAFF);
        final theme = ThemeData.dark().copyWith(
          colorScheme: ThemeData.dark().colorScheme.copyWith(
            surfaceContainerHighest: codeBg,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: selectionColor,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: RichSelectionArea(
                child: LineSelection(
                  child: MarkdownText('Run `git status` now.'),
                ),
              ),
            ),
          ),
        );

        // Inline code spans have no TextStyle.backgroundColor (which would
        // paint over RenderParagraph's selection highlight).
        final paragraph = tester.renderObject<RenderParagraph>(
          find.byType(RichText),
        );
        final hasOpaqueCodeBg = paragraph.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontFamily == 'monospace') {
            return span.style?.backgroundColor == null;
          }
          return true;
        });
        expect(hasOpaqueCodeBg, isTrue);

        // Click and drag across the inline code snippet.
        final rect = tester.getRect(find.byType(RichText));
        final gesture = await tester.startGesture(
          rect.centerLeft + const Offset(2, 0),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await gesture.moveTo(rect.centerRight - const Offset(2, 0));
        await tester.pump();

        expect(
          find.byType(InlineCodeBackground),
          paints
            ..rrect(color: codeBg)
            ..rect(color: selectionColor),
        );

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });

  group('verticalScrollPassthroughDelta', () {
    test('returns null when dx is zero or horizontal scroll dominates', () {
      expect(
        verticalScrollPassthroughDelta(
          scrollDelta: const Offset(0, 60),
          innerPixels: 0,
          innerMinExtent: 0,
          innerMaxExtent: 100,
          innerReversed: false,
          outerReversed: true,
        ),
        isNull,
      );
      expect(
        verticalScrollPassthroughDelta(
          scrollDelta: const Offset(60, 20),
          innerPixels: 0,
          innerMinExtent: 0,
          innerMaxExtent: 100,
          innerReversed: false,
          outerReversed: true,
        ),
        isNull,
      );
    });

    test('returns null when inner scroll view is already at its edge', () {
      expect(
        verticalScrollPassthroughDelta(
          scrollDelta: const Offset(-1, 60),
          innerPixels: 0,
          innerMinExtent: 0,
          innerMaxExtent: 100,
          innerReversed: false,
          outerReversed: true,
        ),
        isNull,
      );
      expect(
        verticalScrollPassthroughDelta(
          scrollDelta: const Offset(1, 60),
          innerPixels: 100,
          innerMinExtent: 0,
          innerMaxExtent: 100,
          innerReversed: false,
          outerReversed: true,
        ),
        isNull,
      );
    });

    test('forwards vertical delta when inner consumes diagonal scroll', () {
      expect(
        verticalScrollPassthroughDelta(
          scrollDelta: const Offset(1, 60),
          innerPixels: 0,
          innerMinExtent: 0,
          innerMaxExtent: 100,
          innerReversed: false,
          outerReversed: true,
        ),
        -60,
      );
      expect(
        verticalScrollPassthroughDelta(
          scrollDelta: const Offset(1, 60),
          innerPixels: 0,
          innerMinExtent: 0,
          innerMaxExtent: 100,
          innerReversed: false,
          outerReversed: false,
        ),
        60,
      );
    });
  });

  group('HorizontalScrollPassthrough', () {
    testWidgets(
      'scrolls the outer reversed list when diagonal wheel hits overflowing child',
      (tester) async {
        final outer = ScrollController(initialScrollOffset: 300);
        addTearDown(outer.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: ListView(
                  controller: outer,
                  reverse: true,
                  children: [
                    const SizedBox(height: 400),
                    HorizontalScrollPassthrough(
                      child: SizedBox(width: 800, height: 150),
                    ),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final before = outer.offset;
        final target = tester.getCenter(
          find.byType(HorizontalScrollPassthrough),
        );
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: target,
            scrollDelta: const Offset(1, 60),
          ),
        );
        await tester.pumpAndSettle();

        expect(outer.offset, lessThan(before));
      },
    );
  });
}
