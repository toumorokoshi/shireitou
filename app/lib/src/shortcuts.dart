/// Keyboard shortcuts (AV-140): the commands, their keys, and how they
/// reach the screens.
///
/// A key press (or, on macOS, the native menu item, see
/// `desktop/app_menu.dart`) sends an [AppCommand] on [appCommandsProvider];
/// the sessions screen and the visible session view listen and act on the
/// commands that concern them.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A command with a keyboard shortcut.
enum AppCommand {
  /// Opens the composer for a new session (Cmd/Ctrl+N).
  newSession('New Session'),

  /// Focuses the session search field (Cmd/Ctrl+K).
  searchSessions('Search Sessions'),

  /// Selects the next session in the list (Alt+↓).
  nextSession('Next Session'),

  /// Selects the previous session in the list (Alt+↑).
  previousSession('Previous Session'),

  /// Stops the open chat's running turn (Cmd/Ctrl+.).
  stop('Stop'),

  /// Focuses the follow-up box of the open session (Cmd/Ctrl+L).
  focusComposer('Focus Composer'),

  /// Scrolls the open chat to the previous user turn (Cmd/Ctrl+Alt+↑,
  /// AV-074).
  previousTurn('Previous Turn'),

  /// Scrolls the open chat to the next user turn (Cmd/Ctrl+Alt+↓,
  /// AV-074).
  nextTurn('Next Turn'),

  /// Opens or closes the review pane on wide layouts (Cmd/Ctrl+Alt+B,
  /// AV-003).
  toggleReviewPane('Toggle Review Pane'),

  /// Opens or closes the terminal panel (Ctrl+` everywhere, as in VS
  /// Code, AV-016).
  toggleTerminal('Toggle Terminal');

  const AppCommand(this.label);

  /// The menu item's label.
  final String label;
}

/// Whether the primary modifier is Cmd (Apple platforms, also in a
/// browser) rather than Ctrl.
bool get usesCommandKey =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// The key for [command]: Cmd on Apple platforms and Ctrl elsewhere
/// ([apple]), and Alt (Option) with the arrows.
SingleActivator activatorFor(AppCommand command, {bool? apple}) {
  final cmd = apple ?? usesCommandKey;
  SingleActivator primary(LogicalKeyboardKey key) =>
      SingleActivator(key, meta: cmd, control: !cmd);
  return switch (command) {
    AppCommand.newSession => primary(LogicalKeyboardKey.keyN),
    AppCommand.searchSessions => primary(LogicalKeyboardKey.keyK),
    AppCommand.nextSession => const SingleActivator(
      LogicalKeyboardKey.arrowDown,
      alt: true,
    ),
    AppCommand.previousSession => const SingleActivator(
      LogicalKeyboardKey.arrowUp,
      alt: true,
    ),
    AppCommand.stop => primary(LogicalKeyboardKey.period),
    AppCommand.focusComposer => primary(LogicalKeyboardKey.keyL),
    AppCommand.previousTurn => SingleActivator(
      LogicalKeyboardKey.arrowUp,
      meta: cmd,
      control: !cmd,
      alt: true,
    ),
    AppCommand.nextTurn => SingleActivator(
      LogicalKeyboardKey.arrowDown,
      meta: cmd,
      control: !cmd,
      alt: true,
    ),
    AppCommand.toggleReviewPane => SingleActivator(
      LogicalKeyboardKey.keyB,
      meta: cmd,
      control: !cmd,
      alt: true,
    ),
    AppCommand.toggleTerminal => const SingleActivator(
      LogicalKeyboardKey.backquote,
      control: true,
    ),
  };
}

/// "Ctrl+K" or "⌘K": [command]'s key for tooltips and help text.
String shortcutLabel(AppCommand command, {bool? apple}) {
  final cmd = apple ?? usesCommandKey;
  final activator = activatorFor(command, apple: cmd);
  final key = switch (activator.trigger) {
    LogicalKeyboardKey.arrowDown => '↓',
    LogicalKeyboardKey.arrowUp => '↑',
    LogicalKeyboardKey.period => '.',
    final other => other.keyLabel.toUpperCase(),
  };
  return [
    if (activator.control) 'Ctrl+',
    if (activator.alt) cmd ? '⌥' : 'Alt+',
    if (activator.meta) '⌘',
    key,
  ].join();
}

/// The commands sent by shortcuts and menu items.
final appCommandsProvider = Provider<AppCommands>((ref) {
  final commands = AppCommands();
  ref.onDispose(commands.close);
  return commands;
});

/// A broadcast of [AppCommand]s.
class AppCommands {
  final _controller = StreamController<AppCommand>.broadcast(sync: true);

  /// The commands, as they are sent.
  Stream<AppCommand> get stream => _controller.stream;

  /// Sends [command] to the listeners.
  void send(AppCommand command) {
    if (!_controller.isClosed) _controller.add(command);
  }

  /// Stops sending.
  Future<void> close() => _controller.close();
}

/// An [Intent] for an [AppCommand].
class AppCommandIntent extends Intent {
  /// Creates the intent for [command].
  const AppCommandIntent(this.command);

  /// The command to send.
  final AppCommand command;
}

/// Maps the AV-140 keys to [AppCommand]s for everything below. When
/// [enabled] is false (macOS, where the native menu bar owns the keys),
/// it returns [child] unchanged.
class AppShortcuts extends ConsumerWidget {
  /// Creates the shortcuts around [child].
  const AppShortcuts({super.key, required this.child, this.enabled = true});

  /// The app content.
  final Widget child;

  /// Whether the keys are handled here.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;
    final commands = ref.watch(appCommandsProvider);
    return Shortcuts(
      shortcuts: {
        for (final command in AppCommand.values)
          activatorFor(command): AppCommandIntent(command),
      },
      child: Actions(
        actions: {
          AppCommandIntent: CallbackAction<AppCommandIntent>(
            onInvoke: (intent) {
              commands.send(intent.command);
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
