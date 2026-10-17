/// A session title that turns into a text field when clicked (AV-073), and
/// the rename dialog of the session list.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Shows [title]; clicking it (or a request on [editRequests]) swaps it
/// for a text field with the text selected. Enter or losing focus calls
/// [onRename] with the typed text; Esc cancels. A new [title] from the
/// host while the field is open does not replace the typed text.
class EditableTitle extends StatefulWidget {
  /// Creates an [EditableTitle].
  const EditableTitle({
    super.key,
    required this.title,
    required this.onRename,
    this.editRequests,
    this.style,
  });

  /// The title shown, and the text the field starts with.
  final String title;

  /// Called with the typed text when editing ends without Esc.
  final ValueChanged<String> onRename;

  /// Opens the text field each time it notifies (the "Rename…" menu item).
  final Listenable? editRequests;

  /// The title's text style, also used in the field.
  final TextStyle? style;

  @override
  State<EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends State<EditableTitle> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    widget.editRequests?.addListener(_start);
  }

  @override
  void didUpdateWidget(EditableTitle old) {
    super.didUpdateWidget(old);
    if (old.editRequests != widget.editRequests) {
      old.editRequests?.removeListener(_start);
      widget.editRequests?.addListener(_start);
    }
  }

  @override
  void dispose() {
    widget.editRequests?.removeListener(_start);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (_editing) return;
    _controller.value = TextEditingValue(
      text: widget.title,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: widget.title.length,
      ),
    );
    setState(() => _editing = true);
    // After this frame builds the field, and after a closing menu hands
    // focus back to the page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focus.requestFocus();
    });
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _finish(save: true);
  }

  void _finish({required bool save}) {
    if (!_editing) return;
    setState(() => _editing = false);
    if (save) widget.onRename(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _finish(save: false),
        },
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          style: widget.style,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Session title',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onSubmitted: (_) => _finish(save: true),
          onTapOutside: (_) => _focus.unfocus(),
        ),
      );
    }
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Rename'): _start,
      },
      child: Tooltip(
        message: 'Click to rename',
        waitDuration: const Duration(milliseconds: 500),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _start,
            child: Text(
              widget.title,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for a new title for the session titled [current]; null when
/// cancelled.
Future<String?> showRenameDialog(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(current: current),
    );

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});

  final String current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.current)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.current.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Rename session'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Title'),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Rename')),
    ],
  );
}
