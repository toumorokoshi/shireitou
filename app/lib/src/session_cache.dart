/// In-memory LRU cache of opened and pre-fetched sessions per host, so
/// switching back and forth between sessions renders immediately while the
/// live subscription refreshes in the background.
library;

import 'package:ahp_client/ahp_client.dart';

import 'hosts/open_hosts.dart';

/// A cached snapshot of a session and its mirrored chats.
class CachedSession {
  /// Creates a [CachedSession].
  const CachedSession({
    required this.session,
    this.defaultChat,
    this.chats = const {},
  });

  /// The last mirrored session state.
  final SessionState session;

  /// The session's default chat URI, if known.
  final String? defaultChat;

  /// Mirrored chat states keyed by chat URI.
  final Map<String, ChatState> chats;
}

/// Holds the most recently read sessions for one host, up to [capacity],
/// dropping the least recently used when full.
class SessionCache {
  /// Creates an empty [SessionCache].
  SessionCache({this.capacity = 64});

  /// The most sessions kept.
  final int capacity;

  final _entries = <String, CachedSession>{};

  /// The number of cached sessions.
  int get length => _entries.length;

  /// Whether [session] is currently cached.
  bool contains(String session) => _entries.containsKey(session);

  /// Returns the cached entry for [session] without changing its recency.
  CachedSession? peek(String session) => _entries[session];

  /// Returns the cached entry for [session] and marks it most recently used.
  CachedSession? operator [](String session) {
    final entry = _entries.remove(session);
    if (entry != null) _entries[session] = entry;
    return entry;
  }

  /// Stores [entry] for [session] as most recently used, evicting the least
  /// recently used entry if [length] exceeds [capacity].
  void remember(String session, CachedSession entry) {
    if (capacity <= 0) return;
    _entries
      ..remove(session)
      ..[session] = entry;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes [session] from the cache, if present.
  void remove(String session) => _entries.remove(session);

  /// Drops all cached sessions.
  void clear() => _entries.clear();
}

/// Updates [cache] from the transition [previous] -> [next].
void recordSessionCache(
  SessionCache cache,
  HostState previous,
  HostState next,
) {
  if (!identical(previous.missingChannels, next.missingChannels)) {
    for (final channel in next.missingChannels) {
      if (!previous.missingChannels.contains(channel)) {
        cache.remove(channel);
      }
    }
  }
  if (next.status == ConnectionStatus.connected &&
      !identical(previous.sessions, next.sessions)) {
    for (final session in previous.sessions.keys) {
      if (!next.sessions.containsKey(session)) {
        cache.remove(session);
      }
    }
  }
  if (identical(previous.sessionChannels, next.sessionChannels) &&
      identical(previous.chatChannels, next.chatChannels)) {
    return;
  }
  for (final MapEntry(key: sessionUri, value: mirror)
      in next.sessionChannels.entries) {
    final sessionState = mirror.state;
    final defaultChat = defaultChatOf(sessionState);
    final existing = cache.peek(sessionUri);
    final chats = Map<String, ChatState>.of(existing?.chats ?? const {});
    final knownChatUris = <String>{
      ?defaultChat,
      for (final chat in sessionState.chats) chat.resource,
    };
    for (final chatUri in knownChatUris) {
      if (next.chatChannels[chatUri]?.state case final chatState?) {
        chats[chatUri] = chatState;
      }
    }
    if (existing != null &&
        identical(existing.session, sessionState) &&
        existing.defaultChat == defaultChat &&
        _sameChatStates(existing.chats, chats)) {
      continue;
    }
    cache.remember(
      sessionUri,
      CachedSession(
        session: sessionState,
        defaultChat: defaultChat,
        chats: Map.unmodifiable(chats),
      ),
    );
  }
}

bool _sameChatStates(Map<String, ChatState> a, Map<String, ChatState> b) {
  if (a.length != b.length) return false;
  for (final MapEntry(key: key, value: value) in b.entries) {
    if (!identical(a[key], value)) return false;
  }
  return true;
}

/// Returns the pinned sessions on [host] that exist in [state]'s catalogue,
/// are not already cached, mirrored, missing, or already [attempted].
List<String> pinnedSessionsToWarm({
  required String host,
  required Set<SessionRef> pinned,
  required HostState state,
  required SessionCache cache,
  Set<String> attempted = const {},
}) => [
  for (final ref in pinned)
    if (ref.host == host &&
        state.sessions.containsKey(ref.session) &&
        !state.missingChannels.contains(ref.session) &&
        !cache.contains(ref.session) &&
        !state.sessionChannels.containsKey(ref.session) &&
        !attempted.contains(ref.session))
      ref.session,
];
