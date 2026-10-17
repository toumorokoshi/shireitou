/// Pinned sessions (AV-028): the set of pinned sessions and its storage
/// format. AHP has no pin field, so pins are kept on this device.
library;

import 'dart:convert';

import '../hosts/open_hosts.dart';

/// [pins] with [session] added ([pinned] true) or removed.
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
