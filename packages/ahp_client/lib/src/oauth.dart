/// OAuth 2.1 sign-in for protected resources (AHP-060): authorization
/// server discovery (RFC 8414, OpenID Connect Discovery), dynamic client
/// registration (RFC 7591), the authorization code flow with PKCE
/// (RFC 7636) and resource indicators (RFC 8707), and refresh, as the MCP
/// authorization spec (2025-11-25) asks of clients.
///
/// The pure pieces (URLs, PKCE, response parsing) are top-level functions;
/// [OAuthHttp] does the HTTP and [signInWithBrowser] runs the whole flow.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'wire.dart';

/// A PKCE code verifier and its `S256` challenge (RFC 7636).
typedef Pkce = ({String verifier, String challenge});

/// [bytes] random bytes, base64url-encoded without padding.
String randomUrlSafe(int bytes, [Random? random]) {
  final source = random ?? Random.secure();
  return _base64UrlNoPad([for (var i = 0; i < bytes; i++) source.nextInt(256)]);
}

String _base64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// The `S256` code challenge of [verifier]: base64url(SHA-256(verifier)).
String pkceChallenge(String verifier) =>
    _base64UrlNoPad(sha256.convert(ascii.encode(verifier)).bytes);

/// A fresh PKCE pair: a 43-character verifier (32 random bytes) and its
/// `S256` challenge.
Pkce createPkce([Random? random]) {
  final verifier = randomUrlSafe(32, random);
  return (verifier: verifier, challenge: pkceChallenge(verifier));
}

/// Why [endpoint] may not be used for OAuth, or null when it may: the MCP
/// authorization spec requires HTTPS, except for loopback addresses (a
/// local authorization server, as in tests).
String? insecureEndpointProblem(Uri endpoint) {
  if (endpoint.scheme == 'https') return null;
  final loopback = const {
    'localhost',
    '127.0.0.1',
    '::1',
    '[::1]',
  }.contains(endpoint.host);
  if (endpoint.scheme == 'http' && loopback) return null;
  return '$endpoint is not an HTTPS URL';
}

/// The metadata URLs to try for the authorization server [issuer], in the
/// order the MCP authorization spec gives: OAuth 2.0 Authorization Server
/// Metadata (RFC 8414) first, then OpenID Connect Discovery, path-inserted
/// for issuers with a path.
List<Uri> authorizationServerMetadataUris(Uri issuer) {
  final path = issuer.path.endsWith('/')
      ? issuer.path.substring(0, issuer.path.length - 1)
      : issuer.path;
  Uri at(String p) => issuer.replace(path: p, query: null, fragment: null);
  if (path.isEmpty) {
    return [
      at('/.well-known/oauth-authorization-server'),
      at('/.well-known/openid-configuration'),
    ];
  }
  return [
    at('/.well-known/oauth-authorization-server$path'),
    at('/.well-known/openid-configuration$path'),
    at('$path/.well-known/openid-configuration'),
  ];
}

/// The parts of an authorization server's metadata (RFC 8414) the flow
/// uses.
final class AuthorizationServerMetadata {
  /// Creates [AuthorizationServerMetadata].
  const AuthorizationServerMetadata({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
    this.codeChallengeMethodsSupported,
    this.tokenEndpointAuthMethodsSupported,
    this.scopesSupported,
  });

  /// Decodes RFC 8414 metadata. Throws [OAuthException] when an endpoint
  /// is missing.
  factory AuthorizationServerMetadata.fromJson(JsonMap json) {
    Uri endpoint(String key) => switch (json[key]) {
      final String url => Uri.parse(url),
      _ => throw OAuthException('invalid_metadata', 'no $key'),
    };
    List<String>? strings(String key) => switch (json[key]) {
      final List<Object?> list => [for (final s in list) '$s'],
      _ => null,
    };
    return AuthorizationServerMetadata(
      issuer: '${json['issuer'] ?? ''}',
      authorizationEndpoint: endpoint('authorization_endpoint'),
      tokenEndpoint: endpoint('token_endpoint'),
      registrationEndpoint: json['registration_endpoint'] == null
          ? null
          : endpoint('registration_endpoint'),
      codeChallengeMethodsSupported: strings(
        'code_challenge_methods_supported',
      ),
      tokenEndpointAuthMethodsSupported: strings(
        'token_endpoint_auth_methods_supported',
      ),
      scopesSupported: strings('scopes_supported'),
    );
  }

