/// Search and sort for the session list (AV-026, AV-027).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import '../hosts/open_hosts.dart';
import 'folder_grouping.dart';
import 'session_filter.dart';
import 'status_badges.dart';

/// The order of sessions within folders, and of the folders.
enum SessionSort {
  /// Most recently modified first (the default).
  recent('Most recent'),

  /// Least recently modified first.
  oldest('Oldest'),

  /// Needs input, then failed, then unread, then the rest; most recent
  /// first within each.
  attention('Needs attention first');

  const SessionSort(this.label);

  /// Text shown in the sort menu.
  final String label;
}

/// 0 for needs input, 1 for an error, 2 for unread, 3 otherwise.
int attentionRank(SessionStatus status) => status.isInputNeeded
    ? 0
    : status.isError
    ? 1
    : !status.isReadFlag
    ? 2
    : 3;

/// Compares sessions for [sort]. Attention ties fall back to the most
/// recent first.
int compareSessions(SessionSort sort, SessionSummary a, SessionSummary b) {
  int recent() => b.modifiedAt.compareTo(a.modifiedAt);
  return switch (sort) {
    SessionSort.recent => recent(),
    SessionSort.oldest => a.modifiedAt.compareTo(b.modifiedAt),
    SessionSort.attention =>
      attentionRank(a.status).compareTo(attentionRank(b.status)) != 0
          ? attentionRank(a.status).compareTo(attentionRank(b.status))
          : recent(),
  };
}

/// The qualifiers [parseSessionQuery] knows (GitHub style `key:value`).
const queryQualifiers = {'agent', 'status', 'repo', 'host'};

/// The `status:` values and what they match.
final statusQualifierValues = <String, bool Function(SessionStatus)>{
  'working': (s) => s.isInProgress && !s.isInputNeeded,
  'input': (s) => s.isInputNeeded,
  'needs-input': (s) => s.isInputNeeded,
  'error': (s) => s.isError,
  'idle': (s) => !s.isInProgress,
  'done': (s) => !s.isArchivedFlag && isDone(s),
  'unread': (s) => !s.isReadFlag,
  'read': (s) => s.isReadFlag,
  'attention': needsAttention,
  'archived': (s) => s.isArchivedFlag,
};

/// A parsed search: free-text [terms] (matched against titles) and
/// qualifier values by qualifier, all lowercase.
@immutable
class SessionQuery {
  /// Creates a [SessionQuery].
  const SessionQuery({this.terms = const [], this.qualifiers = const {}});

  /// Words that must all appear in the title.
  final List<String> terms;

  /// Values per qualifier; one value of each qualifier must match.
  final Map<String, List<String>> qualifiers;

  /// Whether the query matches everything.
  bool get isEmpty => terms.isEmpty && qualifiers.isEmpty;
}

/// Parses [text] into a [SessionQuery]. Words are split on spaces, and a
/// `"quoted phrase"` is one word. `agent:`, `status:`, `repo:` and
/// `host:` words are qualifiers (`status:a,b` lists alternatives); any
/// other word, including an unknown `key:value`, is a title term.
SessionQuery parseSessionQuery(String text) {
  final words = [
    for (final m in RegExp(r'(\S*?)"([^"]*)"?|\S+').allMatches(text))
      m.group(2) != null ? '${m.group(1)}${m.group(2)}' : m.group(0)!,
  ];
  final terms = <String>[];
  final qualifiers = <String, List<String>>{};
  for (final word in words) {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) continue;
    final colon = lower.indexOf(':');
    final key = colon > 0 ? lower.substring(0, colon) : '';
    final value = colon > 0 ? lower.substring(colon + 1) : '';
    if (queryQualifiers.contains(key) && value.isNotEmpty) {
      (qualifiers[key] ??= []).addAll(
        value.split(',').where((v) => v.isNotEmpty),
      );
    } else {
      terms.add(lower);
    }
  }
  return SessionQuery(terms: terms, qualifiers: qualifiers);
}

/// Whether [session] (shown under [hostLabel]) matches [query].
bool matchesQuery(
  HostSession session,
  SessionQuery query, {
  String? hostLabel,
}) {
  if (query.isEmpty) return true;
  final summary = session.summary;
  final title = summary.title.toLowerCase();
  if (!query.terms.every(title.contains)) return false;
  bool anyOf(String key, bool Function(String value) test) =>
      query.qualifiers[key]?.any(test) ?? true;
  final folder = folderKeyOf(summary)?.toLowerCase() ?? '';
  final repo = worktreeInfoOf(summary).repo;
  final places = [
    folder,
    ?repo?.toLowerCase(),
    ?summary.project?.uri.toLowerCase(),
    ?summary.project?.displayName.toLowerCase(),
  ];
  return anyOf('agent', summary.provider.toLowerCase().contains) &&
      anyOf(
        'status',
        (v) => statusQualifierValues[v]?.call(summary.status) ?? false,
      ) &&
      anyOf('repo', (v) => places.any((p) => p.contains(v))) &&
      anyOf(
        'host',
        (v) =>
            session.host.toLowerCase().contains(v) ||
            (hostLabel?.toLowerCase().contains(v) ?? false),
      );
}
