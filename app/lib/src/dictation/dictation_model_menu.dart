/// The "Dictation model" submenu (AV-047): picks which of [speechModels]
/// dictation runs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'dictation.dart';
import 'speech_model.dart';
import 'speech_model_store.dart';

/// The submenu, with each model's trade-off and download size; nothing
/// where there is no dictation.
class DictationModelMenu extends ConsumerWidget {
  /// Creates the submenu.
  const DictationModelMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(dictationProvider) == null) return const SizedBox.shrink();
    final picked = ref.watch(speechModelProvider);
    final notifier = ref.read(speechModelProvider.notifier);
    final muted = AppColors.of(context).mutedText;
    return SubmenuButton(
      leadingIcon: const Icon(AppIcons.dictate),
      menuChildren: [
        for (final model in speechModels)
          RadioMenuButton<String>(
            value: model.id,
            groupValue: picked.id,
            onChanged: (_) => notifier.set(model),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(model.label),
                Text(
                  '${model.description} · ${model.megabytes} MB',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: muted),
                ),
              ],
            ),
          ),
      ],
      child: Text('Dictation model · ${picked.label}'),
    );
  }
}