  /// The issuer identifier.
  final String issuer;

  /// Where the browser is sent to sign in.
  final Uri authorizationEndpoint;

  /// Where codes and refresh tokens are exchanged.
  final Uri tokenEndpoint;

  /// Dynamic client registration (RFC 7591), when offered.
  final Uri? registrationEndpoint;

  /// PKCE methods; the MCP spec forbids proceeding without `S256` here.
  final List<String>? codeChallengeMethodsSupported;

  /// Client authentication methods at [tokenEndpoint] (RFC 8414 default:
  /// `client_secret_basic`).
  final List<String>? tokenEndpointAuthMethodsSupported;

  /// Scopes the server knows.
  final List<String>? scopesSupported;

  /// Whether the server advertises PKCE with `S256`.
  bool get supportsS256 =>
      codeChallengeMethodsSupported?.contains('S256') ?? false;
}

/// An OAuth failure: an `error` code from the authorization server (RFC
/// 6749 §4.1.2.1, §5.2) or one of this client's (`invalid_metadata`,
/// `state_mismatch`, `no_registration`, `pkce_unsupported`, `timeout`).
final class OAuthException implements Exception {
  /// Creates an [OAuthException].
  const OAuthException(this.error, [this.description]);

  /// The error code.
  final String error;

  /// A human-readable description, when there is one.
  final String? description;

  @override
  String toString() => description == null ? error : '$error: $description';
}

/// A token for a protected resource, with what refreshing it needs.
///
/// A pasted token has only [token] and [obtainedAt]. One from
/// [signInWithBrowser] also carries the token endpoint, client and
/// resource indicator, and usually [expiresIn] and [refreshToken].
final class ResourceToken {
  /// Creates a [ResourceToken].
  const ResourceToken({
    required this.token,
    required this.obtainedAt,
    this.expiresIn,
    this.scopes,
    this.refreshToken,
    this.tokenEndpoint,
    this.client,
    this.resource,
    this.authMethod,
  });

  /// Decodes what [toJson] wrote.
  factory ResourceToken.fromJson(JsonMap json) => ResourceToken(
    token: json['token']! as String,
    obtainedAt: DateTime.parse(json['obtainedAt']! as String),
    expiresIn: json['expiresIn'] as int?,
    scopes: (json['scopes'] as List<Object?>?)?.cast<String>(),
    refreshToken: json['refreshToken'] as String?,
    tokenEndpoint: switch (json['tokenEndpoint']) {
      final String url => Uri.parse(url),
      _ => null,
    },
    client: switch (json['client']) {
      final JsonMap client => McpOAuthClient.fromJson(client),
      _ => null,
    },
    resource: json['resource'] as String?,
    authMethod: json['authMethod'] as String?,
  );

  /// The bearer token.
  final String token;

  /// When the token response arrived (or the token was pasted).
  final DateTime obtainedAt;

  /// `expires_in` of the token response, in seconds; null when unknown.
  final int? expiresIn;

  /// The scopes granted, when known.
  final List<String>? scopes;

  /// The refresh token, when the server issued one.
  final String? refreshToken;

  /// Where to refresh.
  final Uri? tokenEndpoint;

  /// The OAuth client the token was issued to.
  final McpOAuthClient? client;

  /// The resource indicator (RFC 8707) the token was requested for.
  final String? resource;

  /// How the client authenticates at [tokenEndpoint]
  /// (`none`, `client_secret_basic` or `client_secret_post`).
  final String? authMethod;

  /// Whether [refresh] can renew it.
  bool get refreshable =>
      refreshToken != null && tokenEndpoint != null && client != null;

  /// The remaining lifetime at [now] in whole seconds (0 once expired),
  /// or null when unknown. `authenticate` sends this as `expiresIn`: the
  /// protocol requires subtracting the time elapsed since the token
  /// response.
  int? remainingSeconds(DateTime now) {
    final lifetime = expiresIn;
    if (lifetime == null) return null;
    final left = lifetime - now.difference(obtainedAt).inSeconds;
    return left < 0 ? 0 : left;
  }

