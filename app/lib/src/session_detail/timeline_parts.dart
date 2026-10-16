/// Widgets for timeline rows: messages, markdown, reasoning, tool calls,
/// input requests and errors (AV-061 to AV-067, AV-083, AV-084).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/sign_in_dialog.dart';
import 'approval_bar.dart';
import 'chat_commands.dart';
import 'code_highlight.dart';
import 'timeline_items.dart';
import 'todo_list.dart';
import 'todo_widgets.dart';
import 'tool_previews.dart';

/// Builds the widget for one [item]. [onAction] dispatches a chat action;
/// [onSignIn] signs a tool call in to its MCP server; [onOpenChat]
/// opens a subagent's chat; [onLoadOlder] pages in older turns.
Widget buildTimelineItem(
  TimelineItem item,
  ValueChanged<JsonMap> onAction, {
  SignIn? onSignIn,
  OpenChat? onOpenChat,
  VoidCallback? onLoadOlder,
}) => switch (item) {
  UserMessageItem(:final message) => UserMessageBubble(message: message),
  ToolCallGroupItem(:final turnId, :final calls) => ToolCallGroupCard(
    turnId: turnId,
    calls: calls,
  ),
  LoadOlderItem() => LoadOlderRow(onLoad: onLoadOlder),
  ResponsePartItem(:final turnId, :final part, :final active) => switch (part) {
    MarkdownResponsePart(:final content) => MarkdownText(content),
    ReasoningResponsePart(:final content) => ReasoningBlock(content: content),
    ToolCallResponsePart(:final toolCall)
        when todoListOf(toolCall) != null && !toolCall.isBlocking =>
      TodoCard(list: todoListOf(toolCall)!, running: !toolCall.isFinished),
    ToolCallResponsePart(:final toolCall) => ToolCallCard(
      turnId: turnId,
      toolCall: toolCall,
      onAction: active ? onAction : null,
      onSignIn: active ? onSignIn : null,
      onOpenChat: onOpenChat,
    ),
    InputRequestResponsePart() => InputRequestCard(
      part: part,
      onAction: active ? onAction : null,
    ),
    ErrorResponsePart(:final error, :final resumable) => ErrorBanner(
      message: error.message,
      onRetry: resumable == true && !active
          ? () => onAction(ChatTurnResumeAction(turnId: turnId).toJson())
          : null,
    ),
    SystemNotificationResponsePart(:final content) => _Note(content.text),
    ResourceResponsePart(:final uri) => _Note(uri),
    ResponsePartUnknown(:final kind) => _Note(
      'Unsupported response part: $kind',
    ),
  },
  TurnFooterItem(:final turn) => _Note(turnFooterText(turn)),
};

/// The oldest row while the host holds older turns back (AV-068): it asks
/// for them as soon as it is built, which happens when the user scrolls
/// near the top.
class LoadOlderRow extends StatefulWidget {
  /// Creates a [LoadOlderRow].
  const LoadOlderRow({super.key, this.onLoad});

  /// Pages in older turns.
  final VoidCallback? onLoad;

  @override
  State<LoadOlderRow> createState() => _LoadOlderRowState();
}

class _LoadOlderRowState extends State<LoadOlderRow> {
  @override
  void initState() {
    super.initState();
    // Not during build: loading changes the provider this list watches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoad?.call();
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: TextButton.icon(
        onPressed: widget.onLoad,
        icon: const Icon(Icons.history),
        label: const Text('Loading older turns…'),
      ),
    ),
  );
}

/// The user's message, right-aligned.
class UserMessageBubble extends StatelessWidget {
  /// Creates a [UserMessageBubble].
  const UserMessageBubble({super.key, required this.message});

  /// The message.
  final Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

/// Assistant markdown (AV-061). Links open in the browser.
class MarkdownText extends StatelessWidget {
  /// Creates a [MarkdownText] for [data].
  const MarkdownText(this.data, {super.key});

  /// Markdown source.
  final String data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: MarkdownBody(
      data: data,
      selectable: true,
      builders: {'pre': _codeBlocks},
      onTapLink: (_, href, _) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri != null) launchUrl(uri);
      },
    ),
  );
}

final _codeBlocks = CodeBlockBuilder();

/// Model reasoning, collapsed by default (AV-062).
class ReasoningBlock extends StatelessWidget {
  /// Creates a [ReasoningBlock].
  const ReasoningBlock({super.key, required this.content});

