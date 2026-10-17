/// The SSH settings of a host (AV-014): server, port, user and how to
/// log in, and its remembered host key.
library;

import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ssh_settings.dart';
import 'ssh_store.dart';

/// Edits the SSH settings of the AHP host with [hostKey], starting from
/// [initial], and saves them; the saved settings, or null when cancelled.
Future<SshSettings?> showSshSettingsDialog(
  BuildContext context, {
  required String hostKey,
  required String hostLabel,
  required SshSettings initial,
}) => showDialog<SshSettings>(
  context: context,
  builder: (_) => SshSettingsDialog(
    hostKey: hostKey,
    hostLabel: hostLabel,
    initial: initial,
  ),
);

/// The SSH settings form; pops with the saved settings.
class SshSettingsDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const SshSettingsDialog({
    super.key,
    required this.hostKey,
    required this.hostLabel,
    required this.initial,
  });

  /// The AHP host the settings belong to (`SavedHost.key`).
  final String hostKey;

  /// The AHP host's name, for the title.
  final String hostLabel;

  /// The settings shown first.
  final SshSettings initial;

  @override
  ConsumerState<SshSettingsDialog> createState() => _SshSettingsDialogState();
}

class _SshSettingsDialogState extends ConsumerState<SshSettingsDialog> {
  late final _host = TextEditingController(text: widget.initial.host);
  late final _port = TextEditingController(text: '${widget.initial.port}');
  late final _user = TextEditingController(text: widget.initial.user);
  late final _password = TextEditingController(text: widget.initial.password);
  late final _key = TextEditingController(text: widget.initial.privateKey);
  late final _passphrase = TextEditingController(
    text: widget.initial.passphrase,
  );
  late var _auth = widget.initial.auth;
  String? _problem;

  /// The remembered host key of the server being edited.
  KnownHostKey? _knownKey;

  @override
  void initState() {
    super.initState();
    unawaited(_loadKnownKey());
  }

  @override
  void dispose() {
    for (final controller in [
      _host,
      _port,
      _user,
      _password,
      _key,
      _passphrase,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  SshSettings get _settings => SshSettings(
    host: _host.text.trim(),
    port: int.tryParse(_port.text.trim()) ?? 0,
    user: _user.text.trim(),
    auth: _auth,
    password: _password.text,
    privateKey: _key.text,
    passphrase: _passphrase.text,
  );

  Future<void> _loadKnownKey() async {
    try {
      final known = await ref.read(sshStoreProvider).loadKnownHosts();
      if (mounted) setState(() => _knownKey = known[_settings.target]);
    } on Object {
      // Shown as no remembered key.
    }
  }

  Future<void> _forgetKey() async {
    await ref.read(sshStoreProvider).saveKnownHost(_settings.target, null);
    if (mounted) setState(() => _knownKey = null);
  }

  Future<void> _loadKeyFile() async {
    final file = await openFile();
    if (file == null) return;
    final text = await file.readAsString();
    if (mounted) setState(() => _key.text = text);
  }

  Future<void> _save() async {
    final settings = _settings;
    final problem = sshSettingsProblem(settings);
    if (problem != null) return setState(() => _problem = problem);
    try {
      await ref.read(sshStoreProvider).saveSettings(widget.hostKey, settings);
    } on Object catch (error) {
      if (!mounted) return;
      return setState(
        () => _problem = 'The settings could not be saved: $error',
      );
    }
    if (mounted) Navigator.of(context).pop(settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final knownKey = _knownKey;
    return AlertDialog(
      title: Text('SSH to ${widget.hostLabel}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _host,
                      decoration: const InputDecoration(labelText: 'Host'),
                      onChanged: (_) => unawaited(_loadKnownKey()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 88,
                    child: TextField(
                      controller: _port,
                      decoration: const InputDecoration(labelText: 'Port'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => unawaited(_loadKnownKey()),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _user,
                decoration: const InputDecoration(labelText: 'User'),
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              SegmentedButton<SshAuthMethod>(
                segments: const [
                  ButtonSegment(
                    value: SshAuthMethod.password,
                    label: Text('Password'),
                  ),
                  ButtonSegment(
                    value: SshAuthMethod.privateKey,
                    label: Text('Private key'),
                  ),
                  ButtonSegment(
                    value: SshAuthMethod.agent,
                    label: Text('SSH agent'),
                  ),
                ],
                selected: {_auth},
                onSelectionChanged: (selected) =>
                    setState(() => _auth = selected.single),
              ),
              const SizedBox(height: 8),
              ...switch (_auth) {
                SshAuthMethod.password => [
                  TextField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ],
                SshAuthMethod.privateKey => [
                  TextField(
                    controller: _key,
                    decoration: const InputDecoration(
                      labelText: 'Private key',
                      hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
                    ),
                    minLines: 3,
                    maxLines: 6,
                    autocorrect: false,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _loadKeyFile,
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Load from file…'),
                    ),
                  ),
                  TextField(
                    controller: _passphrase,
                    decoration: const InputDecoration(
                      labelText: 'Passphrase (if the key has one)',
                    ),
                    obscureText: true,
                  ),
                ],
                SshAuthMethod.agent => [
                  Text(
                    'Logs in with the keys of the SSH agent at SSH_AUTH_SOCK '
                    '(Linux, and macOS outside the App Store sandbox).',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              },
              const SizedBox(height: 16),
              Text('Host key', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              if (knownKey == null)
                Text(
                  'None remembered: the key the server presents on the next '
                  'connection is trusted and remembered.',
                  style: theme.textTheme.bodySmall,
                )
              else ...[
                SelectableText(
                  '${knownKey.type} ${knownKey.fingerprint}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _forgetKey,
                    child: const Text('Forget host key'),
                  ),
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
