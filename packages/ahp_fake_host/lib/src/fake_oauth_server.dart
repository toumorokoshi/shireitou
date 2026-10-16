/// A minimal OAuth 2.1 authorization server for tests, in this process:
/// RFC 8414 metadata, dynamic client registration (RFC 7591), the
/// authorization code flow with PKCE (`S256` only, verified), resource
/// indicators (RFC 8707) and refresh token rotation. The authorization
/// endpoint approves at once (or refuses with `access_denied` while
/// [FakeOAuthServer.denyNext] is set), so a test plays the browser by
/// fetching the authorization URL and following the redirect.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A client the server knows: registered dynamically or up front.
typedef FakeOAuthClient = ({
  String clientId,
  String? clientSecret,
  List<String> redirectUris,
});

typedef _Code = ({
  String clientId,
  String redirectUri,
  String challenge,
  String? resource,
  List<String> scopes,
});

typedef _Grant = ({
  String clientId,
  String? resource,
  List<String> scopes,
  DateTime expires,
});

/// The pre-registered confidential client [FakeOAuthServer] always knows,
/// for tests of a host-provided `McpOAuthClient`.
const preregisteredClientId = 'fake-preregistered';

/// The secret of [preregisteredClientId].
const preregisteredClientSecret = 'fake-secret';

/// The scopes the fake authorization server offers.
const fakeOAuthScopes = ['docs.read', 'docs.search', 'agent'];

/// An in-process OAuth authorization server. [start] it, put [issuer] in
/// a resource's `authorization_servers`, and check pushed tokens with
/// [accepts].
class FakeOAuthServer {
  /// Creates a server whose access tokens live for [tokenLifetime].
  FakeOAuthServer({this.tokenLifetime = const Duration(hours: 1)});

  /// How long access tokens are valid (`expires_in`).
  Duration tokenLifetime;

  /// While true, the authorization endpoint refuses (`access_denied`)
  /// instead of approving.
  bool denyNext = false;

  HttpServer? _server;
  final _random = Random.secure();
  final _clients = <String, FakeOAuthClient>{
    preregisteredClientId: (
      clientId: preregisteredClientId,
      clientSecret: preregisteredClientSecret,
      redirectUris: const [],
    ),
  };
  final _codes = <String, _Code>{};
  final _access = <String, _Grant>{};
  final _refresh = <String, _Grant>{};
  final _log = <String>[];

  /// The issuer URL (`http://127.0.0.1:<port>`); throws before [start].
  Uri get issuer => _issuer ?? (throw StateError('not started'));
  Uri? _issuer;

  /// What happened, in order: `register <client>`, `authorize <client>`,
  /// `deny <client>`, `token <client>`, `refresh <client>`, and
  /// `reject <reason>` for refused requests.
  List<String> get log => List.unmodifiable(_log);

  /// The dynamically registered clients.
  List<FakeOAuthClient> get registeredClients => [
    for (final c in _clients.values)
      if (c.clientId != preregisteredClientId) c,
  ];

  /// Listens on a random loopback port and returns [issuer].
  Future<Uri> start({String address = '127.0.0.1'}) async {
    final server = await HttpServer.bind(address, 0);
    _server = server;
    server.listen(_onRequest);
    return _issuer = Uri(scheme: 'http', host: address, port: server.port);
  }

  /// Stops listening.
  Future<void> close() async => _server?.close(force: true);

  /// Whether [token] is an unexpired access token for [resource].
  bool accepts(String token, String resource) {
    final grant = _access[token];
    return grant != null &&
        grant.resource == resource &&
        DateTime.now().isBefore(grant.expires);
  }

  /// The scopes [token] grants, if it is one of this server's.
  List<String>? scopesOf(String token) => _access[token]?.scopes;

  /// Expires [token] at once (the host then reports `auth/required`).
  void expire(String token) {
    final grant = _access[token];
    if (grant == null) return;
    _access[token] = (
      clientId: grant.clientId,
      resource: grant.resource,
      scopes: grant.scopes,
      expires: DateTime.now().subtract(const Duration(seconds: 1)),
    );
  }

