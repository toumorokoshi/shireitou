/// Pure reducer for terminal channels (AHP-028), ported from
/// `terminalReducer` in `@microsoft/agent-host-protocol@1.0.0`
/// (`types/channels-terminal/reducer.ts`).
library;

import 'wire.dart';

/// Applies [action] to [state], mirroring the protocol's
/// `terminalReducer`. `terminal/input` and unknown actions leave [state]
/// unchanged.
TerminalState reduceTerminal(TerminalState state, TerminalAction action) =>
    switch (action) {
      TerminalDataAction(:final data) => state.copyWith(
        content: _appendData(state.content, data),
      ),
      // Side effect only: the host forwards it to the pty.
      TerminalInputAction() => state,
      TerminalResizedAction(:final cols, :final rows) => state.copyWith(
        cols: cols,
        rows: rows,
      ),
      TerminalClaimedAction(:final claim) => state.copyWith(claim: claim),
      TerminalTitleChangedAction(:final title) => state.copyWith(title: title),
      TerminalCwdChangedAction(:final cwd) => state.copyWith(cwd: cwd),
      TerminalExitedAction(:final exitCode) => state.copyWith(
        lifecycle: TerminalExitedLifecycleState(exitCode: exitCode),
      ),
      TerminalClearedAction() => state.copyWith(
        content: const <TerminalContentPart>[],
      ),
      TerminalCommandDetectionAvailableAction() => state.copyWith(
        supportsCommandDetection: true,
      ),
      TerminalCommandExecutedAction(
        :final commandId,
        :final commandLine,
        :final timestamp,
      ) =>
        state.copyWith(
          content: [
            ...state.content,
            TerminalCommandPart(
              commandId: commandId,
              commandLine: commandLine,
              output: '',
              timestamp: timestamp,
              isComplete: false,
            ),
          ],
          supportsCommandDetection: true,
        ),
      TerminalCommandFinishedAction(
        :final commandId,
        :final exitCode,
        :final durationMs,
      ) =>
        state.copyWith(
          content: [
            for (final part in state.content)
              part is TerminalCommandPart && part.commandId == commandId
                  ? part.copyWith(
                      isComplete: true,
                      exitCode: exitCode,
                      durationMs: durationMs,
                    )
                  : part,
          ],
        ),
      TerminalActionUnknown() => state,
    };

/// [reduceTerminal] over a raw JSON action, for [ChannelMirror]s.
TerminalState reduceTerminalJson(TerminalState state, JsonMap action) =>
    reduceTerminal(state, TerminalAction.fromJson(action));

/// Appends output [data] to the running command, else to the trailing
/// unclassified part, else as a new unclassified part.
List<TerminalContentPart> _appendData(
  List<TerminalContentPart> content,
  String data,
) {
  final tail = content.lastOrNull;
  final head = content.isEmpty
      ? content
      : content.sublist(0, content.length - 1);
  return switch (tail) {
    TerminalCommandPart(isComplete: false) => [
      ...head,
      tail.copyWith(output: tail.output + data),
    ],
    TerminalUnclassifiedPart() => [
      ...head,
      tail.copyWith(value: tail.value + data),
    ],
    _ => [...content, TerminalUnclassifiedPart(value: data)],
  };
}

/// The terminal's output as one string: each command's line and output,
/// and unclassified output, in order (the protocol's "naive consumer"
/// reconstruction, with command lines added).
String terminalTranscript(TerminalState state) => [
  for (final part in state.content)
    switch (part) {
      TerminalCommandPart(:final commandLine, :final output) =>
        '\$ $commandLine\n$output',
      TerminalUnclassifiedPart(:final value) => value,
      TerminalContentPartUnknown() => '',
    },
].join();
