/// Remembers the last host URL and connection token (AV-010 subset,
/// AHP-063) in platform secure storage.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

final _log = Logger('host_store');

/// A saved host: its URL and connection token (may be empty).
typedef SavedHost = ({String url, String token});

/// The [HostStore]; tests override it.
final hostStoreProvider = Provider<HostStore>(
  (ref) => const HostStore(FlutterSecureStorage()),
);

/// Reads and writes the last host in [storage]. The URL is kept in secure
/// storage too, because a URL pasted from pi carries the token as `?tkn=`.
class HostStore {
  /// Creates a [HostStore] over [storage].
  const HostStore(this.storage);

  /// The platform secure storage (Keychain, Keystore, DPAPI, libsecret, or
  /// encrypted local storage on web).
  final FlutterSecureStorage storage;

  static const _urlKey = 'last_host_url';
  static const _tokenKey = 'last_host_token';

  /// The last host connected to, or null. Storage errors are logged and
  /// treated as no saved host.
  Future<SavedHost?> loadLastHost() async {
    try {
      final url = await storage.read(key: _urlKey);
      if (url == null || url.isEmpty) return null;
      return (url: url, token: await storage.read(key: _tokenKey) ?? '');
    } on Object catch (error) {
      _log.warning('could not read the saved host: $error');
      return null;
    }
  }

  /// Saves [host] as the last host. Errors are logged, not thrown.
  Future<void> saveLastHost(SavedHost host) async {
    try {
      await storage.write(key: _urlKey, value: host.url);
      await storage.write(key: _tokenKey, value: host.token);
    } on Object catch (error) {
      _log.warning('could not save the host: $error');
    }
  }
}
