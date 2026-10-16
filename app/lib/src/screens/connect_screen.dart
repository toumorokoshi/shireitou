/// "Connect to host" screen with the remembered hosts (AV-010, AV-011).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import '../hosts/host_store.dart';
import '../hosts/open_hosts.dart';
import '../hosts/saved_hosts.dart';
import 'host_storage_banner.dart';

/// Host URL prefilled from `--dart-define=AHP_URL=...`.
const _defaultUrl = String.fromEnvironment('AHP_URL');

/// Asks for a host URL and connection token, then connects. Lists the
/// remembered hosts to reconnect, edit or forget.
class ConnectScreen extends ConsumerStatefulWidget {
  /// Creates the connect screen. When [addingHost], it is a page pushed
  /// over the session list that connects one more host (AV-012) and
  /// closes once connected.
  const ConnectScreen({super.key, this.addingHost = false});

  /// Whether another host is being added to the open ones.
  final bool addingHost;

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _name = TextEditingController();
  final _url = TextEditingController(text: _defaultUrl);
  final _token = TextEditingController();
  final _form = GlobalKey<FormState>();

  /// The key of the host being connected; its state shows progress and
  /// errors.
  String? _attempt;

  @override
  void initState() {
    super.initState();
    if (_defaultUrl.isNotEmpty || widget.addingHost) return;
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

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    final host = SavedHost(
      url: _url.text.trim(),
      token: _token.text.trim(),
      name: _name.text.trim(),
    );
    setState(() => _attempt = host.key);
    await ref.read(openHostsProvider.notifier).connect(host);
    if (!mounted || !widget.addingHost) return;
    if (ref.read(hostConnectionProvider(host.key)).status ==
        ConnectionStatus.connected) {
      Navigator.of(context).pop();
    }
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
    final attempt = _attempt;
    final host = attempt == null
        ? const HostState()
        : ref.watch(hostConnectionProvider(attempt));
    final connecting = host.status == ConnectionStatus.connecting;
    final theme = Theme.of(context);
    final hosts = ref.watch(hostInfosProvider);
    final live = {
      for (final h in hosts)
        if (h.live) h.key,
    };
    // Open hosts that are not connected: restored after a restart and
    // still connecting, or failed (AV-011).
    final pending = {
      for (final h in hosts)
        if (!h.live) h.key: h,
    };
    return Scaffold(
      appBar: widget.addingHost
          ? AppBar(title: const Text('Add a host'))
          : null,
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
                    const HostStorageBanner(),
                    Text(
                      widget.addingHost
                          ? 'Connect to another host'
                          : 'Connect to a host',
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
                      open: live,
                      pending: pending,
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

/// The remembered hosts, most recent first (AV-010), with the status of
/// those that are open but not connected; tapping one connects (or
/// retries) it.
class _SavedHostList extends ConsumerWidget {
  const _SavedHostList({
    required this.open,
    required this.pending,
    required this.enabled,
    required this.onConnect,
    required this.onEdit,
  });

  /// Keys of the hosts already connected; they are not offered.
  final Set<String> open;

  /// Open hosts that are connecting or failed, by key.
  final Map<String, HostInfo> pending;
  final bool enabled;
  final ValueChanged<SavedHost> onConnect;
  final ValueChanged<SavedHost> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = [
      for (final host
          in ref.watch(savedHostsProvider).value ?? const <SavedHost>[])
        if (!open.contains(host.key)) host,
    ];
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
            subtitle: switch ((pending[host.key], host.name.isEmpty)) {
              (final HostInfo info, _) => Text(
                [
                  if (host.name.isNotEmpty) host.key,
                  hostStatusText(info),
                ].join(' · '),
                style: info.status == ConnectionStatus.failed
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              (null, true) => null,
              (null, false) => Text(host.key),
            },
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
