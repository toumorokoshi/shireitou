/// Inline previews inside tool call cards (AV-065, AV-069): live terminal
/// output, file edit mini-diffs and links to subagent chats.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../channels.dart';
import '../host_connection.dart';
import '../theme/app_colors.dart';
import 'code_highlight.dart';
import 'diff_view.dart';
import 'terminal_text.dart';

/// Opens a chat of the session (a subagent's, for example).
typedef OpenChat = void Function(String chat);

/// The previews of a tool call's [contents] (see `toolCallPreviews`).
/// [live] subscribes to terminals of a running call.
class ToolCallPreviews extends StatelessWidget {
  /// Creates [ToolCallPreviews].
  const ToolCallPreviews({
    super.key,
    required this.contents,
    required this.live,
    this.onOpenChat,
  });

  /// Terminal, file edit and subagent contents.
  final List<ToolResultContent> contents;

  /// Whether the call is still running.
  final bool live;

  /// Opens a subagent's chat; null hides the button.
  final OpenChat? onOpenChat;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final content in contents)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: switch (content) {
              final ToolResultTerminalContent terminal => TerminalPreview(
                content: terminal,
                live: live,
              ),
              final ToolResultFileEditContent edit => FileEditPreview(
                content: edit,
              ),
              final ToolResultSubagentContent subagent => SubagentCard(
                content: subagent,
                onOpen: onOpenChat,
              ),
              _ => const SizedBox.shrink(),
            },
          ),
      ],
    ),
  );
}

/// A terminal box: [title], a status and the output's last lines.
class TerminalBox extends StatelessWidget {
  /// Creates a [TerminalBox].
  const TerminalBox({
    super.key,
    required this.title,
    required this.status,
    required this.output,
    this.maxHeight = 220,
    this.onOpen,
  });

  /// The terminal's title.
  final String title;

  /// "Running", "Exited (0)", ...
  final String status;

  /// Plain output text.
  final String output;

  /// Height limit; the box scrolls and starts at the bottom.
  final double? maxHeight;

  /// Opens the whole output; null hides the button.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final style = codeStyle(context)
        .copyWith(color: colors.terminal.foreground);
    final body = SingleChildScrollView(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Text(output.isEmpty ? ' ' : output, style: style),
    );
    return Container(
      decoration: BoxDecoration(
        color: colors.terminal.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                child: Icon(Icons.terminal, size: 16, color: colors.mutedText),
              ),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.terminal.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.mutedText,
                ),
              ),
              if (onOpen != null)
                IconButton(
                  tooltip: 'Open terminal',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  color: colors.mutedText,
                  icon: const Icon(Icons.open_in_full),
                  onPressed: onOpen,
                )
              else
                const SizedBox(width: 10),
            ],
          ),
          if (maxHeight case final h?)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: h),
              child: body,
            )
          else
            Expanded(child: body),
        ],
      ),
    );
  }
}

/// Live output of [terminal] (subscribed while shown), falling back to
/// [preview] when the host no longer has it (AV-065, AHP-028).
class LiveTerminal extends ConsumerWidget {
  /// Creates a [LiveTerminal].
  const LiveTerminal({
    super.key,
    required this.terminal,
    required this.title,
    this.preview,
    this.maxHeight = 220,
    this.onOpen,
  });

  /// The terminal channel URI.
  final String terminal;

  /// Fallback title.
  final String title;

  /// Output to show when the terminal cannot be subscribed.
  final String? preview;

  /// Height limit, or null to fill the parent.
  final double? maxHeight;

  /// Opens the whole output.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ChannelSubscriber(
    channel: terminal,
    kind: ChannelKind.terminal,
    builder: (context, failed) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(
          hostConnectionProvider(context.host)
              .select((s) => s.terminalChannels[terminal]?.state),
        );
        return TerminalBox(
          title: state?.title ?? title,
          status: state == null
              ? (failed ? 'Unavailable' : 'Connecting…')
              : terminalStatusLabel(state),
          output: tailLines(
            state == null
                ? plainTerminalText(preview ?? '')
                : terminalPlainText(state),
            maxLines: maxHeight == null ? null : 200,
          ),
          maxHeight: maxHeight,
          onOpen: onOpen,
        );
      },
    ),
  );
}

