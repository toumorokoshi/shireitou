import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  group('PKCE', () {
    test('the S256 challenge matches RFC 7636 appendix B', () {
      expect(
        pkceChallenge('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('a fresh verifier is 43 URL-safe characters with its challenge', () {
      final pkce = createPkce();
      expect(pkce.verifier, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(pkce.challenge, pkceChallenge(pkce.verifier));
      expect(createPkce().verifier, isNot(pkce.verifier));
    });
  });

  test('metadata URLs follow RFC 8414, then OpenID Connect discovery', () {
    expect(
      authorizationServerMetadataUris(Uri.parse('https://as.example.com')),
      [
        Uri.parse(
          'https://as.example.com/.well-known/oauth-authorization-server',
        ),
        Uri.parse('https://as.example.com/.well-known/openid-configuration'),
      ],
    );
    expect(
      authorizationServerMetadataUris(
        Uri.parse('https://as.example.com/tenant/'),
      ),
      [
        Uri.parse(
          'https://as.example.com/.well-known/oauth-authorization-server/tenant',
        ),
        Uri.parse(
          'https://as.example.com/.well-known/openid-configuration/tenant',
        ),
        Uri.parse(
          'https://as.example.com/tenant/.well-known/openid-configuration',
        ),
      ],
    );
  });

  test('endpoints must be HTTPS unless they are on loopback', () {
    expect(insecureEndpointProblem(Uri.parse('https://a.example')), isNull);
    expect(insecureEndpointProblem(Uri.parse('http://127.0.0.1:9/x')), isNull);
    expect(insecureEndpointProblem(Uri.parse('http://localhost/x')), isNull);
    expect(insecureEndpointProblem(Uri.parse('http://a.example')), isNotNull);
  });

  final metadata = AuthorizationServerMetadata(
    issuer: 'https://as.example.com',
    authorizationEndpoint: Uri.parse(
      'https://as.example.com/authorize?tenant=x',
    ),
    tokenEndpoint: Uri.parse('https://as.example.com/token'),
  );

  test('the authorization URL carries PKCE, state, scope and resource', () {
    final url = authorizationUrl(
      metadata: metadata,
      clientId: 'c1',
      redirectUri: Uri.parse('http://127.0.0.1:5000/callback'),
      codeChallenge: 'challenge',
      state: 's1',
      resource: 'https://mcp.example.com',
      scopes: ['a', 'b'],
    );
    expect(url.path, '/authorize');
    expect(url.queryParameters, {
      'tenant': 'x',
      'response_type': 'code',
      'client_id': 'c1',
      'redirect_uri': 'http://127.0.0.1:5000/callback',
      'code_challenge': 'challenge',
      'code_challenge_method': 'S256',
      'state': 's1',
      'resource': 'https://mcp.example.com',
      'scope': 'a b',
    });
  });

  group('authorizationCodeFrom', () {
    test('returns the code for the right state', () {
      expect(
        authorizationCodeFrom(
          Uri.parse('http://127.0.0.1/cb?code=abc&state=s1'),
          state: 's1',
        ),
        'abc',
      );
    });

    test('refuses another state', () {
      expect(
        () => authorizationCodeFrom(
          Uri.parse('http://127.0.0.1/cb?code=abc&state=evil'),
          state: 's1',
        ),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.error,
            'error',
            'state_mismatch',
          ),
        ),
      );
    });

    test('reports an error response', () {
      expect(
        () => authorizationCodeFrom(
          Uri.parse(
            'http://127.0.0.1/cb?error=access_denied&error_description=No&state=s1',
          ),
          state: 's1',
        ),
        throwsA(
          isA<OAuthException>()
              .having((e) => e.error, 'error', 'access_denied')
              .having((e) => e.description, 'description', 'No'),
        ),
      );
    });
  });

  test('metadata decoding requires the endpoints and reads PKCE support', () {
    final decoded = AuthorizationServerMetadata.fromJson({
      'issuer': 'https://as',
      'authorization_endpoint': 'https://as/authorize',
      'token_endpoint': 'https://as/token',
      'registration_endpoint': 'https://as/register',
      'code_challenge_methods_supported': ['plain', 'S256'],
    });
    expect(decoded.supportsS256, isTrue);
    expect(decoded.registrationEndpoint, Uri.parse('https://as/register'));
    expect(
      () => AuthorizationServerMetadata.fromJson({'issuer': 'x'}),
      throwsA(isA<OAuthException>()),
    );
  });

  group('tokens', () {
    final now = DateTime.utc(2026, 10, 16, 12);

    test('a token response keeps expiry, scopes and refresh token', () {
      final token = tokenFromResponse(
        {
          'access_token': 'at',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': 'rt',
          'scope': 'docs.read docs.search',
        },
        now: now,
        tokenEndpoint: Uri.parse('https://as/token'),
        client: const McpOAuthClient(clientId: 'c1'),
        resource: 'https://mcp.example.com',
      );
      expect(token.token, 'at');
      expect(token.scopes, ['docs.read', 'docs.search']);
      expect(token.refreshable, isTrue);
      expect(token.remainingSeconds(now), 3600);
      expect(
        token.remainingSeconds(now.add(const Duration(minutes: 10))),
        3000,
      );
      expect(token.isExpired(now.add(const Duration(hours: 2))), isTrue);
    });

    test('without scope the requested scopes are granted; a refresh '
        'without refresh_token keeps the old one', () {
      final token = tokenFromResponse(
        {'access_token': 'at2'},
        now: now,
        requested: ['x'],
        previousRefreshToken: 'rt',
      );
      expect(token.scopes, ['x']);
      expect(token.refreshToken, 'rt');
      expect(token.remainingSeconds(now), isNull);
      expect(token.isExpired(now.add(const Duration(days: 999))), isFalse);
    });

    test('a response without access_token is an error', () {
      expect(
        () => tokenFromResponse({'token_type': 'Bearer'}, now: now),
        throwsA(isA<OAuthException>()),
      );
    });

    test('round-trips through JSON for storage', () {
      final token = ResourceToken(
        token: 'at',
        obtainedAt: now,
        expiresIn: 60,
        scopes: const ['a'],
        refreshToken: 'rt',
        tokenEndpoint: Uri.parse('https://as/token'),
        client: const McpOAuthClient(clientId: 'c', clientSecret: 's'),
        resource: 'https://r',
        authMethod: 'client_secret_basic',
      );
      final back = ResourceToken.fromJson(token.toJson());
      expect(back.toJson(), token.toJson());
      expect(back.client?.clientSecret, 's');
    });
  });

  test('scopes: the challenge first, else the resource', () {
    const resource = ProtectedResourceMetadata(
      resource: 'https://r',
      scopesSupported: ['a', 'b'],
    );
    expect(scopesToRequest(['c'], resource), ['c']);
    expect(scopesToRequest(null, resource), ['a', 'b']);
    expect(
      scopesToRequest(null, const ProtectedResourceMetadata(resource: 'x')),
      isNull,
    );
  });

  test('client authentication at the token endpoint', () {
    const public = McpOAuthClient(clientId: 'c');
    const confidential = McpOAuthClient(clientId: 'c', clientSecret: 's');
    expect(tokenEndpointAuthMethod(public, null), 'none');
    expect(tokenEndpointAuthMethod(confidential, null), 'client_secret_basic');
    expect(
      tokenEndpointAuthMethod(confidential, ['client_secret_post']),
      'client_secret_post',
    );
  });
}
