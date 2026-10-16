/// Riverpod state for the connection to one AHP host.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The connected host's state. Widgets watch this; the [AhpClient] owns the
/// socket and publishes [HostState] changes.
final hostConnectionProvider = NotifierProvider<HostConnection, HostState>(
  HostConnection.new,
);

/// Holds the [AhpClient] for the current host and mirrors its state.
class HostConnection extends Notifier<HostState> {
  AhpClient? _client;
  StreamSubscription<HostState>? _subscription;

  @override
  HostState build() {
    ref.onDispose(_dispose);
    return const HostState();
  }

  /// Connects to [url], adding [token] as the `tkn` query parameter.
  Future<void> connect(String url, {String? token}) async {
    await _dispose();
    final client = AhpClient(
      uri: withConnectionToken(Uri.parse(url.trim()), token?.trim()),
      clientInfo: const Implementation(name: 'shireitou', version: '0.1.0'),
    );
    _client = client;
    _subscription = client.states.listen((next) => state = next);
    await client.connect();
  }

  /// Closes the connection.
  Future<void> disconnect() async {
    await _dispose();
    state = const HostState();
  }

  Future<void> _dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _client?.close();
    _client = null;
  }
}
