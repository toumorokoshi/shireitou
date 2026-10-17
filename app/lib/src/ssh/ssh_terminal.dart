/// The open SSH terminals (AV-014): each one's xterm emulator, its shell
/// and its connection state.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:xterm/xterm.dart';

import 'ssh_settings.dart';
import 'ssh_shell.dart';
import 'ssh_store.dart';

final _log = Logger('ssh_terminal');

/// Lines of scrollback each terminal keeps.
const terminalScrollback = 10000;

/// Where an [SshTerminal]'s connection is.
enum SshStatus {
  /// Connecting, logging in or opening the shell.
  connecting,

  /// The shell is open.
  connected,

  /// The shell exited, the connection failed or it dropped.
  disconnected,
}

/// One SSH terminal: an xterm [terminal] wired to a shell on the server
/// in [settings], opened in [directory] when given. Reconnects on
/// [connect]; [close] ends it.
class SshTerminal extends ChangeNotifier {
  /// Creates a terminal; [connect] opens its shell.
  SshTerminal({
    required this.settings,
    required this.connector,
    required this.store,
    this.directory,
  });

  /// The server and how to log in.
  final SshSettings settings;

  /// Opens the shell.
  final SshConnector connector;

  /// Remembers the server's host key.
  final SshStore store;

  /// The folder to `cd` to once the shell opens (a session's working
  /// directory); null stays in the login directory.
  final String? directory;

  /// The terminal emulator holding the screen and scrollback.
  final terminal = Terminal(maxLines: terminalScrollback);

  /// The connection state.
  SshStatus get status => _status;
  SshStatus _status = SshStatus.disconnected;

  /// Why the terminal is disconnected, for the user; null after a normal
  /// exit or while connected.
  String? get error => _error;
  String? _error;

  /// A short label for a tab: the folder's name or the server.
  String get label {
    final folder = directory?.split('/').where((s) => s.isNotEmpty).lastOrNull;
    return folder == null ? settings.label : '$folder · ${settings.host}';
  }

  /// Whether the next character typed is sent with Ctrl (the key row's
  /// Ctrl, for touch keyboards that have none).
  bool get ctrlLatched => _ctrlLatched;
  var _ctrlLatched = false;
  set ctrlLatched(bool latched) {
    _ctrlLatched = latched;
    notifyListeners();
  }

  SshShell? _shell;
  StreamSubscription<String>? _output;
  var _closed = false;

  /// The refusal of a changed host key, kept to explain the failure.
  String? _hostKeyRefusal;

  /// Opens the shell (closing any open one first), writing progress and
  /// errors into the terminal.
  Future<void> connect() async {
    _disconnectShell();
    _setStatus(SshStatus.connecting, null);
    _hostKeyRefusal = null;
    terminal.write('Connecting to ${settings.label}…\r\n');
    try {
      final shell = await connector(
        settings,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
        verifyHostKey: _verifyHostKey,
      );
      if (_closed) return shell.close();
      _attach(shell);
    } on Object catch (error) {
      if (_closed) return;
      final message = _hostKeyRefusal ?? describeSshError(error, settings);
      _log.info('ssh to ${settings.label} failed: $error');
      terminal.write('\r\n${message.replaceAll('\n', '\r\n')}\r\n');
      _setStatus(SshStatus.disconnected, message);
    }
  }

  void _attach(SshShell shell) {
    _shell = shell;
    _output = shell.output
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(terminal.write);
    terminal.onOutput = (data) {
      if (_ctrlLatched) {
        ctrlLatched = false;
        data = withControl(data);
      }
      shell.write(utf8.encode(data));
    };
    terminal.onResize = (columns, rows, _, _) => shell.resize(columns, rows);
    if (directory case final directory?) {
      shell.write(utf8.encode(changeDirectoryCommand(directory)));
    }
    _setStatus(SshStatus.connected, null);
    unawaited(
      shell.done.then(
        (_) => _ended(shell, null),
        onError: (Object error) =>
            _ended(shell, describeSshError(error, settings)),
      ),
    );
  }