  /// Reasoning text.
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      leading: Icon(Icons.psychology_outlined, color: muted),
      title: Text(
        'Thinking',
        style: theme.textTheme.labelLarge?.copyWith(color: muted),
      ),
      childrenPadding: const EdgeInsets.only(left: 40, bottom: 8),
      expandedAlignment: Alignment.centerLeft,
      children: [
        SelectableText(
          content.trim(),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

/// An icon for a tool name (AV-063).
IconData toolIcon(String toolName) => switch (toolName.toLowerCase()) {
  'bash' || 'shell' || 'terminal' => Icons.terminal,
  'read' || 'view' || 'cat' => Icons.description_outlined,
  'edit' || 'write' || 'patch' => Icons.edit_outlined,
  'grep' || 'find' || 'search' || 'glob' || 'ls' => Icons.search,
  'fetch' || 'web' || 'webfetch' => Icons.public,
  _ => Icons.build_outlined,
};

/// A tool call with its status, approvals, and expandable input and output
/// (AV-063, AV-083).
class ToolCallCard extends StatelessWidget {
  /// Creates a [ToolCallCard]. Approval buttons need [onAction].
  const ToolCallCard({
    super.key,
    required this.turnId,
    required this.toolCall,
    this.onAction,
    this.onSignIn,
    this.onOpenChat,
  });

  /// Turn the call belongs to.
  final String turnId;

  /// The tool call.
  final ToolCallState toolCall;

  /// Dispatches approve/deny; null for finished turns.
  final ValueChanged<JsonMap>? onAction;

  /// Pushes an MCP sign-in token; null hides "Sign in".
  final SignIn? onSignIn;

  /// Opens a subagent's chat.
  final OpenChat? onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previews = toolCallPreviews(toolCall);
    final input = toolCallInputText(toolCall);
    final output = toolCallOutputText(toolCall);
    final failed = switch (toolCall) {
      ToolCallCompletedState(:final success) ||
      ToolCallPendingResultConfirmationState(:final success) => !success,
      _ => false,
    };
    final waiting = toolCall is ToolCallConfirmationState;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            dense: true,
            leading: Icon(toolIcon(toolCall.toolName)),
            title: Text(
              toolCallSummary(toolCall),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${toolCall.displayName} · '
              '${failed ? 'Failed' : toolCallStatusLabel(toolCall)}',
              style: failed ? TextStyle(color: theme.colorScheme.error) : null,
            ),
            trailing: switch (toolCall) {
              ToolCallStreamingState() ||
              ToolCallRunningState() => const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              _ => null,
            },
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              if (input != null) _CodeBlock(label: 'Input', text: input),
              if (output != null) _CodeBlock(label: 'Output', text: output),
              if (input == null && output == null) const Text('No details.'),
            ],
          ),
          if (previews.isNotEmpty)
            ToolCallPreviews(
              contents: previews,
              live: !toolCall.isFinished,
              onOpenChat: onOpenChat,
            ),
          if (waiting && onAction != null)
            ApprovalBar(
              key: ValueKey('approval-${toolCall.toolCallId}'),
              turnId: turnId,
              toolCall: toolCall,
              onAction: onAction!,
            ),
          if (toolCall case final ToolCallAuthRequiredState call
              when onAction != null)
            _AuthBar(
              auth: call.auth,
              onSignIn: onSignIn,
              onCancel: () => onAction!(cancelAuthAction(turnId, call)),
            ),
        ],
      ),
    );
  }
}

/// The call to action of a tool call waiting for MCP sign-in (AHP-062).
class _AuthBar extends StatelessWidget {
  const _AuthBar({
    required this.auth,
    required this.onSignIn,
    required this.onCancel,
  });

