/// Remembers hosts (AV-010) in platform secure storage (AHP-063).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import '../prefs.dart';
import 'saved_hosts.dart';

final _log = Logger('host_store');

/// Secure storage for host URLs and tokens.
///
/// On macOS this uses the legacy file-based login keychain
/// (`usesDataProtectionKeychain: false`), which works in the app sandbox
/// without the `keychain-access-groups` entitlement and so without a
/// provisioning profile. iOS keeps the items in the keychain, readable
/// after the first unlock (so a reconnect in the background can read the
/// token) and never synced or restored to another device. Android encrypts
/// them with a Keystore key (the app opts out of backups, since the key
/// does not survive a restore). Linux uses libsecret (a running secret
/// service such as gnome-keyring), Windows DPAPI, and web encrypted local
/// storage.
const secureStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// The [HostStore]; tests override it.
final hostStoreProvider = Provider<HostStore>(
  (ref) => HostStore(secureStorage, prefs: ref.watch(prefsStoreProvider)),
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

/// All host credentials and resource tokens kept in one secure storage
/// item (`hosts_vault`), so macOS prompts the login keychain at most once
/// instead of once per host and token entry.
@immutable
class HostVault {
  /// Creates a [HostVault].
  const HostVault({this.hosts = const [], this.tokens = const {}});

  /// The remembered hosts, most recently used first.
  final List<SavedHost> hosts;

  /// Saved OAuth and pasted tokens, keyed by `SavedHost.key`.
  final Map<String, Map<String, ResourceToken>> tokens;
}

/// Encodes [vault] as JSON for [HostStore].
String encodeVault(HostVault vault) => jsonEncode({
  'hosts': [for (final host in vault.hosts) host.toJson()],
  'tokens': {
    for (final MapEntry(:key, :value) in vault.tokens.entries)
      if (value.isNotEmpty)
        key: {
          for (final MapEntry(key: res, value: token) in value.entries)
            res: token.toJson(),
        },
  },
});

/// Decodes a [HostVault] from [encoded]; null or invalid JSON decodes as
/// empty.
HostVault decodeVault(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const HostVault();
  try {
    final json = jsonDecode(encoded);
    if (json is! Map<String, Object?>) return const HostVault();
    final hosts = switch (json['hosts']) {
      final List<Object?> list => [
        for (final item in list)
          if (item is Map<String, Object?>) ?_decodeHostItem(item),
      ],
      _ => const <SavedHost>[],
    };
    final tokens = <String, Map<String, ResourceToken>>{};
    if (json['tokens'] case final Map<String, Object?> rawTokens) {
      for (final MapEntry(:key, :value) in rawTokens.entries) {
        if (value is! Map<String, Object?>) continue;
        final decoded = {
          for (final MapEntry(key: res, value: raw) in value.entries)
            if (raw is Map<String, Object?>) res: ?_decodeToken(raw),
        };
        if (decoded.isNotEmpty) tokens[key] = decoded;
      }
    }
    return HostVault(hosts: hosts, tokens: tokens);
  } on FormatException {
    return const HostVault();
  }
}

SavedHost? _decodeHostItem(Map<String, Object?> json) {
  final url = json['url'];
  if (url is! String || url.trim().isEmpty) return null;
  final token = json['token'];
  final name = json['name'];
  return SavedHost(
    url: url.trim(),
    token: token is String ? token : '',
    name: name is String ? name : '',
  );
}

/// Reads and writes the host list and resource tokens in a single
/// [storage] entry (`hosts_vault`), and the non-secret open-host list in
/// [prefs] when provided. URLs are kept in secure storage too, because a
/// URL pasted from pi carries the token as `?tkn=`.
class HostStore {
  /// Creates a [HostStore] over [storage] (and [prefs] for non-secret
  /// open-host keys).
  HostStore(this.storage, {this.prefs});

  /// The platform secure storage.
  final FlutterSecureStorage storage;

  /// Non-secret device preferences (used for `open_hosts`).
  final PrefsStore? prefs;

  HostVault? _cache;
  Future<HostVault>? _loading;
  Future<void> _writeQueue = Future.value();

  static const _vaultKey = 'hosts_vault';
  static const _hostsKey = 'hosts';
  static const _openHostsKey = 'open_hosts';
  static const _legacyUrlKey = 'last_host_url';
  static const _legacyTokenKey = 'last_host_token';

  Future<HostVault> _loadVault() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    final inFlight = _loading;
    if (inFlight != null) return inFlight;
    final future = _readOrMigrateVault()
        .then((vault) {
          _cache = vault;
          return vault;
        })
        .whenComplete(() => _loading = null);
    _loading = future;
    return future;
  }

  Future<HostVault> _readOrMigrateVault() async {
    final encoded = await storage.read(key: _vaultKey);
    if (encoded != null) return decodeVault(encoded);
    return _migrateLegacyVault();
  }

  Future<HostVault> _migrateLegacyVault() async {
    final legacyHostsRaw = await storage.read(key: _hostsKey);
    final List<SavedHost> hosts;
    if (legacyHostsRaw != null) {
      hosts = decodeHosts(legacyHostsRaw);
    } else {
      final url = await storage.read(key: _legacyUrlKey);
      if (url == null || url.isEmpty) {
        hosts = const [];
      } else {
        final token = await storage.read(key: _legacyTokenKey) ?? '';
        hosts = [SavedHost(url: url, token: token)];
      }
    }

    final tokens = <String, Map<String, ResourceToken>>{};
    for (final host in hosts) {
      final hostTokens = decodeTokens(
        await storage.read(key: _tokensKey(host.key)),
      );
      if (hostTokens.isNotEmpty) tokens[host.key] = hostTokens;
    }

    final vault = HostVault(hosts: hosts, tokens: tokens);
    if (legacyHostsRaw != null || hosts.isNotEmpty || tokens.isNotEmpty) {
      await storage.write(key: _vaultKey, value: encodeVault(vault));
      await _deleteLegacyKeys(hosts);
    }
    return vault;
  }

  Future<void> _deleteLegacyKeys(List<SavedHost> hosts) async {
    try {
      await storage.delete(key: _hostsKey);
      await storage.delete(key: _legacyUrlKey);
      await storage.delete(key: _legacyTokenKey);
      for (final host in hosts) {
        await storage.delete(key: _tokensKey(host.key));
      }
    } on Object {
      // Legacy keys are already migrated to hosts_vault; ignore cleanup errors.
    }
  }

  Future<void> _updateVault(HostVault Function(HostVault) update) {
    final next = _writeQueue.then((_) async {
      final current = await _loadVault();
      final updated = update(current);
      await storage.write(key: _vaultKey, value: encodeVault(updated));
      _cache = updated;
    });
    _writeQueue = next.catchError((Object _) {});
    return next;
  }

  /// The saved hosts, most recently used first. Legacy entries (`hosts`,
  /// `last_host_url`, `tokens:*`) are migrated into `hosts_vault`. Throws
  /// the storage error (for example a locked keyring).
  Future<List<SavedHost>> loadHosts() async => (await _loadVault()).hosts;

  /// Saves [hosts]. Throws the storage error.
  Future<void> saveHosts(List<SavedHost> hosts) => _updateVault(
    (current) => HostVault(hosts: hosts, tokens: current.tokens),
  );

  /// The keys of the hosts that were open, in order. Stored in [prefs]
  /// (not secret; migrating any legacy `open_hosts` out of [storage]).
  Future<List<String>> loadOpenHosts() async {
    final store = prefs;
    if (store == null) {
      return decodeHostKeys(await storage.read(key: _openHostsKey));
    }
    final saved = await store.read(_openHostsKey);
    if (saved != null) return decodeHostKeys(saved);
    final legacy = await storage.read(key: _openHostsKey);
    await store.write(_openHostsKey, legacy ?? '[]');
    if (legacy != null) {
      try {
        await storage.delete(key: _openHostsKey);
      } on Object {
        // Migrated to prefs; ignore cleanup errors.
      }
    }
    return decodeHostKeys(legacy);
  }

  /// Saves the keys of the open hosts.
  Future<void> saveOpenHosts(List<String> keys) {
    final encoded = jsonEncode(keys);
    final store = prefs;
    return store != null
        ? store.write(_openHostsKey, encoded)
        : storage.write(key: _openHostsKey, value: encoded);
  }

  /// The OAuth and pasted tokens saved for the host with [hostKey], by
  /// resource (AHP-060, AHP-063). Throws the storage error.
  Future<Map<String, ResourceToken>> loadTokens(String hostKey) async =>
      (await _loadVault()).tokens[hostKey] ?? const {};

  /// Saves [hostKey]'s tokens (an empty map deletes them). Throws the
  /// storage error.
  Future<void> saveTokens(String hostKey, Map<String, ResourceToken> tokens) =>
      _updateVault((current) {
        final next = Map<String, Map<String, ResourceToken>>.from(
          current.tokens,
        );
        if (tokens.isEmpty) {
          next.remove(hostKey);
        } else {
          next[hostKey] = Map<String, ResourceToken>.from(tokens);
        }
        return HostVault(hosts: current.hosts, tokens: next);
      });

  static String _tokensKey(String hostKey) => 'tokens:$hostKey';
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
