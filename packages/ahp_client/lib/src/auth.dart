/// Keeps a host's protected resources signed in (AHP-060, AHP-061):
/// pushes tokens with `authenticate`, answers `auth/required` and
/// `-32007 AuthRequired`, refreshes tokens before they expire, and pushes
/// held tokens again after a reconnect.
///
/// The pure pieces are top-level functions; [HostAuthenticator] holds the
/// tokens and timers of one [AhpClient].
library;

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:logging/logging.dart';

import 'client.dart';
import 'host_state.dart';
import 'oauth.dart';
import 'protocol.dart';
import 'wire.dart';

final _log = Logger('ahp_client.auth');

/// What to sign in to: a protected resource, with the details an MCP
/// challenge adds (a pre-registered client, the scopes it needs, a hint).
final class AuthChallenge {
  /// Creates an [AuthChallenge].
  const AuthChallenge({
    required this.resource,
    this.oauthClient,
    this.requiredScopes,
    this.description,
    this.expired = false,
  });

  /// The challenge of an MCP server or tool call waiting for sign-in.
  factory AuthChallenge.fromRequirement(McpAuthRequirement auth) =>
      AuthChallenge(
        resource: auth.resource,
        oauthClient: auth.oauthClient,
        requiredScopes: auth.requiredScopes,
        description: auth.description,
        expired: auth.reason == McpAuthRequiredReason.expired,
      );

  /// The challenge of an MCP server in the `authRequired` state.
  factory AuthChallenge.fromServerState(McpServerAuthRequiredState state) =>
      AuthChallenge(
        resource: state.resource,
        oauthClient: state.oauthClient,
        requiredScopes: state.requiredScopes,
        description: state.description,
        expired: state.reason == McpAuthRequiredReason.expired,
      );

  /// The resource's RFC 9728 metadata.
  final ProtectedResourceMetadata resource;

  /// The client to use instead of dynamic registration.
  final McpOAuthClient? oauthClient;

  /// The scopes the challenge needs (authoritative when present).
  final List<String>? requiredScopes;

  /// A hint for the user, such as the OAuth `error_description`.
  final String? description;

  /// Whether a token the host had expired or was revoked.
  final bool expired;

  /// The resource's name for people: `resource_name`, else its URI.
  String get name => resource.resourceName ?? resource.resource;
}

/// Asks the user to sign in for a challenge (in the browser, or by pasting
/// a token); null when they cancel.
typedef InteractiveSignIn = Future<ResourceToken?> Function(
  AuthChallenge challenge,
);

/// Where a host's tokens are kept between runs, by resource.
abstract interface class TokenStore {
  /// The saved tokens.
  Future<Map<String, ResourceToken>> load();

  /// Replaces the saved tokens.
  Future<void> save(Map<String, ResourceToken> tokens);
}

/// A [TokenStore] that forgets everything when the app ends.
final class MemoryTokenStore implements TokenStore {
  Map<String, ResourceToken> _tokens = const {};

  @override
  Future<Map<String, ResourceToken>> load() async => _tokens;

  @override
  Future<void> save(Map<String, ResourceToken> tokens) async =>
      _tokens = Map.unmodifiable(tokens);
}

/// The protected resources in the `data` of a `-32007 AuthRequired` error
/// (`AuthRequiredErrorData`), or none when it carries none.
List<ProtectedResourceMetadata> authRequiredResources(Object? data) {
  if (data is! JsonMap) return const [];
  try {
    return AuthRequiredErrorData.fromJson(data).resources;
  } on Object {
    return const [];
  }
}

/// How long to wait before refreshing [token] at [now]: until
/// [maxMargin] (or a fifth of its lifetime, if shorter) before it expires.
/// Null when it cannot be refreshed or its lifetime is unknown.
Duration? refreshDelay(
  ResourceToken token,
  DateTime now, {
  Duration maxMargin = const Duration(seconds: 60),
}) {
  final lifetime = token.expiresIn;
  if (!token.refreshable || lifetime == null) return null;
  final expiry = token.obtainedAt.add(Duration(seconds: lifetime));
  final fifth = Duration(milliseconds: lifetime * 200);
  final margin = fifth < maxMargin ? fifth : maxMargin;
  final delay = expiry.subtract(margin).difference(now);
  return delay.isNegative ? Duration.zero : delay;
}

