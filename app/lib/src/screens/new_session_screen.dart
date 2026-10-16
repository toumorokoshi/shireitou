/// The "New session" composer (AV-040, AV-041).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import '../session_list/folder_grouping.dart';

/// A working-directory URI for [input]: `file:` URIs are kept, paths are
/// converted to `file://` URIs.
String directoryUri(String input) {
  final text = input.trim();
  return text.startsWith('file:') ? text : Uri.file(text).toString();
}

/// Starts a session: agent, model, working directory and prompt. Pops with
/// the new session's URI.
class NewSessionScreen extends ConsumerStatefulWidget {
  /// Creates a [NewSessionScreen]. [initialDirectory] prefills the folder.
  const NewSessionScreen({super.key, this.initialDirectory});

  /// Working directory URI or path to start in; defaults to the host's
  /// `defaultDirectory`.
  final String? initialDirectory;

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final _prompt = TextEditingController();
  late final _directory = TextEditingController(
    text: switch (widget.initialDirectory ??
        ref.read(hostConnectionProvider).defaultDirectory) {
      final uri? => normalizeFolderKey(uri),
      null => '',
    },
  );
  late final _promptFocus = FocusNode(onKeyEvent: _onKey);
  String? _provider;
  String? _model;
  bool _starting = false;
  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    _directory.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _start();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _start() async {
    final agents = ref.read(hostConnectionProvider).root?.agents ?? const [];
    final provider = _provider ?? agents.firstOrNull?.provider;
    final prompt = _prompt.text.trim();
    if (provider == null || prompt.isEmpty || _directory.text.trim().isEmpty) {
      setState(() => _error = 'Pick an agent, a folder and write a prompt.');
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final session = await ref
          .read(hostConnectionProvider.notifier)
          .startSession(
            provider: provider,
            workingDirectory: directoryUri(_directory.text),
            prompt: prompt,
            model: _model == null ? null : ModelSelection(id: _model!),
          );
      if (mounted) Navigator.of(context).pop(session);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(
      hostConnectionProvider.select((s) => s.root?.agents ?? const []),
    );
    final agent =
        agents.where((a) => a.provider == _provider).firstOrNull ??
        agents.firstOrNull;
    final models = agent?.models ?? const <SessionModelInfo>[];
    return Scaffold(
      appBar: AppBar(title: const Text('New session')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Agent'),
                        initialValue: agent?.provider,
                        items: [
                          for (final a in agents)
                            DropdownMenuItem(
                              value: a.provider,
                              child: Text(a.displayName),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _provider = value;
                          _model = null;
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 360,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey(agent?.provider),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Model'),
                        initialValue: _model,
                        items: [
                          const DropdownMenuItem(child: Text('Host default')),
                          for (final m in models)
                            DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                m.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _model = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _directory,
                  decoration: const InputDecoration(
                    labelText: 'Working directory',
                    helperText: 'A folder on the host',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _prompt,
                  focusNode: _promptFocus,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    hintText:
                        'What should the agent do? '
                        '(Enter to start, Shift+Enter for a newline)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _starting ? null : _start,
                    icon: _starting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Start session'),
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
