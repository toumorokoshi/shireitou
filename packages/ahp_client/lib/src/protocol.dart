/// Protocol constants and pure helpers for the AHP handshake.
library;

import 'dart:math' as math;

import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'connection_problems.dart';

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

/// Header that carries the connection token on native platforms (AHP-002).
///
/// The AHP spec leaves connection gating to the transport and names no
/// header; this matches the protocol repo's Swift client, which sends
/// `Authorization: Bearer <token>`.
const tokenHeader = 'Authorization';

/// Where the connection token goes in the WebSocket handshake (AHP-002).
enum TokenTransport {
  /// Only the `tkn` query parameter. The only choice on web, where browsers
  /// cannot set headers on the upgrade request.
  query,

  /// Only the `Authorization: Bearer` header; `tkn` is removed from the URL.
  header,

  /// Both. The native default: hosts that read the header get it, and hosts
  /// that only read `tkn` (pi-agent-host-protocol) still connect.
  queryAndHeader,
}

/// The URL and headers of a WebSocket handshake.
typedef Handshake = ({Uri uri, Map<String, String> headers});

/// The connection token in [uri]'s `tkn` query parameter, or null.
String? connectionTokenOf(Uri uri) {
  final token = uri.queryParameters[tokenQueryParameter];
  return token == null || token.isEmpty ? null : token;
}

/// Splits [uri] (which carries the token as `tkn`, see
/// [withConnectionToken]) into the handshake for [transport].
Handshake handshakeFor(Uri uri, TokenTransport transport) {
  final token = connectionTokenOf(uri);
  if (token == null || transport == TokenTransport.query) {
    return (uri: uri, headers: const {});
  }
  final headers = {tokenHeader: 'Bearer $token'};
  if (transport == TokenTransport.queryAndHeader) {
    return (uri: uri, headers: headers);
  }
  final query = {...uri.queryParameters}..remove(tokenQueryParameter);
  // `Uri.replace` keeps the old query when given none, so rebuild.
  final stripped = Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: query.isEmpty ? null : query,
  );
  return (uri: stripped, headers: headers);
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
  if (code == AhpErrorCodes.authRequired) {
    final resources = data is Map ? data['resources'] : null;
    final names = [
      if (resources is List)
        for (final r in resources)
          if (r is Map) '${r['resource_name'] ?? r['resource']}',
    ];
    return names.isEmpty
        ? 'Sign-in required: $message'
        : 'Sign-in required: ${names.join(', ')}';
  }
  return '$message (code $code)';
}

/// Whether a failed liveness `ping` means the socket is dead. Any JSON-RPC
/// error response (even `MethodNotFound` from a host without `ping`) proves
/// the host answered; a timeout or a closed peer does not.
bool isLivenessFailure(Object error) => error is! RpcException;

/// Whether a failed connect is worth retrying with backoff (AHP-004): the
/// host was unreachable, dropped the socket or did not answer in time. A
/// JSON-RPC error (an unsupported protocol version, for example) and the
/// transport problems [isTransientTransportError] rules out need the user.
bool isTransientConnectError(Object error) => switch (error) {
  RpcException() => false,
  ConnectionProblem() => isTransientTransportError(error),
  _ => true,
};

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
