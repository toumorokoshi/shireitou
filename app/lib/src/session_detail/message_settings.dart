/// The model and settings pickers above the follow-up box (AV-041).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../composer/config_fields.dart';

/// Compact dropdowns for the next message's model (`Message.model`) and
/// its options (the model's `configSchema`, such as the thinking level),
/// and for the session settings that may change mid-session (such as the
/// mode; `session/configChanged`).
class MessageSettingsBar extends StatelessWidget {
  /// Creates a [MessageSettingsBar].
  const MessageSettingsBar({
    super.key,
    required this.models,
    required this.model,
    required this.onModelChanged,
    this.sessionFields = const [],
    this.sessionValues = const {},
    this.onSessionSettingChanged,
  });

  /// The agent's models (`AgentInfo.models`).
  final List<SessionModelInfo> models;

  /// The model for the next message; null for the host's default.
  final ModelSelection? model;

  /// Called when the user picks a model or changes one of its options.
  final ValueChanged<ModelSelection?> onModelChanged;

  /// Session settings that may change now ([mutableSessionFields]).
  final List<ConfigField> sessionFields;

  /// Their current values (`SessionState.config.values`).
  final Map<String, Object?> sessionValues;

  /// Called with a changed session setting.
  final void Function(String id, Object? value)? onSessionSettingChanged;

  @override
  Widget build(BuildContext context) {
    final selected = model;
    final info = models.where((m) => m.id == selected?.id).firstOrNull;
    final options = modelConfigFields(info?.configSchema)
        .where((f) => f.kind == ConfigFieldKind.choice && !f.readOnly)
        .toList();
    final style = Theme.of(context).textTheme.bodySmall;
    Widget picker<T>({
      required String label,
      required T? value,
      required List<(T?, String)> items,
      required ValueChanged<T?>? onChanged,
    }) => Tooltip(
      message: label,
      child: DropdownButton<T?>(
        key: ValueKey('picker-$label'),
        value: items.any((i) => i.$1 == value) ? value : null,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: style,
        hint: Text(label, style: style),
        items: [
          for (final (v, text) in items)
            DropdownMenuItem(value: v, child: Text(text)),
        ],
        onChanged: onChanged,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (models.isNotEmpty)
            picker<String>(
              label: 'Model',
              value: selected?.id,
              items: [
                (null, 'Host default model'),
                for (final m in models) (m.id, m.name),
              ],
              onChanged: (id) => onModelChanged(
                modelSelection(
                  models.where((m) => m.id == id).firstOrNull,
                  const {},
                ),
              ),
            ),
          if (selected != null)
            for (final field in options)
              picker<Object>(
                label: field.title,
                value: selected.config?[field.id] ?? field.defaultValue,
                items: [for (final o in field.options) (o.value, o.label)],
                onChanged: (value) => onModelChanged(
                  ModelSelection(
                    id: selected.id,
                    config: {...?selected.config, field.id: ?value},
                  ),
                ),
              ),
          for (final field in sessionFields)
            picker<Object>(
              label: field.title,
              value: sessionValues[field.id] ?? field.defaultValue,
              items: [for (final o in field.options) (o.value, o.label)],
              onChanged: onSessionSettingChanged == null
                  ? null
                  : (value) => onSessionSettingChanged!(field.id, value),
            ),
        ],
      ),
    );
  }
}
