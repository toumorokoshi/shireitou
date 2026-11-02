/// Tests for pasting rich text into the composer and message editor,
/// converting HTML to Markdown.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/clipboard/rich_clipboard.dart';
import 'package:shireitou/src/clipboard/rich_paste.dart';
import 'package:shireitou/src/session_detail/inline_message_editor.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockClipboard(WidgetTester tester, {String? plainText, String? html}) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': plainText};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(richClipboardChannel, (call) async {
      if (call.method == 'getHtml') {
        return html;
      }
      return null;
    });
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(SystemChannels.platform, null)
        ..setMockMethodCallHandler(richClipboardChannel, null);
    });
  }

  group('getPasteText', () {
    testWidgets('converts clipboard HTML to Markdown', (tester) async {
      mockClipboard(
        tester,
        plainText: 'First bullet Second bullet',
        html: '<ul><li>First bullet</li><li>Second bullet</li></ul>',
      );

      final text = await getPasteText();
      expect(text, '- First bullet\n- Second bullet');
    });

    testWidgets('falls back to plain text when HTML is missing', (
      tester,
    ) async {
      mockClipboard(tester, plainText: 'Plain text only');

      final text = await getPasteText();
      expect(text, 'Plain text only');
    });

    testWidgets('skips HTML conversion when plainTextOnly is true', (
      tester,
    ) async {
      mockClipboard(
        tester,
        plainText: 'Plain unformatted text',
        html: '<ul><li>Rich bullet</li></ul>',
      );

      final text = await getPasteText(plainTextOnly: true);
      expect(text, 'Plain unformatted text');
    });
  });

  group('insertTextIntoController', () {
    test('inserts at end when selection is invalid', () {
      final controller = TextEditingController(text: 'Hello');
      insertTextIntoController(controller, ' world');
      expect(controller.text, 'Hello world');
      expect(controller.selection.baseOffset, 11);
    });

    test('replaces selected range and updates caret', () {
      final controller = TextEditingController(text: 'Hello world');
      controller.selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      insertTextIntoController(controller, 'there');
      expect(controller.text, 'Hello there');
      expect(controller.selection.baseOffset, 11);
    });
  });

  group('FollowUpInput rich paste', () {
    testWidgets('pastes converted Markdown on Cmd+V / Ctrl+V', (tester) async {
      mockClipboard(
        tester,
        plainText: 'First bullet Second bullet',
        html: '''
<b id="docs-internal-guid-abc" style="font-weight:normal;">
  <ul>
    <li><span>First bullet</span></li>
    <li><span>Second bullet with </span><b>bold</b></li>
  </ul>
</b>''',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpInput(
              working: false,
              onSend: (
                text, {
                required sendNow,
                model,
                attachments = const [],
              }) {},
            ),
          ),
        ),
      );

      // Focus the text field
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Send paste shortcut (Meta+V on macOS or Control+V)
      final modifier = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;

      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(textField);
      expect(
        input.controller?.text,
        '- First bullet\n- Second bullet with **bold**',
      );
    });

    testWidgets(
      'pastes plain text without conversion on Shift+Cmd+V / Shift+Ctrl+V',
      (tester) async {
        mockClipboard(
          tester,
          plainText: 'Raw plain text bullets',
          html: '<ul><li>Rich bullet</li></ul>',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FollowUpInput(
                working: false,
                onSend: (
                  text, {
                  required sendNow,
                  model,
                  attachments = const [],
                }) {},
              ),
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        final modifier = defaultTargetPlatform == TargetPlatform.macOS
            ? LogicalKeyboardKey.metaLeft
            : LogicalKeyboardKey.controlLeft;

        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle();

        final input = tester.widget<TextField>(textField);
        expect(input.controller?.text, 'Raw plain text bullets');
      },
    );
  });

  group('InlineMessageEditor rich paste', () {
    testWidgets('pastes converted Markdown into editor on paste', (
      tester,
    ) async {
      mockClipboard(
        tester,
        plainText: 'Item 1 Item 2',
        html: '<ul><li>Item 1</li><li>Item 2</li></ul>',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineMessageEditor(
              initial: 'Prefix: ',
              onSave: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      final modifier = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;

      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(textField);
      expect(input.controller?.text, 'Prefix: - Item 1\n- Item 2');
    });

    testWidgets('pastes via pasteIntoController directly', (tester) async {
      mockClipboard(
        tester,
        plainText: 'Direct item',
        html: '<ul><li>Direct item</li></ul>',
      );

      final controller = TextEditingController();
      await pasteIntoController(controller);
      expect(controller.text, '- Direct item');
    });
  });
}
