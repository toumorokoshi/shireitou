/// The "Files changed" pane (AV-100 to AV-103): the session's (and, on
/// 1.0.0, the chat's) changesets, each file with how it changed, its line
/// counts and a "reviewed" checkbox, host-advertised operations, and the
/// diff viewer.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../channels.dart';
import '../host_connection.dart';
import '../session_detail/diff_view.dart';
import '../session_detail/session_inputs.dart';
import '../session_detail/tool_previews.dart';
import '../shortcuts.dart';
import 'review_logic.dart';
import '../theme/app_icons.dart';

/// The changes of [session] and its open [chat].
class ChangesPane extends ConsumerStatefulWidget {
  /// Creates a [ChangesPane].
  const ChangesPane({super.key, required this.session, this.chat});

  /// The session URI.
  final String session;

  /// The open chat URI.
  final String? chat;

  @override
  ConsumerState<ChangesPane> createState() => _ChangesPaneState();
}

class _ChangesPaneState extends ConsumerState<ChangesPane> {
  String? _template;
  String? _turnId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(
      hostConnectionProvider(context.host)
          .select((s) => s.sessionChannels[widget.session]?.state),
    );
    final chatUri = widget.chat;
    final chat = chatUri == null
        ? null
        : ref.watch(
            hostConnectionProvider(context.host)
                .select((s) => s.chatChannels[chatUri]?.state),
          );
    final version = ref.watch(
      hostConnectionProvider(context.host).select((s) => s.protocolVersion),
    );
    final entries = availableChangesets(
      session,
      chat,
      chatChangesets: supportsFeature(version, ProtocolFeature.chatChangesets),
    );
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('The host lists no changes for this session.'),
        ),
      );
    }
    final entry =
        entries
            .where((e) => e.changeset.uriTemplate == _template)
            .firstOrNull ??
        entries.first;
    final changeset = entry.changeset;
    final scope = changesetScopeOf(changeset);
    final turns = turnChoices(chat);
    final turnId = turns.any((t) => t.id == _turnId) ? _turnId : null;
    final uri = changesetUriFor(changeset, chat, turnId: turnId);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text('Files changed', style: theme.textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: changeset.uriTemplate,
                isDense: true,
                items: [
                  for (final e in entries)
                    DropdownMenuItem(
                      value: e.changeset.uriTemplate,
                      child: Text(
                        e.fromChat
                            ? '${e.changeset.label} (chat)'
                            : e.changeset.label,
                      ),
                    ),
                ],
                onChanged: (t) => setState(() => _template = t),
              ),
              if (scope == ChangesetScope.turn && turns.isNotEmpty)
                DropdownButton<String>(
                  value: turnId ?? turns.first.id,
                  isDense: true,
                  items: [
                    for (final t in turns)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (t) => setState(() => _turnId = t),
                ),
            ],
          ),
        ),
        if (changeset.description case final d?)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(d, style: theme.textTheme.bodySmall),
          ),
        const Divider(),
        Expanded(
          child: uri == null
              ? const Center(child: Text('No turns to show changes for yet.'))
              : ChannelSubscriber(
                  key: ValueKey(uri),
                  channel: uri,
                  kind: ChannelKind.changeset,
                  builder: (context, failed) => _ChangesetView(
                    uri: uri,
                    review: supportsReview(changeset),
                    failed: failed,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChangesetView extends ConsumerWidget {
  const _ChangesetView({
    required this.uri,
    required this.review,
    required this.failed,
  });

  final String uri;
  final bool review;
  final bool failed;

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _invoke(
    BuildContext context,
    WidgetRef ref,
    ChangesetOperation op, {
    ChangesetOperationTarget? target,
  }) async {
    final host = context.host;
    if (op.confirmation case final question?) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(op.label),
          content: Text(question.text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(op.label),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      final result = await ref
          .read(hostConnectionProvider(host).notifier)
          .invokeChangesetOperation(uri, op.id, target: target);
      if (!context.mounted) return;
      _snack(context, result.message?.text ?? '${op.label}: done');
      if (result.followUp case final followUp?) {
        if (followUp.external ?? false) {
          await launchUrl(Uri.parse(followUp.content.uri));
        } else if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (_) => HostScope(
              host: host,
              child: _FollowUpDialog(
                title: op.label,
                content: followUp.content.uri,
              ),
            ),
          );
        }
      }
    } on Object catch (error) {
      if (context.mounted) _snack(context, '${op.label} failed: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      hostConnectionProvider(context.host)
          .select((s) => s.changesetChannels[uri]?.state),
    );
    if (state == null) {
      return Center(
        child: failed
            ? const Text('Could not load these changes.')
            : const CircularProgressIndicator(),
      );
    }
    final theme = Theme.of(context);
    final files = state.files;
    final reviewed = reviewedCount(files);
    final status = changesetStatusLabel(state);
    final fileOps = operationsFor(state, ChangesetOperationScope.resource);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (state.status != ChangesetStatus.error)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(child: Text(status)),
              ],
            ),
          ),
        Text(changesetSummary(files), style: theme.textTheme.bodyMedium),
        if (review && files.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Reviewed $reviewed of ${files.length}'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: reviewed / files.length),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final op in operationsFor(
              state,
              ChangesetOperationScope.changeset,
            ))
              _OperationButton(
                op: op,
                onPressed: () => _invoke(context, ref, op),
              ),
          ],
        ),
        for (final op in state.operations ?? const <ChangesetOperation>[])
          if (op.status == ChangesetOperationStatus.error)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${op.label} failed: ${op.error?.message ?? 'unknown error'}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        const SizedBox(height: 8),
        if (files.isEmpty) const Text('No changed files.'),
        for (final file in files)
          _FileRow(
            file: file,
            review: review,
            onReviewed: (value) => _dispatchReview(context, ref, file, value),
            fileOps: fileOps,
            onOperation: (op) => _invoke(
              context,
              ref,
              op,
              target: ChangesetOperationTargetResource(resource: file.id),
            ),
          ),
      ],
    );
  }

  void _dispatchReview(
    BuildContext context,
    WidgetRef ref,
    ChangesetFile file,
    bool reviewed,
  ) {
    try {
      ref
          .read(hostConnectionProvider(context.host).notifier)
          .dispatch(
            uri,
            ChangesetFilesReviewChangedAction(
              files: [file.id],
              reviewed: reviewed,
            ).toJson(),
          );
    } on StateError catch (error) {
      _snack(context, 'Could not send that: ${error.message}');
    }
  }
}