  final McpAuthRequirement auth;
  final SignIn? onSignIn;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final resource = auth.resource;
    final name = resource.resourceName ?? resource.resource;
    final onSignIn = this.onSignIn;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(auth.description ?? 'Sign in to $name to continue.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onSignIn != null)
                FilledButton.icon(
                  icon: const Icon(Icons.key),
                  label: const Text('Sign in'),
                  onPressed: () =>
                      onSignIn(AuthChallenge.fromRequirement(auth)),
                ),
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel tool call'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const Spacer(),
              IconButton(
                tooltip: 'Copy $label',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy),
                onPressed: () => Clipboard.setData(ClipboardData(text: text)),
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How long the user may pause typing before an input draft is synced.
const draftSyncDelay = Duration(milliseconds: 400);

/// An input request: an inline form while open, a summary once answered
/// (AV-084). Answers are synced as drafts while the user types
/// (`chat/inputAnswerChanged`), and drafts from other clients fill the
/// fields the user has not touched.
class InputRequestCard extends StatefulWidget {
  /// Creates an [InputRequestCard]. The form needs [onAction].
  const InputRequestCard({super.key, required this.part, this.onAction});

  /// The input request part.
  final InputRequestResponsePart part;

  /// Dispatches the answer; null for finished turns.
  final ValueChanged<JsonMap>? onAction;

  @override
  State<InputRequestCard> createState() => _InputRequestCardState();
}

class _InputRequestCardState extends State<InputRequestCard> {
  late final Map<String, Object?> _values = {
    for (final q in _questions(widget.part))
      q.id:
          answerFormValue(q, widget.part.request.answers?[q.id])?.value ??
          switch (q) {
            ChatInputMultiSelectQuestion() => <String>{},
            ChatInputBooleanQuestion(:final defaultValue) =>
              defaultValue ?? false,
            ChatInputTextQuestion(:final defaultValue?) => defaultValue,
            ChatInputNumberQuestion(:final defaultValue?) => '$defaultValue',
            _ => '',
          },
  };

  /// Free-form text by question ID, for select questions that allow it.
  late final Map<String, String> _freeform = {
    for (final q in _questions(widget.part))
      if (answerFormValue(q, widget.part.request.answers?[q.id]) case (
        :final freeform?,
        value: _,
      ))
        q.id: freeform,
  };

  /// Questions the user changed here: drafts from other clients no longer
  /// replace them.
  final _touched = <String>{};

  /// Bumped when another client's draft replaces a field, so the field
  /// starts over from the new value.
  final _revisions = <String, int>{};

  final _draftTimers = <String, Timer>{};

  static List<ChatInputQuestion> _questions(InputRequestResponsePart part) =>
      part.request.questions ?? const <ChatInputQuestion>[];

  @override
  void didUpdateWidget(InputRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.part.request.answers;
    final after = widget.part.request.answers;
    for (final q in _questions(widget.part)) {
      if (_touched.contains(q.id) || before?[q.id] == after?[q.id]) continue;
      final form = answerFormValue(q, after?[q.id]);
      if (form == null) continue;
      _values[q.id] = form.value;
      if (form.freeform case final text?) _freeform[q.id] = text;
      _revisions[q.id] = (_revisions[q.id] ?? 0) + 1;
    }
  }

  @override
  void dispose() {
    for (final timer in _draftTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  /// Syncs [q]'s draft to the host (`chat/inputAnswerChanged`) once the
  /// user pauses, so other clients see it.
  void _syncDraft(ChatInputQuestion q) {
    _touched.add(q.id);
    final onAction = widget.onAction;
    if (onAction == null || widget.part.response != null) return;
    _draftTimers.remove(q.id)?.cancel();
    _draftTimers[q.id] = Timer(draftSyncDelay, () {
      _draftTimers.remove(q.id);
      if (!mounted || widget.part.response != null) return;
      onAction(
        inputAnswerChangedAction(
          widget.part.request,
          q,
          _values[q.id],
          freeform: _freeform[q.id],
        ),
      );
    });
  }

  void _set(ChatInputQuestion q, Object? value) {
    setState(() => _values[q.id] = value);
    _syncDraft(q);
  }

  void _submit(ValueChanged<JsonMap> onAction, {required bool accept}) {
    for (final timer in _draftTimers.values) {
      timer.cancel();
    }
    _draftTimers.clear();
    final request = widget.part.request;
    onAction(
      accept
          ? inputCompletedAction(
              request,
              accept: true,
              values: _values,
              freeform: _freeform,
            )
          : inputCompletedAction(request, accept: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.part.request;
    final onAction = widget.onAction;
    final open = widget.part.response == null && onAction != null;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              request.message ?? 'The agent needs your input',
              style: theme.textTheme.titleSmall,
            ),
            if (request.url case final url?)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(url)),
                child: Text(url),
              ),
            if (!open)
              Text('Response: ${widget.part.response?.wireValue ?? 'none'}')
            else ...[
              for (final q in request.questions ?? <ChatInputQuestion>[])
                _question(q),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed:
                        inputComplete(request, _values, freeform: _freeform)
                        ? () => _submit(onAction, accept: true)
                        : null,
                    child: const Text('Submit'),
                  ),
                  OutlinedButton(
                    onPressed: () => _submit(onAction, accept: false),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _question(ChatInputQuestion q) {
    final label = [
      q.title ?? q.message,
      if (q.required ?? false) '*',
    ].join(' ');
    final help = q.title == null ? null : q.message;
    final value = _values[q.id];
    final allowsFreeform = switch (q) {
      ChatInputSingleSelectQuestion(:final allowFreeformInput) ||
      ChatInputMultiSelectQuestion(
        :final allowFreeformInput,
      ) => allowFreeformInput ?? false,
      _ => false,
    };
    final field = switch (q) {
      ChatInputSingleSelectQuestion(:final options)
          when options.any((o) => o.description != null) =>
        _OptionList(
          label: label,
          help: help,
          options: options,
          selected: value as String?,
          onSelected: (id) => _set(q, id),
        ),
      _ => _field(q, label, help, value),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: !allowsFreeform
          ? field
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field,
                TextFormField(
                  key: ValueKey('freeform-${q.id}-${_revisions[q.id] ?? 0}'),
                  initialValue: _freeform[q.id],
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Or write your own answer',
                    helperText: 'Sent with the choice, or instead of it',
                  ),
                  onChanged: (v) {
                    setState(() => _freeform[q.id] = v);
                    _syncDraft(q);
                  },
                ),
              ],
            ),
    );
  }

  Widget _field(
    ChatInputQuestion q,
    String label,
    String? help,
    Object? value,
  ) => switch (q) {
    ChatInputBooleanQuestion() => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: help == null ? null : Text(help),
      value: value == true,
      onChanged: (v) => _set(q, v),
    ),
    ChatInputSingleSelectQuestion(:final options) =>
      DropdownButtonFormField<String>(
        key: ValueKey('select-${q.id}-${_revisions[q.id] ?? 0}'),
        decoration: InputDecoration(labelText: label, helperText: help),
        initialValue: (value as String?)?.isEmpty ?? true ? null : value,
        items: [
          for (final o in options)
            DropdownMenuItem(value: o.id, child: Text(o.label)),
        ],
        onChanged: (v) => _set(q, v ?? ''),
      ),
    ChatInputMultiSelectQuestion(:final options) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Wrap(
          spacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o.label),
                selected: (value! as Set<String>).contains(o.id),
                onSelected: (on) {
                  final next = {...(value as Set<String>)};
                  on ? next.add(o.id) : next.remove(o.id);
                  _set(q, next);
                },
              ),
          ],
        ),
      ],
    ),
    _ => TextFormField(
      key: ValueKey('text-${q.id}-${_revisions[q.id] ?? 0}'),
      initialValue: value as String?,
      decoration: InputDecoration(labelText: label, helperText: help),
      keyboardType: q is ChatInputNumberQuestion
          ? TextInputType.number
          : TextInputType.text,
      onChanged: (v) => _set(q, v),
    ),
  };
}

