/// Converting pasted rich text (from Google Docs, web pages, or rich text
/// editors) to Markdown and inserting it into a text controller.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'html_to_markdown.dart';
import 'rich_clipboard.dart';

/// Gets the text to paste: converts rich text HTML on the clipboard to
/// Markdown if available; otherwise returns plain text from the clipboard.
///
/// When [plainTextOnly] is true (e.g. Shift+Cmd+V), rich text conversion is
/// skipped.
Future<String?> getPasteText({bool plainTextOnly = false}) async {
  if (!plainTextOnly) {
    try {
      final html = await getRichClipboardHtml();
      if (html != null && html.trim().isNotEmpty) {
        final markdown = htmlToMarkdown(html);
        if (markdown.trim().isNotEmpty) {
          return markdown;
        }
      }
    } catch (_) {
      // Fall through to plain text on any error.
    }
  }

  final data = await Clipboard.getData(Clipboard.kTextPlain);
  return data?.text;
}

/// Inserts [text] into [controller] at its current selection (or replaces
/// the selected range), positioning the caret at the end of the insertion.
void insertTextIntoController(TextEditingController controller, String text) {
  final value = controller.value;
  final selection = value.selection;
  if (!selection.isValid) {
    controller.value = TextEditingValue(
      text: value.text + text,
      selection: TextSelection.collapsed(
        offset: value.text.length + text.length,
      ),
    );
    return;
  }

  final start = selection.start;
  final end = selection.end;
  final newText = value.text.replaceRange(start, end, text);
  final newOffset = start + text.length;

  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newOffset),
  );
}

/// Pastes text from the clipboard into [controller], converting rich text
/// HTML to Markdown unless [plainTextOnly] is true.
Future<void> pasteIntoController(
  TextEditingController controller, {
  bool plainTextOnly = false,
}) async {
  final text = await getPasteText(plainTextOnly: plainTextOnly);
  if (text == null || text.isEmpty) return;
  insertTextIntoController(controller, text);
}

/// Context menu builder replacing standard paste with rich-to-markdown paste.
Widget buildRichPasteContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
  TextEditingController controller,
) {
  final buttonItems = editableTextState.contextMenuButtonItems;
  final pasteIndex = buttonItems.indexWhere(
    (item) => item.type == ContextMenuButtonType.paste,
  );
  if (pasteIndex != -1) {
    buttonItems[pasteIndex] = buttonItems[pasteIndex].copyWith(
      onPressed: () {
        editableTextState.hideToolbar();
        unawaited(pasteIntoController(controller));
      },
    );
  }
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

/// Handles keyboard shortcut for paste (Cmd+V on macOS / iOS, Ctrl+V on
/// other platforms), with Shift for paste-as-plain-text.
KeyEventResult handleRichPasteKey(
  KeyEvent event,
  TextEditingController controller,
) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;
  if (event.logicalKey != LogicalKeyboardKey.keyV) {
    return KeyEventResult.ignored;
  }
  final keyboard = HardwareKeyboard.instance;
  final isModifier =
      defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS
      ? keyboard.isMetaPressed
      : keyboard.isControlPressed;
  if (!isModifier) return KeyEventResult.ignored;
  if (keyboard.isAltPressed) return KeyEventResult.ignored;

  final plainTextOnly = keyboard.isShiftPressed;
  unawaited(pasteIntoController(controller, plainTextOnly: plainTextOnly));
  return KeyEventResult.handled;
}
