/// The C functions of `src/flutter_pty.h`, from the library the build
/// hook compiles.
// The names are the C symbols.
// ignore_for_file: non_constant_identifier_names
@DefaultAsset('package:flutter_pty/src/bindings.dart')
library;

import 'dart:ffi';

/// What `pty_create` starts.
final class PtyOptions extends Struct {
  @Int()
  external int rows;

  @Int()
  external int cols;

  external Pointer<Char> executable;

  external Pointer<Pointer<Char>> arguments;

  external Pointer<Pointer<Char>> environment;

  external Pointer<Char> working_directory;

  @Int64()
  external int stdout_port;

  @Int64()
  external int exit_port;

  @Bool()
  external bool ackRead;
}

/// A running pseudo-terminal.
final class PtyHandle extends Opaque {}

@Native<IntPtr Function(Pointer<Void>)>()
external int Dart_InitializeApiDL(Pointer<Void> data);

@Native<Pointer<PtyHandle> Function(Pointer<PtyOptions>)>()
external Pointer<PtyHandle> pty_create(Pointer<PtyOptions> options);

@Native<Void Function(Pointer<PtyHandle>, Pointer<Char>, Int)>()
external void pty_write(
  Pointer<PtyHandle> handle,
  Pointer<Char> buffer,
  int length,
);

@Native<Void Function(Pointer<PtyHandle>)>()
external void pty_ack_read(Pointer<PtyHandle> handle);

@Native<Int Function(Pointer<PtyHandle>, Int, Int)>()
external int pty_resize(Pointer<PtyHandle> handle, int rows, int cols);

@Native<Int Function(Pointer<PtyHandle>)>()
external int pty_getpid(Pointer<PtyHandle> handle);

@Native<Pointer<Char> Function()>()
external Pointer<Char> pty_error();
