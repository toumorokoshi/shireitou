/// Pure reducer for the `ahp-root://` channel (AHP-021, AHP-023).
library;

import 'wire.dart';

/// Applies [action] to [state], mirroring `rootReducer` in protocol 1.0.0.
///
/// Unknown actions (newer protocol versions or host `x-` extensions) leave
/// the state unchanged.
RootState reduceRoot(RootState state, RootAction action) => switch (action) {
  RootAgentsChanged(:final agents) => state.copyWith(agents: agents),
  RootActiveSessionsChanged(:final activeSessions) => state.copyWith(
    activeSessions: activeSessions,
  ),
  RootTerminalsChanged(:final terminals) => state.copyWith(
    terminals: terminals,
  ),
  RootConfigChanged(:final config, :final replace) => switch (state.config) {
    null => state,
    final current => state.copyWith(
      config: current.copyWith(
        values: replace ?? false ? {...config} : {...current.values, ...config},
      ),
    ),
  },
  RootUnknownAction() => state,
};
