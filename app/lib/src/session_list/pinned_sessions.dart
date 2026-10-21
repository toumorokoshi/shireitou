/// Pinned sessions (AV-028): the set of pinned sessions, its storage
/// format, and the split of the listed sessions into the sidebar's
/// "Pinned" section and the rest. AHP has no pin field, so pins are kept
/// on this device.
library;

import 'dart:convert';

import '../hosts/open_hosts.dart';

/// The `PrefsStore` key the pins are kept under ([encodePinned]).
const pinnedSessionsKey = 'pinned_sessions';

/// The sessions of [sessions] that are in [pins], in the order of [pins]
/// (the order they were pinned in), and the other sessions in their
/// order. Pins of sessions that are not in [sessions] (filtered out, on
/// a closed host, or gone) are skipped.
({List<HostSession> pinned, List<HostSession> rest}) splitPinned(
  Set<SessionRef> pins,
  Iterable<HostSession> sessions,
) {
  final byRef = {for (final s in sessions) s.ref: s};
  return (
    pinned: [for (final p in pins) ?byRef[p]],
    rest: [
      for (final s in sessions)
        if (!pins.contains(s.ref)) s,
    ],
  );
}

/// [pins] with [session] added at the end ([pinned] true) or removed.
Set<SessionRef> withPinned(
  Set<SessionRef> pins,
  SessionRef session, {
  required bool pinned,
}) => pinned
    ? {...pins, session}
    : {
        for (final p in pins)
          if (p != session) p,
      };

/// The pins of [older] and then those of [newer] that [older] lacks, both
/// in [encodePinned] form, encoded the same way.
String mergePinned(String older, String newer) =>
    encodePinned({...decodePinned(older), ...decodePinned(newer)});

/// Encodes [pins] as a JSON list of `{host, session}` objects.
String encodePinned(Set<SessionRef> pins) => jsonEncode([
  for (final p in pins) {'host': p.host, 'session': p.session},
]);

/// Decodes [encodePinned] output, skipping malformed entries.
Set<SessionRef> decodePinned(String? text) {
  if (text == null || text.isEmpty) return const {};
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return const {};
  }
  if (json is! List) return const {};
  return {
    for (final p in json)
      if (p case {'host': final String host, 'session': final String session})
        (host: host, session: session),
  };
}
