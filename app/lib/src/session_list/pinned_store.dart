/// The pinned sessions (AV-028), kept on this device with
/// [prefsStoreProvider].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/open_hosts.dart';
import '../prefs.dart';
import 'pinned_sessions.dart';

/// The pinned sessions, by host and session.
final pinnedSessionsProvider =
    NotifierProvider<PinnedSessions, Set<SessionRef>>(PinnedSessions.new);

/// Loads, changes and saves the pinned sessions.
class PinnedSessions extends Notifier<Set<SessionRef>> {
  Future<void>? _loading;

  @override
  Set<SessionRef> build() {
    _loading = _load();
    return const {};
  }

  Future<void> _load() async {
    state = decodePinned(
      await ref.read(prefsStoreProvider).read(pinnedSessionsKey),
    );
  }

  /// Pins [session] ([pinned] true) or unpins it.
  Future<void> setPinned(SessionRef session, {required bool pinned}) async {
    await _loading;
    state = withPinned(state, session, pinned: pinned);
    await ref
        .read(prefsStoreProvider)
        .write(pinnedSessionsKey, encodePinned(state));
  }
}
