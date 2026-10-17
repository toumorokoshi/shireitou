/// Keeps the SSH settings of each host and the remembered SSH host keys
/// in platform secure storage (AV-014, AHP-063).
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../hosts/host_store.dart';
import 'ssh_settings.dart';

/// The [SshStore]; tests override it.
final sshStoreProvider = Provider<SshStore>(
  (ref) => const SshStore(secureStorage),
);

/// Reads and writes SSH settings (with their secrets) and known host keys.
class SshStore {
  /// Creates an [SshStore] over [storage].
  const SshStore(this.storage);

  /// The platform secure storage.
  final FlutterSecureStorage storage;

  static const _knownHostsKey = 'ssh_known_hosts';

  static String _settingsKey(String hostKey) => 'ssh:$hostKey';

  /// The SSH settings of the AHP host with [hostKey] (a `SavedHost.key`),
  /// or null when none are saved. Throws the storage error.
  Future<SshSettings?> loadSettings(String hostKey) async {
    final encoded = await storage.read(key: _settingsKey(hostKey));
    if (encoded == null) return null;
    try {
      return SshSettings.fromJson(jsonDecode(encoded));
    } on FormatException {
      return null;
    }
  }

  /// Saves [settings] for the AHP host with [hostKey]. Throws the storage
  /// error.
  Future<void> saveSettings(String hostKey, SshSettings settings) => storage
      .write(key: _settingsKey(hostKey), value: jsonEncode(settings.toJson()));

  /// The remembered host keys, by [sshTarget]. Throws the storage error.
  Future<Map<String, KnownHostKey>> loadKnownHosts() async =>
      decodeKnownHosts(await storage.read(key: _knownHostsKey));

  /// Remembers [key] for [target], or forgets the target's key when [key]
  /// is null. Throws the storage error.
  Future<void> saveKnownHost(String target, KnownHostKey? key) async {
    final hosts = {...await loadKnownHosts()};
    if (key == null) {
      hosts.remove(target);
    } else {
      hosts[target] = key;
    }
    await storage.write(key: _knownHostsKey, value: encodeKnownHosts(hosts));
  }
}