/// An agent's protected resource that needs a token this client does not
/// hold.
typedef AgentSignIn = ({AgentInfo agent, ProtectedResourceMetadata resource});

/// The protected resources of [root]'s agents that require a token
/// (`required` absent counts as true) and are not in [signedIn].
List<AgentSignIn> missingAgentSignIns(
  RootState? root,
  Set<String> signedIn,
) => [
  for (final agent in root?.agents ?? const <AgentInfo>[])
    for (final resource
        in agent.protectedResources ?? const <ProtectedResourceMetadata>[])
      if ((resource.required ?? true) && !signedIn.contains(resource.resource))
        (agent: agent, resource: resource),
];

/// Keeps one host's protected resources signed in.
///
/// [start] loads saved tokens, listens for `auth/required`, answers
/// `-32007` errors for [client] (it retries the command once a token is
/// pushed), and pushes the held tokens whenever the client (re)connects.
/// A token that can be refreshed is renewed shortly before it expires
/// and when the host reports it expired; otherwise [interactive] asks the
/// user. Tokens are never replayed after the host said they expired.
final class HostAuthenticator {
  /// Creates an authenticator for [client].
  HostAuthenticator({
    required this.client,
    required this.interactive,
    TokenStore? store,
    this.oauth,
    this.now = DateTime.now,
  }) : store = store ?? MemoryTokenStore();

  /// The client tokens are pushed through.
  final AhpClient client;

  /// Asks the user to sign in.
  final InteractiveSignIn interactive;

  /// Where tokens are kept between runs.
  final TokenStore store;

  /// The clock (replaced in tests).
  final DateTime Function() now;

  /// The HTTP client for refreshes; a short-lived one per refresh when
  /// null. Closed by [close].
  final OAuthHttp? oauth;

  final _tokens = <String, ResourceToken>{};
  final _timers = <String, Timer>{};
  final _renewing = <String, Future<bool>>{};
  final _changes = StreamController<Set<String>>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  var _connected = false;
  var _closed = false;

  /// The resources this client holds a token for.
  Set<String> get signedIn => Set.unmodifiable(_tokens.keys);

  /// [signedIn] after every change.
  Stream<Set<String>> get changes => _changes.stream;

  /// The token held for [resource].
  ResourceToken? tokenFor(String resource) => _tokens[resource];

  /// Loads saved tokens and starts listening to [client]. Call before
  /// [AhpClient.connect] so the first connection pushes them.
  Future<void> start() async {
    try {
      _tokens.addAll(await store.load());
    } on Object catch (error) {
      _log.warning('could not load saved tokens: $error');
    }
    _emit();
    client.onAuthRequired = _onAuthError;
    _subscriptions
      ..add(client.authRequired.listen(_onAuthRequired))
      ..add(
        client.states.listen((state) {
          final connected = state.status == ConnectionStatus.connected;
          if (connected && !_connected) unawaited(_pushAll());
          _connected = connected;
        }),
      );
    if (client.state.status == ConnectionStatus.connected) {
      _connected = true;
      await _pushAll();
    }
  }

  /// Stops listening and cancels refresh timers. Saved tokens stay saved.
  Future<void> close() async {
    _closed = true;
    if (identical(client.onAuthRequired, _onAuthError)) {
      client.onAuthRequired = null;
    }
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    oauth?.close();
    await _changes.close();
  }

  /// Asks the user to sign in for [challenge] and pushes the token.
  /// False when they cancel; throws when the host refuses the token.
  Future<bool> signIn(AuthChallenge challenge) async {
    final token = await interactive(challenge);
    if (token == null) return false;
    await push(challenge.resource.resource, token);
    return true;
  }

  /// Pushes [token] for [resource] (`authenticate` with its remaining
  /// lifetime and scopes), keeps it, and schedules its refresh. Throws the
  /// host's error when it refuses the token.
  Future<void> push(String resource, ResourceToken token) async {
    await client.authenticate(
      resource: resource,
      token: token.token,
      expiresIn: token.remainingSeconds(now()),
      scopes: token.scopes,
    );
    _keep(resource, token);
  }

