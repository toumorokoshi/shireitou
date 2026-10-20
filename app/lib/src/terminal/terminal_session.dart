/// The terminals of the terminal panel (AV-016): each one's xterm
/// emulator wired to the system `ssh` in a pty, and the open terminals of
/// every host.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:xterm/xterm.dart';

import 'pty_process.dart';
import 'ssh_command.dart';

final _log = Logger('terminal');

/// Lines of scrollback each terminal keeps.
const terminalScrollback = 10000;

/// One terminal: `ssh` to [host] (in [directory] when given) in a pty,
/// shown by an xterm [terminal]. [start] runs it again after it exits;
/// [close] ends it.
class TerminalSession extends ChangeNotifier {
  /// Creates a terminal; [start] runs `ssh`.
  TerminalSession({
    required this.hostKey,
    required this.host,
    required this.spawner,
    required this.environment,
    this.directory,
  });

  /// The AHP host the terminal belongs to (`SavedHost.key`).
  final String hostKey;

  /// The SSH destination: the AHP URL's host.
  final String host;

  /// The folder the shell starts in (a session's working directory), or
  /// null for the login folder.
  final String? directory;

  /// Starts the process.
  final PtySpawner spawner;

  /// The app's environment, passed on to `ssh`.
  final Map<String, String> environment;

  /// The terminal emulator holding the screen and scrollback.
  final terminal = Terminal(maxLines: terminalScrollback);

  /// The tab's label.
  String get label => terminalLabel(host, directory: directory);

  /// Whether `ssh` is running.
  bool get running => _process != null;

  /// The last exit code, or null while running or when `ssh` did not
  /// start.
  int? get exitCode => _exitCode;
  int? _exitCode;

  PtyProcess? _process;
  StreamSubscription<String>? _output;
  var _closed = false;
  var _focusRequested = true;

  /// Whether the terminal should take the keyboard focus when it is next
  /// shown (it was just opened or chosen); true once.
  bool takeFocusRequest() {
    final requested = _focusRequested;
    _focusRequested = false;
    return requested;
  }

  /// Asks for the focus the next time the terminal is shown.
  void requestFocus() => _focusRequested = true;

  /// Runs `ssh` (ending a running one first).
  void start() {
    _detach()?.kill();
    _exitCode = null;
    final PtyProcess process;
    try {
      process = spawner(
        sshExecutable,
        sshArguments(host, directory: directory),
        environment: sshEnvironment(environment),
        rows: terminal.viewHeight,
        columns: terminal.viewWidth,
      );
    } on Object catch (error) {
      _log.warning('could not start ssh to $host: $error');
      terminal.write('Could not start $sshExecutable: $error\r\n');
      notifyListeners();
      return;
    }
    _process = process;
    _output = process.output
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(terminal.write);
    terminal.onOutput = (data) => process.write(utf8.encode(data));
    terminal.onResize = (columns, rows, _, _) => process.resize(rows, columns);
    notifyListeners();
    unawaited(process.exitCode.then((code) => _exited(process, code)));
  }

  void _exited(PtyProcess process, int code) {
    if (_closed || _process != process) return;
    _detach();
    _exitCode = code;
    terminal.write('\r\n[Process exited with code $code]\r\n');
    notifyListeners();
  }

  /// Ends `ssh` and stops the terminal.
  void close() {
    if (_closed) return;
    _closed = true;
    _detach()?.kill();
    dispose();
  }

  /// Stops listening to the running process and returns it.
  PtyProcess? _detach() {
    unawaited(_output?.cancel());
    _output = null;
    terminal.onOutput = null;
    terminal.onResize = null;
    final process = _process;
    _process = null;
    return process;
  }
}

/// The open terminals, in the order they were opened, and the one shown
/// for each AHP host (by `SavedHost.key`).
typedef TerminalTabs = ({
  List<TerminalSession> terminals,
  Map<String, TerminalSession> selected,
});

/// The terminals of the AHP host with [hostKey] in [tabs].
List<TerminalSession> terminalsOf(TerminalTabs tabs, String hostKey) => [
  for (final terminal in tabs.terminals)
    if (terminal.hostKey == hostKey) terminal,
];

/// The open terminals of every host.
final terminalsProvider = NotifierProvider<TerminalsNotifier, TerminalTabs>(
  TerminalsNotifier.new,
);

/// Opens, selects and closes terminals.
class TerminalsNotifier extends Notifier<TerminalTabs> {
  /// The open terminals, for closing them when the provider is disposed
  /// (state cannot be read then).
  final _open = <TerminalSession>{};

  @override
  TerminalTabs build() {
    ref.onDispose(() {
      for (final terminal in _open) {
        terminal.close();
      }
      _open.clear();
    });
    return (terminals: const [], selected: const {});
  }

  /// Opens a terminal to [host] for the AHP host [hostKey] (in
  /// [directory] when given), shows it and starts `ssh`.
  TerminalSession open({
    required String hostKey,
    required String host,
    String? directory,
  }) {
    final terminal = TerminalSession(
      hostKey: hostKey,
      host: host,
      directory: directory,
      spawner: ref.read(ptySpawnerProvider),
      environment: ref.read(processEnvironmentProvider),
    );
    _open.add(terminal);
    state = (
      terminals: [...state.terminals, terminal],
      selected: {...state.selected, hostKey: terminal},
    );
    terminal.start();
    return terminal;
  }

  /// Shows [terminal] for its host.
  void select(TerminalSession terminal) {
    terminal.requestFocus();
    state = (
      terminals: state.terminals,
      selected: {...state.selected, terminal.hostKey: terminal},
    );
  }

  /// Closes [terminal] and shows its host's neighbouring terminal.
  void close(TerminalSession terminal) {
    final siblings = terminalsOf(state, terminal.hostKey);
    final index = siblings.indexOf(terminal);
    if (index < 0) return;
    final rest = [...siblings]..removeAt(index);
    final selected = {...state.selected};
    if (selected[terminal.hostKey] == terminal) {
      if (rest.isEmpty) {
        selected.remove(terminal.hostKey);
      } else {
        selected[terminal.hostKey] = rest[index.clamp(0, rest.length - 1)];
      }
    }
    state = (
      terminals: [
        for (final other in state.terminals)
          if (other != terminal) other,
      ],
      selected: selected,
    );
    _open.remove(terminal);
    terminal.close();
  }
}
