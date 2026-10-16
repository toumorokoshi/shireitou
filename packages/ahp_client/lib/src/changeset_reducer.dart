/// Pure reducers for changeset and canvas channels (AHP-027, AHP-031),
/// ported from `changesetReducer` and `canvasReducer` in
/// `@microsoft/agent-host-protocol@1.0.0`.
///
/// The client does not subscribe to these channels yet; the reducers are
/// ready for the review pane (AV-100 to AV-103).
library;

import 'wire.dart';

/// Applies [action] to [state], mirroring the protocol's
/// `changesetReducer`. Unknown actions leave [state] unchanged.
ChangesetState reduceChangeset(ChangesetState state, ChangesetAction action) =>
    switch (action) {
      // An error is kept only while the status is `error`.
      ChangesetStatusChangedAction(:final status, :final error) =>
        state.copyWith(
          status: status,
          error: status == ChangesetStatus.error ? error : null,
        ),
      ChangesetFileSetAction(:final file) => state.copyWith(
        files: state.files.any((f) => f.id == file.id)
            ? [for (final f in state.files) f.id == file.id ? file : f]
            : [...state.files, file],
      ),
      ChangesetFileRemovedAction(:final fileId) =>
        state.files.any((f) => f.id == fileId)
            ? state.copyWith(
                files: [
                  for (final f in state.files)
                    if (f.id != fileId) f,
                ],
              )
            : state,
      ChangesetFilesReviewChangedAction(:final files, :final reviewed) => () {
        final ids = files.toSet();
        bool changes(ChangesetFile f) =>
            ids.contains(f.id) && f.reviewed != reviewed;
        return state.files.any(changes)
            ? state.copyWith(
                files: [
                  for (final f in state.files)
                    changes(f) ? f.copyWith(reviewed: reviewed) : f,
                ],
              )
            : state;
      }(),
      ChangesetContentChangedAction(:final files, :final operations) =>
        operations == null
            ? state.copyWith(files: files)
            : state.copyWith(files: files, operations: operations),
      ChangesetOperationsChangedAction(:final operations) => state.copyWith(
        operations: operations,
      ),
      ChangesetOperationStatusChangedAction(
        :final operationId,
        :final status,
        :final error,
      ) =>
        state.operations?.any((o) => o.id == operationId) ?? false
            ? state.copyWith(
                operations: [
                  for (final o in state.operations!)
                    o.id == operationId
                        ? o.copyWith(
                            status: status,
                            error: status == ChangesetOperationStatus.error
                                ? error
                                : null,
                          )
                        : o,
                ],
              )
            : state,
      ChangesetClearedAction() =>
        state.files.isEmpty ? state : state.copyWith(files: const []),
      ChangesetActionUnknown() => state,
    };

/// [reduceChangeset] over a raw JSON action.
ChangesetState reduceChangesetJson(ChangesetState state, JsonMap action) =>
    reduceChangeset(state, ChangesetAction.fromJson(action));

/// Applies a canvas channel action to [state], mirroring the protocol's
/// `canvasReducer`: `canvas/stateChanged` replaces the state; anything
/// else leaves it unchanged.
CanvasState reduceCanvasJson(CanvasState state, JsonMap action) =>
    switch (StateAction.fromJson(action)) {
      CanvasStateChangedAction(:final canvas) => canvas,
      _ => state,
    };