  /// Whether the token has expired at [now] (never, when the lifetime is
  /// unknown).
  bool isExpired(DateTime now) => remainingSeconds(now) == 0;

  /// Encodes everything, refresh token included, for secure storage.
  JsonMap toJson() => {
    'token': token,
    'obtainedAt': obtainedAt.toUtc().toIso8601String(),
    'expiresIn': ?expiresIn,
    'scopes': ?scopes,
    'refreshToken': ?refreshToken,
    'tokenEndpoint': ?tokenEndpoint?.toString(),
    'client': ?client?.toJson(),
    'resource': ?resource,
    'authMethod': ?authMethod,
  };
}

/// The scopes to request: the challenge's [requiredScopes] when given
/// (authoritative per AHP), else the resource's `scopes_supported`; null
/// (omit `scope`) when neither has any.
List<String>? scopesToRequest(
  List<String>? requiredScopes,
  ProtectedResourceMetadata resource,
) {
  final scopes = (requiredScopes?.isNotEmpty ?? false)
      ? requiredScopes!
      : resource.scopesSupported ?? const <String>[];
  return scopes.isEmpty ? null : scopes;
}

/// The authorization request URL ([metadata]'s authorization endpoint with
/// `response_type=code`, PKCE `S256`, [state], [scopes] and the RFC 8707
/// [resource] indicator).
Uri authorizationUrl({
  required AuthorizationServerMetadata metadata,
  required String clientId,
  required Uri redirectUri,
  required String codeChallenge,
  required String state,
  required String resource,
  List<String>? scopes,
}) {
  final endpoint = metadata.authorizationEndpoint;
  return endpoint.replace(
    queryParameters: {
      ...endpoint.queryParameters,
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': '$redirectUri',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      'resource': resource,
      if (scopes != null) 'scope': scopes.join(' '),
    },
  );
}

/// The authorization code in the browser's [redirect], after checking
/// that it carries [state]. Throws [OAuthException] for an error response
/// (`access_denied` when the user refused) or a state mismatch.
String authorizationCodeFrom(Uri redirect, {required String state}) {
  final params = redirect.queryParameters;
  if (params['state'] != state) {
    throw const OAuthException(
      'state_mismatch',
      'the redirect does not belong to this sign-in',
    );
  }
  if (params['error'] case final error?) {
    throw OAuthException(error, params['error_description']);
  }
  return params['code'] ??
      (throw const OAuthException('invalid_request', 'no code'));
}

/// Decodes a token response (RFC 6749 §5.1) received at [now]. Without a
/// `scope` the granted scopes are the [requested] ones (§3.3); a refresh
/// response without `refresh_token` keeps [previousRefreshToken].
ResourceToken tokenFromResponse(
  JsonMap json, {
  required DateTime now,
  List<String>? requested,
  Uri? tokenEndpoint,
  McpOAuthClient? client,
  String? resource,
  String? authMethod,
  String? previousRefreshToken,
}) {
  final token = json['access_token'];
  if (token is! String || token.isEmpty) {
    throw const OAuthException('invalid_response', 'no access_token');
  }
  final expiresIn = switch (json['expires_in']) {
    final num n when n > 0 => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };
  final scope = json['scope'];
  return ResourceToken(
    token: token,
    obtainedAt: now,
    expiresIn: expiresIn,
    scopes: scope is String
        ? scope.split(' ').where((s) => s.isNotEmpty).toList()
        : requested,
    refreshToken: json['refresh_token'] as String? ?? previousRefreshToken,
    tokenEndpoint: tokenEndpoint,
    client: client,
    resource: resource,
    authMethod: authMethod,
  );
}

/// How a client with [client]'s credentials authenticates at a token
/// endpoint that supports [supported]: `none` for a public client,
/// otherwise `client_secret_basic` (the RFC 8414 default) unless only
/// `client_secret_post` is offered.
String tokenEndpointAuthMethod(McpOAuthClient client, List<String>? supported) {
  if (client.clientSecret == null) return 'none';
  final methods = supported ?? const ['client_secret_basic'];
  return methods.contains('client_secret_basic') ||
          !methods.contains('client_secret_post')
      ? 'client_secret_basic'
      : 'client_secret_post';
}

/// Receives the browser's redirect back to the app after sign-in.
abstract interface class RedirectReceiver {
  /// The `redirect_uri` to register and send.
  Uri get redirectUri;

