/// The shell an SSH terminal (AV-014) talks to, and how connection errors
/// read to the user. The connection itself is made by `connectSsh` in
/// `ssh_connect.dart`; tests use a fake [SshShell].
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ssh_connect.dart';
import 'ssh_settings.dart';

/// An interactive shell with a pty on an SSH server.
abstract interface class SshShell {
  /// The shell's output (stdout and stderr), as the pty writes it.
  Stream<Uint8List> get output;

  /// Sends [data] (keys typed or text pasted) to the shell.
  void write(Uint8List data);

  /// Tells the pty its new size, in character cells.
  void resize(int columns, int rows);

  /// Completes when the shell or the connection ends, with an error when
  /// the connection failed.
  Future<void> get done;

  /// Closes the shell and its connection.
  void close();
}

/// Decides whether to accept the host key a server [presented]; false
/// refuses the connection.
typedef HostKeyCheck = FutureOr<bool> Function(KnownHostKey presented);

/// Opens a shell with a [columns] by [rows] pty on the server in
/// [settings], checking its host key with [verifyHostKey]. Throws when
/// the connection, authentication or the shell fails.
typedef SshConnector = Future<SshShell> Function(
  SshSettings settings, {
  required int columns,
  required int rows,
  required HostKeyCheck verifyHostKey,
});

/// The [SshConnector]: [connectSsh]; tests override it.
final sshConnectorProvider = Provider<SshConnector>((ref) => connectSsh);

/// A connection error thrown by [connectSsh] with text for the user.
class SshConnectError implements Exception {
  /// Creates an error with [message].
  const SshConnectError(this.message);

  /// What went wrong, for the user.
  final String message;

  @override
  String toString() => message;
}

/// User-facing text for an [error] from connecting to [settings].
String describeSshError(Object error, SshSettings settings) => switch (error) {
  SshConnectError(:final message) => message,
  SSHKeyDecryptError() =>
    'The private key could not be decrypted: check its passphrase.',
  SSHKeyDecodeError(:final message) =>
    'The private key could not be read: $message',
  UnsupportedError(:final message?) =>
    'The private key is not supported: '
        '$message',
  // The connection closed before logging in, for example over the host
  // key or a network error: describe the cause.
  SSHAuthAbortError(:final reason?) => describeSshError(reason, settings),
  SSHAuthAbortError(:final message) =>
    'The connection to ${settings.host}:${settings.port} closed before '
        'logging in: $message',
  SSHAuthError() =>
    'Authentication as ${settings.user} on ${settings.host} failed: check '
        'the user and the ${_authNoun(settings.auth)}.',
  SSHHostkeyError(:final message) => 'The host key was refused: $message',
  SSHSocketError(:final error) =>
    'The connection to ${settings.host}:${settings.port} failed: $error',
  TimeoutException() =>
    'Timed out connecting to ${settings.host}:${settings.port}.',
  SSHChannelOpenError(:final description) =>
    'The server refused to open a shell: $description',
  _ => 'The SSH connection failed: $error',
};

String _authNoun(SshAuthMethod auth) => switch (auth) {
  SshAuthMethod.password => 'password',
  SshAuthMethod.privateKey => 'private key',
  SshAuthMethod.agent => 'keys in the SSH agent',
};
