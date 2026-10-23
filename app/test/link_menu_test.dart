import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/link_menu.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';

const _url = 'https://example.com/docs';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SelectionArea(child: child)),
);

Future<void> _rightClick(WidgetTester tester, Finder finder) => tester.tap(
  finder,
  buttons: kSecondaryButton,
  kind: PointerDeviceKind.mouse,
);

/// Records clipboard writes.
List<String> _mockClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  testWidgets('right-clicking a markdown link shows it and copies it', (
    tester,
  ) async {
    final copied = _mockClipboard(tester);
    await tester.pumpWidget(
      _app(const MarkdownText('Plain words.\n\n[docs]($_url)')),
    );

    await _rightClick(tester, find.text('docs'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(_url), findsOneWidget);
    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();

    expect(copied, [_url]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Link copied'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('right-clicking plain markdown text shows no link dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const MarkdownText('Plain words.\n\n[docs]($_url)')),
    );

    await _rightClick(tester, find.text('Plain words.'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('right-clicking a link button shows its link', (tester) async {
    await tester.pumpWidget(
      _app(
        LinkContextMenu(
          url: _url,
          child: TextButton(onPressed: () {}, child: const Text('Docs')),
        ),
      ),
    );

    await _rightClick(tester, find.text('Docs'));
    await tester.pumpAndSettle();
    expect(find.text(_url), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