  /// Completes with the first redirect that arrives.
  Future<Uri> get redirect;

  /// Stops listening.
  Future<void> close();
}

/// The HTTP side of OAuth: discovery, registration and the token
/// endpoint.
final class OAuthHttp {
  /// Creates an [OAuthHttp] on [client] (a new `http.Client` by default).
  OAuthHttp([http.Client? client]) : _http = client ?? http.Client();

  final http.Client _http;

  /// Closes the HTTP client.
  void close() => _http.close();

  /// Fetches the metadata of the authorization server [issuer], trying
  /// each of [authorizationServerMetadataUris] in turn.
  Future<AuthorizationServerMetadata> discover(Uri issuer) async {
    _requireSecure(issuer);
    for (final uri in authorizationServerMetadataUris(issuer)) {
      final response = await _http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) continue;
      final metadata = AuthorizationServerMetadata.fromJson(
        jsonDecode(response.body) as JsonMap,
      );
      _requireSecure(metadata.authorizationEndpoint);
      _requireSecure(metadata.tokenEndpoint);
      return metadata;
    }
    throw OAuthException(
      'invalid_metadata',
      'no authorization server metadata at $issuer',
    );
  }

  /// Registers a public client for [redirectUri] (RFC 7591) and returns
  /// its credentials.
  Future<McpOAuthClient> register(
    Uri endpoint, {
    required Uri redirectUri,
    required String clientName,
    List<String>? scopes,
  }) async {
    _requireSecure(endpoint);
    final response = await _http.post(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'client_name': clientName,
        'redirect_uris': ['$redirectUri'],
        'grant_types': ['authorization_code', 'refresh_token'],
        'response_types': ['code'],
        'token_endpoint_auth_method': 'none',
        'scope': ?scopes?.join(' '),
      }),
    );
    final json = _jsonOrError(response, ok: const {200, 201});
    final id = json['client_id'];
    if (id is! String) {
      throw const OAuthException('invalid_client_metadata', 'no client_id');
    }
    return McpOAuthClient(
      clientId: id,
      clientSecret: json['client_secret'] as String?,
    );
  }

  /// Exchanges [code] for a token (with the PKCE [verifier] and the
  /// [resource] indicator).
  Future<ResourceToken> exchangeCode({
    required AuthorizationServerMetadata metadata,
    required McpOAuthClient client,
    required String code,
    required String verifier,
    required Uri redirectUri,
    required String resource,
    List<String>? scopes,
    DateTime Function() now = DateTime.now,
  }) async {
    final method = tokenEndpointAuthMethod(
      client,
      metadata.tokenEndpointAuthMethodsSupported,
    );
    final json = await _tokenRequest(metadata.tokenEndpoint, client, method, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': '$redirectUri',
      'code_verifier': verifier,
      'resource': resource,
    });
    return tokenFromResponse(
      json,
      now: now(),
      requested: scopes,
      tokenEndpoint: metadata.tokenEndpoint,
      client: client,
      resource: resource,
      authMethod: method,
    );
  }

  /// Renews [token] with its refresh token. Throws [OAuthException]
  /// (`invalid_grant` when the refresh token is no longer valid).
  Future<ResourceToken> refresh(
    ResourceToken token, {
    DateTime Function() now = DateTime.now,
  }) async {
    final client = token.client;
    final endpoint = token.tokenEndpoint;
    final refreshToken = token.refreshToken;
    if (client == null || endpoint == null || refreshToken == null) {
      throw const OAuthException('invalid_grant', 'no refresh token');
    }
    final method = token.authMethod ?? tokenEndpointAuthMethod(client, null);
    final json = await _tokenRequest(endpoint, client, method, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'resource': ?token.resource,
    });
    return tokenFromResponse(
      json,
      now: now(),
      requested: token.scopes,
      tokenEndpoint: endpoint,
      client: client,
      resource: token.resource,
      authMethod: method,
      previousRefreshToken: refreshToken,
    );
  }

  Future<JsonMap> _tokenRequest(
    Uri endpoint,
    McpOAuthClient client,
    String method,
    Map<String, String> body,
  ) async {
    _requireSecure(endpoint);
    final secret = client.clientSecret;
    final response = await _http.post(
      endpoint,
      headers: {
        'Accept': 'application/json',
        if (method == 'client_secret_basic' && secret != null)
          'Authorization':
              'Basic ${base64.encode(utf8.encode('${Uri.encodeQueryComponent(client.clientId)}:${Uri.encodeQueryComponent(secret)}'))}',
      },
      body: {
        ...body,
        if (method != 'client_secret_basic') 'client_id': client.clientId,
        if (method == 'client_secret_post' && secret != null)
          'client_secret': secret,
      },
    );
    return _jsonOrError(response, ok: const {200});
  }

  static JsonMap _jsonOrError(http.Response response, {required Set<int> ok}) {
    Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      body = null;
    }
    if (ok.contains(response.statusCode) && body is JsonMap) return body;
    if (body is JsonMap && body['error'] is String) {
      throw OAuthException(
        body['error']! as String,
        body['error_description'] as String?,
      );
    }
    throw OAuthException(
      'server_error',
      'HTTP ${response.statusCode} from ${response.request?.url}',
    );
  }

  static void _requireSecure(Uri endpoint) {
    if (insecureEndpointProblem(endpoint) case final problem?) {
      throw OAuthException('insecure_endpoint', problem);
    }
  }
}

