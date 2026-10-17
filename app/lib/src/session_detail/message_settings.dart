/// The composer's chips (AV-041, AV-096): the mode, the model and the
/// effort and context window, each a flat text button that opens a menu.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../composer/composer_labels.dart';
import '../composer/config_fields.dart';
import '../composer/config_form.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// The chips for the next message's model (`Message.model`) and its
/// options (the model's `configSchema`, such as the thinking level), and
/// for the session settings that may change mid-session (such as the mode;
/// `session/configChanged`), left to right: one chip per session setting,
/// the model chip ("anthropic/claude-opus-5-5 · implementation lane") and
/// the effort and context chip ("Medium · 1M").
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

  void _setOption(ModelSelection selected, String id, Object? value) =>
      onModelChanged(
        ModelSelection(
          id: selected.id,
          config: {...?selected.config, id: ?value},
        ),
      );

  /// Opens a dialog with the model options a menu cannot hold (text,
  /// numbers, switches).
  Future<void> _moreOptions(
    BuildContext context,
    ModelSelection selected,
    List<ConfigField> fields,
  ) => showDialog<void>(
    context: context,
    builder: (context) {
      var current = selected;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Model options'),
          content: ConfigForm(
            fields: fields,
            values: current.config ?? const {},
            onChanged: (id, value) {
              setState(
                () => current = ModelSelection(
                  id: current.id,
                  config: {...?current.config, id: ?value},
                ),
              );
              onModelChanged(current);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final selected = model;
    final info = models.where((m) => m.id == selected?.id).firstOrNull;
    final options = selected == null
        ? const <ConfigField>[]
        : modelConfigFields(info?.configSchema);
    final effort = options
        .where((f) => isPickerField(f) && isEffortField(f))
        .firstOrNull;
    final choices = [
      for (final f in options)
        if (isPickerField(f) && f != effort) f,
    ];
    final others = [
      for (final f in options)
        if (!isPickerField(f) && f.kind != ConfigFieldKind.unsupported) f,
    ];
    final effortLabel = effortChipLabel(
      effort: effort == null
          ? null
          : capitalized(
              effort.labelOf(configValueOf(effort, selected?.config)),
            ),
      contextWindow: contextWindowLabel(info?.maxContextWindow),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in sessionFields)
          pickerChip<Object>(
            label: field.title,
            icon: field.id == 'mode' ? AppIcons.mode : AppIcons.setting,
            value: sessionValues[field.id] ?? field.defaultValue,
            items: [for (final o in field.options) (o.value, o.label)],
            onChanged: onSessionSettingChanged == null
                ? null
                : (value) => onSessionSettingChanged!(field.id, value),
          ),
        if (models.isNotEmpty)
          ComposerChip(
            key: const ValueKey('picker-Model'),
            icon: AppIcons.model,
            tooltip: 'Model',
            label: modelChipLabel(info, selected),
            menuChildren: [
              choiceMenuItem(
                hostDefaultModelLabel,
                selected: selected == null,
                onPressed: () => onModelChanged(null),
              ),
              for (final m in models)
                choiceMenuItem(
                  m.name,
                  selected: m.id == selected?.id,
                  onPressed: () => onModelChanged(modelSelection(m, const {})),
                ),
              if (selected != null)
                for (final field in choices)
                  SubmenuButton(
                    menuChildren: [
                      for (final o in field.options)
                        choiceMenuItem(
                          o.label,
                          selected:
                              o.value == configValueOf(field, selected.config),
                          onPressed: () =>
                              _setOption(selected, field.id, o.value),
                        ),
                    ],
                    child: Text(
                      '${field.title}: '
                      '${field.labelOf(configValueOf(field, selected.config))}',
                    ),
                  ),
              if (selected != null && others.isNotEmpty)
                MenuItemButton(
                  onPressed: () => _moreOptions(context, selected, others),
                  child: const Text('More options…'),
                ),
            ],
          ),
        if (effortLabel != null)
          ComposerChip(
            key: const ValueKey('picker-effort'),
            tooltip: effort?.title ?? 'Context window',
            label: effortLabel,
            menuChildren: [
              if (effort != null && selected != null)
                for (final o in effort.options)
                  choiceMenuItem(
                    capitalized(o.label),
                    selected: o.value == configValueOf(effort, selected.config),
                    onPressed: () => _setOption(selected, effort.id, o.value),
                  ),
            ],
          ),
      ],
    );
  }
}

/// A menu item with a check before it when [selected].
Widget choiceMenuItem(
  String text, {
  required bool selected,
  required VoidCallback? onPressed,
}) => MenuItemButton(
  leadingIcon: SizedBox(
    width: 16,
    child: selected ? const Icon(Icons.check, size: 16) : null,
  ),
  onPressed: onPressed,
  child: Text(text),
);

/// A chip that picks one of [items] from its menu, showing the picked
/// item's text (or [label] while nothing is picked) and named [label] by
/// its tooltip: the composer's setting chips and the new-session draft's
/// host and agent chips.
Widget pickerChip<T>({
  required String label,
  required T? value,
  required List<(T?, String)> items,
  required ValueChanged<T?>? onChanged,
  IconData? icon,
}) => ComposerChip(
  key: ValueKey('picker-$label'),
  icon: icon,
  tooltip: label,
  label: items.where((i) => i.$1 == value).firstOrNull?.$2 ?? label,
  menuChildren: [
    for (final (v, text) in items)
      choiceMenuItem(
        text,
        selected: v == value,
        onPressed: onChanged == null ? null : () => onChanged(v),
      ),
  ],
);

/// A flat text button in the composer's bottom row (AV-096): a small
/// leading [icon] and [label] in muted text that brightens on hover, and a
/// menu of [menuChildren] when tapped (none when empty).
class ComposerChip extends StatefulWidget {
  /// Creates a [ComposerChip].
  const ComposerChip({
    super.key,
    required this.label,
    required this.tooltip,
    required this.menuChildren,
    this.icon,
  });

  /// The chip's text.
  final String label;

  /// Names the chip for the pointer and screen readers.
  final String tooltip;

  /// The menu's items; the chip is not a button when empty.
  final List<Widget> menuChildren;

  /// The small icon before [label]; none when null.
  final IconData? icon;

  @override
  State<ComposerChip> createState() => _ComposerChipState();
}

class _ComposerChipState extends State<ComposerChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppColors.of(context).mutedText;
    return MenuAnchor(
      menuChildren: widget.menuChildren,
      builder: (context, controller, _) {
        final color = _hovered || controller.isOpen
            ? theme.colorScheme.onSurface
            : muted;
        final enabled = widget.menuChildren.isNotEmpty;
        return Tooltip(
          message: widget.tooltip,
          child: Semantics(
            button: enabled,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onHover: (hovered) => setState(() => _hovered = hovered),
              onTap: enabled
                  ? () => controller.isOpen
                        ? controller.close()
                        : controller.open()
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon case final icon?) ...[
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      widget.label,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
