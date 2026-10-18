/// An inline editor for a message's text, used for queued messages (AV-081)
/// and for editing the latest message to restart from it (AV-088).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A message's text in an editor: Enter saves, Shift+Enter adds a line,
/// Escape cancels.
class InlineMessageEditor extends StatefulWidget {
  /// Creates an [InlineMessageEditor].
  const InlineMessageEditor({
    super.key,
    required this.initial,
    required this.onSave,
    required this.onCancel,
    this.icon,
    this.labelText = 'Edit message',
    this.helperText,
    this.saveTooltip = 'Save',
  });

  /// The message's text when the editor opened.
  final String initial;

  /// Saves the edited text.
  final ValueChanged<String> onSave;

  /// Closes the editor without saving.
  final VoidCallback onCancel;

  /// Shown before the field, if any.
  final Widget? icon;

  /// The field's label.
  final String labelText;

  /// The hint under the field, if any.
  final String? helperText;

  /// The save button's tooltip.
  final String saveTooltip;

  @override
  State<InlineMessageEditor> createState() => _InlineMessageEditorState();
}

class _InlineMessageEditorState extends State<InlineMessageEditor> {
  late final _text = TextEditingController(text: widget.initial);
  late final _focus = FocusNode(onKeyEvent: _onKey);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onCancel();
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        !HardwareKeyboard.instance.isShiftPressed) {
      widget.onSave(_text.text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        if (widget.icon case final icon?)
          Padding(padding: const EdgeInsets.only(right: 16), child: icon),
        Expanded(
          child: TextField(
            controller: _text,
            focusNode: _focus,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              isDense: true,
              labelText: widget.labelText,
              helperText: widget.helperText,
            ),
          ),
        ),
        IconButton(
          tooltip: widget.saveTooltip,
          icon: const Icon(Icons.check),
          onPressed: () => widget.onSave(_text.text),
        ),
        IconButton(
          tooltip: 'Cancel',
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ],
    ),
  );
}