  String _secret() => base64Url
      .encode([for (var i = 0; i < 24; i++) _random.nextInt(256)])
      .replaceAll('=', '');

  Future<void> _onRequest(HttpRequest request) async {
    final path = request.uri.path;
    // The web app calls the metadata, registration and token endpoints
    // from the browser.
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    try {
      switch ((request.method, path)) {
        case ('OPTIONS', _):
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        case ('GET', '/.well-known/oauth-authorization-server'):
          await _json(request.response, 200, _metadata());
        case ('POST', '/register'):
          await _register(request);
        case ('GET', '/authorize'):
          await _authorize(request);
        case ('POST', '/token'):
          await _token(request);
        default:
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
      }
    } on Object catch (error) {
      _log.add('reject $error');
      await _json(request.response, 500, {'error': 'server_error'});
    }
  }

  Map<String, Object?> _metadata() => {
    'issuer': '$issuer',
    'authorization_endpoint': '${issuer.replace(path: '/authorize')}',
    'token_endpoint': '${issuer.replace(path: '/token')}',
    'registration_endpoint': '${issuer.replace(path: '/register')}',
    'response_types_supported': ['code'],
    'grant_types_supported': ['authorization_code', 'refresh_token'],
    'code_challenge_methods_supported': ['S256'],
    'token_endpoint_auth_methods_supported': [
      'none',
      'client_secret_basic',
      'client_secret_post',
    ],
    'scopes_supported': fakeOAuthScopes,
  };

  Future<void> _register(HttpRequest request) async {
    final body = jsonDecode(await utf8.decodeStream(request));
    final uris = body is Map ? body['redirect_uris'] : null;
    if (uris is! List || uris.isEmpty) {
      return _error(request, 'invalid_redirect_uri', 'redirect_uris needed');
    }
    final id = 'client-${_secret().substring(0, 8)}';
    _clients[id] = (
      clientId: id,
      clientSecret: null,
      redirectUris: [for (final u in uris) '$u'],
    );
    _log.add('register $id');
    await _json(request.response, 201, {
      'client_id': id,
      'client_id_issued_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'redirect_uris': uris,
      'token_endpoint_auth_method': 'none',
      'grant_types': ['authorization_code', 'refresh_token'],
      'response_types': ['code'],
    });
  }

  /// Loopback redirect URIs match on everything but the port (RFC 8252
  /// §7.3); the pre-registered client takes any loopback redirect.
  bool _redirectAllowed(FakeOAuthClient client, String redirect) {
    final uri = Uri.tryParse(redirect);
    if (uri == null) return false;
    final loopback = uri.scheme == 'http' && uri.host == '127.0.0.1';
    if (client.clientId == preregisteredClientId) return loopback;
    return client.redirectUris.any((r) {
      final registered = Uri.parse(r);
      return r == redirect ||
          (loopback &&
              registered.host == uri.host &&
              registered.path == uri.path);
    });
  }

  Future<void> _authorize(HttpRequest request) async {
    final q = request.uri.queryParameters;
    final client = _clients[q['client_id']];
    final redirect = q['redirect_uri'] ?? '';
    if (client == null || !_redirectAllowed(client, redirect)) {
      // Never redirect to an unverified URI.
      _log.add('reject unknown client or redirect');
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('unknown client or redirect_uri');
      await request.response.close();
      return;
    }
    Future<void> back(Map<String, String> params) async {
      final target = Uri.parse(redirect);
      await request.response.redirect(
        target.replace(
          queryParameters: {
            ...target.queryParameters,
            ...params,
            'state': ?q['state'],
          },
        ),
        status: HttpStatus.found,
      );
    }

    final problem = q['response_type'] != 'code'
        ? 'unsupported_response_type'
        : q['code_challenge_method'] != 'S256' ||
              (q['code_challenge'] ?? '').length < 43
        ? 'invalid_request'
        : null;
    if (problem != null) {
      _log.add('reject $problem');
      return back({'error': problem});
    }
    if (denyNext) {
      denyNext = false;
      _log.add('deny ${client.clientId}');
      return back({
        'error': 'access_denied',
        'error_description': 'The user refused.',
      });
    }
    final code = _secret();
    _codes[code] = (
      clientId: client.clientId,
      redirectUri: redirect,
      challenge: q['code_challenge']!,
      resource: q['resource'],
      scopes: (q['scope'] ?? '').split(' ').where((s) => s.isNotEmpty).toList(),
    );
    _log.add('authorize ${client.clientId}');
    await back({'code': code});
  }