/// Whether [resource] names an authorization server, so
/// [signInWithBrowser] can try it.
bool canSignInWithBrowser(ProtectedResourceMetadata resource) =>
    resource.authorizationServers?.isNotEmpty ?? false;

/// Signs in to [resource] in the browser and returns its token (AHP-060).
///
/// Discovers the first authorization server of the resource's metadata,
/// uses [oauthClient] when the host pre-registered one and otherwise
/// registers a client dynamically, sends the browser ([openBrowser]) to
/// the authorization endpoint with PKCE, the RFC 8707 `resource` and the
/// scopes from [scopesToRequest], waits up to [timeout] for [receiver] to
/// get the redirect, and exchanges the code. [receiver] is closed at the
/// end.
Future<ResourceToken> signInWithBrowser({
  required ProtectedResourceMetadata resource,
  required RedirectReceiver receiver,
  required Future<void> Function(Uri url) openBrowser,
  McpOAuthClient? oauthClient,
  List<String>? requiredScopes,
  OAuthHttp? oauth,
  String clientName = 'shireitou',
  Duration timeout = const Duration(minutes: 5),
  DateTime Function() now = DateTime.now,
  Random? random,
}) async {
  final http = oauth ?? OAuthHttp();
  try {
    final issuer = resource.authorizationServers?.firstOrNull;
    if (issuer == null) {
      throw OAuthException(
        'no_authorization_server',
        '${resource.resource} names no authorization server',
      );
    }
    final metadata = await http.discover(Uri.parse(issuer));
    if (!metadata.supportsS256) {
      throw OAuthException(
        'pkce_unsupported',
        '$issuer does not advertise PKCE (S256)',
      );
    }
    final scopes = scopesToRequest(requiredScopes, resource);
    final client =
        oauthClient ??
        switch (metadata.registrationEndpoint) {
          final endpoint? => await http.register(
            endpoint,
            redirectUri: receiver.redirectUri,
            clientName: clientName,
            scopes: scopes,
          ),
          null => throw OAuthException(
            'no_registration',
            '$issuer offers no client registration and the host gave no '
                'client',
          ),
        };
    final pkce = createPkce(random);
    final state = randomUrlSafe(16, random);
    await openBrowser(
      authorizationUrl(
        metadata: metadata,
        clientId: client.clientId,
        redirectUri: receiver.redirectUri,
        codeChallenge: pkce.challenge,
        state: state,
        resource: resource.resource,
        scopes: scopes,
      ),
    );
    final redirect = await receiver.redirect.timeout(
      timeout,
      onTimeout: () => throw const OAuthException(
        'timeout',
        'the browser did not come back in time',
      ),
    );
    final code = authorizationCodeFrom(redirect, state: state);
    return await http.exchangeCode(
      metadata: metadata,
      client: client,
      code: code,
      verifier: pkce.verifier,
      redirectUri: receiver.redirectUri,
      resource: resource.resource,
      scopes: scopes,
      now: now,
    );
  } finally {
    await receiver.close();
    if (oauth == null) http.close();
  }
}
