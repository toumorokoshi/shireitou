/// Remembers hosts (AV-010) in platform secure storage (AHP-063).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import 'saved_hosts.dart';

final _log = Logger('host_store');

/// Secure storage for host URLs and tokens.
///
/// On macOS this uses the legacy file-based login keychain
/// (`usesDataProtectionKeychain: false`), which works in the app sandbox
/// without the `keychain-access-groups` entitlement and so without a
/// provisioning profile. Linux uses libsecret (a running secret service such
/// as gnome-keyring), Windows DPAPI, and web encrypted local storage.
const secureStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(usesDataProtectionKeychain: false),
);

/// The [HostStore]; tests override it.
final hostStoreProvider = Provider<HostStore>(
  (ref) => const HostStore(secureStorage),
);

/// The remembered hosts, most recently used first.
final savedHostsProvider = AsyncNotifierProvider<SavedHosts, List<SavedHost>>(
  SavedHosts.new,
);

/// Loads, remembers and forgets hosts through the [HostStore].
class SavedHosts extends AsyncNotifier<List<SavedHost>> {
  @override
  Future<List<SavedHost>> build() => ref.read(hostStoreProvider).loadHosts();

  /// Moves [host] to the front of the list and saves it.
  Future<void> remember(SavedHost host) =>
      _update((hosts) => rememberHost(hosts, host));

  /// Removes the host with [key] and saves the list.
  Future<void> forget(String key) => _update((hosts) => forgetHost(hosts, key));

  Future<void> _update(List<SavedHost> Function(List<SavedHost>) change) async {
    final next = change(await future);
    state = AsyncData(next);
    await ref.read(hostStoreProvider).saveHosts(next);
  }
}

/// Reads and writes the host list in [storage]. URLs are kept in secure
/// storage too, because a URL pasted from pi carries the token as `?tkn=`.
class HostStore {
  /// Creates a [HostStore] over [storage].
  const HostStore(this.storage);

  /// The platform secure storage.
  final FlutterSecureStorage storage;

  static const _hostsKey = 'hosts';
  static const _legacyUrlKey = 'last_host_url';
  static const _legacyTokenKey = 'last_host_token';

  /// The saved hosts, most recently used first. A host saved by an earlier
  /// version (one `last_host_url`) is migrated. Storage errors are logged
  /// and treated as no saved hosts.
  Future<List<SavedHost>> loadHosts() async {
    try {
      final encoded = await storage.read(key: _hostsKey);
      if (encoded != null) return decodeHosts(encoded);
      return await _migrateLegacy();
    } on Object catch (error) {
      _log.warning('could not read the saved hosts: $error');
      return const [];
    }
  }

  /// Saves [hosts]. Errors are logged, not thrown.
  Future<void> saveHosts(List<SavedHost> hosts) async {
    try {
      await storage.write(key: _hostsKey, value: encodeHosts(hosts));
    } on Object catch (error) {
      _log.warning('could not save the hosts: $error');
    }
  }

  Future<List<SavedHost>> _migrateLegacy() async {
    final url = await storage.read(key: _legacyUrlKey);
    if (url == null || url.isEmpty) return const [];
    final token = await storage.read(key: _legacyTokenKey) ?? '';
    final hosts = [SavedHost(url: url, token: token)];
    await saveHosts(hosts);
    await storage.delete(key: _legacyUrlKey);
    await storage.delete(key: _legacyTokenKey);
    return hosts;
  }
}
