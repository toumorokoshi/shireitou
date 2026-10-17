/// Pure helpers for `@`/`/` completions in a message being typed (AHP-044):
/// finding the token under the cursor, and the slash commands a session's
/// customizations offer when the host does not answer `completions`.
library;

import 'generated/ahp_types.dart';

/// A word being completed: [text] from [start] (the trigger character) to
/// [end] (the cursor). [query] is what follows the trigger.
typedef CompletionToken = ({int start, int end, String trigger, String query});

/// The token that ends at [offset] in [text] when it starts with one of
/// [triggers] at the start of [text] or after whitespace, else null.
/// Offsets are UTF-16 code units, as in `CompletionsParams.offset`.
CompletionToken? completionToken(
  String text,
  int offset,
  Iterable<String> triggers,
) {
  if (offset < 1 || offset > text.length) return null;
  var start = offset;
  while (start > 0 && !_isSpace(text.codeUnitAt(start - 1))) {
    start--;
  }
  if (start == offset) return null;
  final trigger = text[start];
  if (!triggers.contains(trigger)) return null;
  return (
    start: start,
    end: offset,
    trigger: trigger,
    query: text.substring(start + 1, offset),
  );
}

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0a || unit == 0x0d;

/// A command a user can type after `/`: a skill or a prompt.
typedef SlashCommand = ({String name, String? description});

/// The skills and prompts in [customizations] (the children of plugins and
/// directories) that a user may invoke, in order, without duplicate names.
/// Disabled children and skills with `disableUserInvocation` are left out.
List<SlashCommand> slashCommands(List<Customization>? customizations) {
  final children = [
    for (final customization in customizations ?? const <Customization>[])
      ...switch (customization) {
        PluginCustomization(:final children) ||
        DirectoryCustomization(:final children) => children ?? const [],
        _ => const <ChildCustomization>[],
      },
  ];
  final seen = <String>{};
  return [
    for (final child in children)
      if (switch (child) {
            SkillCustomization(
              :final name,
              :final description,
              :final enabled,
              :final disableUserInvocation,
            )
                when enabled != false && disableUserInvocation != true =>
              (name: name, description: description),
            PromptCustomization(:final name, :final description, :final enabled)
                when enabled != false =>
              (name: name, description: description),
            _ => null,
          }
          case final command? when seen.add(command.name))
        command,
  ];
}
