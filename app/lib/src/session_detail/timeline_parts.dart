/// Widgets for timeline rows: messages, markdown, reasoning, tool calls,
/// input requests and errors (AV-061 to AV-067, AV-083, AV-084).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_commands.dart';
import 'timeline_items.dart';

/// Pushes a token for a protected resource (`authenticate`).
typedef Authenticate = Future<void> Function({
  required String resource,
  required String token,
});

/// Builds the widget for one [item]. [onAction] dispatches a chat action;
/// [onAuthenticate] signs a tool call in to its MCP server.
Widget buildTimelineItem(
  TimelineItem item,
  ValueChanged<JsonMap> onAction, {
  Authenticate? onAuthenticate,
}) => switch (item) {
  UserMessageItem(:final message) => UserMessageBubble(message: message),
  ResponsePartItem(:final turnId, :final part, :final active) => switch (part) {
    MarkdownResponsePart(:final content) => MarkdownText(content),
    ReasoningResponsePart(:final content) => ReasoningBlock(content: content),
    ToolCallResponsePart(:final toolCall) => ToolCallCard(
      turnId: turnId,
      toolCall: toolCall,
      onAction: active ? onAction : null,
      onAuthenticate: active ? onAuthenticate : null,
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
  PendingMessageItem(:final kind, :final pending) => PendingMessageRow(
    kind: kind,
    pending: pending,
    onRemove: () => onAction(
      ChatPendingMessageRemovedAction(kind: kind, id: pending.id).toJson(),
    ),
  ),
};

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
      onTapLink: (_, href, _) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri != null) launchUrl(uri);
      },
    ),
  );
}

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
    this.onAuthenticate,
  });

  /// Turn the call belongs to.
  final String turnId;

  /// The tool call.
  final ToolCallState toolCall;

  /// Dispatches approve/deny; null for finished turns.
  final ValueChanged<JsonMap>? onAction;

  /// Pushes an MCP sign-in token; null hides "Sign in".
  final Authenticate? onAuthenticate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          if (waiting && onAction != null) _approvalBar(context),
          if (toolCall case final ToolCallAuthRequiredState call
              when onAction != null)
            _AuthBar(
              auth: call.auth,
              onSignIn: onAuthenticate,
              onCancel: () => onAction!(cancelAuthAction(turnId, call)),
            ),
        ],
      ),
    );
  }

  Widget _approvalBar(BuildContext context) {
    final onAction = this.onAction!;
    final pending = switch (toolCall) {
      final ToolCallPendingConfirmationState pending => pending,
      _ => null,
    };
    final title = pending?.confirmationTitle?.text;
    final options = pending?.options ?? const <ConfirmationOption>[];
    final buttons = options.isEmpty
        ? [
            FilledButton(
              onPressed: () => onAction(
                confirmToolCallAction(turnId, toolCall, approve: true),
              ),
              child: const Text('Approve'),
            ),
            OutlinedButton(
              onPressed: () => onAction(
                confirmToolCallAction(turnId, toolCall, approve: false),
              ),
              child: const Text('Deny'),
            ),
          ]
        : [
            for (final option in options)
              option.kind == ConfirmationOptionKind.approve
                  ? FilledButton(
                      onPressed: () => onAction(
                        confirmToolCallAction(
                          turnId,
                          toolCall,
                          approve: true,
                          option: option,
                        ),
                      ),
                      child: Text(option.label),
                    )
                  : OutlinedButton(
                      onPressed: () => onAction(
                        confirmToolCallAction(
                          turnId,
                          toolCall,
                          approve: false,
                          option: option,
                        ),
                      ),
                      child: Text(option.label),
                    ),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[Text(title), const SizedBox(height: 8)],
          if (pending?.riskAssessment case ToolCallRiskAssessmentCompleteState(
            :final safety,
          )) ...[
            Text('Risk assessment: safety ${safety.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
          ],
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
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
  final Authenticate? onSignIn;
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
                  onPressed: () => signInWithToken(
                    context,
                    resource: resource,
                    onAuthenticate: onSignIn,
                  ),
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

/// Asks for a token for [resource] and pushes it with [onAuthenticate].
/// Shows a snackbar when the host refuses it.
///
/// There is no OAuth flow yet (AHP-060): the user pastes a token.
Future<void> signInWithToken(
  BuildContext context, {
  required ProtectedResourceMetadata resource,
  required Authenticate onAuthenticate,
}) async {
  final token = await showDialog<String>(
    context: context,
    builder: (context) => _TokenDialog(resource: resource),
  );
  if (token == null || token.isEmpty) return;
  try {
    await onAuthenticate(resource: resource.resource, token: token);
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text('Sign-in failed: $error')));
    }
  }
}

