/// The approval bar under a tool call that waits for the user (AV-083):
/// approve or deny (or the host's own options, grouped), the risk
/// assessment, editing the input before approving, and accepting or
/// discarding a result that needs confirmation.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import 'chat_commands.dart';
import 'timeline_items.dart';

/// The buttons, risk and editor for a [ToolCallConfirmationState].
class ApprovalBar extends StatefulWidget {
  /// Creates an [ApprovalBar].
  const ApprovalBar({
    super.key,
    required this.turnId,
    required this.toolCall,
    required this.onAction,
  });

  /// The turn of [toolCall].
  final String turnId;

  /// The waiting call.
  final ToolCallState toolCall;

  /// Dispatches the answer.
  final ValueChanged<JsonMap> onAction;

  @override
  State<ApprovalBar> createState() => _ApprovalBarState();
}

class _ApprovalBarState extends State<ApprovalBar> {
  /// The input as the user edited it; null while unedited.
  String? _edited;

  /// The input the editor started from (inline, or read from the host).
  String? _original;

  bool _loadingInput = false;

  @override
  void didUpdateWidget(ApprovalBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toolCall.toolCallId != widget.toolCall.toolCallId) {
      _edited = null;
      _original = null;
    }
  }

  void _answer({required bool approve, ConfirmationOption? option}) {
    final original = _original;
    final edited = _edited;
    widget.onAction(
      confirmToolCallAction(
        widget.turnId,
        widget.toolCall,
        approve: approve,
        option: option,
        editedInput: approve && original != null && edited != null
            ? editedToolInput(original, edited)
            : null,
      ),
    );
  }

  /// The current input text: inline, or read from the host for a
  /// `ContentRef` (never cached: it may change until confirmed).
  Future<String?> _currentInput() async {
    switch (widget.toolCall.toolInput) {
      case InlineToolInput(:final value):
        return value;
      case ContentRef(:final uri):
        setState(() => _loadingInput = true);
        try {
          final container = ProviderScope.containerOf(context);
          final result = await container
              .read(hostConnectionProvider(HostScope.of(context)).notifier)
              .readResource(uri);
          return result.encoding == ContentEncoding.base64
              ? utf8.decode(base64.decode(result.data), allowMalformed: true)
              : result.data;
        } on Object catch (error) {
          if (mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text('Could not read the input: $error')),
            );
          }
          return null;
        } finally {
          if (mounted) setState(() => _loadingInput = false);
        }
      case null:
        return null;
    }
  }

  Future<void> _edit() async {
    final original = _original ?? await _currentInput();
    if (original == null || !mounted) return;
    final edited = await showDialog<String>(
      context: context,
      builder: (context) => EditToolInputDialog(
        original: original,
        initial: _edited ?? prettyToolInput(original),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() {
      _original = original;
      _edited = editedToolInput(original, edited) == null ? null : edited;
    });
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.toolCall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: call is ToolCallPendingResultConfirmationState
          ? _resultBar(context, call)
          : _confirmBar(context, call),
    );
  }

  Widget _resultBar(
    BuildContext context,
    ToolCallPendingResultConfirmationState call,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        call.success
            ? 'Use this result? The agent sees it only if you accept it.'
            : 'The tool failed. Pass the failure to the agent?',
      ),
      if (toolCallOutputText(call) case final output?) ...[
        const SizedBox(height: 8),
        _InputPreview(label: 'Result', text: output),
      ],
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: () => _answer(approve: true),
            child: const Text('Use result'),
          ),
          OutlinedButton(
            onPressed: () => _answer(approve: false),
            child: const Text('Discard result'),
          ),
        ],
      ),
    ],
  );

  Widget _confirmBar(BuildContext context, ToolCallState call) {
    final pending = call is ToolCallPendingConfirmationState ? call : null;
    final title = pending?.confirmationTitle?.text;
    final options = pending?.options ?? const <ConfirmationOption>[];
    final editable = (pending?.editable ?? false) && pending?.toolInput != null;
    final edited = _edited;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[Text(title), const SizedBox(height: 8)],
        if (pending?.riskAssessment case final risk?) ...[
          RiskAssessmentView(risk: risk),
          const SizedBox(height: 8),
        ],
        if (edited != null) ...[
          _InputPreview(label: 'Edited input', text: edited),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._buttons(options),
            if (editable)
              TextButton.icon(
                icon: _loadingInput
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                label: Text(edited == null ? 'Edit input' : 'Edit again'),
                onPressed: _loadingInput ? null : _edit,
              ),
            if (edited != null)
              TextButton(
                onPressed: () => setState(() => _edited = null),
                child: const Text('Undo edit'),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buttons(List<ConfirmationOption> options) {
    if (options.isEmpty) {
      return [
        FilledButton(
          onPressed: () => _answer(approve: true),
          child: Text(_edited == null ? 'Approve' : 'Approve edited'),
        ),
        OutlinedButton(
          onPressed: () => _answer(approve: false),
          child: const Text('Deny'),
        ),
      ];
    }
    final primary = options
        .where((o) => o.kind == ConfirmationOptionKind.approve)
        .firstOrNull;
    return [
      for (final (i, group) in confirmationOptionGroups(options).indexed) ...[
        if (i > 0) const SizedBox(height: 24, child: VerticalDivider()),
        for (final option in group)
          if (option.kind == ConfirmationOptionKind.approve)
            identical(option, primary)
                ? FilledButton(
                    onPressed: () => _answer(approve: true, option: option),
                    child: Text(option.label),
                  )
                : FilledButton.tonal(
                    onPressed: () => _answer(approve: true, option: option),
                    child: Text(option.label),
                  )
          else
            OutlinedButton(
              onPressed: () => _answer(approve: false, option: option),
              child: Text(option.label),
            ),
      ],
    ];
  }
}

/// A risk assessment: "Assessing risk…" while the judge runs, then the
/// level, safety score and reason.
class RiskAssessmentView extends StatelessWidget {
  /// Creates a [RiskAssessmentView].
  const RiskAssessmentView({super.key, required this.risk});

  /// The assessment.
  final ToolCallRiskAssessment risk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return switch (risk) {
      ToolCallRiskAssessmentUnknown() => const SizedBox.shrink(),
      ToolCallRiskAssessmentLoadingState() => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Assessing risk…'),
        ],
      ),
      ToolCallRiskAssessmentCompleteState(:final safety, :final reason) => () {
        final level = riskLevel(safety);
        final color = switch (level) {
          RiskLevel.high => scheme.error,
          RiskLevel.medium => scheme.tertiary,
          RiskLevel.low => scheme.primary,
        };
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${level.label} '
                          '(safety ${(safety * 100).round()}%)',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' · ${reason.text}'),
                  ],
                ),
              ),
            ),
          ],
        );
      }(),
    };
  }
}

/// Edits a tool's input before approval; pops with the text.
class EditToolInputDialog extends StatefulWidget {
  /// Creates an [EditToolInputDialog].
  const EditToolInputDialog({
    super.key,
    required this.original,
    required this.initial,
  });

  /// The input as the host proposed it (decides whether JSON is required).
  final String original;

  /// The text to start from.
  final String initial;

  @override
  State<EditToolInputDialog> createState() => _EditToolInputDialogState();
}

class _EditToolInputDialogState extends State<EditToolInputDialog> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final error = toolInputEditError(widget.original, _text.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _text.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit tool input'),
    content: SizedBox(
      width: 560,
      child: TextField(
        controller: _text,
        autofocus: true,
        minLines: 4,
        maxLines: 16,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: 'Input',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _InputPreview extends StatelessWidget {
  const _InputPreview({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
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
    );
  }
}
