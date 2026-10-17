/// Queued and steering messages above the follow-up box (AV-081): click a
/// message to edit it in place, remove it, and drag (or move) queued ones
/// to reorder them.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_commands.dart';
import 'timeline_items.dart';

/// The chat's steering and queued messages, editable and reorderable.
class PendingMessagesPanel extends StatefulWidget {
  /// Creates a [PendingMessagesPanel] for non-empty [pending].
  const PendingMessagesPanel({
    super.key,
    required this.pending,
    required this.onAction,
  });

  /// The steering message first, then the queue (see `pendingMessages`).
  final List<PendingMessageItem> pending;

  /// Dispatches a chat action.
  final ValueChanged<JsonMap> onAction;

  @override
  State<PendingMessagesPanel> createState() => _PendingMessagesPanelState();
}

class _PendingMessagesPanelState extends State<PendingMessagesPanel> {
  /// The ID of the message open in the inline editor, if any.
  String? _editingId;

  PendingMessageItem? _find(String id) =>
      widget.pending.where((p) => p.pending.id == id).firstOrNull;

  List<PendingMessage> get _queued => [
    for (final p in widget.pending)
      if (p.kind == PendingMessageKind.queued) p.pending,
  ];

  @override
  void didUpdateWidget(PendingMessagesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = _editingId;
    if (id == null || _find(id) != null) return;
    // The host sent or removed the message while it was being edited.
    _editingId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'The message was sent or removed before the edit was saved.',
          ),
        ),
      );
    });
  }

  void _move(int from, int to) {
    if (reorderQueuedAction(_queued, from, to) case final action?) {
      widget.onAction(action);
    }
  }

  void _save(String id, String text) {
    final item = _find(id);
    if (item != null) {
      if (savePendingEditAction(item.kind, item.pending, text)
          case final action?) {
        widget.onAction(action);
      }
    }
    setState(() => _editingId = null);
  }

  Widget _row(PendingMessageItem item, {Key? key, int? position}) {
    final id = item.pending.id;
    return _PendingRow(
      key: key,
      item: item,
      onAction: widget.onAction,
      position: position,
      count: _queued.length,
      onMove: _move,
      editing: _editingId == id,
      onEdit: () => setState(() => _editingId = id),
      onSave: (text) => _save(id, text),
      onCancel: () => setState(() => _editingId = null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steering = widget.pending.where(
      (p) => p.kind == PendingMessageKind.steering,
    );
    final queued = _queued;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          children: [
            for (final item in steering) _row(item),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: _move,
              children: [
                for (final (i, message) in queued.indexed)
                  _row(
                    PendingMessageItem(PendingMessageKind.queued, message),
                    key: ValueKey(message.id),
                    position: i,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    super.key,
    required this.item,
    required this.onAction,
    required this.position,
    required this.count,
    required this.onMove,
    required this.editing,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  /// The message shown.
  final PendingMessageItem item;

  /// Dispatches a chat action.
  final ValueChanged<JsonMap> onAction;

  /// Index in the queue, or null for the steering message.
  final int? position;

  /// The number of queued messages.
  final int count;

  /// Moves the queued message at `from` to `to`.
  final void Function(int from, int to) onMove;

  /// Whether the message is open in the inline editor.
  final bool editing;

  /// Opens the message in the inline editor.
  final VoidCallback onEdit;

  /// Saves the editor's text.
  final ValueChanged<String> onSave;

  /// Closes the editor without saving.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final steering = item.kind == PendingMessageKind.steering;
    final position = this.position;
    final icon = Icon(steering ? Icons.bolt : Icons.schedule, size: 18);
    if (editing) {
      return _InlineEditor(
        icon: icon,
        initial: item.pending.message.text,
        onSave: onSave,
        onCancel: onCancel,
      );
    }
    // The tile and the trailing buttons are siblings, so a tap on the
    // menu or the drag handle does not open the editor.
    return Row(
      children: [
        Expanded(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: onEdit,
            leading: icon,
            title: Text(
              item.pending.message.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(steering ? 'Steering (next step)' : 'Queued'),
          ),
        ),
        PopupMenuButton<VoidCallback>(
          tooltip: 'Message actions',
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            PopupMenuItem(value: onEdit, child: const Text('Edit')),
            if (position != null && position > 0)
              PopupMenuItem(
                value: () => onMove(position, position - 1),
                child: const Text('Move up'),
              ),
            if (position != null && position < count - 1)
              PopupMenuItem(
                value: () => onMove(position, position + 1),
                child: const Text('Move down'),
              ),
            PopupMenuItem(
              value: () =>
                  onAction(removePendingAction(item.kind, item.pending.id)),
              child: const Text('Remove'),
            ),
          ],
        ),
        if (position != null)
          ReorderableDragStartListener(
            index: position,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_handle, semanticLabel: 'Reorder'),
            ),
          ),
      ],
    );
  }
}

/// A pending message's text in an editor: Enter saves, Shift+Enter adds a
/// line, Escape cancels.
class _InlineEditor extends StatefulWidget {
  const _InlineEditor({
    required this.icon,
    required this.initial,
    required this.onSave,
    required this.onCancel,
  });

  /// The steering or queued icon.
  final Widget icon;

  /// The message's text when the editor opened.
  final String initial;

  /// Saves the edited text.
  final ValueChanged<String> onSave;

  /// Closes the editor without saving.
  final VoidCallback onCancel;

  @override
  State<_InlineEditor> createState() => _InlineEditorState();
}

class _InlineEditorState extends State<_InlineEditor> {
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
        Padding(padding: const EdgeInsets.only(right: 16), child: widget.icon),
        Expanded(
          child: TextField(
            controller: _text,
            focusNode: _focus,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Edit message',
              helperText: 'Enter saves, Esc cancels; empty removes it',
            ),
          ),
        ),
        IconButton(
          tooltip: 'Save',
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
