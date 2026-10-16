/// The run groups (AV-045), kept on this device with [prefsStoreProvider].
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/open_hosts.dart';
import '../prefs.dart';
import 'run_groups.dart';

const _key = 'run_groups';

/// Every saved [RunGroup], newest first.
final runGroupsProvider = NotifierProvider<RunGroups, List<RunGroup>>(
  RunGroups.new,
);

/// Loads, changes and saves the run groups.
class RunGroups extends Notifier<List<RunGroup>> {
  Future<void>? _loading;

  @override
  List<RunGroup> build() {
    _loading = _load();
    return const [];
  }

  Future<void> _load() async {
    final saved = decodeRunGroups(
      await ref.read(prefsStoreProvider).read(_key),
    );
    // Groups added while loading stay in front.
    state = saved.fold(
      state,
      (groups, g) => [...groups, if (!groups.any((x) => x.id == g.id)) g],
    );
  }

  Future<void> _save() async {
    await _loading;
    await ref.read(prefsStoreProvider).write(_key, encodeRunGroups(state));
  }

  /// Adds [group] (newest first).
  Future<void> add(RunGroup group) async {
    state = withGroup(state, group);
    await _save();
  }

  /// Marks [winner] as group [id]'s pick (null clears it).
  Future<void> pick(String id, SessionRef? winner) async {
    state = withWinner(state, id, winner);
    await _save();
  }
}
