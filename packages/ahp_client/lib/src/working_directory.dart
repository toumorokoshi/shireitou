/// Pure rules for moving a session's primary working directory
/// (`session/workingDirectoryReplaced`).
library;

import 'wire.dart';

/// Whether [agent] lets clients replace a session's primary working
/// directory (index `0` of `SessionState.workingDirectories`).
///
/// Requires `capabilities.multipleWorkingDirectories`, with either
/// `primaryReplacement` set or `immutablePrimary` unset/false.
bool canReplacePrimaryWorkingDirectory(AgentInfo? agent) {
  final mwd = agent?.capabilities?.multipleWorkingDirectories;
  if (mwd == null) return false;
  return (mwd.primaryReplacement ?? false) || !(mwd.immutablePrimary ?? false);
}

/// Builds a `session/workingDirectoryReplaced` action replacing the
/// primary working directory in [currentDirectories] with [replacement],
/// or null when [currentDirectories] is empty, [replacement] is empty,
/// or the primary directory is already [replacement].
JsonMap? replacePrimaryWorkingDirectoryAction(
  List<String>? currentDirectories,
  String replacement,
) {
  final current = currentDirectories?.firstOrNull;
  if (current == null || replacement.isEmpty || current == replacement) {
    return null;
  }
  return SessionWorkingDirectoryReplacedAction(
    directory: current,
    replacement: replacement,
  ).toJson();
}
