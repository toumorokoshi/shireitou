/// The SSH terminals screen (AV-014): a tab per open terminal, the
/// terminal with its connection state, and keys for touch keyboards.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../hosts/saved_hosts.dart';
import '../theme/app_colors.dart';
import 'ssh_connect.dart';
import 'ssh_settings.dart';
import 'ssh_settings_dialog.dart';
import 'ssh_store.dart';
import 'ssh_terminal.dart';

/// The label of the menu item that opens an SSH terminal.
const openSshTerminalLabel = 'Open SSH terminal';

/// Opens an SSH terminal to the AHP [host], in [directory] when given:
/// asks for the SSH settings first when the host has none (or they are
/// incomplete), then shows the terminals screen.
Future<void> openSshTerminal(
  BuildContext context,
  WidgetRef ref,
  SavedHost host, {
  String? directory,
}) async {
  if (!sshSupported) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text(sshUnsupportedReason)));
    return;
  }
  SshSettings? settings;
  try {
    settings = await ref.read(sshStoreProvider).loadSettings(host.key);
  } on Object {
    settings = null;
  }
  if (settings == null || sshSettingsProblem(settings) != null) {
    if (!context.mounted) return;
    settings = await showSshSettingsDialog(
      context,
      hostKey: host.key,
      hostLabel: host.label,
      initial: settings ?? defaultSshSettings(host.url),
    );
    if (settings == null) return;
  }
  ref.read(sshTerminalsProvider.notifier).open(settings, directory: directory);
  if (!context.mounted) return;
  final notifier = ref.read(sshTerminalsProvider.notifier);
  if (notifier.screenOpen) return;
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SshTerminalsScreen()));
}

/// Edits the SSH settings of the AHP [host].
Future<void> editSshSettings(
  BuildContext context,
  WidgetRef ref,
  SavedHost host,
) async {
  SshSettings? settings;
  try {
    settings = await ref.read(sshStoreProvider).loadSettings(host.key);
  } on Object {
    settings = null;
  }
  if (!context.mounted) return;
  await showSshSettingsDialog(
    context,
    hostKey: host.key,
    hostLabel: host.label,
    initial: settings ?? defaultSshSettings(host.url),
  );
}

/// The open SSH terminals, one shown at a time under a row of tabs.
class SshTerminalsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const SshTerminalsScreen({super.key});

  @override
  ConsumerState<SshTerminalsScreen> createState() => _SshTerminalsScreenState();
}

class _SshTerminalsScreenState extends ConsumerState<SshTerminalsScreen> {
  late final SshTerminalsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(sshTerminalsProvider.notifier)..screenOpen = true;
  }

  @override
  void dispose() {
    _notifier.screenOpen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (:terminals, :selected) = ref.watch(sshTerminalsProvider);
    final shown = terminals.isEmpty ? null : terminals[selected];
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH terminals'),
        bottom: terminals.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final (index, terminal) in terminals.indexed)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: InputChip(
                            label: ListenableBuilder(
                              listenable: terminal,
                              builder: (_, _) => Text(terminal.label),
                            ),
                            selected: index == selected,
                            showCheckmark: false,
                            onPressed: () => _notifier.select(index),
                            onDeleted: () => _notifier.close(terminal),
                            deleteButtonTooltipMessage: 'Close terminal',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      body: shown == null
          ? const Center(child: Text('No terminals are open.'))
          : SshTerminalView(key: ObjectKey(shown), terminal: shown),
    );
  }
}

/// One terminal: its connection state with Reconnect, the xterm view
/// (copy and paste from the keyboard shortcuts or a right-click), and a
/// row of keys touch keyboards lack.
class SshTerminalView extends StatefulWidget {
  /// Creates the view of [terminal].
  const SshTerminalView({super.key, required this.terminal});

  /// The terminal shown.
  final SshTerminal terminal;

  @override
  State<SshTerminalView> createState() => _SshTerminalViewState();
}

class _SshTerminalViewState extends State<SshTerminalView> {
  final _controller = TerminalController();
  final _focus = FocusNode(debugLabel: 'ssh terminal');

