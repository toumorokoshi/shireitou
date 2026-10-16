import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A real pi-agent-host-protocol host whose model is pi's scripted faux
/// provider (`scripts/pi-faux-host.ts`), run as a `node` process. Tests
/// stream real pi turns with it, without an API key; see
/// docs/testing.md for the replies.
class PiFauxHost {
  PiFauxHost._(this.process, this.url, this.stateDir, this._options);

  /// The `node` process running the host.
  final Process process;

  /// Where clients connect, with `tkn` when the host has a token.
  final Uri url;

  /// Sessions, settings and the archive; kept by [restart].
  final Directory stateDir;

  final _PiFauxOptions _options;

  /// The host's port.
  int get port => url.port;

  /// The folder the host offers as the default working directory.
  String get workspace => '${stateDir.path}/workspace';

  /// The repository root (where `scripts/pi-faux-host.ts` is): `SHIREITOU_REPO`,
  /// else found upwards from the current directory or the running
  /// executable (a desktop app under `app/build`); null when not run
  /// inside the repo.
  static Directory? get repoRoot {
    bool isRoot(Directory dir) =>
        File('${dir.path}/scripts/pi-faux-host.ts').existsSync();
    final configured = Platform.environment['SHIREITOU_REPO'];
    if (configured != null && isRoot(Directory(configured))) {
      return Directory(configured);
    }
    for (final start in [
      Directory.current.absolute,
      File(Platform.resolvedExecutable).parent,
    ]) {
      for (var dir = start; ; dir = dir.parent) {
        if (isRoot(dir)) return dir;
        if (dir.parent.path == dir.path) break;
      }
    }
    return null;
  }

  /// The pi-agent-host-protocol checkout: `PI_AHP_HOST_DIR`, else a
  /// sibling of this repo, else one inside it (where CI checks it out).
  static String? get piDir {
    final configured = Platform.environment['PI_AHP_HOST_DIR'];
    if (configured != null && configured.isNotEmpty) return configured;
    final root = repoRoot;
    if (root == null) return null;
    final inside = '${root.path}/pi-agent-host-protocol';
    return File('$inside/src/host/agent-host.ts').existsSync()
        ? inside
        : '${root.parent.path}/pi-agent-host-protocol';
  }

  /// Why the host cannot run here, or null when it can (the checkout and
  /// its `node_modules` exist).
  static String? get unavailable {
    final dir = piDir;
    if (repoRoot == null) return 'not inside the shireitou repository';
    if (dir == null || !File('$dir/src/host/agent-host.ts').existsSync()) {
      return 'no pi-agent-host-protocol checkout (set PI_AHP_HOST_DIR)';
    }
    if (!Directory('$dir/node_modules/@earendil-works').existsSync()) {
      return 'run npm ci in $dir';
    }
    return null;
  }

  /// Starts a host on [port] (0 for a free one) with [token] (null for
  /// none), keeping its state in [stateDir] (a new temp directory when
  /// null, deleted by [stop]).
  static Future<PiFauxHost> start({
    int port = 0,
    String? token = 'faux-token',
    Directory? stateDir,
    int tokensPerSecond = 500,
  }) async {
    final dir =
        stateDir ?? await Directory.systemTemp.createTemp('shireitou-pi-');
    return _start(
      _PiFauxOptions(
        token: token,
        tokensPerSecond: tokensPerSecond,
        ownsStateDir: stateDir == null,
      ),
      port,
      dir,
    );
  }

  static Future<PiFauxHost> _start(
    _PiFauxOptions options,
    int port,
    Directory stateDir,
  ) async {
    final process = await Process.start('node', [
      '${repoRoot!.path}/scripts/pi-faux-host.ts',
      '--pi-dir',
      piDir!,
      '--state-dir',
      stateDir.path,
      '--port',
      '$port',
      '--tokens-per-second',
      '${options.tokensPerSecond}',
      if (options.token case final token?) ...[
        '--token',
        token,
      ] else
        '--no-token',
    ]);
    final log = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(log.write);
    final listening = RegExp(r'listening on (ws://\S+)');
    final lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    try {
      final url = await lines
          .map(listening.firstMatch)
          .firstWhere((m) => m != null)
          .timeout(const Duration(seconds: 60))
          .then((m) => Uri.parse(m!.group(1)!));
      lines.listen((_) {});
      return PiFauxHost._(process, url, stateDir, options);
    } on Object {
      process.kill();
      throw StateError('pi-faux-host did not start: $log');
    }
  }

  /// Stops the host. Its state directory is deleted unless the caller
  /// passed it in, or [keepState] is set (for [restart]).
  Future<void> stop({bool keepState = false}) async {
    process.kill();
    await process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    if (!keepState && _options.ownsStateDir && stateDir.existsSync()) {
      await stateDir.delete(recursive: true);
    }
  }

  /// Stops the host and starts a new one on the same port and state, as
  /// a host restart would: clients it knew are forgotten, sessions saved
  /// to disk stay.
  Future<PiFauxHost> restart() async {
    await stop(keepState: true);
    return _start(_options, port, stateDir);
  }
}

class _PiFauxOptions {
  const _PiFauxOptions({
    required this.token,
    required this.tokensPerSecond,
    required this.ownsStateDir,
  });

  final String? token;
  final int tokensPerSecond;
  final bool ownsStateDir;
}
