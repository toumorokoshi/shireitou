# flutter_pty (vendored)

Processes in a pseudo-terminal on macOS, Linux and Windows, for the
app's terminal panel (AV-016, see [docs/terminal.md](../../docs/terminal.md)).

This is [flutter_pty](https://github.com/TerminalStudio/flutter_pty) 0.4.2
by xuty (MIT, see [LICENSE](LICENSE)), with these changes:

- **A Dart build hook instead of a Flutter plugin.** `hook/build.dart`
  compiles `src/flutter_pty.c` with `native_toolchain_c` for macOS, Linux
  and Windows. The published plugin builds through CocoaPods on macOS
  (no Swift Package Manager support) and is bundled into iOS and Android
  apps that cannot use it.
- **`@Native` bindings.** `lib/src/bindings.dart` declares the six C
  functions and `Dart_InitializeApiDL` instead of the 777-line ffigen
  output, and finds them in the hook's library.
- **Windows command lines.** The C code built the command line from the
  executable followed by the whole argv, which starts with the executable
  again, and did not quote arguments: `ssh -t -- host` ran as
  `ssh ssh -t -- host`. Now `build_command` joins argv alone (converted
  from UTF-8), and `Pty.start` quotes each argument on Windows with
  `windowsQuote`.

The Dart SDK headers in `src/include/` are from the Dart SDK (BSD).

## Tests

`dart test` builds the library with the hook and runs a real pty. Exit
codes are not checked there: the test runner reaps child processes
itself, so the pty's `waitpid` finds none and reads 0. The app's
integration test checks them in the built app.
