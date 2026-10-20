/// Processes in a pseudo-terminal on macOS, Linux and Windows (`forkpty`
/// and ConPTY). Vendored from flutter_pty 0.4.2; see the README.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/bindings.dart' as native;
import 'src/command_line.dart';

export 'src/command_line.dart' show windowsQuote;

final _initialized = native.Dart_InitializeApiDL(NativeApi.initializeApiDLData);

void _ensureInitialized() {
  if (_initialized != 0) {
    throw StateError('Failed to initialize native bindings');
  }
}

/// A process running in a pseudo-terminal.
///
/// To create a Pty, use [Pty.start].
class Pty {
  /// Spawns [executable] with [arguments] in a pseudo-terminal of [rows]
  /// by [columns]. The arguments have the same meaning as in
  /// [Process.start]; [environment] is added to `TERM`, `LANG` and a few
  /// variables copied from this process. With [ackRead], the pty waits
  /// for [ackRead] before sending more output.
  Pty.start(
    this.executable, {
    this.arguments = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    int rows = 25,
    int columns = 80,
    bool ackRead = false,
  }) {
    _ensureInitialized();

    final effectiveEnv = <String, String>{
      'TERM': 'xterm-256color',
      // Without this, tools like "vi" produce sequences that are not UTF-8
      // friendly.
      'LANG': 'en_US.UTF-8',
      for (final entry in Platform.environment.entries)
        if (_envValuesToCopy.contains(entry.key)) entry.key: entry.value,
      ...?environment,
    };

    // The Windows side joins argv into a command line as it is.
    final argv = Platform.isWindows
        ? [executable, ...arguments].map(windowsQuote).toList()
        : [executable, ...arguments];

    using((arena) {
      Pointer<Char> string(String value) =>
          value.toNativeUtf8(allocator: arena).cast();
      Pointer<Pointer<Char>> strings(List<String> values) {
        final array = arena<Pointer<Char>>(values.length + 1);
        for (final (i, value) in values.indexed) {
          array[i] = string(value);
        }
        array[values.length] = nullptr;
        return array;
      }

      final options = arena<native.PtyOptions>();
      options.ref
        ..rows = rows
        ..cols = columns
        ..executable = string(executable)
        ..arguments = strings(argv)
        ..environment = strings([
          for (final MapEntry(:key, :value) in effectiveEnv.entries)
            '$key=$value',
        ])
        ..working_directory = workingDirectory == null
            ? nullptr
            : string(workingDirectory)
        ..stdout_port = _stdoutPort.sendPort.nativePort
        ..exit_port = _exitPort.sendPort.nativePort
        ..ackRead = ackRead;
      _handle = native.pty_create(options);
    });

    if (_handle == nullptr) {
      throw StateError('Failed to create PTY: ${_ptyError()}');
    }

    _exitPort.first.then(_onExitCode);
  }

  static const _envValuesToCopy = {
    'LOGNAME',
    'USER',
    'DISPLAY',
    'LC_TYPE',
    'HOME',
    'PATH',
  };

  /// The program started.
  final String executable;

  /// Its arguments.
  final List<String> arguments;

  final _stdoutPort = ReceivePort();

  final _exitPort = ReceivePort();

  final _exitCodeCompleter = Completer<int>();

  late final Pointer<native.PtyHandle> _handle;

  /// The output of the pseudo-terminal, which does not separate stdout
  /// and stderr.
  Stream<Uint8List> get output => _stdoutPort.cast();

  /// Completes with the exit code of the process when it ends: on Linux
  /// and macOS 0 to 255, or minus the signal number if a signal ended it;
  /// on Windows the 32-bit exit code as a signed value.
  ///
  /// [output] may still deliver buffered output after it completes.
  Future<int> get exitCode => _exitCodeCompleter.future;

  /// The process id of the process running in the pseudo-terminal.
  int get pid => native.pty_getpid(_handle);

  /// Writes [data] to the pseudo-terminal.
  void write(Uint8List data) {
    final buf = malloc<Uint8>(data.length);
    buf.asTypedList(data.length).setAll(0, data);
    native.pty_write(_handle, buf.cast(), data.length);
    malloc.free(buf);
  }

  /// Resizes the pseudo-terminal.
  void resize(int rows, int cols) => native.pty_resize(_handle, rows, cols);

  /// Sends [signal] to the process where signals exist (Linux and macOS),
  /// and ends it on Windows.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      Process.killPid(pid, signal);

  /// Says a chunk of [output] has been handled, when started with
  /// `ackRead`: the pty sends no more output until then.
  void ackRead() => native.pty_ack_read(_handle);

  void _onExitCode(dynamic exitCode) {
    _stdoutPort.close();
    _exitPort.close();
    _exitCodeCompleter.complete(exitCode as int);
  }
}

String? _ptyError() {
  final error = native.pty_error();
  return error == nullptr ? null : error.cast<Utf8>().toDartString();
}
