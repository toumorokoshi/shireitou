/// Pure view logic for agent todo lists and plans (AV-070).
///
/// AHP has no todo or plan response part. Agents keep their task list
/// with a tool, and hosts pass the call through as an ordinary tool call:
/// Claude's `TodoWrite`, the Copilot CLI's `update_todo` (also named
/// `todowrite`), VS Code's `manage_todo_list` and Codex's `update_plan`.
/// Each call carries the whole list in its input, so the newest call is
/// the current list.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

/// Where a todo item stands.
enum TodoStatus {
  /// Not started.
  pending,

  /// Being worked on.
  inProgress,

  /// Done.
  completed,
}

/// One item of a todo list.
@immutable
class TodoItem {
  /// Creates a [TodoItem].
  const TodoItem(this.title, this.status, {this.activeTitle});

  /// What the item is.
  final String title;

  /// Where it stands.
  final TodoStatus status;

  /// The present-continuous form shown while it runs (Claude's
  /// `activeForm`), if the agent sent one.
  final String? activeTitle;

  @override
  bool operator ==(Object other) =>
      other is TodoItem &&
      other.title == title &&
      other.status == status &&
      other.activeTitle == activeTitle;

  @override
  int get hashCode => Object.hash(title, status, activeTitle);

  @override
  String toString() => 'TodoItem($title, $status)';
}

/// An agent's todo list or plan, as of one tool call.
@immutable
class TodoList {
  /// Creates a [TodoList].
  const TodoList(this.items, {this.explanation});

  /// The items, in the agent's order.
  final List<TodoItem> items;

  /// A note the agent sent with the plan (Codex's `explanation`).
  final String? explanation;

  /// How many items are done.
  int get completed =>
      items.where((i) => i.status == TodoStatus.completed).length;

  /// The item being worked on, if any.
  TodoItem? get current =>
      items.where((i) => i.status == TodoStatus.inProgress).firstOrNull;

  /// Whether every item is done.
  bool get done => items.isNotEmpty && completed == items.length;

  /// "2 of 5 done".
  String get progressLabel => '$completed of ${items.length} done';
}

/// Tool names (lower case) whose input is a whole todo list.
const todoToolNames = {
  'todowrite',
  'todo_write',
  'update_todo',
  'manage_todo_list',
  'update_plan',
};

/// Whether [toolName] is a todo or plan tool.
bool isTodoTool(String toolName) =>
    todoToolNames.contains(toolName.toLowerCase());

TodoStatus? _status(Object? value) =>
    switch ('$value'.toLowerCase().replaceAll(RegExp('[-_ ]'), '')) {
      'pending' || 'notstarted' || 'todo' || 'open' => TodoStatus.pending,
      'inprogress' || 'active' || 'running' => TodoStatus.inProgress,
      'completed' || 'done' || 'complete' => TodoStatus.completed,
      _ => null,
    };

String? _text(Object? value) => switch (value) {
  final String s when s.trim().isNotEmpty => s.trim(),
  _ => null,
};

TodoItem? _item(Object? json) {
  if (json is! Map) return null;
  final title = _text(json['content'] ?? json['title'] ?? json['step']);
  if (title == null) return null;
  return TodoItem(
    title,
    _status(json['status']) ?? TodoStatus.pending,
    activeTitle: _text(json['activeForm']),
  );
}

/// A markdown checklist ("- [x] Done", "- [ ] Next", "- [~] Doing"), as
/// the Copilot CLI sends it.
List<TodoItem> parseChecklist(String text) => [
  for (final match in RegExp(
    r'^\s*[-*]\s*\[( |x|X|~|-|>)\]\s*(.+?)\s*$',
    multiLine: true,
  ).allMatches(text))
    TodoItem(match.group(2)!, switch (match.group(1)!) {
      'x' || 'X' => TodoStatus.completed,
      '~' || '-' || '>' => TodoStatus.inProgress,
      _ => TodoStatus.pending,
    }),
];

/// The todo list in a todo tool's [input] JSON, or null when it has none.
TodoList? parseTodoInput(String input) {
  final Object? json;
  try {
    json = jsonDecode(input);
  } on FormatException {
    return null;
  }
  if (json is! Map) return null;
  final list = json['todos'] ?? json['todoList'] ?? json['plan'];
  final items = switch (list) {
    final List<Object?> entries => [for (final e in entries) ?_item(e)],
    final String checklist => parseChecklist(checklist),
    _ => const <TodoItem>[],
  };
  if (items.isEmpty) return null;
  return TodoList(items, explanation: _text(json['explanation']));
}

/// The todo list [toolCall] sets, or null when it is not a todo tool or
/// its input is not complete yet.
TodoList? todoListOf(ToolCallState toolCall) {
  if (!isTodoTool(toolCall.toolName)) return null;
  return switch (toolCall.toolInput) {
    InlineToolInput(:final value) => parseTodoInput(value),
    _ => null,
  };
}

TodoList? _inParts(List<ResponsePart> parts) {
  for (final part in parts.reversed) {
    if (part case ToolCallResponsePart(:final toolCall)) {
      if (todoListOf(toolCall) case final list?) return list;
    }
  }
  return null;
}

final _turnsTodo = Expando<({TodoList? list})>('turns todo');

/// The newest todo list in [chat] (the active turn first, then the
/// finished turns from the newest), or null when the agent kept none.
/// The finished turns are searched once per `turns` list, so streaming
/// only rescans the active turn.
TodoList? latestTodoList(ChatState chat) {
  if (chat.activeTurn case final active?) {
    if (_inParts(active.responseParts) case final list?) return list;
  }
  return (_turnsTodo[chat.turns] ??= (
    list: chat.turns.reversed
        .map((t) => _inParts(t.responseParts))
        .nonNulls
        .firstOrNull,
  )).list;
}
