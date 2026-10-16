/// "Connect to host" screen (AV-010 subset, AV-011).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import '../host_store.dart';

/// Host URL prefilled from `--dart-define=AHP_URL=...`.
const _defaultUrl = String.fromEnvironment('AHP_URL');

/// Asks for a host URL and connection token, then connects.
class ConnectScreen extends ConsumerStatefulWidget {
  /// Creates the connect screen.
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _url = TextEditingController(text: _defaultUrl);
  final _token = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (_defaultUrl.isNotEmpty) return;
    // Prefill the last host so it does not have to be retyped.
    ref.read(hostStoreProvider).loadLastHost().then((saved) {
      if (saved == null || !mounted || _url.text.isNotEmpty) return;
      _url.text = saved.url;
      _token.text = saved.token;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  void _connect() {
    if (!_form.currentState!.validate()) return;
    ref
        .read(hostConnectionProvider.notifier)
        .connect(_url.text, token: _token.text);
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