/// A terminal shown by a tool call: live while the call runs, else the
/// result's preview (subscribing only when there is none).
class TerminalPreview extends StatelessWidget {
  /// Creates a [TerminalPreview].
  const TerminalPreview({super.key, required this.content, required this.live});

  /// The tool result's terminal reference.
  final ToolResultTerminalContent content;

  /// Whether the call is still running.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final result = content.result;
    void open() => openTerminal(
      context,
      terminal: content.resource,
      title: content.title,
      preview: result?.preview,
    );
    if (!live && result?.preview != null) {
      return TerminalBox(
        title: content.title,
        status: switch (result!.exitCode) {
          final code? => 'Exited ($code)',
          null => 'Done',
        },
        output: tailLines(
          plainTerminalText(result.preview!) +
              (result.truncated ?? false ? '\n…' : ''),
          maxLines: 12,
        ),
        onOpen: open,
      );
    }
    return LiveTerminal(
      terminal: content.resource,
      title: content.title,
      preview: result?.preview,
      onOpen: open,
    );
  }
}

/// Opens the whole output of [terminal] on its own page.
Future<void> openTerminal(
  BuildContext context, {
  required String terminal,
  required String title,
  String? preview,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => HostScope(
      host: context.host,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: LiveTerminal(
            terminal: terminal,
            title: title,
            preview: preview,
            maxHeight: null,
          ),
        ),
      ),
    ),
  ),
);

/// A file edit: path, change kind and counts, and a mini-diff (AV-065).
class FileEditPreview extends StatelessWidget {
  /// Creates a [FileEditPreview].
  const FileEditPreview({super.key, required this.content});

  /// The edit.
  final ToolResultFileEditContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final edit = FileEdit(
      before: content.before,
      after: content.after,
      diff: content.diff,
    );
    final uri = fileEditUri(edit);
    final kind = fileChangeKindOf(edit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(fileChangeIcon(kind), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                shortPath(uri),
                style: theme.textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (content.diff case final diff?)
              Text(
                diffStatsLabel(diff.added, diff.removed),
                style: theme.textTheme.labelMedium,
              ),
            IconButton(
              tooltip: 'Open diff',
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.open_in_full),
              onPressed: () => openFileDiff(
                context,
                before: content.before?.content,
                after: content.after?.content,
                uri: uri,
              ),
            ),
          ],
        ),
        FileEditDiff(
          before: content.before?.content,
          after: content.after?.content,
          path: uri,
          maxLines: 12,
        ),
      ],
    );
  }
}

/// An icon for how a file changed (AV-100).
IconData fileChangeIcon(FileChangeKind kind) => switch (kind) {
  FileChangeKind.created => Icons.add_box_outlined,
  FileChangeKind.deleted => Icons.indeterminate_check_box_outlined,
  FileChangeKind.renamed => Icons.drive_file_rename_outline,
  FileChangeKind.modified => Icons.edit_note,
};

/// A label for how a file changed (AV-100).
String fileChangeLabel(FileChangeKind kind) => switch (kind) {
  FileChangeKind.created => 'Added',
  FileChangeKind.deleted => 'Deleted',
  FileChangeKind.renamed => 'Renamed',
  FileChangeKind.modified => 'Modified',
};

/// A subagent spawned by a tool call, with a button that opens its chat
/// (AV-069).
class SubagentCard extends StatelessWidget {
  /// Creates a [SubagentCard].
  const SubagentCard({super.key, required this.content, this.onOpen});

  /// The tool result's subagent reference.
  final ToolResultSubagentContent content;

  /// Opens the subagent's chat.
  final OpenChat? onOpen;

  @override
  Widget build(BuildContext context) {
    final onOpen = this.onOpen;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.smart_toy_outlined),
        title: Text(content.title),
        subtitle: Text(
          [?content.agentName, ?content.description].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onOpen == null
            ? null
            : TextButton(
                onPressed: () => onOpen(content.resource),
                child: const Text('Open chat'),
              ),
      ),
    );
  }
}
