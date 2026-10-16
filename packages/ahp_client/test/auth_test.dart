import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 16, 12);

  ResourceToken token({int? expiresIn, bool refreshable = true}) =>
      ResourceToken(
        token: 'at',
        obtainedAt: now,
        expiresIn: expiresIn,
        refreshToken: refreshable ? 'rt' : null,
        tokenEndpoint: refreshable ? Uri.parse('https://as/token') : null,
        client: refreshable ? const McpOAuthClient(clientId: 'c') : null,
      );

  group('refreshDelay', () {
    test('a minute before expiry for long-lived tokens', () {
      expect(
        refreshDelay(token(expiresIn: 3600), now),
        const Duration(minutes: 59),
      );
    });

    test('a fifth of the lifetime before expiry for short ones', () {
      expect(
        refreshDelay(token(expiresIn: 10), now),
        const Duration(seconds: 8),
      );
    });

    test('at once when already due, never without refresh or lifetime', () {
      expect(
        refreshDelay(token(expiresIn: 10), now.add(const Duration(hours: 1))),
        Duration.zero,
      );
      expect(refreshDelay(token(), now), isNull);
      expect(
        refreshDelay(token(expiresIn: 60, refreshable: false), now),
        isNull,
      );
    });
  });

  test('-32007 data lists the protected resources', () {
    final data = const AuthRequiredErrorData(
      resources: [
        ProtectedResourceMetadata(resource: 'https://r', resourceName: 'R'),
      ],
    ).toJson();
    expect(authRequiredResources(data).single.resource, 'https://r');
    expect(authRequiredResources(null), isEmpty);
    expect(authRequiredResources({'resources': 'nope'}), isEmpty);
    expect(
      describeRpcError(AhpErrorCodes.authRequired, 'Unauthorized', data),
      'Sign-in required: R',
    );
  });

  test('agents list the required resources not signed in', () {
    const root = RootState(
      agents: [
        AgentInfo(
          provider: 'a',
          displayName: 'A',
          description: '',
          models: [],
          protectedResources: [
            ProtectedResourceMetadata(resource: 'https://required'),
            ProtectedResourceMetadata(
              resource: 'https://optional',
              required: false,
            ),
            ProtectedResourceMetadata(resource: 'https://held'),
          ],
        ),
        AgentInfo(provider: 'b', displayName: 'B', description: '', models: []),
      ],
    );
    expect(
      [
        for (final s in missingAgentSignIns(root, {'https://held'}))
          s.resource.resource,
      ],
      ['https://required'],
    );
    expect(missingAgentSignIns(null, {}), isEmpty);
  });

  test('a challenge from an MCP requirement keeps its client and scopes', () {
    final challenge = AuthChallenge.fromRequirement(
      const McpAuthRequirement(
        reason: McpAuthRequiredReason.expired,
        resource: ProtectedResourceMetadata(resource: 'https://r'),
        oauthClient: McpOAuthClient(clientId: 'c'),
        requiredScopes: ['s'],
      ),
    );
    expect(challenge.expired, isTrue);
    expect(challenge.oauthClient?.clientId, 'c');
    expect(challenge.requiredScopes, ['s']);
    expect(challenge.name, 'https://r');
  });
}
