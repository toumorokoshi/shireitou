/// Opens a session's folder in a code editor (AV-015), and the dialog
/// that picks the editor and where a host's folders are.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/saved_hosts.dart';
import 'editor_store.dart';
import 'editor_target.dart';

/// The label of the host menu item that edits [editEditorSettings].
const editorSettingsLabel = 'Editor settings…';

/// Opens [folder] (an absolute path on the AHP [host]) in the chosen
/// editor: asks where the host's folders are first when it is not known
/// (a loopback host is taken to be this computer), then hands the URL to
/// the system.
Future<void> openInEditor(
  BuildContext context,
  WidgetRef ref,
  SavedHost host,
  String folder,
) async {
  final store = ref.read(editorTargetStoreProvider);
  final fallback = defaultEditorTarget(host.url);
  var target = await store.load(host.key);
  if (target == null && fallback.location == EditorLocation.thisComputer) {
    target = fallback;
  }
  if (target == null || editorTargetProblem(target) != null) {
    if (!context.mounted) return;
    target = await showEditorSettingsDialog(
      context,
      hostKey: host.key,
      hostLabel: host.label,
      initial: target ?? fallback,
    );
    if (target == null) return;
  }
  final editor = ref.read(codeEditorProvider);
  final uri = openInEditorUri(editor, target, folder);
  final opened = await ref
      .read(editorLauncherProvider)(uri)
      .catchError((Object _) => false);
  if (!opened && context.mounted) _couldNotOpen(context, editor, target);
}

void _couldNotOpen(
  BuildContext context,
  CodeEditor editor,
  EditorTarget target,
) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
  SnackBar(
    content: Text(
      'Could not open ${editor.label}. Is it installed'
      '${target.location == EditorLocation.ssh ? ', with the Remote - SSH extension' : ''}?',
    ),
  ),
);

/// Edits the editor and where the folders of the AHP [host] are.
Future<void> editEditorSettings(
  BuildContext context,
  WidgetRef ref,
  SavedHost host,
) async {
  final target = await ref.read(editorTargetStoreProvider).load(host.key);
  if (!context.mounted) return;
  await showEditorSettingsDialog(
    context,
    hostKey: host.key,
    hostLabel: host.label,
    initial: target ?? defaultEditorTarget(host.url),
  );
}

/// Edits the editor and the target of the AHP host with [hostKey],
/// starting from [initial], and saves them; the saved target, or null
/// when cancelled.
Future<EditorTarget?> showEditorSettingsDialog(
  BuildContext context, {
  required String hostKey,
  required String hostLabel,
  required EditorTarget initial,
}) => showDialog<EditorTarget>(
  context: context,
  builder: (_) => EditorSettingsDialog(
    hostKey: hostKey,
    hostLabel: hostLabel,
    initial: initial,
  ),
);

/// The editor settings form; pops with the saved target.
class EditorSettingsDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const EditorSettingsDialog({
    super.key,
    required this.hostKey,
    required this.hostLabel,
    required this.initial,
  });

  /// The AHP host the target belongs to (`SavedHost.key`).
  final String hostKey;

  /// The AHP host's name, for the title.
  final String hostLabel;

  /// The target shown first.
  final EditorTarget initial;

  @override
  ConsumerState<EditorSettingsDialog> createState() =>
      _EditorSettingsDialogState();
}

class _EditorSettingsDialogState extends ConsumerState<EditorSettingsDialog> {
  late final _host = TextEditingController(text: widget.initial.host);
  late final _port = TextEditingController(text: '${widget.initial.port}');
  late final _user = TextEditingController(text: widget.initial.user);
  late var _location = widget.initial.location;
  late var _editor = ref.read(codeEditorProvider);
  String? _problem;

  @override
  void dispose() {
    for (final controller in [_host, _port, _user]) {
      controller.dispose();
    }
    super.dispose();
  }

  EditorTarget get _target => EditorTarget(
    location: _location,
    host: _host.text.trim(),
    port: int.tryParse(_port.text.trim()) ?? 0,
    user: _user.text.trim(),
  );

  Future<void> _save() async {
    final target = _target;
    final problem = editorTargetProblem(target);
    if (problem != null) return setState(() => _problem = problem);
    try {
      await ref.read(codeEditorProvider.notifier).set(_editor);
      await ref.read(editorTargetStoreProvider).save(widget.hostKey, target);
    } on Object catch (error) {
      if (!mounted) return;
      return setState(
        () => _problem = 'The settings could not be saved: $error',
      );
    }
    if (mounted) Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Open ${widget.hostLabel} in an editor'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editor', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<CodeEditor>(
                segments: [
                  for (final editor in CodeEditor.values)
                    ButtonSegment(value: editor, label: Text(editor.label)),
                ],
                selected: {_editor},
                onSelectionChanged: (selected) =>
                    setState(() => _editor = selected.single),
              ),
              const SizedBox(height: 16),
              Text('Folders are on', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<EditorLocation>(
                segments: const [
                  ButtonSegment(
                    value: EditorLocation.thisComputer,
                    label: Text('This computer'),
                  ),
                  ButtonSegment(
                    value: EditorLocation.ssh,
                    label: Text('An SSH host'),
                  ),
                ],
                selected: {_location},
                onSelectionChanged: (selected) =>
                    setState(() => _location = selected.single),
              ),
              if (_location == EditorLocation.ssh) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _host,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          hintText: 'An address or ~/.ssh/config alias',
                        ),
                        autocorrect: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 88,
                      child: TextField(
                        controller: _port,
                        decoration: const InputDecoration(labelText: 'Port'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _user,
                  decoration: const InputDecoration(
                    labelText: 'User (optional)',
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_editor.label} connects with its Remote - SSH '
                  'extension, which logs in with your SSH config, keys and '
                  'agent.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (_problem case final problem?) ...[
                const SizedBox(height: 8),
                Text(problem, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
