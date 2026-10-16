/// Remembers hosts (AV-010) in platform secure storage (AHP-063).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/services.dart';
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

/// Why the hosts could not be read or saved (for example a locked Linux
/// keyring), for a banner; null when storage works.
final hostStorageProblemProvider =
    NotifierProvider<HostStorageProblem, String?>(HostStorageProblem.new);

/// Holds the last secure storage problem, as text for the user.
class HostStorageProblem extends Notifier<String?> {
  @override
  String? build() => null;

  /// Records [problem] (null clears it).
  void report(String? problem) => state = problem;
}

/// Loads, remembers and forgets hosts through the [HostStore]. Storage
/// errors are reported to [hostStorageProblemProvider] instead of thrown,
/// so the app keeps working with the hosts in memory.
class SavedHosts extends AsyncNotifier<List<SavedHost>> {
  @override
  Future<List<SavedHost>> build() async {
    try {
      return await ref.read(hostStoreProvider).loadHosts();
    } on Object catch (error) {
      _report(error, reading: true);
      return const [];
    }
  }

  /// Moves [host] to the front of the list and saves it.
  Future<void> remember(SavedHost host) =>
      _update((hosts) => rememberHost(hosts, host));

  /// Removes the host with [key] and saves the list.
  Future<void> forget(String key) => _update((hosts) => forgetHost(hosts, key));

  /// Tries again after a storage problem (for example once the keyring is
  /// unlocked): reads the stored hosts, keeps the ones only in memory, and
  /// saves the list.
  Future<void> retry() async {
    final inMemory = await future;
    try {
      final stored = await ref.read(hostStoreProvider).loadHosts();
      final merged = inMemory.reversed.fold(stored, rememberHost);
      state = AsyncData(merged);
      await _save(merged);
    } on Object catch (error) {
      _report(error, reading: true);
    }
  }

  Future<void> _update(List<SavedHost> Function(List<SavedHost>) change) async {
    final next = change(await future);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> _save(List<SavedHost> hosts) async {
    try {
      await ref.read(hostStoreProvider).saveHosts(hosts);
      ref.read(hostStorageProblemProvider.notifier).report(null);
    } on Object catch (error) {
      _report(error, reading: false);
    }
  }

  void _report(Object error, {required bool reading}) {
    _log.warning('could not ${reading ? 'read' : 'save'} the hosts: $error');
    ref
        .read(hostStorageProblemProvider.notifier)
        .report(describeStorageError(error, reading: reading));
  }
}

/// User-facing text for a secure storage [error]. Linux's libsecret
/// plugin reports a locked keyring as `KeyringLocked`, and a missing
/// Secret Service as a `Libsecret error` naming `org.freedesktop.secrets`.
String describeStorageError(Object error, {required bool reading}) {
  final (code, message) = switch (error) {
    PlatformException(:final code, :final message) => (code, message ?? ''),
    _ => ('', '$error'),
  };
  final text = '$code $message'.toLowerCase();
  final what = reading
      ? 'Saved hosts could not be read'
      : 'Hosts are not being remembered';
  if (code == 'KeyringLocked' || text.contains('locked')) {
    return '$what: the system keyring is locked. Unlock it (for example '
        'in Passwords and Keys) and retry.';
  }
  if (text.contains('org.freedesktop.secrets') ||
      text.contains('secret service') ||
      text.contains('serviceunknown')) {
    return '$what: no Secret Service (such as GNOME Keyring or KWallet) is '
        'running. Start one and retry.';
  }
  return '$what: secure storage failed ($message${message.isEmpty ? code : ''}).';
}

/// Reads and writes the host list in [storage]. URLs are kept in secure
/// storage too, because a URL pasted from pi carries the token as `?tkn=`.
class HostStore {
  /// Creates a [HostStore] over [storage].
  const HostStore(this.storage);

  /// The platform secure storage.
  final FlutterSecureStorage storage;

  static const _hostsKey = 'hosts';
  static const _openHostsKey = 'open_hosts';
  static const _legacyUrlKey = 'last_host_url';
  static const _legacyTokenKey = 'last_host_token';

  /// The saved hosts, most recently used first. A host saved by an earlier
  /// version (one `last_host_url`) is migrated. Throws the storage error
  /// (for example a locked keyring).
  Future<List<SavedHost>> loadHosts() async {
    final encoded = await storage.read(key: _hostsKey);
    if (encoded != null) return decodeHosts(encoded);
    return _migrateLegacy();
  }

  /// Saves [hosts]. Throws the storage error.
  Future<void> saveHosts(List<SavedHost> hosts) =>
      storage.write(key: _hostsKey, value: encodeHosts(hosts));

  /// The keys of the hosts that were open, in order. Throws the storage
  /// error.
  Future<List<String>> loadOpenHosts() async =>
      decodeHostKeys(await storage.read(key: _openHostsKey));

  /// Saves the keys of the open hosts. Throws the storage error.
  Future<void> saveOpenHosts(List<String> keys) =>
      storage.write(key: _openHostsKey, value: jsonEncode(keys));

  /// The OAuth and pasted tokens saved for the host with [hostKey], by
  /// resource (AHP-060, AHP-063). Throws the storage error.
  Future<Map<String, ResourceToken>> loadTokens(String hostKey) async =>
      decodeTokens(await storage.read(key: _tokensKey(hostKey)));

  /// Saves [hostKey]'s tokens (an empty map deletes them). Throws the
  /// storage error.
  Future<void> saveTokens(String hostKey, Map<String, ResourceToken> tokens) =>
      tokens.isEmpty
      ? storage.delete(key: _tokensKey(hostKey))
      : storage.write(key: _tokensKey(hostKey), value: encodeTokens(tokens));

  static String _tokensKey(String hostKey) => 'tokens:$hostKey';

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

/// [tokens] as JSON, for [HostStore.saveTokens].
String encodeTokens(Map<String, ResourceToken> tokens) => jsonEncode({
  for (final MapEntry(:key, :value) in tokens.entries) key: value.toJson(),
});

/// The tokens [encoded] by [encodeTokens]; entries that do not decode are
/// dropped, and null or garbage decodes as none.
Map<String, ResourceToken> decodeTokens(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const {};
  try {
    final json = jsonDecode(encoded);
    if (json is! Map<String, Object?>) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (value is Map<String, Object?>) key: ?_decodeToken(value),
    };
  } on FormatException {
    return const {};
  }
}

ResourceToken? _decodeToken(Map<String, Object?> json) {
  try {
    return ResourceToken.fromJson(json);
  } on Object {
    return null;
  }
}

/// A host's tokens in the [HostStore], for its [HostAuthenticator].
class HostTokenStore implements TokenStore {
  /// Creates the token store of the host with [hostKey].
  const HostTokenStore(this.store, this.hostKey);

  /// Where hosts are kept.
  final HostStore store;

  /// The host's key ([SavedHost.key]).
  final String hostKey;

  @override
  Future<Map<String, ResourceToken>> load() => store.loadTokens(hostKey);

  @override
  Future<void> save(Map<String, ResourceToken> tokens) =>
      store.saveTokens(hostKey, tokens);
}
