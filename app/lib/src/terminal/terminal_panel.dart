/// The terminal panel (AV-016): VS Code's bottom panel in the session
/// pane, with a tab per terminal (the system `ssh` to the AHP host), and
/// the actions that open it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../editor/editor_store.dart';
import '../hosts/saved_hosts.dart';
import '../pane_resize_handle.dart';
import '../prefs.dart';
import '../shortcuts.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'pty_process.dart';
import 'ssh_command.dart';
import 'terminal_session.dart';

/// The label of the button and menu item that open the `ssh://` link
/// where there is no pty.
const connectWithSshLabel = 'Connect with SSH';

/// The label of the panel's button that opens another terminal.
const newTerminalLabel = 'New terminal';

/// The tooltip of the session header's terminal button.
String get toggleTerminalLabel => ptySupported
    ? 'Toggle terminal (${shortcutLabel(AppCommand.toggleTerminal)})'
    : connectWithSshLabel;

/// The session menu's item: another terminal, or the `ssh://` link.
String get newTerminalMenuLabel =>
    ptySupported ? newTerminalLabel : connectWithSshLabel;

/// The panel's height until the user drags its edge.
const defaultTerminalPanelHeight = 260.0;

/// The shortest the panel gets.
const minTerminalPanelHeight = 120.0;

/// The room the conversation keeps above the panel (unless maximized).
const minConversationHeight = 160.0;

/// [height] kept at least [minTerminalPanelHeight] and at most
/// [available] (the session pane's height less [minConversationHeight])
/// unless that is below the minimum.
double clampedTerminalPanelHeight(
  double height, {
  double available = double.infinity,
}) => height.clamp(
  minTerminalPanelHeight,
  available < minTerminalPanelHeight ? minTerminalPanelHeight : available,
);

/// Whether the terminal panel is open under the session.
final terminalPanelOpenProvider = NotifierProvider<StoredFlag, bool>(
  () => StoredFlag('terminal_panel_open'),
);

/// The panel's height, which the user sets by dragging its top edge.
final terminalPanelHeightProvider = NotifierProvider<StoredWidth, double>(
  () => StoredWidth(
    'terminal_panel_height',
    defaultTerminalPanelHeight,
    clamp: clampedTerminalPanelHeight,
  ),
);

/// Whether the panel fills the session pane; not kept between runs.
final terminalPanelMaximizedProvider =
    NotifierProvider<TerminalPanelMaximized, bool>(TerminalPanelMaximized.new);

/// Maximizes and restores the panel.
class TerminalPanelMaximized extends Notifier<bool> {
  @override
  bool build() => false;

  /// Maximizes it when restored, and restores it when maximized.
  void toggle() => state = !state;
}

/// Opens or closes the panel for the AHP [host]. Opening it with no
/// terminal on the host starts one in [directory]. Without a pty (web,
/// iOS, Android) it opens the `ssh://` link instead.
Future<void> toggleTerminalPanel(
  BuildContext context,
  WidgetRef ref,
  SavedHost host, {
  String? directory,
}) async {
  if (!ptySupported) return _openSshLink(context, ref, host);
  final panel = ref.read(terminalPanelOpenProvider.notifier);
  if (ref.read(terminalPanelOpenProvider)) return panel.set(false);
  final tabs = ref.read(terminalsProvider);
  final terminals = terminalsOf(tabs, host.key);
  if (terminals.isEmpty) {
    return openNewTerminal(context, ref, host, directory: directory);
  }
  (tabs.selected[host.key] ?? terminals.first).requestFocus();
  await panel.set(true);
}

/// Opens a terminal to the AHP [host] in [directory] and shows the panel,
/// or opens the `ssh://` link without a pty.
Future<void> openNewTerminal(
  BuildContext context,
  WidgetRef ref,
  SavedHost host, {
  String? directory,
}) async {
  if (!ptySupported) return _openSshLink(context, ref, host);
  final sshHost = sshHostOf(host.url);
  if (sshHost == null) return _noSshHost(context, host);
  ref
      .read(terminalsProvider.notifier)
      .open(hostKey: host.key, host: sshHost, directory: directory);
  await ref.read(terminalPanelOpenProvider.notifier).set(true);
}