  /// The client authenticated by [request] (Basic header, or `client_id`
  /// with `client_secret` in the body for confidential clients), or null.
  FakeOAuthClient? _authenticate(
    HttpRequest request,
    Map<String, String> form,
  ) {
    final header = request.headers.value(HttpHeaders.authorizationHeader);
    if (header != null && header.startsWith('Basic ')) {
      final pair = utf8.decode(base64.decode(header.substring(6)));
      final colon = pair.indexOf(':');
      final id = Uri.decodeQueryComponent(pair.substring(0, colon));
      final secret = Uri.decodeQueryComponent(pair.substring(colon + 1));
      final client = _clients[id];
      return client?.clientSecret == secret ? client : null;
    }
    final client = _clients[form['client_id']];
    if (client == null) return null;
    if (client.clientSecret == null) return client;
    return client.clientSecret == form['client_secret'] ? client : null;
  }

  Future<void> _token(HttpRequest request) async {
    final form = Uri.splitQueryString(await utf8.decodeStream(request));
    final client = _authenticate(request, form);
    if (client == null) {
      return _error(request, 'invalid_client', 'unknown client', 401);
    }
    switch (form['grant_type']) {
      case 'authorization_code':
        final code = _codes.remove(form['code']);
        if (code == null || code.clientId != client.clientId) {
          return _error(request, 'invalid_grant', 'unknown code');
        }
        if (code.redirectUri != form['redirect_uri']) {
          return _error(request, 'invalid_grant', 'redirect_uri differs');
        }
        final verifier = form['code_verifier'] ?? '';
        final challenge = base64Url
            .encode(sha256.convert(ascii.encode(verifier)).bytes)
            .replaceAll('=', '');
        if (challenge != code.challenge) {
          return _error(request, 'invalid_grant', 'PKCE verification failed');
        }
        if (code.resource != null && form['resource'] != code.resource) {
          return _error(request, 'invalid_target', 'resource differs');
        }
        _log.add('token ${client.clientId}');
        await _issue(request, client.clientId, code.resource, code.scopes);
      case 'refresh_token':
        final grant = _refresh.remove(form['refresh_token']);
        if (grant == null || grant.clientId != client.clientId) {
          return _error(request, 'invalid_grant', 'unknown refresh token');
        }
        _log.add('refresh ${client.clientId}');
        await _issue(request, client.clientId, grant.resource, grant.scopes);
      default:
        return _error(request, 'unsupported_grant_type', form['grant_type']);
    }
  }

  Future<void> _issue(
    HttpRequest request,
    String clientId,
    String? resource,
    List<String> scopes,
  ) async {
    final access = 'at-${_secret()}';
    final refresh = 'rt-${_secret()}';
    final expires = DateTime.now().add(tokenLifetime);
    _access[access] = (
      clientId: clientId,
      resource: resource,
      scopes: scopes,
      expires: expires,
    );
    _refresh[refresh] = (
      clientId: clientId,
      resource: resource,
      scopes: scopes,
      expires: expires,
    );
    await _json(request.response, 200, {
      'access_token': access,
      'token_type': 'Bearer',
      'expires_in': tokenLifetime.inSeconds,
      'refresh_token': refresh,
      if (scopes.isNotEmpty) 'scope': scopes.join(' '),
    });
  }

  Future<void> _error(
    HttpRequest request,
    String error,
    String? description, [
    int status = 400,
  ]) async {
    _log.add('reject $error');
    await _json(request.response, status, {
      'error': error,
      'error_description': ?description,
    });
  }

  static Future<void> _json(
    HttpResponse response,
    int status,
    Map<String, Object?> body,
  ) async {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store')
      ..write(jsonEncode(body));
    await response.close();
  }
}
