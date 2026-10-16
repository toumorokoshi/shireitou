/// Pure functions over the root-channel session catalogue (AHP-023).
///
/// The catalogue is an unmodifiable map from session URI to
/// [SessionSummary], built from `listSessions` and kept current by the
/// `root/sessionAdded`, `root/sessionRemoved` and
/// `root/sessionSummaryChanged` notifications.
library;

import 'wire.dart';

/// Session URI to summary.
typedef SessionCatalogue = Map<String, SessionSummary>;

/// An empty catalogue.
const SessionCatalogue emptyCatalogue = <String, SessionSummary>{};

/// Builds a catalogue from `listSessions` pages.
SessionCatalogue catalogueFromSummaries(Iterable<SessionSummary> summaries) =>
    Map.unmodifiable({for (final s in summaries) s.resource: s});

/// Applies `root/sessionAdded` (also replaces an existing entry).
SessionCatalogue applySessionAdded(
  SessionCatalogue catalogue,
  SessionSummary summary,
) => Map.unmodifiable({...catalogue, summary.resource: summary});

/// Applies `root/sessionRemoved`.
SessionCatalogue applySessionRemoved(
  SessionCatalogue catalogue,
  String session,
) => Map.unmodifiable({...catalogue}..remove(session));

/// Applies `root/sessionSummaryChanged`, whose `changes` is a
/// `Partial<SessionSummary>`. Unknown sessions are ignored, because a partial
/// summary cannot be decoded on its own.
SessionCatalogue applySessionSummaryChanged(
  SessionCatalogue catalogue,
  String session,
  JsonMap changes,
) {
  final current = catalogue[session];
  if (current == null) return catalogue;
  final merged = SessionSummary.fromJson({
    ...current.toJson(),
    ...changes,
    'resource': session,
  });
  return Map.unmodifiable({...catalogue, session: merged});
}

/// Applies a root-channel catalogue notification by JSON-RPC [method].
///
/// Returns [catalogue] unchanged for other methods.
SessionCatalogue applyRootNotification(
  SessionCatalogue catalogue,
  String method,
  JsonMap params,
) => switch (method) {
  'root/sessionAdded' => applySessionAdded(
    catalogue,
    SessionSummary.fromJson(params['summary']! as JsonMap),
  ),
  'root/sessionRemoved' => applySessionRemoved(
    catalogue,
    params['session']! as String,
  ),
  'root/sessionSummaryChanged' => applySessionSummaryChanged(
    catalogue,
    params['session']! as String,
    params['changes']! as JsonMap,
  ),
  _ => catalogue,
};

/// The catalogue key of the session created as [created], or null if it is
/// not listed yet.
///
/// Hosts may publish a session under another URI than the one sent to
/// `createSession` (pi lists `ahp-session:/<id>` as `pi:/<id>`), so this
/// matches the exact URI first, then the same trailing ID.
String? resolveSessionResource(SessionCatalogue catalogue, String created) {
  if (catalogue.containsKey(created)) return created;
  final id = sessionIdOf(created);
  return catalogue.keys.where((key) => sessionIdOf(key) == id).firstOrNull;
}

/// The ID part of a session URI: the text after the last `/`.
String sessionIdOf(String session) =>
    session.substring(session.lastIndexOf('/') + 1);
