/// Widgets for timeline rows: messages, markdown, reasoning, tool calls,
/// input requests and errors (AV-061 to AV-067, AV-083, AV-084, AV-095).
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../auth/sign_in_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'approval_bar.dart';
import 'chat_commands.dart';
import 'code_highlight.dart';
import 'copy_button.dart';
import 'inline_message_editor.dart';
import 'link_menu.dart';
import 'timeline_items.dart';
import 'timeline_selection.dart';
import 'todo_list.dart';
import 'todo_widgets.dart';
import 'tool_previews.dart';
import 'turn_markdown.dart';

/// Builds the widget for one [item]. [onAction] dispatches a chat action;
/// [onSignIn] signs a tool call in to its MCP server; [onOpenChat]
/// opens a subagent's chat; [onLoadOlder] pages in older turns. A
/// [StepsItem] is expanded when its key is in [expandedSteps];
/// [onToggleSteps] is called with the key to expand or collapse it. The
/// message of turn [editableTurn] gets an edit button that calls
/// [onEditMessage] with the turn and the edited text (AV-088).
Widget buildTimelineItem(
  TimelineItem item,
  ValueChanged<JsonMap> onAction, {
  SignIn? onSignIn,
  OpenChat? onOpenChat,
  VoidCallback? onLoadOlder,
  Set<String> expandedSteps = const {},
  ValueChanged<String>? onToggleSteps,
  String? editableTurn,
  void Function(String turnId, String text)? onEditMessage,
}) => switch (item) {
  UserMessageItem(:final turnId, :final message, :final startedAt) =>
    UserMessageBubble(
      message: message,
      startedAt: startedAt,
      onEdit: turnId == editableTurn && onEditMessage != null
          ? (text) => onEditMessage(turnId, text)
          : null,
    ),
  StepsItem() => StepsRow(
    item: item,
    expanded: expandedSteps.contains(item.key),
    onToggle: () => onToggleSteps?.call(item.key),
    buildStep: (step) => buildTimelineItem(
      step,
      onAction,
      onSignIn: onSignIn,
      onOpenChat: onOpenChat,
    ),
  ),
  ToolCallGroupItem(:final turnId, :final calls) => ToolCallGroupCard(
    turnId: turnId,
    calls: calls,
  ),
  LoadOlderItem() => LoadOlderRow(onLoad: onLoadOlder),
  WorkingItem(:final activity) => WorkingIndicatorRow(activity: activity),
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
  TurnFooterItem(:final turn) => _TurnFooter(turn),
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

/// The last timeline row while the chat works: three pulsing dots (a
/// static "…" when the platform asks for reduced motion) and the current
/// [activity].
class WorkingIndicatorRow extends StatefulWidget {
  /// Creates a [WorkingIndicatorRow].
  const WorkingIndicatorRow({super.key, this.activity});

  /// What the agent is doing now, or null.
  final String? activity;

  @override
  State<WorkingIndicatorRow> createState() => _WorkingIndicatorRowState();
}

class _WorkingIndicatorRowState extends State<WorkingIndicatorRow>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final activity = widget.activity;
    return Semantics(
      label: workingLabel(activity),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (MediaQuery.disableAnimationsOf(context))
              Text(
                '…',
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              )
            else
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var dot = 0; dot < 3; dot++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Opacity(
                          opacity: typingDotOpacity(dot, _pulse.value),
                          child: Icon(Icons.circle, size: 6, color: color),
                        ),
                      ),
                  ],
                ),
              ),
            if (activity != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  activity,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The user's message (AV-095): a right-aligned bubble with a light fill,
/// at most nine tenths of the timeline wide. With [onEdit], an edit button
/// beside it opens the text in an inline editor, and Enter restarts from
/// the edited message (AV-088).
class UserMessageBubble extends StatefulWidget {
  /// Creates a [UserMessageBubble].
  const UserMessageBubble({
    super.key,
    required this.message,
    this.startedAt,
    this.onEdit,
  });

  /// The message.
  final Message message;

  /// ISO 8601 timestamp at which the turn started, when available.
  final String? startedAt;

  /// Restarts from this message with the edited text; no edit button when
  /// null.
  final ValueChanged<String>? onEdit;

  @override
  State<UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<UserMessageBubble> {
  bool _editing = false;

  @override
  void didUpdateWidget(UserMessageBubble old) {
    super.didUpdateWidget(old);
    // The message is no longer the latest (or the chat became read-only).
    if (widget.onEdit == null) _editing = false;
  }

  @override
  Widget build(BuildContext context) {
    final onEdit = widget.onEdit;
    if (_editing && onEdit != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 28),
        child: InlineMessageEditor(
          initial: widget.message.text,
          helperText: 'Enter restarts from this message, Esc cancels',
          saveTooltip: 'Restart from here',
          onSave: (text) {
            setState(() => _editing = false);
            if (text.trim().isNotEmpty) onEdit(text);
          },
          onCancel: () => setState(() => _editing = false),
        ),
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final timestamp = formatTurnTimestamp(
      widget.startedAt,
      MaterialLocalizations.of(context),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onEdit != null)
              Padding(
                padding: const EdgeInsets.only(top: 24, right: 4),
                child: IconButton(
                  tooltip: 'Edit and restart from here',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  color: colors.mutedText,
                  icon: const Icon(AppIcons.edit),
                  onPressed: () => setState(() => _editing = true),
                ),
              ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.9,
                    ),
                    margin: EdgeInsets.only(
                      top: 24,
                      bottom: timestamp == null ? 28 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bubbleFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // A leaf of its own: next to the edit button, Flutter web
                    // would expose the text only as the row's aria-label.
                    child: Semantics(
                      container: true,
                      child: Text(
                        widget.message.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (timestamp != null)
                    Tooltip(
                      message: widget.startedAt!,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 24),
                        child: Text(
                          timestamp,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.mutedText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats an AHP turn start timestamp in the user's local date and time
/// conventions. Returns null when the host omitted or malformed it.
String? formatTurnTimestamp(
  String? value,
  MaterialLocalizations localizations, {
  required bool alwaysUse24HourFormat,
}) {
  final timestamp = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (timestamp == null) return null;
  final date = localizations.formatCompactDate(timestamp);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(timestamp),
    alwaysUse24HourFormat: alwaysUse24HourFormat,
  );
  return '$date · $time';
}

/// The style of agent replies (AV-095): body text with a comfortable line
/// height, compact headings, inline code on a tinted background, and
/// tables with bordered, padded cells and a bold, start-aligned header
/// row, drawn with the scheme's outline (the hairline is too faint for
/// cell borders in the reference).
MarkdownStyleSheet markdownStyle(ThemeData theme, AppColors colors) {
  final scheme = theme.colorScheme;
  final text = theme.textTheme;
  final body = text.bodyMedium?.copyWith(height: 1.6);
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: body,
    listBullet: body,
    tableBody: body,
    tableHead: body?.copyWith(fontWeight: FontWeight.w600),
    tableHeadAlign: TextAlign.start,
    h1: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    h2: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
    h3: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    h1Padding: const EdgeInsets.only(top: 12),
    h2Padding: const EdgeInsets.only(top: 12),
    h3Padding: const EdgeInsets.only(top: 8),
    blockSpacing: 12,
    code: text.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'DejaVu Sans Mono'],
      backgroundColor: scheme.surfaceContainerHighest,
    ),
    tableBorder: TableBorder.all(color: scheme.outline),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    tableColumnWidth: const IntrinsicColumnWidth(),
  );
}

/// Assistant markdown (AV-061, AV-095): full width with no bubble. Links
/// open in the browser; right-clicking one shows it in [showLinkDialog]
/// (AV-075).
class MarkdownText extends StatefulWidget {
  /// Creates a [MarkdownText] for [data].
  const MarkdownText(this.data, {super.key});

  /// Markdown source.
  final String data;

  @override
  State<MarkdownText> createState() => _MarkdownTextState();
}

class _MarkdownTextState extends State<MarkdownText> {
  /// Whether the next link callback is a right-click rather than a tap.
  bool _rightClicked = false;

  /// The markdown package only hands a link's `href` to `onTapLink`, so
  /// a right-click runs the link's tap with [_rightClicked] set.
  void _onRightClick(TapGestureRecognizer link) {
    _rightClicked = true;
    try {
      link.onTap?.call();
    } finally {
      _rightClicked = false;
    }
  }

  void _onLink(String? href) {
    if (href == null) return;
    if (_rightClicked) {
      unawaited(showLinkDialog(context, href));
    } else {
      openLink(href);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LinkSecondaryTap(
      onLink: _onRightClick,
      child: MarkdownBody(
        data: widget.data,
        styleSheet: markdownStyle(Theme.of(context), AppColors.of(context)),
        builders: {'pre': _codeBlocks},
        onTapLink: (_, href, _) => _onLink(href),
      ),
    ),
  );
}

/// "Jump to latest" (AV-066, AV-095): a small round button with ↓ at the
/// bottom right of the timeline, shown while the user scrolled up.
class JumpToLatestButton extends StatelessWidget {
  /// Creates a [JumpToLatestButton].
  const JumpToLatestButton({super.key, required this.onPressed});

  /// Scrolls to the newest row.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return IconButton(
      tooltip: 'Jump to latest',
      onPressed: onPressed,
      iconSize: 18,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: colors.raisedSurface,
        foregroundColor: colors.mutedText,
        side: BorderSide(color: colors.hairline),
      ),
      icon: const Icon(AppIcons.jumpToLatest),
    );
  }
}

/// A turn's steps collapsed into one muted line (AV-095): "Completed 3
/// steps in 1m 47s", or "Working… 3 steps" with the typing indicator
/// (AV-072) while the chat works. Tapping it shows the steps, built with
/// [buildStep], below a hairline on the left.
class StepsRow extends StatelessWidget {
  /// Creates a [StepsRow].
  const StepsRow({
    super.key,
    required this.item,
    required this.expanded,
    required this.onToggle,
    required this.buildStep,
  });

  /// The steps.
  final StepsItem item;

  /// Whether the steps are shown.
  final bool expanded;

  /// Expands or collapses the steps.
  final VoidCallback onToggle;

  /// Builds one step's widget.
  final Widget Function(TimelineItem step) buildStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final muted = colors.mutedText;
    final summary = stepsSummary(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label: summary,
              excludeSemantics: true,
              onTap: onToggle,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                        size: 18,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (item.working) ...[
              const SizedBox(width: 8),
              Flexible(child: WorkingIndicatorRow(activity: item.activity)),
            ],
          ],
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.only(left: 4, bottom: 8),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final step in item.steps)
                  KeyedSubtree(key: ValueKey(step.key), child: buildStep(step)),
              ],
            ),
          ),
      ],
    );
  }
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
        Text(
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
          SelectionContainer.disabled(
            child: Row(
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const Spacer(),
                CopyButton(text: () => text, tooltip: 'Copy $label'),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ScrollSelection(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
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
              LinkContextMenu(
                url: url,
                child: TextButton(
                  onPressed: () => openLink(url),
                  child: Text(url),
                ),
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
            child: Text(
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

/// A finished turn's footer (AV-067): a button that copies the reply as
/// markdown (AV-071), then the end state, duration and tokens in the
/// smallest muted text, so it reads as metadata under the reply rather
/// than part of it (the reference UI has no footer at all).
class _TurnFooter extends StatelessWidget {
  const _TurnFooter(this.turn);

  final Turn turn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        CopyButton(
          text: () => turnMarkdown(turn),
          tooltip: 'Copy reply',
          iconSize: 14,
        ),
        Flexible(
          // Its own node, so screen readers (and the web's text) do not
          // fold the button into the footer's label.
          child: Semantics(
            container: true,
            child: Text(
              turnFooterText(turn),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.of(context).mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
