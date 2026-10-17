/// Small, non-secret app settings kept on this device (notification
/// settings, run groups, pane visibility), behind an interface tests replace.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('prefs');

/// Reads and writes string values by key.
abstract interface class PrefsStore {
  /// The value of [key], or null.
  Future<String?> read(String key);

  /// Stores [value] under [key].
  Future<void> write(String key, String value);
}

/// [PrefsStore] on `shared_preferences`. Failures (no plugin, a broken
/// file) are logged and read as "no value", so a setting falls back to
/// its default instead of breaking the app.
class SharedPrefsStore implements PrefsStore {
  SharedPreferencesAsync? _instance;

  // Created on first use: the constructor throws where the plugin is not
  // registered (widget tests).
  SharedPreferencesAsync get _prefs => _instance ??= SharedPreferencesAsync();

  @override
  Future<String?> read(String key) async {
    try {
      return await _prefs.getString(key);
    } on Object catch (error) {
      _log.warning('could not read $key: $error');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } on Object catch (error) {
      _log.warning('could not write $key: $error');
    }
  }
}

/// [PrefsStore] in memory, for tests.
class MemoryPrefsStore implements PrefsStore {
  /// Creates a [MemoryPrefsStore] holding [values].
  MemoryPrefsStore([Map<String, String>? values]) : values = {...?values};

  /// The stored values.
  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// The app's [PrefsStore].
final prefsStoreProvider = Provider<PrefsStore>((ref) => SharedPrefsStore());

/// A true or false setting kept with [prefsStoreProvider] under [key]
/// ("true" or "false"); false until it loads and when unset.
class StoredFlag extends Notifier<bool> {
  /// Creates the setting stored under [key].
  StoredFlag(this.key);

  /// The [PrefsStore] key.
  final String key;

  Future<void>? _loading;

  @override
  bool build() {
    _loading = _load();
    return false;
  }

  Future<void> _load() async {
    state = await ref.read(prefsStoreProvider).read(key) == 'true';
  }

  /// Sets it to [value] and saves it, after it has loaded so the loaded
  /// value does not replace [value].
  Future<void> set(bool value) async {
    await _loading;
    state = value;
    await ref.read(prefsStoreProvider).write(key, '$value');
  }

  /// Turns it off when on, and on when off.
  Future<void> toggle() async {
    await _loading;
    await set(!state);
  }
}
