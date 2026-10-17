/// Pure pieces of `/` and `@` completions in the composer and the
/// follow-up box (AV-044): the items shown, filtering them as the user
/// types, and applying the accepted one to the text.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';

import '../session_list/folder_grouping.dart';

/// One item in the completion popup.
class ComposerCompletion {
  /// Creates a [ComposerCompletion].
  const ComposerCompletion({
    required this.label,
    required this.insertText,
    this.description,
    this.rangeStart,
    this.rangeEnd,
    this.sourceLength,
    this.attachment,
  });

  /// What the popup shows, such as `/review`.
  final String label;

  /// Shown under [label]; null when the host gave none.
  final String? description;

  /// The text that replaces `[rangeStart, rangeEnd)`.
  final String insertText;

  /// Start of the replaced range in the text the item was made for; null
  /// inserts [insertText] at the cursor.
  final int? rangeStart;

  /// End of the replaced range; null with a [rangeStart] means the cursor.
  final int? rangeEnd;

  /// The length of the text the host answered for, so the range can be
  /// moved when the user typed since; null when [rangeEnd] is the cursor.
  final int? sourceLength;

  /// The attachment the host associates with the item, sent with the
  /// message that contains [insertText] (`CompletionItem.attachment`).
  final MessageAttachment? attachment;
}

/// A host completion as a popup item. Its description is the attachment's
/// `_meta.description` (as pi and VS Code's hosts send it), else the
/// description of the [commands] entry with the same `/name`.
ComposerCompletion hostCompletion(
  CompletionItem item, {
  required String text,
  List<SlashCommand> commands = const [],
}) {
  final label = item.attachment.label;
  final meta = item.attachment.meta?['description'];
  return ComposerCompletion(
    label: label,
    insertText: item.insertText,
    description: meta is String
        ? meta
        : commands.where((c) => '/${c.name}' == label).firstOrNull?.description,
    rangeStart: item.rangeStart,
    rangeEnd: item.rangeEnd,
    sourceLength: text.length,
    attachment: item.attachment,
  );
}

/// The [commands] as items that replace the `/word` of [token]. A skill's
/// item carries a skill reference (`_meta` with its `uri`, `name` and
/// `description`, the shape VS Code sends), so a host that names its
/// skill commands differently, such as pi's `/skill:name`, still loads it.
List<ComposerCompletion> commandCompletions(
  List<SlashCommand> commands,
  CompletionToken token,
) => [
  for (final command in commands)
    ComposerCompletion(
      label: '/${command.name}',
      description: command.description,
      insertText: '/${command.name} ',
      rangeStart: token.start,
      attachment: switch (command.skillUri) {
        final uri? => SimpleMessageAttachment(
          label: '/${command.name}',
          displayKind: 'skill',
          meta: {
            'uri': uri,
            'name': command.name,
            'description': ?command.description,
          },
        ),
        null => null,
      },
    ),
];

/// The commands for a new session of [agent] in [directory]: the agent's
/// own, else those of a session of the same agent in [sessions] (one in
/// [directory] first), for hosts that list skills only on sessions.
List<SlashCommand> draftCommands({
  required AgentInfo? agent,
  required Iterable<SessionState> sessions,
  String? directory,
}) {
  final own = slashCommands(agent?.customizations);
  if (own.isNotEmpty || agent == null) return own;
  final folder = directory == null ? null : normalizeFolderKey(directory);
  final candidates = [
    for (final session in sessions)
      if (session.provider == agent.provider &&
          slashCommands(session.customizations).isNotEmpty)
        session,
  ];
  final inFolder = candidates.where(
    (s) => (s.workingDirectories ?? const [])
        .map(normalizeFolderKey)
        .contains(folder),
  );
  return slashCommands(
    (inFolder.firstOrNull ?? candidates.firstOrNull)?.customizations,
  );
}

/// The [items] matching [query]: those whose label, without its trigger
/// character, holds the query's characters in order (case-insensitive),
/// with labels starting with the query first. Host order is kept
/// otherwise.
List<ComposerCompletion> filterCompletions(
  List<ComposerCompletion> items,
  String query,
) {
  final q = query.toLowerCase();
  String name(ComposerCompletion item) =>
      item.label.replaceFirst(RegExp(r'^[/@#]'), '').toLowerCase();
  final matching = [
    for (final item in items)
      if (_isSubsequence(q, name(item))) item,
  ];
  return [
    ...matching.where((item) => name(item).startsWith(q)),
    ...matching.where((item) => !name(item).startsWith(q)),
  ];
}

bool _isSubsequence(String query, String text) {
  var i = 0;
  for (var j = 0; j < text.length && i < query.length; j++) {
    if (text[j] == query[i]) i++;
  }
  return i == query.length;
}

/// [value] with [item] accepted: `[rangeStart, rangeEnd)` replaced by its
/// insert text (the end moved by what was typed since the host answered),
/// or the insert text put at the cursor when the item has no range. The
/// cursor ends after the inserted text.
TextEditingValue applyCompletion(
  TextEditingValue value,
  ComposerCompletion item,
) {
  final text = value.text;
  final cursor = value.selection.isValid
      ? value.selection.extentOffset
      : text.length;
  final start = (item.rangeStart ?? cursor).clamp(0, text.length);
  final end = switch ((item.rangeStart, item.rangeEnd, item.sourceLength)) {
    (null, _, _) || (_, null, _) => cursor,
    (_, final end?, final length?) => end + text.length - length,
    (_, final end?, null) => end,
  }.clamp(start, text.length);
  final replaced = text.replaceRange(start, end, item.insertText);
  return TextEditingValue(
    text: replaced,
    selection: TextSelection.collapsed(offset: start + item.insertText.length),
  );
}

/// The attachments of the accepted [items] whose insert text (trimmed) is
/// still in [text], once each, to send with the message.
List<MessageAttachment> acceptedAttachments(
  List<ComposerCompletion> items,
  String text,
) {
  final seen = <String>{};
  return [
    for (final item in items)
      if (item.attachment case final attachment?
          when text.contains(item.insertText.trim()) &&
              seen.add(item.insertText.trim()))
        attachment,
  ];
}

/// The characters that open completions: the host's
/// `completionTriggerCharacters`, else `/` when there are [commands].
List<String> completionTriggers(
  List<String> hostTriggers,
  List<SlashCommand> commands,
) => hostTriggers.isNotEmpty
    ? hostTriggers
    : commands.isEmpty
    ? const []
    : const ['/'];

/// The completions for [token] in [text]: the host's answer to [request]
/// (`completions`) when given, else, or when the host fails or answers
/// nothing (hosts such as pi answer nothing when they cannot list their
/// commands), the [commands] matching a `/` word.
Future<List<ComposerCompletion>> resolveCompletions({
  required String text,
  required CompletionToken token,
  required List<SlashCommand> commands,
  Future<List<CompletionItem>> Function()? request,
}) async {
  if (request != null) {
    try {
      final items = await request();
      if (items.isNotEmpty) {
        return [
          for (final item in items)
            hostCompletion(item, text: text, commands: commands),
        ];
      }
    } on Object {
      // Fall back to the commands below.
    }
  }
  return token.trigger == '/'
      ? filterCompletions(commandCompletions(commands, token), token.query)
      : const [];
}