class _TokenDialog extends StatefulWidget {
  const _TokenDialog({required this.resource});

  final ProtectedResourceMetadata resource;

  @override
  State<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<_TokenDialog> {
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    final docs = resource.resourceDocumentation;
    return AlertDialog(
      title: Text('Sign in to ${resource.resourceName ?? resource.resource}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paste an access token for ${resource.resource}.'),
          if (docs != null)
            TextButton(
              onPressed: () => launchUrl(Uri.parse(docs)),
              child: const Text('How to get a token'),
            ),
          TextField(
            controller: _token,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Access token'),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _token.text.trim()),
          child: const Text('Sign in'),
        ),
      ],
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

/// An input request: an inline form while open, a summary once answered
/// (AV-084).
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
    for (final q in widget.part.request.questions ?? <ChatInputQuestion>[])
      q.id: switch (q) {
        ChatInputMultiSelectQuestion() => <String>{},
        ChatInputBooleanQuestion(:final defaultValue) => defaultValue ?? false,
        ChatInputTextQuestion(:final defaultValue?) => defaultValue,
        ChatInputNumberQuestion(:final defaultValue?) => '$defaultValue',
        _ => '',
      },
  };

  void _set(String id, Object? value) => setState(() => _values[id] = value);

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
                    onPressed: inputComplete(request, _values)
                        ? () => onAction(
                            inputCompletedAction(
                              request,
                              accept: true,
                              values: _values,
                            ),
                          )
                        : null,
                    child: const Text('Submit'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        onAction(inputCompletedAction(request, accept: false)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: switch (q) {
        ChatInputBooleanQuestion() => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: help == null ? null : Text(help),
          value: value == true,
          onChanged: (v) => _set(q.id, v),
        ),
        ChatInputSingleSelectQuestion(:final options) =>
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: label, helperText: help),
            initialValue: (value as String?)?.isEmpty ?? true ? null : value,
            items: [
              for (final o in options)
                DropdownMenuItem(value: o.id, child: Text(o.label)),
            ],
            onChanged: (v) => _set(q.id, v ?? ''),
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
                      _set(q.id, next);
                    },
                  ),
              ],
            ),
          ],
        ),
        _ => TextFormField(
          initialValue: value as String?,
          decoration: InputDecoration(labelText: label, helperText: help),
          keyboardType: q is ChatInputNumberQuestion
              ? TextInputType.number
              : TextInputType.text,
          onChanged: (v) => _set(q.id, v),
        ),
      },
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

/// A steering or queued message (AV-081), removable.
class PendingMessageRow extends StatelessWidget {
  /// Creates a [PendingMessageRow].
  const PendingMessageRow({
    super.key,
    required this.kind,
    required this.pending,
    required this.onRemove,
  });

  /// Steering or queued.
  final PendingMessageKind kind;

  /// The pending message.
  final PendingMessage pending;

  /// Removes the message.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: InputChip(
      avatar: Icon(
        kind == PendingMessageKind.steering ? Icons.bolt : Icons.schedule,
        size: 16,
      ),
      label: Text(
        '${kind == PendingMessageKind.steering ? 'Steering' : 'Queued'}: '
        '${pending.message.text}',
        overflow: TextOverflow.ellipsis,
      ),
      onDeleted: onRemove,
      deleteButtonTooltipMessage: 'Remove',
    ),
  );
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
