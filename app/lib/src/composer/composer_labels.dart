/// Pure text for the composer's placeholder and chips (AV-096): the model
/// chip ("anthropic/claude-opus-5-5 · implementation lane") and the effort
/// and context chip ("Medium · 1M").
library;

import 'package:ahp_client/ahp_client.dart';

import 'config_fields.dart';

/// The model chip's text when no model is picked (the host's default).
const hostDefaultModelLabel = 'Host default model';

/// The composer's placeholder: "Chat with Pi [cruise]", naming the agent
/// and the workspace folder; "Describe a task…" when there is no agent
/// yet (a new-session draft on a host without agents).
String composerPlaceholder({String? agent, String? folder}) =>
    switch ((agent, folder)) {
      (null, _) => 'Describe a task…',
      (final agent?, null) => 'Chat with $agent',
      (final agent?, final folder?) => 'Chat with $agent [$folder]',
    };

/// Whether [field] is the model's reasoning level (pi's and VS Code's
/// `thinkingLevel`, or a `reasoningEffort`), which the effort chip shows
/// instead of the model chip.
bool isEffortField(ConfigField field) => RegExp(
  'thinking|reasoning|effort',
  caseSensitive: false,
).hasMatch('${field.id} ${field.title}');

/// The value of [field] in [config], else its default.
Object? configValueOf(ConfigField field, Map<String, Object?>? config) =>
    config != null && config.containsKey(field.id)
    ? config[field.id]
    : field.defaultValue;

/// [text] with its first letter in upper case, so raw option values such
/// as pi's `medium` read like labels ("Medium").
String capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// The model chip's text: the model id when it names its provider (pi's
/// "anthropic/claude-opus-5-5"), else the model's name, then the label of
/// the first choice option that is not the reasoning level, as in
/// "anthropic/claude-opus-5-5 · implementation lane".
String modelChipLabel(SessionModelInfo? info, ModelSelection? selection) {
  if (selection == null) return hostDefaultModelLabel;
  final name = selection.id.contains('/')
      ? selection.id
      : info?.name ?? selection.id;
  final key = modelConfigFields(info?.configSchema)
      .where((f) => isPickerField(f) && !isEffortField(f))
      .firstOrNull;
  return switch (key) {
    final field? =>
      '$name · ${field.labelOf(configValueOf(field, selection.config))}',
    null => name,
  };
}

/// A context window in tokens as the reference writes it: "1M", "1.5M",
/// "200K", "128K"; null when unknown.
String? contextWindowLabel(int? tokens) {
  if (tokens == null || tokens <= 0) return null;
  String scaled(double value, String unit) {
    final whole = value.round();
    return (value - whole).abs() < 0.05 || value >= 10
        ? '$whole$unit'
        : '${value.toStringAsFixed(1)}$unit';
  }

  if (tokens >= 1000000) return scaled(tokens / 1000000, 'M');
  if (tokens >= 1000) return scaled(tokens / 1000, 'K');
  return '$tokens';
}

/// The effort and context chip's text: the reasoning level's label and
/// the context window, as in "Medium · 1M"; null when neither is known.
String? effortChipLabel({String? effort, String? contextWindow}) {
  final parts = [?effort, ?contextWindow];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// The tooltip of the composer's disabled "+" button, until attachments
/// can be picked (AV-042).
const attachmentsUnsupportedLabel = 'Attachments are not supported yet';
