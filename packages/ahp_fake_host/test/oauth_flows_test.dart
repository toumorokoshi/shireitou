/// The OAuth sign-in (AHP-060) and re-authentication (AHP-061) of
/// [HostAuthenticator] against the fake host and its fake authorization
/// server, over real loopback HTTP and WebSocket. The browser is played by
/// fetching the authorization URL and following its redirect to the
/// loopback receiver.
library;

import 'dart:async';

import 'package:ahp_client/ahp_client.dart';
import 'package:ahp_fake_host/ahp_fake_host.dart';
import 'package:http/http.dart' as http;
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';

const _timeout = Duration(seconds: 10);

/// The test's browser: loads [url]; the fake server approves at once and
/// redirects to the loopback receiver, which `http` follows.
Future<void> _browser(Uri url) async {
  await http.get(url);
}

/// Signs in to [challenge] in the "browser".
Future<ResourceToken> _browserSignIn(AuthChallenge challenge) async =>
    signInWithBrowser(
      resource: challenge.resource,
      oauthClient: challenge.oauthClient,
      requiredScopes: challenge.requiredScopes,
      receiver: await LoopbackRedirectReceiver.start(),
      openBrowser: _browser,
    );

void main() {
  late FakeAhpHost host;
  late AhpClient client;
  late HostAuthenticator auth;
  late String chat;
  late List<AuthChallenge> prompts;
  late Future<ResourceToken?> Function(AuthChallenge) answer;

  Future<void> connect({
    Duration tokenLifetime = const Duration(hours: 1),
    TokenStore? store,
  }) async {
    host = FakeAhpHost(
      stepDelay: const Duration(milliseconds: 5),
      tokenLifetime: tokenLifetime,
    );
    final url = await host.start();
    client = AhpClient(uri: url, pingInterval: Duration.zero);
    prompts = [];
    answer = _browserSignIn;
    auth = HostAuthenticator(
      client: client,
      store: store,
      interactive: (challenge) {
        prompts.add(challenge);
        return answer(challenge);
      },
    );
    await auth.start();
    await client.connect();
    expect(client.state.status, ConnectionStatus.connected);
    chat = (await client.openSession(seededSession))!;
  }

  tearDown(() async {
    await auth.close();
    await client.close();
    await host.close();
  });

  ChatState chatState() => client.state.chatChannels[chat]!.state;

  Future<void> until(bool Function(HostState state) test) async {
    if (test(client.state)) return;
    await client.states.firstWhere(test).timeout(_timeout);
  }

  void send(String text) => client.dispatch(
    chat,
    ChatTurnStartedAction(
      turnId: 'turn-$text-${DateTime.now().microsecondsSinceEpoch}',
      startedAt: DateTime.now().toUtc().toIso8601String(),
      message: userMessage(text),
    ).toJson(),
  );

  List<ResponsePart> parts() => [
    ...?chatState().activeTurn?.responseParts,
    if (chatState().activeTurn == null) ...chatState().turns.last.responseParts,
  ];

  String replies() => [
    for (final p in parts())
      if (p is MarkdownResponsePart) p.content,
  ].join('\n');

  Future<void> turnDone() => until(
    (_) => chatState().activeTurn == null && chatState().turns.isNotEmpty,
  );

  Iterable<JsonMap> pushed([String resource = docsResource]) => [
    for (final r in host.received)
      if (r.action['type'] == '#authenticate' &&
          r.action['resource'] == resource)
        r.action,
  ];

  Future<ToolCallAuthRequiredState> waitingForSignIn() async {
    send('auth');
    await until(
      (_) => parts().whereType<ToolCallResponsePart>().any(
        (p) => p.toolCall is ToolCallAuthRequiredState,
      ),
    );
    return parts().whereType<ToolCallResponsePart>().single.toolCall
        as ToolCallAuthRequiredState;
  }

  group('sign-in in the browser (AHP-060)', () {
    test('registers a client, authorizes with PKCE, exchanges the code and '
        'resumes the tool call', () async {
      await connect();
      final call = await waitingForSignIn();
      expect(call.auth.resource.authorizationServers, [
        '${host.oauthServer.issuer}',
      ]);
      expect(
        await auth.signIn(AuthChallenge.fromRequirement(call.auth)),
        isTrue,
      );
      await turnDone();
      expect(replies(), contains('Signed in. I found 2 pages.'));
      final push = pushed().single;
      expect(push['token'], startsWith('at-'));
      expect(push['scopes'], [docsScope]);
      expect(push['expiresIn'], inInclusiveRange(3590, 3600));
      expect(host.oauthServer.log, [
        startsWith('register client-'),
        startsWith('authorize client-'),
        startsWith('token client-'),
      ]);
      expect(auth.signedIn, {docsResource});
    });

    test('uses a host-provided client instead of registering', () async {
      await connect();
      final token = await signInWithBrowser(
        resource: docsMetadata(host.oauthServer.issuer),
        oauthClient: const McpOAuthClient(
          clientId: preregisteredClientId,
          clientSecret: preregisteredClientSecret,
        ),
        receiver: await LoopbackRedirectReceiver.start(),
        openBrowser: _browser,
      );
      expect(host.oauthServer.log, [
        'authorize $preregisteredClientId',
        'token $preregisteredClientId',
      ]);
      expect(token.authMethod, 'client_secret_basic');
      expect(host.oauthServer.accepts(token.token, docsResource), isTrue);
    });

    test('a refusal in the browser is reported', () async {
      await connect();
      host.oauthServer.denyNext = true;
      await expectLater(
        _browserSignIn(
          AuthChallenge(resource: docsMetadata(host.oauthServer.issuer)),
        ),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.error,
            'error',
            'access_denied',
          ),
        ),
      );
    });

    test('the server checks the PKCE verifier', () async {
      await connect();
      final oauth = OAuthHttp();
      addTearDown(oauth.close);
      final metadata = await oauth.discover(host.oauthServer.issuer);
      final receiver = await LoopbackRedirectReceiver.start();
      addTearDown(receiver.close);
      final client = await oauth.register(
        metadata.registrationEndpoint!,
        redirectUri: receiver.redirectUri,
        clientName: 'test',
      );
      final pkce = createPkce();
      await _browser(
        authorizationUrl(
          metadata: metadata,
          clientId: client.clientId,
          redirectUri: receiver.redirectUri,
          codeChallenge: pkce.challenge,
          state: 'st',
          resource: docsResource,
        ),
      );
      final code = authorizationCodeFrom(await receiver.redirect, state: 'st');
      await expectLater(
        oauth.exchangeCode(
          metadata: metadata,
          client: client,
          code: code,
          verifier: createPkce().verifier,
          redirectUri: receiver.redirectUri,
          resource: docsResource,
        ),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.error,
            'error',
            'invalid_grant',
          ),
        ),
      );
    });

    test('the host refuses a token it did not issue', () async {
      await connect();
      await expectLater(
        client.authenticate(resource: docsResource, token: 'forged'),
        throwsA(
          isA<RpcException>().having(
            (e) => e.code,
            'code',
            AhpErrorCodes.authRequired,
          ),
        ),
      );
    });

    test('a pasted token still works', () async {
      await connect();
      answer = (_) async =>
          ResourceToken(token: fakePersonalToken, obtainedAt: DateTime.now());
      final call = await waitingForSignIn();
      await auth.signIn(AuthChallenge.fromRequirement(call.auth));
      await turnDone();
      expect(replies(), contains('Signed in.'));
      expect(pushed().single, isNot(contains('expiresIn')));
    });
  });

  group('re-authentication (AHP-061)', () {
    test('-32007 from createSession signs in, then retries', () async {
      await connect();
      final session = await client.createSession(
        provider: securedProvider,
        workingDirectories: ['file:///workspace'],
      );
      expect(client.state.sessions.keys, contains(session));
      expect(prompts.single.resource.resource, agentResource);
      expect(pushed(agentResource), hasLength(1));
    });

    test('-32007 reaches the caller when the user cancels', () async {
      await connect();
      answer = (_) async => null;
      await expectLater(
        client.createSession(provider: securedProvider),
        throwsA(
          isA<RpcException>().having(
            (e) => e.code,
            'code',
            AhpErrorCodes.authRequired,
          ),
        ),
      );
    });

    test('auth/required (expired) refreshes without asking', () async {
      await connect();
      final call = await waitingForSignIn();
      await auth.signIn(AuthChallenge.fromRequirement(call.auth));
      await turnDone();
      final first = pushed().single['token'];
      send('expire');
      await turnDone();
      expect(replies(), contains('Signed in to Example Docs again.'));
      expect(prompts, hasLength(1));
      expect(host.oauthServer.log.last, startsWith('refresh client-'));
      expect(pushed().last['token'], isNot(first));
    });

    test('auth/required (expired) asks again for a pasted token', () async {
      await connect();
      answer = (_) async =>
          ResourceToken(token: fakePersonalToken, obtainedAt: DateTime.now());
      final call = await waitingForSignIn();
      await auth.signIn(AuthChallenge.fromRequirement(call.auth));
      await turnDone();
      answer = _browserSignIn;
      send('expire');
      await turnDone();
      expect(replies(), contains('Signed in to Example Docs again.'));
      expect(prompts, hasLength(2));
      expect(prompts.last.expired, isTrue);
    });

    test('a token is refreshed before it expires', () async {
      await connect(tokenLifetime: const Duration(seconds: 2));
      final call = await waitingForSignIn();
      await auth.signIn(AuthChallenge.fromRequirement(call.auth));
      await turnDone();
      final refreshed = await host.actions
          .where((r) => r.action['type'] == '#authenticate')
          .first
          .timeout(_timeout);
      expect(refreshed.action['token'], isNot(pushed().first['token']));
      expect(refreshed.action['expiresIn'], inInclusiveRange(1, 2));
      expect(host.oauthServer.log.last, startsWith('refresh client-'));
    });

    test('saved tokens are pushed when the client connects', () async {
      final store = MemoryTokenStore();
      await connect(store: store);
      final call = await waitingForSignIn();
      await auth.signIn(AuthChallenge.fromRequirement(call.auth));
      await turnDone();
      final saved = (await store.load())[docsResource]!;
      // A restart: a new client and authenticator with the same store.
      final second = AhpClient(uri: client.uri, pingInterval: Duration.zero);
      final secondAuth = HostAuthenticator(
        client: second,
        store: store,
        interactive: (_) async => null,
      );
      await secondAuth.start();
      await second.connect();
      await host.actions
          .where(
            (r) =>
                r.action['type'] == '#authenticate' &&
                r.action['clientId'] == second.clientId,
          )
          .first
          .timeout(_timeout);
      expect(pushed().last['token'], saved.token);
      await secondAuth.close();
      await second.close();
    });
  });
}
