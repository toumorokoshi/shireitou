/// "Connect to host" screen with the remembered hosts (AV-010, AV-011).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import '../hosts/host_store.dart';
import '../hosts/saved_hosts.dart';

/// Host URL prefilled from `--dart-define=AHP_URL=...`.
const _defaultUrl = String.fromEnvironment('AHP_URL');

/// Asks for a host URL and connection token, then connects. Lists the
/// remembered hosts to reconnect, edit or forget.
class ConnectScreen extends ConsumerStatefulWidget {
  /// Creates the connect screen.
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _name = TextEditingController();
  final _url = TextEditingController(text: _defaultUrl);
  final _token = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (_defaultUrl.isNotEmpty) return;
    // Prefill the most recent host so it does not have to be retyped.
    ref.read(savedHostsProvider.future).then((hosts) {
      if (hosts.isEmpty || !mounted || _url.text.isNotEmpty) return;
      _fill(hosts.first);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  void _fill(SavedHost host) {
    _name.text = host.name;
    _url.text = host.url;
    _token.text = host.token;
  }

  void _connect() {
    if (!_form.currentState!.validate()) return;
    ref
        .read(hostConnectionProvider.notifier)
        .connect(_url.text, token: _token.text, name: _name.text);
  }

  void _connectTo(SavedHost host) {
    _fill(host);
    _connect();
  }

  static String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !(uri.isScheme('ws') || uri.isScheme('wss'))) {
      return 'Enter a ws:// or wss:// URL';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(hostConnectionProvider);
    final connecting = host.status == ConnectionStatus.connecting;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connect to a host',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste the URL an Agent Host Protocol host printed, '
                      'for example ws://127.0.0.1:63877?tkn=…',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Name (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _connect(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _url,
                      decoration: const InputDecoration(
                        labelText: 'Host URL',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: _validateUrl,
                      onFieldSubmitted: (_) => _connect(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _token,
                      decoration: const InputDecoration(
                        labelText: 'Connection token (optional)',
                        helperText: 'Leave empty if the URL already has ?tkn=',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onFieldSubmitted: (_) => _connect(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: connecting ? null : _connect,
                      child: connecting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                    if (host.status == ConnectionStatus.failed &&
                        host.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        host.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        semanticsLabel: 'Connection error: ${host.error}',
                      ),
                    ],
                    _SavedHostList(
                      enabled: !connecting,
                      onConnect: _connectTo,
                      onEdit: _fill,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The remembered hosts, most recent first (AV-010).
class _SavedHostList extends ConsumerWidget {
  const _SavedHostList({
    required this.enabled,
    required this.onConnect,
    required this.onEdit,
  });

  final bool enabled;
  final ValueChanged<SavedHost> onConnect;
  final ValueChanged<SavedHost> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(savedHostsProvider).value ?? const [];
    if (hosts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Text('Recent hosts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final host in hosts)
          ListTile(
            key: ValueKey(host.key),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.dns_outlined),
            title: Text(host.label),
            subtitle: host.name.isEmpty ? null : Text(host.key),
            enabled: enabled,
            onTap: () => onConnect(host),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit ${host.label}',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: enabled ? () => onEdit(host) : null,
                ),
                IconButton(
                  tooltip: 'Forget ${host.label}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: enabled
                      ? () => ref
                            .read(savedHostsProvider.notifier)
                            .forget(host.key)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
