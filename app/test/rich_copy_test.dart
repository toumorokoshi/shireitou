import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/clipboard/rich_clipboard.dart';
import 'package:shireitou/src/clipboard/span_html.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';
import 'package:shireitou/src/session_detail/timeline_selection.dart';
import 'package:shireitou/src/session_detail/turn_markdown.dart';

const _url = 'https://example.com/docs?a=1&b=2';

/// Clipboard writes: rich ones (`setHtml`) and plain ones.
typedef _Copies = ({List<Map<Object?, Object?>> rich, List<String> plain});

/// Records clipboard writes; [rich] false answers the rich channel as a
/// runner without it does.
_Copies _mockClipboard(WidgetTester tester, {bool rich = true}) {
  final copies = (rich: <Map<Object?, Object?>>[], plain: <String>[]);
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copies.plain.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  messenger.setMockMethodCallHandler(richClipboardChannel, (call) async {
    if (!rich) throw MissingPluginException();
    if (call.method == 'setHtml') {
      copies.rich.add(call.arguments as Map<Object?, Object?>);
    }
    return null;
  });
  addTearDown(() {
    messenger
      ..setMockMethodCallHandler(SystemChannels.platform, null)
      ..setMockMethodCallHandler(richClipboardChannel, null);
  });
  return copies;
}

Widget _area(List<Widget> rows) => MaterialApp(
  home: Scaffold(
    body: RichSelectionArea(
      child: ListView(
        children: [for (final row in rows) LineSelection(child: row)],
      ),
    ),
  ),
);

Future<void> _select(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(
    tester.getTopLeft(from) + const Offset(1, 2),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  await gesture.moveTo(tester.getBottomRight(to) - const Offset(1, 1));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _selectAndCopy(WidgetTester tester, Finder from, Finder to) async {
  await _select(tester, from, to);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  group('spanRuns', () {
    test('keeps links, bold, italic and code, merging equal runs', () {
      final link = TapGestureRecognizer();
      addTearDown(link.dispose);
      final span = TextSpan(
        children: [
          const TextSpan(text: 'See '),
          TextSpan(text: 'the ', recognizer: link),
          TextSpan(text: 'docs', recognizer: link),
          const TextSpan(
            text: ' now',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(
            text: ' x<y',
            style: TextStyle(
              fontFamily: 'monospace',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
      final runs = spanRuns(
        span,
        0,
        span.toPlainText().length,
        hrefOf: (s) => s.recognizer == link ? _url : null,
      );
      expect(runs.map((r) => r.text), ['See ', 'the docs', ' now', ' x<y']);
      expect(
        runsHtml(runs),
        'See <a href="https://example.com/docs?a=1&amp;b=2">the docs</a>'
        '<b> now</b><i><code> x&lt;y</code></i>',
      );
    });

    test('clips to the selection and counts placeholders', () {
      const span = TextSpan(
        children: [
          TextSpan(text: 'ab'),
          WidgetSpan(child: SizedBox()),
          TextSpan(text: 'cd\nef'),
        ],
      );
      final runs = spanRuns(span, 1, 6);
      expect(runs.map((r) => r.text), ['bcd\n']);
      expect(runsHtml(runs), 'bcd<br>');
    });
  });

  test('joinRichPieces breaks lines between rows but not around blocks', () {
    const line = Rect.fromLTWH(0, 0, 100, 10);
    final joined = joinRichPieces([
      (bounds: line, text: '•', html: '•'),
      (bounds: line, text: ' one', html: ' <b>one</b>'),
      (bounds: line.shift(const Offset(0, 20)), text: 'two', html: 'two'),
      (
        bounds: line.shift(const Offset(0, 40)),
        text: 'code',
        html: preHtml('code'),
      ),
      (bounds: line.shift(const Offset(0, 60)), text: 'end', html: 'end'),
    ]);
    expect(joined.text, '• one\ntwo\ncode\nend');
    expect(joined.html, '• <b>one</b><br>two<pre>code</pre>end');
  });

  test('windowsClipboardHtml points its offsets at the fragment', () {
    const fragment = '<a href="https://example.com">café</a>';
    final bytes = utf8.encode(windowsClipboardHtml(fragment));
    int field(String name) => int.parse(
      RegExp('$name:(\\d+)').firstMatch(utf8.decode(bytes))!.group(1)!,
    );
    String slice(int from, int to) => utf8.decode(bytes.sublist(from, to));
    expect(slice(field('StartFragment'), field('EndFragment')), fragment);
    expect(slice(field('StartHTML'), field('StartHTML') + 6), '<html>');
    expect(field('EndHTML'), bytes.length);
  });

  test('markdownHtml renders links and emphasis', () {
    expect(
      markdownHtml('See [docs]($_url) and **this**.'),
      '<p>See <a href="https://example.com/docs?a=1&b=2">docs</a> and '
      '<strong>this</strong>.</p>\n',
    );
  });

  testWidgets('copying a selection puts its links on the clipboard as HTML', (
    tester,
  ) async {
    final copies = _mockClipboard(tester);
    await tester.pumpWidget(
      _area([
        const MarkdownText('See [the docs]($_url) for **more**.'),
        const Text('Second row'),
      ]),
    );
    await _selectAndCopy(
      tester,
      find.textContaining('See', findRichText: true),
      find.text('Second row'),
    );
    expect(copies.plain, isEmpty);
    expect(copies.rich, [
      {
        'text': 'See the docs for more.\nSecond row',
        'html':
            '<meta charset="utf-8">See '
            '<a href="https://example.com/docs?a=1&amp;b=2">the docs</a> '
            'for <b>more</b>.<br>Second row',
      },
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('the context menu copies HTML too', (tester) async {
    final copies = _mockClipboard(tester);
    await tester.pumpWidget(_area([const MarkdownText('Read [it]($_url).')]));
    final text = find.textContaining('Read', findRichText: true);
    await _select(tester, text, text);
    // Inside the selection, which a right-click keeps.
    await tester.tapAt(
      tester.getTopLeft(text) + const Offset(12, 8),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copies.rich.single['html'], contains('<a href='));
    expect(copies.rich.single['text'], 'Read it.');
    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('without the rich channel a selection copies plain text', (
    tester,
  ) async {
    final copies = _mockClipboard(tester, rich: false);
    await tester.pumpWidget(_area([const MarkdownText('See [docs]($_url).')]));
    final text = find.textContaining('See', findRichText: true);
    await _selectAndCopy(tester, text, text);
    expect(copies.plain, ['See docs.']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a text field in the area keeps its own copy', (tester) async {
    final copies = _mockClipboard(tester);
    final controller = TextEditingController(text: 'field text');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_area([TextField(controller: controller)]));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(copies.rich, isEmpty);
    expect(copies.plain, ['field']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
