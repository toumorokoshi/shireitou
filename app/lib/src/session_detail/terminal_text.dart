/// Pure helpers for showing terminal output as plain text (AV-065).
library;

import 'package:ahp_client/ahp_client.dart';

/// CSI, OSC and other escape sequences.
final _escape = RegExp(
  r'\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07\x1B]*(?:\x07|\x1B\\)|[@-Z\\-_])',
);

/// [output] without VT escape sequences, with each line's carriage
/// returns applied (only the text after the last `\r` is kept, the way a
/// progress bar redraws its line).
String plainTerminalText(String output) => output
    .replaceAll(_escape, '')
    .replaceAll('\r\n', '\n')
    .split('\n')
    .map((line) {
      final cr = line.lastIndexOf('\r');
      return cr < 0 ? line : line.substring(cr + 1);
    })
    .join('\n');

/// The last [maxLines] lines of [text] (all of them when null), without a
/// trailing newline.
String tailLines(String text, {int? maxLines}) {
  final trimmed = text.endsWith('\n')
      ? text.substring(0, text.length - 1)
      : text;
  if (maxLines == null) return trimmed;
  final lines = trimmed.split('\n');
  return lines.length <= maxLines
      ? trimmed
      : lines.sublist(lines.length - maxLines).join('\n');
}

/// The plain text of a [terminal]'s output, VT sequences removed.
String terminalPlainText(TerminalState terminal) =>
    plainTerminalText(terminalTranscript(terminal));

/// A one-line status of [terminal]: running, or how it exited.
String terminalStatusLabel(TerminalState terminal) =>
    switch (terminal.lifecycle) {
      TerminalExitedLifecycleState(:final exitCode?) => 'Exited ($exitCode)',
      TerminalExitedLifecycleState() => 'Exited',
      TerminalRunningLifecycleState() => 'Running',
      TerminalLifecycleStateUnknown() => '',
    };
