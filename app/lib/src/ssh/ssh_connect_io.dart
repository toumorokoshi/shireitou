/// The SSH connector on desktop and mobile, on dartssh2.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:dartssh2/dartssh2.dart';

import 'ssh_agent_codec.dart';
import 'ssh_settings.dart';
import 'ssh_shell.dart';

/// Whether this platform can open SSH terminals.
const sshSupported = true;

/// Why there is no SSH terminal here; unused where [sshSupported].
const sshUnsupportedReason = '';

/// How long to wait for the TCP connection.
const _connectTimeout = Duration(seconds: 15);

/// Connects to the server in [settings], checks its host key with
/// [verifyHostKey], logs in and opens a shell with a [columns] by [rows]
/// `xterm-256color` pty. Throws [SshConnectError] or dartssh2's errors
/// (see [describeSshError]).
Future<SshShell> connectSsh(
  SshSettings settings, {
  required int columns,
  required int rows,
  required HostKeyCheck verifyHostKey,
}) async {
  final agent = settings.auth == SshAuthMethod.agent
      ? await _SshAgent.connect()
      : null;
  try {
    final identities = switch (settings.auth) {
      SshAuthMethod.password => null,
      SshAuthMethod.privateKey => SSHKeyPair.fromPem(
        settings.privateKey,
        settings.passphrase.isEmpty ? null : settings.passphrase,
      ),
      SshAuthMethod.agent => await agent!.identities(),
    };
    final SSHSocket socket;
    try {
      socket = await SSHSocket.connect(
        settings.host,
        settings.port,
        timeout: _connectTimeout,
      );
    } on SocketException catch (error) {
      throw SshConnectError(
        'Could not reach ${settings.host}:${settings.port}: '
        '${error.osError?.message ?? error.message}',
      );
    }
    final password = settings.auth == SshAuthMethod.password
        ? settings.password
        : null;
    final client = SSHClient(
      socket,
      username: settings.user,
      onVerifyHostKey: (type, fingerprint) =>
          verifyHostKey((type: type, fingerprint: utf8.decode(fingerprint))),
      identities: identities,
      onPasswordRequest: password == null ? null : () => password,
      // Servers such as macOS's ask for the password this way.
      onUserInfoRequest: password == null
          ? null
          : (request) => [for (final _ in request.prompts) password],
    );
    try {
      final session = await client.shell(
        pty: SSHPtyConfig(width: columns, height: rows),
      );
      return _DartSshShell(client, session, agent);
    } on Object {
      unawaited(client.close());
      rethrow;
    }
  } on Object {
    await agent?.close();
    rethrow;
  }
}

/// [SshShell] on a dartssh2 session.
class _DartSshShell implements SshShell {
  _DartSshShell(this._client, this._session, this._agent) {
    // The shell exits, or the connection drops (with an error).
    done = Future.any([_session.done, _client.done]).whenComplete(() {
      unawaited(_client.close());
      unawaited(_agent?.close());
    });
  }

  final SSHClient _client;
  final SSHSession _session;
  final _SshAgent? _agent;

  @override
  late final Future<void> done;

  @override
  late final Stream<Uint8List> output = StreamGroup.merge([
    _session.stdout,
    _session.stderr,
  ]);

  @override
  void write(Uint8List data) => _session.write(data);

  @override
  void resize(int columns, int rows) => _session.resizeTerminal(columns, rows);

  @override
  void close() {
    _session.close();
    unawaited(_client.close());
  }
}

/// A connection to the running SSH agent (`SSH_AUTH_SOCK`), whose keys
/// log in as dartssh2 identities.
class _SshAgent {
  _SshAgent(this._socket) {
    _socket.listen(
      _onData,
      onError: _fail,
      onDone: () => _fail(const SshConnectError('The SSH agent hung up.')),
    );
  }

  /// Connects to the agent at `SSH_AUTH_SOCK`.
  static Future<_SshAgent> connect() async {
    if (Platform.isWindows) {
      throw const SshConnectError(
        'The SSH agent is not supported on Windows: use a password or a '
        'private key.',
      );
    }
    final path = Platform.environment['SSH_AUTH_SOCK'];
    if (path == null || path.isEmpty) {
      throw const SshConnectError(
        'No SSH agent is running (SSH_AUTH_SOCK is not set): use a password '
        'or a private key.',
      );
    }
    try {
      final address = InternetAddress(path, type: InternetAddressType.unix);
      return _SshAgent(await Socket.connect(address, 0));
    } on SocketException catch (error) {
      throw SshConnectError('Could not reach the SSH agent: ${error.message}');
    }
  }

  final Socket _socket;
  var _buffer = Uint8List(0);
  final _replies = <Completer<Uint8List>>[];

  /// The agent's keys, as identities that ask the agent to sign.
  Future<List<SSHIdentity>> identities() async {
    final keys = parseIdentitiesAnswer(
      await _request(requestIdentitiesMessage()),
    );
    if (keys.isEmpty) {
      throw const SshConnectError('The SSH agent holds no keys.');
    }
    return [
      for (final key in keys)
        if (agentSignatureAlgorithm(agentKeyType(key.blob)) case (
          final type,
          final flags,
        ))
          SSHIdentity.custom(
            type: type,
            publicKey: SSHRawHostKey(key.blob),
            comment: key.comment,
            shouldProbe: true,
            signer: (data) async => SSHRawSignature(
              parseSignResponse(
                await _request(signRequestMessage(key.blob, data, flags)),
              ),
            ),
          ),
    ];
  }

  Future<void> close() => _socket.close();

  Future<Uint8List> _request(Uint8List message) {
    final reply = Completer<Uint8List>();
    _replies.add(reply);
    _socket.add(frameAgentMessage(message));
    return reply.future;
  }

  void _onData(Uint8List data) {
    _buffer = Uint8List.fromList([..._buffer, ...data]);
    for (
      var frame = readAgentFrame(_buffer);
      frame != null;
      frame = readAgentFrame(_buffer)
    ) {
      final (payload, length) = frame;
      if (_replies.isNotEmpty) _replies.removeAt(0).complete(payload);
      _buffer = Uint8List.sublistView(_buffer, length);
    }
  }

  void _fail(Object error) {
    for (final reply in _replies) {
      reply.completeError(error);
    }
    _replies.clear();
  }
}
