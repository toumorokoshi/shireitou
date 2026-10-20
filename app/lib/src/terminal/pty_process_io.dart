/// [PtyProcess] on `flutter_pty`, for platforms with `dart:ffi`.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';

import 'pty_process.dart';

/// Starts [executable] in a pty with `flutter_pty`.
PtyProcess startPty(
  String executable,
  List<String> arguments, {
  required Map<String, String> environment,
  required int rows,
  required int columns,
}) => _FlutterPty(
  Pty.start(
    executable,
    arguments: arguments,
    environment: environment,
    rows: rows,
    columns: columns,
  ),
);

/// The app's environment.
Map<String, String> processEnvironment() => Platform.environment;

class _FlutterPty implements PtyProcess {
  _FlutterPty(this._pty);

  final Pty _pty;

  @override
  Stream<Uint8List> get output => _pty.output;

  @override
  Future<int> get exitCode => _pty.exitCode;

  @override
  void write(Uint8List data) => _pty.write(data);

  @override
  void resize(int rows, int columns) => _pty.resize(rows, columns);

  @override
  void kill() => _pty.kill();
}
