/// Pure logic for host-described settings (AV-041): a model's
/// `configSchema` (for example `thinkingLevel`) and the session settings
/// from `resolveSessionConfig` (for example `mode` or `branch`), as one
/// list of form fields.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

/// The kind of control a [ConfigField] needs.
enum ConfigFieldKind {
  /// A fixed list of values: a dropdown.
  choice,

  /// Values suggested by the host as the user types
  /// (`sessionConfigCompletions`).
  suggested,

  /// On or off.
  toggle,

  /// Free text.
  text,

  /// A number.
  number,

  /// Arrays and objects, which the app does not edit.
  unsupported,
}

/// One allowed value with its display text.
@immutable
class ConfigOption {
  /// Creates a [ConfigOption].
  const ConfigOption(this.value, this.label, [this.description]);

  /// The value to send.
  final Object? value;

  /// The text to show.
  final String label;

  /// A longer explanation, if the host gave one.
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is ConfigOption &&
      other.value == value &&
      other.label == label &&
      other.description == description;

  @override
  int get hashCode => Object.hash(value, label, description);
}

/// A setting to show in a form.
@immutable
class ConfigField {
  /// Creates a [ConfigField].
  const ConfigField({
    required this.id,
    required this.title,
    required this.kind,
    this.description,
    this.defaultValue,
    this.options = const [],
    this.readOnly = false,
    this.sessionMutable = false,
    this.required = false,
  });

  /// The property id (the key in the config map).
  final String id;

  /// The label.
  final String title;

  /// The control it needs.
  final ConfigFieldKind kind;

  /// The tooltip.
  final String? description;

  /// The schema's default.
  final Object? defaultValue;

  /// The allowed (or, for [ConfigFieldKind.suggested], seed) values.
  final List<ConfigOption> options;

  /// Shown but not editable.
  final bool readOnly;

  /// May change after the session started (`session/configChanged`).
  final bool sessionMutable;

  /// The schema lists it as required.
  final bool required;

  /// The label for [value]: its option's label, else the value as text.
  String labelOf(Object? value) =>
      options.where((o) => o.value == value).firstOrNull?.label ??
      (value == null ? '' : '$value');
}

List<ConfigOption> _options(
  List<Object?>? values,
  List<String>? labels,
  List<String>? descriptions,
) => [
  for (final (i, value) in (values ?? const []).indexed)
    ConfigOption(
      value,
      labels != null && i < labels.length ? labels[i] : '$value',
      descriptions != null && i < descriptions.length ? descriptions[i] : null,
    ),
];

ConfigFieldKind _kind(
  String type, {
  required bool hasEnum,
  bool dynamic = false,
}) => switch (type) {
  _ when dynamic => ConfigFieldKind.suggested,
  _ when hasEnum => ConfigFieldKind.choice,
  'boolean' => ConfigFieldKind.toggle,
  'string' => ConfigFieldKind.text,
  'number' => ConfigFieldKind.number,
  _ => ConfigFieldKind.unsupported,
};

/// The fields of a model's `configSchema` (sent as `ModelSelection.config`).
List<ConfigField> modelConfigFields(ConfigSchema? schema) => [
  for (final MapEntry(key: id, value: p)
      in (schema?.properties ?? const {}).entries)
    ConfigField(
      id: id,
      title: p.title,
      description: p.description,
      kind: _kind(p.type.wireValue, hasEnum: p.enumValues?.isNotEmpty ?? false),
      defaultValue: p.defaultValue,
      options: _options(p.enumValues, p.enumLabels, p.enumDescriptions),
      readOnly: p.readOnly ?? false,
      required: schema?.required?.contains(id) ?? false,
    ),
];

/// The fields of a session config schema (from `resolveSessionConfig`, or
/// a session's `config`).
List<ConfigField> sessionConfigFields(SessionConfigSchema? schema) => [
  for (final MapEntry(key: id, value: p)
      in (schema?.properties ?? const {}).entries)
    ConfigField(
      id: id,
      title: p.title,
      description: p.description,
      kind: _kind(
        p.type.wireValue,
        hasEnum: p.enumValues?.isNotEmpty ?? false,
        dynamic: p.enumDynamic ?? false,
      ),
      defaultValue: p.defaultValue,
      options: _options(p.enumValues, p.enumLabels, p.enumDescriptions),
      readOnly: p.readOnly ?? false,
      sessionMutable: p.sessionMutable ?? false,
      required: schema?.required?.contains(id) ?? false,
    ),
];

/// The values to send for [fields]: what the user chose in [chosen], else
/// the default. Fields the app cannot edit, and values that are not JSON
/// primitives, are left out.
JsonMap configValues(List<ConfigField> fields, Map<String, Object?> chosen) => {
  for (final field in fields)
    if (field.kind != ConfigFieldKind.unsupported)
      if (chosen.containsKey(field.id) ? chosen[field.id] : field.defaultValue
          case final value? when _isPrimitive(value))
        field.id: value,
};

bool _isPrimitive(Object value) =>
    value is String || value is num || value is bool;

/// A [ModelSelection] for [model] with its options, or null for the host's
/// default model. Options equal to the schema default are still sent, so
/// the host does not have to guess.
ModelSelection? modelSelection(
  SessionModelInfo? model,
  Map<String, Object?> chosen,
) {
  if (model == null) return null;
  final config = configValues(modelConfigFields(model.configSchema), chosen);
  return ModelSelection(id: model.id, config: config.isEmpty ? null : config);
}

/// A short label for [selection]: the model's name and its option labels,
/// for example "Scripted · High".
String modelSelectionLabel(
  ModelSelection selection,
  List<SessionModelInfo> models,
) {
  final model = models.where((m) => m.id == selection.id).firstOrNull;
  final fields = modelConfigFields(model?.configSchema);
  return [
    model?.name ?? selection.id,
    for (final MapEntry(:key, :value) in (selection.config ?? const {}).entries)
      fields.where((f) => f.id == key).firstOrNull?.labelOf(value) ?? '$value',
  ].join(' · ');
}

/// The session settings the user may still change (`sessionMutable`)
/// with the choices the app can offer.
List<ConfigField> mutableSessionFields(SessionConfigState? config) => [
  for (final field in sessionConfigFields(config?.schema))
    if (field.sessionMutable &&
        !field.readOnly &&
        field.kind == ConfigFieldKind.choice)
      field,
];