Future<void> _openSshLink(
  BuildContext context,
  WidgetRef ref,
  SavedHost host,
) async {
  final sshHost = sshHostOf(host.url);
  if (sshHost == null) return _noSshHost(context, host);
  final uri = sshUri(sshHost);
  final opened = await ref
      .read(editorLauncherProvider)(uri)
      .catchError((Object _) => false);
  if (opened || !context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text('Could not open $uri. Is an SSH app installed?')),
  );
}

void _noSshHost(BuildContext context, SavedHost host) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('${host.label} has no host name to SSH to.')),
    );

/// [child] (the conversation) with the terminal panel of the AHP host
/// [hostKey] under it while the panel is open; [onNewTerminal] opens
/// another terminal. The conversation stays mounted while the panel is
/// maximized, so its scroll position and drafts survive.
class TerminalDock extends ConsumerWidget {
  /// Creates the dock around [child].
  const TerminalDock({
    super.key,
    required this.hostKey,
    required this.onNewTerminal,
    required this.child,
  });

  /// The AHP host whose terminals show.
  final String hostKey;

  /// Opens another terminal on the host.
  final VoidCallback onNewTerminal;

  /// The conversation.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ptySupported && ref.watch(terminalPanelOpenProvider);
    final maximized = ref.watch(terminalPanelMaximizedProvider);
    final height = ref.watch(terminalPanelHeightProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight = !open
            ? 0.0
            : maximized
            ? constraints.maxHeight
            : clampedTerminalPanelHeight(
                height,
                available: constraints.maxHeight - minConversationHeight,
              );
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: panelHeight,
              child: Offstage(offstage: open && maximized, child: child),
            ),
            if (open)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: TerminalPanel(
                  hostKey: hostKey,
                  onNewTerminal: onNewTerminal,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The panel: a bar with the host's terminals as tabs and the panel's
/// buttons, over the selected terminal. Its top edge resizes it.
class TerminalPanel extends ConsumerWidget {
  /// Creates the panel of the AHP host [hostKey].
  const TerminalPanel({
    super.key,
    required this.hostKey,
    required this.onNewTerminal,
  });

  /// The AHP host whose terminals show.
  final String hostKey;

  /// Opens another terminal on the host.
  final VoidCallback onNewTerminal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(terminalsProvider);
    final terminals = terminalsOf(tabs, hostKey);
    final shown = tabs.selected[hostKey] ?? terminals.firstOrNull;
    final maximized = ref.watch(terminalPanelMaximizedProvider);
    final colors = AppColors.of(context);
    final heightNotifier = ref.read(terminalPanelHeightProvider.notifier);
    return Semantics(
      container: true,
      label: 'Terminal panel',
      child: Material(
        color: colors.terminal.background,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                _TabBar(
                  terminals: terminals,
                  shown: shown,
                  maximized: maximized,
                  onSelect: ref.read(terminalsProvider.notifier).select,
                  onClose: ref.read(terminalsProvider.notifier).close,
                  onNewTerminal: onNewTerminal,
                  onMaximize: ref
                      .read(terminalPanelMaximizedProvider.notifier)
                      .toggle,
                  onHide: () => unawaited(
                    ref.read(terminalPanelOpenProvider.notifier).set(false),
                  ),
                ),
                Expanded(
                  child: shown == null
                      ? Center(
                          child: TextButton.icon(
                            onPressed: onNewTerminal,
                            icon: const Icon(AppIcons.add, size: 16),
                            label: const Text(newTerminalLabel),
                          ),
                        )
                      : TerminalTabView(key: ObjectKey(shown), session: shown),
                ),
              ],
            ),
            if (!maximized)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: PaneResizeHandle(
                  label: 'Resize terminal panel',
                  axis: Axis.vertical,
                  // The panel is at the bottom, so dragging up heightens it.
                  onDrag: (dy) => heightNotifier.resize(-dy),
                  onDragEnd: () => unawaited(heightNotifier.save()),
                  onReset: () => unawaited(heightNotifier.reset()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.terminals,
    required this.shown,
    required this.maximized,
    required this.onSelect,
    required this.onClose,
    required this.onNewTerminal,
    required this.onMaximize,
    required this.onHide,
  });

  final List<TerminalSession> terminals;
  final TerminalSession? shown;
  final bool maximized;
  final ValueChanged<TerminalSession> onSelect;
  final ValueChanged<TerminalSession> onClose;
  final VoidCallback onNewTerminal;
  final VoidCallback onMaximize;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    Widget button(String tooltip, IconData icon, VoidCallback onPressed) =>
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
        );
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'TERMINAL',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.mutedText,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final terminal in terminals)
                  _Tab(
                    terminal: terminal,
                    selected: terminal == shown,
                    onSelect: () => onSelect(terminal),
                    onClose: () => onClose(terminal),
                  ),
              ],
            ),
          ),
          if (shown case final shown?)
            ListenableBuilder(
              listenable: shown,
              builder: (context, _) => shown.running
                  ? const SizedBox.shrink()
                  : button('Restart', AppIcons.restart, shown.start),
            ),
          button(newTerminalLabel, AppIcons.add, onNewTerminal),
          button(
            maximized ? 'Restore panel size' : 'Maximize panel',
            maximized ? AppIcons.restore : AppIcons.maximize,
            onMaximize,
          ),
          button('Hide panel', AppIcons.close, onHide),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.terminal,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final TerminalSession terminal;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Material(
        color: selected ? colors.selectedFill : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.terminal, size: 14),
                const SizedBox(width: 6),
                ListenableBuilder(
                  listenable: terminal,
                  builder: (context, _) => Text(
                    terminal.running
                        ? terminal.label
                        : '${terminal.label} (exited)',
                    style: style?.copyWith(
                      color: selected ? null : colors.mutedText,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close terminal',
                  icon: const Icon(AppIcons.close, size: 14),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One terminal's xterm view in the theme's terminal colours. Copy and
/// paste use the platform's keys (Cmd+C and Cmd+V on macOS, Ctrl+Shift+C
/// and Ctrl+V elsewhere) or a right-click (copy the selection, else
/// paste). Alt+T and Ctrl+` still toggle the panel while it has the
/// focus, so Alt+T does not reach the shell.
class TerminalTabView extends ConsumerStatefulWidget {
  /// Creates the view of [session].
  const TerminalTabView({super.key, required this.session});

  /// The terminal shown.
  final TerminalSession session;

  @override
  ConsumerState<TerminalTabView> createState() => _TerminalTabViewState();
}

class _TerminalTabViewState extends ConsumerState<TerminalTabView> {
  final _controller = TerminalController();
  final _focus = FocusNode(debugLabel: 'terminal');
  late final _autofocus = widget.session.takeFocusRequest();

  Terminal get _terminal => widget.session.terminal;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _copyOrPaste() async {
    if (_controller.selection case final selection?) {
      await Clipboard.setData(
        ClipboardData(text: _terminal.buffer.getText(selection)),
      );
      _controller.clearSelection();
      return;
    }
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text != null && text.isNotEmpty) _terminal.paste(text);
    _focus.requestFocus();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final toggles = activatorsFor(AppCommand.toggleTerminal);
    if (!toggles.any((t) => t.accepts(event, HardwareKeyboard.instance))) {
      return KeyEventResult.ignored;
    }
    ref.read(appCommandsProvider).send(AppCommand.toggleTerminal);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => TerminalView(
    _terminal,
    controller: _controller,
    focusNode: _focus,
    autofocus: _autofocus,
    keyboardAppearance: Theme.of(context).brightness,
    theme: AppColors.of(context).terminal,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    onSecondaryTapDown: (_, _) => unawaited(_copyOrPaste()),
    onKeyEvent: _onKey,
  );
}
