/// The composer's round send, queue and stop button (AV-096).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The diameter of [ComposerActionButton].
const composerActionButtonSize = 26.0;

/// A filled circle in the theme's foreground colour with its glyph in the
/// composer's background colour, dimmed while [onPressed] is null.
class ComposerActionButton extends StatelessWidget {
  const ComposerActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  /// An [Icon], or [StopSquare].
  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.onSurface;
    final glyph = AppColors.of(context).raisedSurface;
    return IconButton.filled(
      tooltip: tooltip,
      iconSize: 14,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: composerActionButtonSize,
        height: composerActionButtonSize,
      ),
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: fill,
        foregroundColor: glyph,
        disabledBackgroundColor: fill.withValues(alpha: 0.3),
        disabledForegroundColor: glyph,
      ),
      icon: icon,
      onPressed: onPressed,
    );
  }
}

/// The solid square of the stop button, in the surrounding icon colour.
/// The icon fonts only have outlined squares.
class StopSquare extends StatelessWidget {
  const StopSquare({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 9,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: IconTheme.of(context).color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