class _OperationButton extends StatelessWidget {
  const _OperationButton({required this.op, required this.onPressed});

  final ChangesetOperation op;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final running = op.status == ChangesetOperationStatus.running;
    final button = FilledButton.tonalIcon(
      onPressed: running || op.status == ChangesetOperationStatus.disabled
          ? null
          : onPressed,
      icon: running
          ? const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_operationIcon(op.icon), size: 18),
      label: Text(op.label),
    );
    return op.description == null
        ? button
        : Tooltip(message: op.description!, child: button);
  }
}

IconData _operationIcon(String? hint) => switch (hint) {
  'check' => Icons.check,
  'trash' || 'discard' => Icons.delete_outline,
  'git-pull-request' || 'pr' => Icons.merge_type,
  'undo' || 'revert' => Icons.undo,
  _ => Icons.play_arrow_outlined,
};

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.review,
    required this.onReviewed,
    required this.fileOps,
    required this.onOperation,
  });

  final ChangesetFile file;
  final bool review;
  final ValueChanged<bool> onReviewed;
  final List<ChangesetOperation> fileOps;
  final ValueChanged<ChangesetOperation> onOperation;

  @override
  Widget build(BuildContext context) {
    final edit = file.edit;
    final uri = fileEditUri(edit);
    final kind = fileChangeKindOf(edit);
    final diff = edit.diff;
    final renamedFrom = kind == FileChangeKind.renamed
        ? ' from ${shortPath(edit.before!.uri)}'
        : '';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Tooltip(
        message: fileChangeLabel(kind),
        child: Icon(fileChangeIcon(kind)),
      ),
      title: Text(shortPath(uri), overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${fileChangeLabel(kind)}$renamedFrom'
        '${diff == null ? '' : ' · ${diffStatsLabel(diff.added, diff.removed)}'}',
      ),
      onTap: () => openFileDiff(
        context,
        before: edit.before?.content,
        after: edit.after?.content,
        uri: uri,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fileOps.isNotEmpty)
            PopupMenuButton<ChangesetOperation>(
              tooltip: 'File actions',
              onSelected: onOperation,
              itemBuilder: (_) => [
                for (final op in fileOps)
                  PopupMenuItem(
                    value: op,
                    enabled:
                        op.status == ChangesetOperationStatus.idle ||
                        op.status == ChangesetOperationStatus.error,
                    child: Text(op.label),
                  ),
              ],
            ),
          if (review)
            Tooltip(
              message: 'Reviewed',
              child: Checkbox(
                value: file.reviewed ?? false,
                onChanged: (v) => onReviewed(v ?? false),
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowUpDialog extends ConsumerWidget {
  const _FollowUpDialog({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(
      resourceTextProvider((host: context.host, uri: content)),
    );
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(
          text.when(
            data: (t) => t,
            loading: () => 'Loading…',
            error: (e, _) => 'Could not load: $e',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// How long the review pane takes to open or close (AV-003).
const reviewPaneAnimation = Duration(milliseconds: 200);

/// The review pane beside the timeline on wide layouts (AV-003): [child]
/// at [width] after a divider while [open], sliding open and shut (at once
/// with reduced motion). Nothing is built while closed.
class CollapsibleReviewPane extends StatelessWidget {
  /// Creates the pane around [child].
  const CollapsibleReviewPane({
    super.key,
    required this.open,
    required this.width,
    required this.child,
    this.handle,
  });

  /// Whether the pane is open.
  final bool open;

  /// The open pane's width, without the divider.
  final double width;

  /// The pane's content.
  final Widget child;

  /// A [PaneResizeHandle] laid over the divider, so the pane can be
  /// resized (AV-005).
  final Widget? handle;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : reviewPaneAnimation,
    curve: Curves.easeInOut,
    builder: (context, shown, pane) => shown == 0
        ? const SizedBox.shrink()
        : ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: shown,
              child: pane,
            ),
          ),
    child: SizedBox(
      width: width + 1,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
          if (handle case final handle?)
            Positioned(top: 0, bottom: 0, left: 0, child: handle),
        ],
      ),
    ),
  );
}

/// Opens and closes the review pane (AV-003): an icon in the title bar
/// (AV-091) with the session's [changes] ("+3 −1 · 1 file") in its
/// tooltip and the number of changed files in a badge, so the user sees
/// there is something to review.
class ReviewPaneToggle extends StatelessWidget {
  /// Creates the toggle.
  const ReviewPaneToggle({
    super.key,
    required this.open,
    required this.changes,
    required this.onToggle,
  });

  /// Whether the pane is open.
  final bool open;

  /// The session's change counts, if the host reports them.
  final ChangesSummary? changes;

  /// Opens or closes the pane.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tooltip = reviewToggleTooltip(
      open: open,
      shortcut: shortcutLabel(AppCommand.toggleReviewPane),
    );
    final files = changes?.files ?? 0;
    final changed =
        files > 0 ||
        (changes?.additions ?? 0) > 0 ||
        (changes?.deletions ?? 0) > 0;
    return Semantics(
      label: reviewToggleSemantics(open: open, changes: changes),
      button: true,
      onTap: onToggle,
      excludeSemantics: true,
      child: IconButton(
        tooltip: [tooltip, ?changesLabel(changes)].join('\n'),
        isSelected: open,
        onPressed: onToggle,
        icon: Badge(
          isLabelVisible: changed,
          backgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          label: files > 0 ? Text('$files') : null,
          smallSize: 6,
          child: Icon(open ? AppIcons.reviewPane : AppIcons.reviewPaneOff),
        ),
      ),
    );
  }
}
