import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Compiles `src/flutter_pty.c` into the library behind
/// `lib/src/bindings.dart`, on the desktops only: iOS and Android apps
/// cannot run the system `ssh`.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final os = input.config.code.targetOS;
    if (![OS.macOS, OS.linux, OS.windows].contains(os)) return;
    await CBuilder.library(
      name: 'flutter_pty',
      assetName: 'src/bindings.dart',
      sources: ['src/flutter_pty.c'],
      defines: {'DART_SHARED_LIB': null},
      libraries: [if (os == OS.linux) 'pthread'],
    ).run(input: input, output: output);
  });
}
