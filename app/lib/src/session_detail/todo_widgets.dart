/// Todo list and plan cards (AV-070).
library;

import 'package:flutter/material.dart';

import 'todo_list.dart';

/// The items of [list] as a checklist.
class TodoChecklist extends StatelessWidget {
  /// Creates a [TodoChecklist].
  const TodoChecklist({super.key, required this.list});

  /// The list to show.
  final TodoList list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.explanation case final note?)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(note, style: theme.textTheme.bodySmall),
          ),
        for (final item in list.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (item.status) {
                    TodoStatus.completed => Icons.check_circle,
                    TodoStatus.inProgress => Icons.timelapse,
                    TodoStatus.pending => Icons.radio_button_unchecked,
                  },
                  size: 18,
                  semanticLabel: switch (item.status) {
                    TodoStatus.completed => 'Done',
                    TodoStatus.inProgress => 'In progress',
                    TodoStatus.pending => 'Not started',
                  },
                  color: switch (item.status) {
                    TodoStatus.completed => theme.colorScheme.primary,
                    TodoStatus.inProgress => theme.colorScheme.tertiary,
                    TodoStatus.pending => theme.colorScheme.outline,
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.status == TodoStatus.inProgress
                        ? item.activeTitle ?? item.title
                        : item.title,
                    style: item.status == TodoStatus.completed
                        ? TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : item.status == TodoStatus.inProgress
                        ? const TextStyle(fontWeight: FontWeight.w600)
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A todo tool call in the timeline: the list it set, as a card.
class TodoCard extends StatelessWidget {
  /// Creates a [TodoCard].
  const TodoCard({super.key, required this.list, this.running = false});

  /// The list the call set.
  final TodoList list;

  /// Whether the call is still running.
  final bool running;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Todo list · ${list.progressLabel}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (running)
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TodoChecklist(list: list),
        ],
      ),
    ),
  );
}

/// The chat's current todo list above the follow-up box: progress and
/// the current item, expandable to the whole list.
class TodoPanel extends StatelessWidget {
  /// Creates a [TodoPanel].
  const TodoPanel({super.key, required this.list});

  /// The newest list.
  final TodoList list;

  @override
  Widget build(BuildContext context) {
    final current = list.current;
    return ExpansionTile(
      key: const PageStorageKey('todo-panel'),
      dense: true,
      leading: const Icon(Icons.checklist),
      title: Text('Todo list · ${list.progressLabel}'),
      subtitle: current == null
          ? null
          : Text(
              current.activeTitle ?? current.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: SizedBox(
        width: 64,
        child: LinearProgressIndicator(
          value: list.items.isEmpty ? 0 : list.completed / list.items.length,
          semanticsLabel: 'Todo progress',
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [TodoChecklist(list: list)],
    );
  }
}
