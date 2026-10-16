/// Form controls for host-described settings (AV-041).
library;

import 'package:flutter/material.dart';

import 'config_fields.dart';

/// Fetches suggested values for a [ConfigFieldKind.suggested] field.
typedef ConfigSuggestions = Future<List<ConfigOption>> Function(
  ConfigField field,
  String query,
);

/// One control per field in a wrapping row: dropdowns for choices,
/// switches, text and number fields, and a field with host suggestions for
/// dynamic values. Unsupported fields (arrays, objects) are skipped.
class ConfigForm extends StatelessWidget {
  /// Creates a [ConfigForm].
  const ConfigForm({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.suggestions,
    this.fieldWidth = 220,
  });

  /// The fields to show.
  final List<ConfigField> fields;

  /// The current values by field id (missing means the default).
  final Map<String, Object?> values;

  /// Called with a field id and its new value.
  final void Function(String id, Object? value) onChanged;

  /// Suggestions for dynamic fields; without it they are plain text.
  final ConfigSuggestions? suggestions;

  /// The width of each control.
  final double fieldWidth;

  Object? _value(ConfigField field) =>
      values.containsKey(field.id) ? values[field.id] : field.defaultValue;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      for (final field in fields)
        if (field.kind != ConfigFieldKind.unsupported)
          SizedBox(
            width: fieldWidth,
            child: Tooltip(
              message: field.description ?? '',
              child: _control(field),
            ),
          ),
    ],
  );

  Widget _control(ConfigField field) {
    final value = _value(field);
    final decoration = InputDecoration(labelText: field.title);
    void set(Object? v) => onChanged(field.id, v);
    return switch (field.kind) {
      ConfigFieldKind.choice => DropdownButtonFormField<Object?>(
        key: ValueKey('config-${field.id}'),
        isExpanded: true,
        decoration: decoration,
        initialValue: field.options.any((o) => o.value == value) ? value : null,
        items: [
          for (final option in field.options)
            DropdownMenuItem(
              value: option.value,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: field.readOnly ? null : set,
      ),
      ConfigFieldKind.toggle => SwitchListTile(
        key: ValueKey('config-${field.id}'),
        contentPadding: EdgeInsets.zero,
        title: Text(field.title),
        value: value == true,
        onChanged: field.readOnly ? null : set,
      ),
      ConfigFieldKind.suggested => _SuggestedField(
        key: ValueKey('config-${field.id}'),
        field: field,
        value: value?.toString() ?? '',
        suggestions: suggestions,
        onChanged: set,
      ),
      ConfigFieldKind.number => TextFormField(
        key: ValueKey('config-${field.id}'),
        initialValue: value?.toString() ?? '',
        readOnly: field.readOnly,
        decoration: decoration,
        keyboardType: TextInputType.number,
        onChanged: (text) => set(num.tryParse(text.trim())),
      ),
      ConfigFieldKind.text || ConfigFieldKind.unsupported => TextFormField(
        key: ValueKey('config-${field.id}'),
        initialValue: value?.toString() ?? '',
        readOnly: field.readOnly,
        decoration: decoration,
        onChanged: (text) => set(text.isEmpty ? null : text),
      ),
    };
  }
}

/// A text field whose suggestions come from the host as the user types.
class _SuggestedField extends StatelessWidget {
  const _SuggestedField({
    super.key,
    required this.field,
    required this.value,
    required this.suggestions,
    required this.onChanged,
  });

  final ConfigField field;
  final String value;
  final ConfigSuggestions? suggestions;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) => Autocomplete<ConfigOption>(
    initialValue: TextEditingValue(text: value),
    displayStringForOption: (option) => '${option.value}',
    optionsBuilder: (text) async {
      final query = text.text.trim();
      final fetch = suggestions;
      if (fetch == null || field.readOnly) {
        return field.options.where((o) => '${o.value}'.contains(query));
      }
      try {
        return await fetch(field, query);
      } on Object {
        return field.options.where((o) => '${o.value}'.contains(query));
      }
    },
    onSelected: (option) => onChanged(option.value),
    fieldViewBuilder: (context, controller, focus, onSubmitted) => TextField(
      controller: controller,
      focusNode: focus,
      readOnly: field.readOnly,
      decoration: InputDecoration(labelText: field.title),
      onChanged: (text) => onChanged(text.isEmpty ? null : text),
      onSubmitted: (_) => onSubmitted(),
    ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final option in options)
                ListTile(
                  dense: true,
                  title: Text(option.label),
                  subtitle: option.description == null
                      ? null
                      : Text(option.description!),
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
