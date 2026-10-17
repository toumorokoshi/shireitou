/// Pure view logic for the "Files changed" pane (AV-100 to AV-103): which
/// changesets a session and chat advertise, and the URI to subscribe to
/// for the turns the user picked.
library;

import 'package:ahp_client/ahp_client.dart';

/// A changeset the pane can show, and whether the chat (rather than the
/// session) advertised it.
typedef ChangesetEntry = ({Changeset changeset, bool fromChat});

/// The changesets of [session], then those of [chat] when [chatChangesets]
/// (per-chat changesets are 1.0.0 only). Changesets the session already
/// lists (same template) are not repeated.
List<ChangesetEntry> availableChangesets(
  SessionState? session,
  ChatState? chat, {
  required bool chatChangesets,
}) {
  final fromSession = session?.changesets ?? const <Changeset>[];
  final templates = {for (final c in fromSession) c.uriTemplate};
  return [
    for (final c in fromSession) (changeset: c, fromChat: false),
    if (chatChangesets)
      for (final c in chat?.changesets ?? const <Changeset>[])
        if (!templates.contains(c.uriTemplate)) (changeset: c, fromChat: true),
  ];
}

/// The turns of [chat] a turn changeset can be expanded with, newest
/// first: the active turn, then the finished ones.
List<({String id, String label})> turnChoices(ChatState? chat) {
  if (chat == null) return const [];
  final turns = [
    for (final (i, t) in chat.turns.indexed)
      (id: t.id, n: i + 1, text: t.message.text),
    if (chat.activeTurn case final a?)
      (id: a.id, n: chat.turns.length + 1, text: a.message.text),
  ];
  return [
    for (final t in turns.reversed)
      (id: t.id, label: 'Turn ${t.n}: ${_preview(t.text)}'),
  ];
}

String _preview(String text) {
  final line = text.split('\n').first.trim();
  return line.length <= 40 ? line : '${line.substring(0, 39)}…';
}

/// The channel URI for [entry] with the picked turns: [turnId] for a turn
/// changeset (default: the newest turn), [originalTurnId] and
/// [modifiedTurnId] for a comparison (default: oldest and newest). Null
/// when the chat has no turns to expand with.
String? changesetUriFor(
  Changeset changeset,
  ChatState? chat, {
  String? turnId,
  String? originalTurnId,
  String? modifiedTurnId,
}) {
  final turns = turnChoices(chat);
  return expandChangesetUri(
    changeset,
    turnId: turnId ?? turns.firstOrNull?.id,
    originalTurnId: originalTurnId ?? turns.lastOrNull?.id,
    modifiedTurnId: modifiedTurnId ?? turns.firstOrNull?.id,
  );
}

/// "3 files · +10 −2".
String changesetSummary(List<ChangesetFile> files) {
  final (:added, :removed) = changesetLineCounts(files);
  return '${files.length} file${files.length == 1 ? '' : 's'} · '
      '+$added −$removed';
}

/// The operations of [state] that apply to [scope].
List<ChangesetOperation> operationsFor(
  ChangesetState state,
  ChangesetOperationScope scope,
) => [
  for (final op in state.operations ?? const <ChangesetOperation>[])
    if (op.scopes.contains(scope)) op,
];

/// A label for a changeset's computation status.
String? changesetStatusLabel(ChangesetState state) => switch (state.status) {
  ChangesetStatus.computing => 'Computing changes…',
  ChangesetStatus.recomputing => 'Updating…',
  ChangesetStatus.error => 'Error: ${state.error?.message ?? 'unknown'}',
  ChangesetStatus.ready || ChangesetStatus.$unknown => null,
};

/// The review pane toggle's tooltip (AV-003): "Show review pane (⌥⌘B)"
/// while closed, "Hide …" while [open]; [shortcut] is the key's label.
String reviewToggleTooltip({required bool open, required String shortcut}) =>
    '${open ? 'Hide' : 'Show'} review pane ($shortcut)';

/// What a screen reader says for the review pane toggle: the action, then
/// [changes] in words ("3 lines added, 1 removed, 1 file").
String reviewToggleSemantics({
  required bool open,
  required ChangesSummary? changes,
}) {
  final files = changes?.files;
  return [
    '${open ? 'Hide' : 'Show'} review pane',
    if (changes != null)
      '${changes.additions ?? 0} lines added, ${changes.deletions ?? 0} removed',
    if (files != null) '$files ${files == 1 ? 'file' : 'files'}',
  ].join(', ');
}