  /// Revokes [resource]'s token on the host (an empty `authenticate`)
  /// and forgets it.
  Future<void> signOut(String resource) async {
    _forget(resource);
    await client.authenticate(resource: resource, token: '');
  }

  void _keep(String resource, ResourceToken token) {
    _tokens[resource] = token;
    _schedule(resource, token);
    unawaited(_save());
    _emit();
  }

  void _forget(String resource) {
    _timers.remove(resource)?.cancel();
    if (_tokens.remove(resource) == null) return;
    unawaited(_save());
    _emit();
  }

  Future<void> _save() async {
    try {
      await store.save(Map.of(_tokens));
    } on Object catch (error) {
      _log.warning('could not save tokens: $error');
    }
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(signedIn);
  }

  void _schedule(String resource, ResourceToken token) {
    _timers.remove(resource)?.cancel();
    final delay = refreshDelay(token, now());
    if (delay == null || _closed) return;
    _timers[resource] = Timer(delay, () {
      _timers.remove(resource);
      if (!identical(_tokens[resource], token)) return;
      unawaited(_refreshAndPush(resource, token));
    });
  }

  /// Refreshes [token] and pushes the new one; false (and the token is
  /// forgotten) when either fails.
  Future<bool> _refreshAndPush(String resource, ResourceToken token) async {
    final http = oauth ?? OAuthHttp();
    try {
      final next = await http.refresh(token, now: now);
      await push(resource, next);
      _log.fine('refreshed the token for $resource');
      return true;
    } on Object catch (error) {
      _log.info('could not refresh the token for $resource: $error');
      _forget(resource);
      return false;
    } finally {
      if (oauth == null) http.close();
    }
  }

  /// Gets a new token for [challenge]: a refresh when possible, otherwise
  /// the user. Concurrent renewals of one resource share the first.
  Future<bool> _renew(AuthChallenge challenge) {
    final resource = challenge.resource.resource;
    return _renewing[resource] ??= () async {
      try {
        final held = _tokens[resource];
        if (held != null && held.refreshable) {
          if (await _refreshAndPush(resource, held)) return true;
        } else {
          _forget(resource);
        }
        return await signIn(challenge);
      } on Object catch (error) {
        _log.warning('sign-in to $resource failed: $error');
        return false;
      } finally {
        unawaited(_renewing.remove(resource));
      }
    }();
  }

  /// `-32007` from a command: renew every listed resource, then let the
  /// client retry.
  Future<bool> _onAuthError(List<ProtectedResourceMetadata> resources) async {
    for (final resource in resources) {
      if (!await _renew(AuthChallenge(resource: resource))) return false;
    }
    return true;
  }

  Future<void> _onAuthRequired(AuthRequiredParams params) async {
    final resource = params.resource.resource;
    final expired = params.reason == AuthRequiredReason.expired;
    final held = _tokens[resource];
    // A token the host never saw expire may be pushed again (it may have
    // forgotten it); an expired one must not be replayed.
    if (!expired && held != null && !held.isExpired(now())) {
      try {
        await push(resource, held);
        return;
      } on Object catch (error) {
        _log.info('the host refused the held token for $resource: $error');
      }
    }
    await _renew(AuthChallenge(resource: params.resource, expired: expired));
  }

  /// Pushes every held token after a (re)connect: the host's sign-ins
  /// belong to a connection. Expired ones are refreshed or dropped.
  Future<void> _pushAll() async {
    for (final MapEntry(key: resource, value: token)
        in _tokens.entries.toList()) {
      if (token.isExpired(now())) {
        if (!token.refreshable || !await _refreshAndPush(resource, token)) {
          _forget(resource);
        }
        continue;
      }
      try {
        await push(resource, token);
      } on RpcException catch (error) {
        _log.info('the host refused the saved token for $resource: $error');
        if (error.code == AhpErrorCodes.authRequired && token.refreshable) {
          await _refreshAndPush(resource, token);
        } else {
          _forget(resource);
        }
      } on Object catch (error) {
        _log.fine('could not push the token for $resource: $error');
      }
    }
  }
}
