/// Queued and steering messages above the follow-up box (AV-081): click a
/// message to edit it in place, remove it, send a queued one now, and
/// drag (or move) queued ones to reorder them.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'chat_commands.dart';
import 'inline_message_editor.dart';
import 'timeline_items.dart';

/// The chat's steering and queued messages, editable and reorderable.
class PendingMessagesPanel extends StatefulWidget {
  /// Creates a [PendingMessagesPanel] for non-empty [pending].
  const PendingMessagesPanel({
    super.key,
    required this.pending,
    required this.onAction,
    this.editNewestRequests,
    this.onEditorClosed,
    this.onSendNow,
  });

  /// The steering message first, then the queue (see `pendingMessages`).
  final List<PendingMessageItem> pending;

  /// Dispatches a chat action.
  final ValueChanged<JsonMap> onAction;

  /// Sends a queued message now (see `sendQueuedNowActions`); null hides
  /// the "Send now" buttons.
  final ValueChanged<PendingMessage>? onSendNow;

  /// Opens the newest message (the last queued one, else the steering
  /// one) in the inline editor whenever this changes (↑ in the composer,
  /// AV-087).
  final Listenable? editNewestRequests;

  /// Called when the inline editor closes (saved, cancelled, or the
  /// message left the queue).
  final VoidCallback? onEditorClosed;

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
  void initState() {
    super.initState();
    widget.editNewestRequests?.addListener(_editNewest);
  }

  @override
  void dispose() {
    widget.editNewestRequests?.removeListener(_editNewest);
    super.dispose();
  }

  void _editNewest() {
    if (widget.pending.lastOrNull case final newest?) {
      setState(() => _editingId = newest.pending.id);
    }
  }

  void _close() {
    setState(() => _editingId = null);
    widget.onEditorClosed?.call();
  }

  @override
  void didUpdateWidget(PendingMessagesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editNewestRequests != widget.editNewestRequests) {
      oldWidget.editNewestRequests?.removeListener(_editNewest);
      widget.editNewestRequests?.addListener(_editNewest);
    }
    final id = _editingId;
    if (id == null || _find(id) != null) return;
    // The host sent or removed the message while it was being edited.
    _editingId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onEditorClosed?.call();
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
    _close();
  }

  Widget _row(PendingMessageItem item, {Key? key, int? position}) {
    final id = item.pending.id;
    final sendNow = widget.onSendNow;
    return _PendingRow(
      key: key,
      item: item,
      onAction: widget.onAction,
      onSendNow: sendNow == null || item.kind != PendingMessageKind.queued
          ? null
          : () => sendNow(item.pending),
      position: position,
      count: _queued.length,
      onMove: _move,
      editing: _editingId == id,
      onEdit: () => setState(() => _editingId = id),
      onSave: (text) => _save(id, text),
      onCancel: _close,
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
    this.onSendNow,
  });

  /// The message shown.
  final PendingMessageItem item;

  /// Dispatches a chat action.
  final ValueChanged<JsonMap> onAction;

  /// Sends the queued message now, or null for the steering message.
  final VoidCallback? onSendNow;

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
    final sendNow = onSendNow;
    final icon = Icon(steering ? Icons.bolt : Icons.schedule, size: 18);
    if (editing) {
      return InlineMessageEditor(
        icon: icon,
        initial: item.pending.message.text,
        helperText: 'Enter saves, Esc cancels; empty removes it',
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
        if (sendNow != null)
          IconButton(
            tooltip: 'Send now',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(AppIcons.sendNow),
            onPressed: sendNow,
          ),
        PopupMenuButton<VoidCallback>(
          tooltip: 'Message actions',
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            PopupMenuItem(value: onEdit, child: const Text('Edit')),
            if (sendNow != null)
              PopupMenuItem(value: sendNow, child: const Text('Send now')),
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