/// A single-select question whose options have descriptions (such as a
/// plan review's "Implement plan" / "Approve plan only"), as a list of
/// choices instead of a dropdown (AV-046, AV-084).
class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.label,
    required this.help,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String? help;
  final List<ChatInputOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label),
        if (help != null) Text(help!, style: theme.textTheme.bodySmall),
        RadioGroup<String>(
          groupValue: selected == null || selected!.isEmpty ? null : selected,
          onChanged: (id) {
            if (id != null) onSelected(id);
          },
          child: Column(
            children: [
              for (final o in options)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: o.id,
                  title: Text(
                    o.recommended ?? false
                        ? '${o.label} (recommended)'
                        : o.label,
                  ),
                  subtitle: o.description == null ? null : Text(o.description!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A turn error shown inline (AV-067), with Retry when it is resumable.
class ErrorBanner extends StatelessWidget {
  /// Creates an [ErrorBanner].
  const ErrorBanner({super.key, required this.message, this.onRetry});

  /// The error message.
  final String message;

  /// Resumes the turn; null when not resumable.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Consecutive calls of one tool folded into an expandable row (AV-064):
/// "Read · 3 calls", with each call's card inside.
class ToolCallGroupCard extends StatelessWidget {
  /// Creates a [ToolCallGroupCard].
  const ToolCallGroupCard({
    super.key,
    required this.turnId,
    required this.calls,
  });

  /// Turn the calls belong to.
  final String turnId;

  /// The calls.
  final List<ToolCallState> calls;

  @override
  Widget build(BuildContext context) {
    final status = toolCallGroupStatus(calls);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        dense: true,
        leading: Icon(toolIcon(calls.first.toolName)),
        title: Text(toolCallGroupSummary(calls)),
        subtitle: Text(
          '${calls.map(toolCallSummary).join(', ')} · $status',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: status == 'Running'
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          for (final call in calls)
            ToolCallCard(
              key: ValueKey(call.toolCallId),
              turnId: turnId,
              toolCall: call,
            ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