  Terminal get _terminal => widget.terminal.terminal;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final selection = _controller.selection;
    if (selection == null) return;
    await Clipboard.setData(
      ClipboardData(text: _terminal.buffer.getText(selection)),
    );
    _controller.clearSelection();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text != null && text.isNotEmpty) _terminal.paste(text);
    _focus.requestFocus();
  }

  /// Copies the selection, or pastes when nothing is selected (a
  /// right-click, as in many terminals).
  Future<void> _copyOrPaste() =>
      _controller.selection == null ? _paste() : _copy();

  void _sendKey(TerminalKey key) {
    _terminal.keyInput(key);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final terminal = widget.terminal;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: terminal,
          builder: (context, _) => _StatusBar(
            terminal: terminal,
            onReconnect: () => unawaited(terminal.connect()),
            onCopy: _copy,
            onPaste: _paste,
          ),
        ),
        Expanded(
          child: TerminalView(
            _terminal,
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            keyboardAppearance: theme.brightness,
            theme: AppColors.of(context).terminal,
            padding: const EdgeInsets.all(4),
            onSecondaryTapDown: (_, _) => unawaited(_copyOrPaste()),
          ),
        ),
        ListenableBuilder(
          listenable: terminal,
          builder: (context, _) => _KeyRow(
            ctrl: terminal.ctrlLatched,
            onCtrl: () {
              terminal.ctrlLatched = !terminal.ctrlLatched;
              _focus.requestFocus();
            },
            onKey: _sendKey,
            onChar: (char) {
              _terminal.textInput(char);
              _focus.requestFocus();
            },
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.terminal,
    required this.onReconnect,
    required this.onCopy,
    required this.onPaste,
  });

  final SshTerminal terminal;
  final VoidCallback onReconnect;
  final VoidCallback onCopy;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text, color) = switch (terminal.status) {
      SshStatus.connecting => (
        Icons.sync,
        'Connecting to ${terminal.settings.label}…',
        theme.colorScheme.outline,
      ),
      SshStatus.connected => (
        Icons.circle,
        'Connected to ${terminal.settings.label}',
        AppColors.of(context).statusColors.done,
      ),
      SshStatus.disconnected => (
        Icons.link_off,
        terminal.error ?? 'Disconnected from ${terminal.settings.label}',
        terminal.error == null
            ? theme.colorScheme.outline
            : theme.colorScheme.error,
      ),
    };
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (terminal.status == SshStatus.disconnected)
              TextButton.icon(
                onPressed: onReconnect,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reconnect'),
              ),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: onCopy,
            ),
            IconButton(
              tooltip: 'Paste',
              icon: const Icon(Icons.paste, size: 18),
              onPressed: onPaste,
            ),
          ],
        ),
      ),
    );
  }
}

/// Esc, Tab, a sticky Ctrl, arrows and a few symbols, for touch
/// keyboards that lack them.
class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.ctrl,
    required this.onCtrl,
    required this.onKey,
    required this.onChar,
  });

  final bool ctrl;
  final VoidCallback onCtrl;
  final ValueChanged<TerminalKey> onKey;
  final ValueChanged<String> onChar;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onPressed, {String? tooltip}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Tooltip(
            message: tooltip ?? label,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(40, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: onPressed,
              child: Text(label),
            ),
          ),
        );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            key('Esc', () => onKey(TerminalKey.escape)),
            key('Tab', () => onKey(TerminalKey.tab)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FilterChip(
                label: const Text('Ctrl'),
                tooltip: 'Send the next key with Ctrl',
                selected: ctrl,
                showCheckmark: false,
                onSelected: (_) => onCtrl(),
              ),
            ),
            key('←', () => onKey(TerminalKey.arrowLeft), tooltip: 'Left'),
            key('↓', () => onKey(TerminalKey.arrowDown), tooltip: 'Down'),
            key('↑', () => onKey(TerminalKey.arrowUp), tooltip: 'Up'),
            key('→', () => onKey(TerminalKey.arrowRight), tooltip: 'Right'),
            for (final char in ['/', '-', '|', '~'])
              key(char, () => onChar(char)),
          ],
        ),
      ),
    );
  }
}
