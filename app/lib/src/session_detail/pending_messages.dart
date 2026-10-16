/// Queued and steering messages above the follow-up box (AV-081): edit,
/// remove, and drag (or move) queued ones to reorder them.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import 'chat_commands.dart';
import 'timeline_items.dart';

/// The chat's steering and queued messages, editable and reorderable.
class PendingMessagesPanel extends StatelessWidget {
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

  List<PendingMessage> get _queued => [
    for (final p in pending)
      if (p.kind == PendingMessageKind.queued) p.pending,
  ];

  void _move(int from, int to) {
    if (reorderQueuedAction(_queued, from, to) case final action?) {
      onAction(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steering = pending
        .where((p) => p.kind == PendingMessageKind.steering)
        .toList();
    final queued = _queued;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          children: [
            for (final item in steering)
              _PendingRow(
                item: item,
                onAction: onAction,
                position: null,
                count: 0,
                onMove: _move,
              ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: _move,
              children: [
                for (final (i, message) in queued.indexed)
                  _PendingRow(
                    key: ValueKey(message.id),
                    item: PendingMessageItem(
                      PendingMessageKind.queued,
                      message,
                    ),
                    onAction: onAction,
                    position: i,
                    count: queued.length,
                    onMove: _move,
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
  });

  final PendingMessageItem item;
  final ValueChanged<JsonMap> onAction;

  /// Index in the queue, or null for the steering message.
  final int? position;
  final int count;
  final void Function(int from, int to) onMove;

  Future<void> _edit(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(initial: item.pending.message.text),
    );
    if (text == null || text.trim().isEmpty) return;
    onAction(editPendingAction(item.kind, item.pending, text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final steering = item.kind == PendingMessageKind.steering;
    final position = this.position;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(steering ? Icons.bolt : Icons.schedule, size: 18),
      title: Text(
        item.pending.message.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(steering ? 'Steering (next step)' : 'Queued'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<VoidCallback>(
            tooltip: 'Message actions',
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => _edit(context),
                child: const Text('Edit'),
              ),
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
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initial});

  final String initial;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit message'),
    content: TextField(
      controller: _text,
      autofocus: true,
      minLines: 1,
      maxLines: 6,
      decoration: const InputDecoration(labelText: 'Message'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _text.text),
        child: const Text('Save'),
      ),
    ],
  );
}