  void _ended(SshShell shell, String? error) {
    if (_closed || _shell != shell) return;
    _disconnectShell();
    terminal.write(
      '\r\n[${error ?? 'Connection to ${settings.label} closed.'}]\r\n',
    );
    _setStatus(SshStatus.disconnected, error);
  }

  Future<bool> _verifyHostKey(KnownHostKey presented) async {
    final target = settings.target;
    final known = (await store.loadKnownHosts())[target];
    switch (decideHostKey(known, presented)) {
      case HostKeyDecision.matches:
        return true;
      case HostKeyDecision.trustNew:
        await store.saveKnownHost(target, presented);
        terminal.write(
          'Trusting the host key of $target on first use:\r\n'
          '  ${presented.type} ${presented.fingerprint}\r\n',
        );
        return true;
      case HostKeyDecision.changed:
        _hostKeyRefusal = changedHostKeyMessage(target, known!, presented);
        return false;
    }
  }

  /// Ends the shell and stops the terminal.
  void close() {
    _closed = true;
    _disconnectShell();
    dispose();
  }

  void _disconnectShell() {
    unawaited(_output?.cancel());
    _output = null;
    _shell?.close();
    _shell = null;
    terminal.onOutput = null;
    terminal.onResize = null;
  }

  void _setStatus(SshStatus status, String? error) {
    _status = status;
    _error = error;
    notifyListeners();
  }
}

/// [data] typed with Ctrl held: a single letter or one of `@[\]^_` and
/// space becomes its control character, `?` becomes DEL, and anything
/// else is unchanged.
String withControl(String data) {
  if (data.length != 1) return data;
  final code = data.toUpperCase().codeUnitAt(0);
  return switch (code) {
    >= 0x40 && <= 0x5f => String.fromCharCode(code - 0x40),
    0x20 => '\x00',
    0x3f => '\x7f',
    _ => data,
  };
}

/// The open terminals and which one is shown.
typedef SshTerminals = ({List<SshTerminal> terminals, int selected});

/// The open SSH terminals.
final sshTerminalsProvider =
    NotifierProvider<SshTerminalsNotifier, SshTerminals>(
      SshTerminalsNotifier.new,
    );

/// Opens, selects and closes SSH terminals.
class SshTerminalsNotifier extends Notifier<SshTerminals> {
  /// Whether the terminals screen is on the navigator, so opening another
  /// terminal shows it there rather than pushing a second screen.
  bool screenOpen = false;

  /// The open terminals, for closing them when the provider is disposed
  /// (state cannot be read then).
  final _open = <SshTerminal>{};

  @override
  SshTerminals build() {
    ref.onDispose(() {
      for (final terminal in _open) {
        terminal.close();
      }
      _open.clear();
    });
    return (terminals: const [], selected: 0);
  }

  /// Opens a terminal to [settings] (in [directory], when given), shows it
  /// and connects.
  SshTerminal open(SshSettings settings, {String? directory}) {
    final terminal = SshTerminal(
      settings: settings,
      directory: directory,
      connector: ref.read(sshConnectorProvider),
      store: ref.read(sshStoreProvider),
    );
    _open.add(terminal);
    final terminals = [...state.terminals, terminal];
    state = (terminals: terminals, selected: terminals.length - 1);
    unawaited(terminal.connect());
    return terminal;
  }

  /// Shows the terminal at [index].
  void select(int index) =>
      state = (terminals: state.terminals, selected: index);

  /// Closes [terminal] and shows its neighbour.
  void close(SshTerminal terminal) {
    final index = state.terminals.indexOf(terminal);
    if (index < 0) return;
    final terminals = [...state.terminals]..removeAt(index);
    final selected =
        state.selected > index || state.selected >= terminals.length
        ? state.selected - 1
        : state.selected;
    state = (terminals: terminals, selected: selected < 0 ? 0 : selected);
    _open.remove(terminal);
    terminal.close();
  }
}
