/// The hosts the app is connected to at once (AV-010, AV-012) and the
/// sessions of all of them.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../host_connection.dart';
import 'host_store.dart';
import 'saved_hosts.dart';

final _log = Logger('open_hosts');

/// The hosts the user connected to, in the order they were added. Each
/// one has its own [hostConnectionProvider] entry, keyed by
/// [SavedHost.key].
final openHostsProvider = NotifierProvider<OpenHosts, List<SavedHost>>(
  OpenHosts.new,
);

/// Connects to and disconnects from hosts, and remembers which hosts are
/// open (by key, in the [HostStore]) so [restore] reopens them after a
/// restart.
class OpenHosts extends Notifier<List<SavedHost>> {
  bool _restored = false;

  @override
  List<SavedHost> build() => const [];

  /// Reconnects the remembered hosts that were open when the app last
  /// ran (once; later calls do nothing). Hosts that fail stay open with
  /// their error, so they can be retried.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final List<String> keys;
    try {
      keys = await ref.read(hostStoreProvider).loadOpenHosts();
    } on Object catch (error) {
      _log.warning('could not read the open hosts: $error');
      return;
    }
    if (keys.isEmpty) return;
    final saved = await ref.read(savedHostsProvider.future);
    final hosts = hostsToRestore(keys, saved, open: state);
    if (hosts.isEmpty) return;
    // Listed at once, in their old order, while they connect.
    state = hosts.fold(state, withHost);
    await Future.wait([for (final host in hosts) _connect(host)]);
  }

  /// Connects to [host] alongside the others (reconnecting it if it was
  /// already open). A host whose connect fails stays open, failed, when
  /// it is a remembered host (one that connected before), so it can be
  /// retried from the sidebar or the connect screen; a host that
  /// never connected is dropped again, and its error stays in
  /// `hostConnectionProvider(host.key)` for the connect screen.
  Future<void> connect(SavedHost host) async {
    state = withHost(state, host);
    await _persist();
    await _connect(host);
  }

  /// Connects the open host with [key] again (after a failure).
  Future<void> retry(String key) async {
    final host = state.where((h) => h.key == key).firstOrNull;
    if (host != null) await _connect(host);
  }

  Future<void> _connect(SavedHost host) async {
    final connection = ref.read(hostConnectionProvider(host.key).notifier);
    await connection.connect(host.url, token: host.token, name: host.name);
    if (ref.read(hostConnectionProvider(host.key)).status !=
        ConnectionStatus.failed) {
      return;
    }
    final saved = await ref.read(savedHostsProvider.future);
    if (saved.any((h) => h.key == host.key)) return;
    state = [
      for (final h in state)
        if (h.key != host.key) h,
    ];
    await _persist();
  }

  /// Closes the connection to the host with [key].
  Future<void> disconnect(String key) async {
    state = [
      for (final h in state)
        if (h.key != key) h,
    ];
    await _persist();
    await ref.read(hostConnectionProvider(key).notifier).disconnect();
  }

  /// Closes every connection.
  Future<void> disconnectAll() async {
    final keys = [for (final h in state) h.key];
    state = const [];
    await _persist();
    await Future.wait([
      for (final key in keys)
        ref.read(hostConnectionProvider(key).notifier).disconnect(),
    ]);
  }

  Future<void> _persist() async {
    try {
      await ref.read(hostStoreProvider).saveOpenHosts([
        for (final h in state) h.key,
      ]);
    } on Object catch (error) {
      _log.warning('could not save the open hosts: $error');
    }
  }
}

/// The remembered hosts ([saved]) whose keys are in [keys], in that
/// order, leaving out hosts already [open] and keys no longer remembered.
List<SavedHost> hostsToRestore(
  List<String> keys,
  List<SavedHost> saved, {
  List<SavedHost> open = const [],
}) => [
  for (final key in keys.toSet())
    if (!open.any((h) => h.key == key))
      ?saved.where((h) => h.key == key).firstOrNull,
];

/// [hosts] with [host] replacing the entry with the same key in place, or
/// appended.
List<SavedHost> withHost(List<SavedHost> hosts, SavedHost host) =>
    hosts.any((h) => h.key == host.key)
    ? [for (final h in hosts) h.key == host.key ? host : h]
    : [...hosts, host];

