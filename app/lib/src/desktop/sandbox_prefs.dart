/// Brings back the settings the macOS app kept while it was sandboxed.
///
/// A sandboxed app's `UserDefaults` live in its container
/// (`~/Library/Containers/<bundle id>/Data/Library/Preferences`); the app
/// runs unsandboxed since the terminal panel (AV-016), so `UserDefaults`
/// moved to `~/Library/Preferences` and the app started without its pins,
/// folder order, theme and the rest. On the first start that finds the
/// container's preferences, the settings missing from the current ones are
/// copied over and the pins are merged.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../prefs.dart';
import '../session_list/pinned_sessions.dart';

final _log = Logger('sandbox_prefs');

/// The [PrefsStore] key set once the migration has run.
const sandboxPrefsMigratedKey = 'sandbox_prefs_migrated';

/// Must match `PRODUCT_BUNDLE_IDENTIFIER` in
/// `macos/Runner/Configs/AppInfo.xcconfig`.
const _bundleId = 'dev.shireitou.shireitou';

/// How a setting found in both places is combined: the sandboxed value
/// and the current one in, the value to keep out.
typedef PrefMerge = String Function(String sandboxed, String current);

/// The settings merged instead of keeping the current value.
const Map<String, PrefMerge> sandboxPrefMerges = {
  pinnedSessionsKey: mergePinned,
};

/// The values to write so the current settings take in the [sandboxed]
/// ones: a string setting that [current] lacks is copied, one in
/// [merges] is merged, and any other keeps its current value. Values
/// that are not strings belong to plugins, not to [PrefsStore], and are
/// skipped.
Map<String, String> sandboxPrefWrites({
  required Map<String, Object?> sandboxed,
  required Map<String, String?> current,
  Map<String, PrefMerge> merges = sandboxPrefMerges,
}) {
  String? write(String key, String value) {
    final now = current[key];
    if (now == null) return value;
    final merged = merges[key]?.call(value, now);
    return merged == now ? null : merged;
  }

  return {
    for (final MapEntry(:key, :value) in sandboxed.entries)
      if (value is String) key: ?write(key, value),
  };
}

/// Reads the sandboxed preferences, or null if there are none.
typedef SandboxPrefsReader = Future<Map<String, Object?>?> Function();

/// Copies the sandboxed settings into [store] once (see the library
/// comment); later calls only read [sandboxPrefsMigratedKey]. Does nothing
/// off macOS. Failures are logged and leave the settings as they are.
Future<void> migrateSandboxPrefs(
  PrefsStore store, {
  SandboxPrefsReader read = readSandboxPrefs,
}) async {
  if (await store.read(sandboxPrefsMigratedKey) == 'true') return;
  try {
    final sandboxed = await read();
    if (sandboxed != null) {
      final current = {
        for (final key in sandboxed.keys) key: await store.read(key),
      };
      final writes = sandboxPrefWrites(sandboxed: sandboxed, current: current);
      for (final MapEntry(:key, :value) in writes.entries) {
        await store.write(key, value);
      }
      _log.info('restored ${writes.length} settings from the sandbox');
    }
    await store.write(sandboxPrefsMigratedKey, 'true');
  } on Object catch (error) {
    _log.warning('could not restore the sandboxed settings: $error');
  }
}

/// The container's preferences plist, converted with `plutil`; null off
/// macOS or when the app never ran sandboxed.
Future<Map<String, Object?>?> readSandboxPrefs() async {
  if (kIsWeb || !Platform.isMacOS) return null;
  final home = Platform.environment['HOME'];
  if (home == null) return null;
  final plist = File(
    '$home/Library/Containers/$_bundleId/Data/Library/Preferences/'
    '$_bundleId.plist',
  );
  if (!plist.existsSync()) return null;
  final result = await Process.run('plutil', [
    '-convert',
    'json',
    '-o',
    '-',
    plist.path,
  ]);
  if (result.exitCode != 0) {
    throw ProcessException('plutil', [plist.path], '${result.stderr}');
  }
  final json = jsonDecode(result.stdout as String);
  return json is Map<String, Object?> ? json : null;
}
