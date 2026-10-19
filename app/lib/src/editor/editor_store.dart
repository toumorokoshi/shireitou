/// Keeps the chosen code editor and each host's [EditorTarget] on this
/// device with [prefsStoreProvider] (AV-015).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../hosts/host_store.dart';
import '../prefs.dart';
import 'editor_target.dart';

/// The editor folders open in; [CodeEditor.vscode] until it loads and
/// when unset.
final codeEditorProvider = NotifierProvider<StoredEditor, CodeEditor>(
  StoredEditor.new,
);

/// Loads and saves the chosen [CodeEditor].
class StoredEditor extends Notifier<CodeEditor> {
  static const _key = 'code_editor';

  Future<void>? _loading;

  @override
  CodeEditor build() {
    _loading = _load();
    return CodeEditor.vscode;
  }

  Future<void> _load() async {
    final saved = await ref.read(prefsStoreProvider).read(_key);
    state = CodeEditor.values.asNameMap()[saved] ?? state;
  }

  /// Picks [editor] and saves it.
  Future<void> set(CodeEditor editor) async {
    await _loading;
    state = editor;
    await ref.read(prefsStoreProvider).write(_key, editor.name);
  }
}

/// The [EditorTargetStore]; tests override it.
final editorTargetStoreProvider = Provider<EditorTargetStore>(
  (ref) => EditorTargetStore(ref.watch(prefsStoreProvider), secureStorage),
);

/// Reads and writes the [EditorTarget] of each AHP host.
class EditorTargetStore {
  /// Creates a store over [prefs], moving the SSH terminal's former
  /// settings out of [secureStorage] as they are read.
  const EditorTargetStore(this.prefs, this.secureStorage);

  /// Where targets are kept.
  final PrefsStore prefs;

  /// Where the SSH terminal kept its settings (with passwords and keys)
  /// and its known host keys.
  final FlutterSecureStorage secureStorage;

  static String _key(String hostKey) => 'editor_target:$hostKey';

  /// The target of the AHP host with [hostKey] (a `SavedHost.key`), or
  /// null when none is saved. A host with only SSH terminal settings gets
  /// their host, port and user, and the old settings are deleted.
  Future<EditorTarget?> load(String hostKey) async {
    final saved = _decode(await prefs.read(_key(hostKey)));
    if (saved != null) return saved;
    final legacyKey = 'ssh:$hostKey';
    final String? legacy;
    try {
      legacy = await secureStorage.read(key: legacyKey);
    } on Object {
      return null;
    }
    if (legacy == null) return null;
    final target = _decode(legacy);
    if (target != null) await save(hostKey, target);
    try {
      await secureStorage.delete(key: legacyKey);
      await secureStorage.delete(key: 'ssh_known_hosts');
    } on Object {
      // Left behind; read again (and moved) next time.
    }
    return target;
  }

  /// Saves [target] for the AHP host with [hostKey].
  Future<void> save(String hostKey, EditorTarget target) =>
      prefs.write(_key(hostKey), jsonEncode(target.toJson()));

  static EditorTarget? _decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return EditorTarget.fromJson(jsonDecode(encoded));
    } on FormatException {
      return null;
    }
  }
}

/// Opens a URL in the app registered for its scheme; false when none
/// opened it. On the web the browser hands it over (or asks) without
/// leaving the page. Tests replace it.
final editorLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      ),
);

/// Whether this device can have a desktop editor: the desktop apps and
/// the web app, not the phone and tablet apps.
bool get editorSupported =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => false,
      _ => true,
    };