/// What the app shows about one open host.
@immutable
class HostInfo {
  /// Creates a [HostInfo].
  const HostInfo({
    required this.host,
    required this.status,
    this.serverName,
    this.error,
    this.protocolVersion,
    this.label = '',
  });

  /// The host as the user entered it.
  final SavedHost host;

  /// Its connection status.
  final ConnectionStatus status;

  /// `serverInfo.name` from `initialize`.
  final String? serverName;

  /// The last connection error.
  final String? error;

  /// The negotiated protocol version.
  final String? protocolVersion;

  /// A name that tells it apart from the other open hosts
  /// ([hostLabels]).
  final String label;

  /// The host key.
  String get key => host.key;

  /// Whether its sessions can be shown (connected, or reconnecting).
  bool get live =>
      status == ConnectionStatus.connected ||
      status == ConnectionStatus.reconnecting;

  /// A copy with [label].
  HostInfo withLabel(String label) => HostInfo(
    host: host,
    status: status,
    serverName: serverName,
    error: error,
    protocolVersion: protocolVersion,
    label: label,
  );

  @override
  bool operator ==(Object other) =>
      other is HostInfo &&
      other.host == host &&
      other.status == status &&
      other.serverName == serverName &&
      other.error == error &&
      other.protocolVersion == protocolVersion &&
      other.label == label;

  @override
  int get hashCode =>
      Object.hash(host, status, serverName, error, protocolVersion, label);
}

/// A host's connection status for the user: "Connected", "Connecting…",
/// or the error of a failed connect.
String hostStatusText(HostInfo host) => switch (host.status) {
  ConnectionStatus.connected => 'Connected',
  ConnectionStatus.reconnecting => 'Reconnecting…',
  ConnectionStatus.connecting => 'Connecting…',
  ConnectionStatus.failed => host.error ?? 'Failed',
  ConnectionStatus.disconnected => 'Not connected',
};

/// Labels for [hosts]: the user's name for a host, else the server's
/// name, else its URL (without token). Labels two hosts share get the
/// host's address appended.
List<String> hostLabels(List<HostInfo> hosts) {
  String base(HostInfo h) =>
      h.host.name.isNotEmpty ? h.host.name : h.serverName ?? h.host.key;
  final bases = [for (final h in hosts) base(h)];
  String address(HostInfo h) {
    final uri = Uri.tryParse(h.host.key);
    return uri == null || uri.host.isEmpty
        ? h.host.key
        : uri.hasPort
        ? '${uri.host}:${uri.port}'
        : uri.host;
  }

  return [
    for (final (i, h) in hosts.indexed)
      bases.where((b) => b == bases[i]).length > 1
          ? '${bases[i]} (${address(h)})'
          : bases[i],
  ];
}

/// The open hosts with their status and labels.
final hostInfosProvider = Provider<List<HostInfo>>((ref) {
  final hosts = [
    for (final host in ref.watch(openHostsProvider))
      () {
        final (status, serverName, error, version) = ref.watch(
          hostConnectionProvider(host.key).select(
            (s) => (s.status, s.serverInfo?.name, s.error, s.protocolVersion),
          ),
        );
        return HostInfo(
          host: host,
          status: status,
          serverName: serverName,
          error: error,
          protocolVersion: version,
        );
      }(),
  ];
  final labels = hostLabels(hosts);
  return [for (final (i, h) in hosts.indexed) h.withLabel(labels[i])];
});

/// A session and the host it lives on.
typedef SessionRef = ({String host, String session});

/// A catalogue entry tagged with its host (AV-012).
@immutable
class HostSession {
  /// Creates a [HostSession].
  const HostSession(this.host, this.summary);

  /// The host key.
  final String host;

  /// The session's catalogue entry.
  final SessionSummary summary;

  /// The session's reference.
  SessionRef get ref => (host: host, session: summary.resource);

  @override
  bool operator ==(Object other) =>
      other is HostSession && other.host == host && other.summary == summary;

  @override
  int get hashCode => Object.hash(host, summary);
}

/// The sessions of every live host, merged into one inbox (AV-012).
final allSessionsProvider = Provider<List<HostSession>>(
  (ref) => [
    for (final info in ref.watch(hostInfosProvider))
      if (info.live)
        for (final summary
            in ref
                .watch(
                  hostConnectionProvider(info.key).select((s) => s.sessions),
                )
                .values)
          HostSession(info.key, summary),
  ],
);
