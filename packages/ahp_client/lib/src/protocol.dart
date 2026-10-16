/// Protocol constants and pure helpers for the AHP handshake.
library;

import 'dart:math' as math;

/// The protocol version shireitou's wire types are modeled on.
const targetProtocolVersion = '1.0.0';

/// Versions offered in `initialize`, most preferred first. Matches
/// `SUPPORTED_PROTOCOL_VERSIONS` of `@microsoft/agent-host-protocol@1.0.0`.
const offeredProtocolVersions = <String>['1.0.0', '0.9.0'];

/// The root channel URI.
const rootChannel = 'ahp-root://';

/// Query parameter that carries the connection token (pi uses `tkn`).
const tokenQueryParameter = 'tkn';

/// AHP JSON-RPC error codes (`AhpErrorCodes` in protocol 1.0.0).
abstract final class AhpErrorCodes {
  /// The session does not exist.
  static const sessionNotFound = -32001;

  /// The agent provider does not exist.
  static const providerNotFound = -32002;

  /// `createSession` used a URI that already exists.
  static const sessionAlreadyExists = -32003;

  /// A turn is already running.
  static const turnInProgress = -32004;

  /// None of the offered protocol versions is supported.
  static const unsupportedProtocolVersion = -32005;

  /// The request needs authentication.
  static const authRequired = -32007;

  /// The resource (or reconnecting client) was not found.
  static const notFound = -32008;

  /// The request is not allowed.
  static const permissionDenied = -32009;

  /// The resource already exists.
  static const alreadyExists = -32010;

  /// The request conflicts with the current state.
  static const conflict = -32011;
}

/// Returns [uri] with [token] in the `tkn` query parameter (AHP-002).
///
/// Leaves [uri] unchanged when [token] is null or empty, so a URL pasted from
/// the host (which already carries `?tkn=…`) keeps its token.
Uri withConnectionToken(Uri uri, String? token) {
  if (token == null || token.isEmpty) return uri;
  return uri.replace(
    queryParameters: {...uri.queryParameters, tokenQueryParameter: token},
  );
}

/// Builds `initialize` params (AHP-003).
Map<String, Object?> initializeParams({
  required String clientId,
  required Map<String, Object?> clientInfo,
  required List<String> initialSubscriptions,
  String? locale,
  List<String> protocolVersions = offeredProtocolVersions,
}) => {
  'channel': rootChannel,
  'protocolVersions': protocolVersions,
  'clientId': clientId,
  'clientInfo': clientInfo,
  'initialSubscriptions': initialSubscriptions,
  'locale': ?locale,
};

/// Builds `reconnect` params (AHP-004).
Map<String, Object?> reconnectParams({
  required String clientId,
  required int lastSeenServerSeq,
  required List<String> subscriptions,
}) => {
  'channel': rootChannel,
  'clientId': clientId,
  'lastSeenServerSeq': lastSeenServerSeq,
  'subscriptions': subscriptions,
};

/// Describes a JSON-RPC error from the host for display.
///
/// For `-32005 UnsupportedProtocolVersion` it lists the host's
/// `supportedVersions` (AHP-003).
String describeRpcError(int code, String message, Object? data) {
  if (code == AhpErrorCodes.unsupportedProtocolVersion) {
    final supported = data is Map ? data['supportedVersions'] : null;
    final versions = supported is List ? supported.join(', ') : 'unknown';
    return 'Unsupported protocol version. Client offers '
        '${offeredProtocolVersions.join(', ')}; host supports $versions.';
  }
  return '$message (code $code)';
}

/// Exponential reconnect backoff with a cap: 0.5s, 1s, 2s, ... up to [max].
Duration reconnectDelay(
  int attempt, {
  Duration base = const Duration(milliseconds: 500),
  Duration max = const Duration(seconds: 30),
}) {
  final factor = math.pow(2, math.min(attempt, 16)).toInt();
  final delay = base * factor;
  return delay > max ? max : delay;
}
