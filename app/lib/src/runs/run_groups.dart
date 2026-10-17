/// Pure model of parallel runs (best-of-N, AV-045).
///
/// AHP has no notion of linked sessions, so the link lives in the
/// client: a [RunGroup] lists the sessions one prompt started (on any
/// connected host) and the one the user picked. Groups are kept on this
/// device (`run_group_store.dart`); another client sees the sessions
/// but not the group.
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

import '../hosts/open_hosts.dart';

/// One session of a [RunGroup].
@immutable
class RunMember {
  /// Creates a [RunMember].
  const RunMember({
    required this.host,
    required this.session,
    required this.label,
  });

  /// Decodes a [RunMember].
  factory RunMember.fromJson(Map<String, Object?> json) => RunMember(
    host: json['host']! as String,
    session: json['session']! as String,
    label: (json['label'] as String?) ?? '',
  );

  /// The host key.
  final String host;

  /// The session URI, as the host lists it.
  final String session;

  /// The agent and model it ran with ("Claude · Sonnet").
  final String label;

  /// The session's reference.
  SessionRef get ref => (host: host, session: session);

  /// Encodes the member.
  Map<String, Object?> toJson() => {
    'host': host,
    'session': session,
    'label': label,
  };

  @override
  bool operator ==(Object other) =>
      other is RunMember &&
      other.host == host &&
      other.session == session &&
      other.label == label;

  @override
  int get hashCode => Object.hash(host, session, label);
}

/// Sessions started from one prompt, to compare and pick from.
@immutable
class RunGroup {
  /// Creates a [RunGroup].
  const RunGroup({
    required this.id,
    required this.prompt,
    required this.createdAt,
    required this.members,
    this.winner,
  });

  /// Decodes a [RunGroup]; throws on malformed data.
  factory RunGroup.fromJson(Map<String, Object?> json) {
    final winner = json['winner'];
    return RunGroup(
      id: json['id']! as String,
      prompt: (json['prompt'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
      members: [
        for (final m in json['members']! as List<Object?>)
          RunMember.fromJson((m! as Map).cast<String, Object?>()),
      ],
      winner: winner is Map
          ? (
              host: winner['host']! as String,
              session: winner['session']! as String,
            )
          : null,
    );
  }

  /// A unique ID.
  final String id;

  /// The prompt every run was started with.
  final String prompt;

  /// When the runs were started (ISO 8601).
  final String createdAt;

  /// The runs, in the order they were set up.
  final List<RunMember> members;

  /// The run the user picked, if any.
  final SessionRef? winner;

  /// The 1-based position of [session] in the group, or null.
  int? positionOf(SessionRef session) {
    final i = members.indexWhere((m) => m.ref == session);
    return i < 0 ? null : i + 1;
  }

  /// A copy with [winner] (null clears it).
  RunGroup withWinner(SessionRef? winner) => RunGroup(
    id: id,
    prompt: prompt,
    createdAt: createdAt,
    members: members,
    winner: winner,
  );

  /// Encodes the group.
  Map<String, Object?> toJson() => {
    'id': id,
    'prompt': prompt,
    'createdAt': createdAt,
    'members': [for (final m in members) m.toJson()],
    if (winner case final w?) 'winner': {'host': w.host, 'session': w.session},
  };

  @override
  bool operator ==(Object other) =>
      other is RunGroup &&
      other.id == id &&
      other.prompt == prompt &&
      other.createdAt == createdAt &&
      listEquals(other.members, members) &&
      other.winner == winner;

  @override
  int get hashCode =>
      Object.hash(id, prompt, createdAt, Object.hashAll(members), winner);
}

/// How many groups are kept; older ones are dropped.
const maxRunGroups = 50;

/// How many runs one prompt may start.
const maxRuns = 5;

/// [groups] with [group] first (replacing one with the same ID), keeping
/// the newest [maxRunGroups].
List<RunGroup> withGroup(List<RunGroup> groups, RunGroup group) => [
  group,
  ...groups.where((g) => g.id != group.id),
].take(maxRunGroups).toList();

/// [groups] with group [id]'s winner set to [winner] (null clears it).
List<RunGroup> withWinner(
  List<RunGroup> groups,
  String id,
  SessionRef? winner,
) => [for (final g in groups) g.id == id ? g.withWinner(winner) : g];

/// The group [session] belongs to, or null.
RunGroup? groupOf(List<RunGroup> groups, SessionRef session) =>
    groups.where((g) => g.positionOf(session) != null).firstOrNull;

/// A short label for every session in a group: "Run 2 of 3", with
/// "· picked" for the winner.
Map<SessionRef, String> labelsOfRuns(List<RunGroup> groups) => {
  for (final g in groups)
    for (final (i, m) in g.members.indexed)
      m.ref:
          'Run ${i + 1} of ${g.members.length}'
          '${g.winner == m.ref ? ' · picked' : ''}',
};

/// Encodes [groups].
String encodeRunGroups(List<RunGroup> groups) =>
    jsonEncode([for (final g in groups) g.toJson()]);

/// Decodes [encodeRunGroups] output, skipping malformed groups.
List<RunGroup> decodeRunGroups(String? text) {
  if (text == null || text.isEmpty) return const [];
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  if (json is! List) return const [];
  return [
    for (final g in json)
      if (g is Map)
        ?(() {
          try {
            return RunGroup.fromJson(g.cast<String, Object?>());
          } on Object {
            return null;
          }
        })(),
  ];
}

/// The text of the newest reply in [chat]: the markdown of the active
/// turn, else of the last finished turn. Null when there is none yet.
String? lastReplyOf(ChatState chat) {
  String? text(List<ResponsePart> parts) {
    final markdown = [
      for (final p in parts)
        if (p case MarkdownResponsePart(:final content)
            when content.trim().isNotEmpty)
          content.trim(),
    ];
    return markdown.isEmpty ? null : markdown.join('\n\n');
  }

  if (chat.activeTurn case final active?) {
    if (text(active.responseParts) case final t?) return t;
  }
  for (final turn in chat.turns.reversed) {
    if (text(turn.responseParts) case final t?) return t;
  }
  return null;
}

/// The runs that started on [host] and the messages of those that did
/// not, from [results] in run order (a started session's URI, or the
/// error) and each run's [labels]. A failure is "Run 2: …" when there
/// were several runs.
({List<RunMember> started, List<String> failures}) runOutcome({
  required String host,
  required List<String> labels,
  required List<Object> results,
}) => (
  started: [
    for (final (i, result) in results.indexed)
      if (result is String)
        RunMember(host: host, session: result, label: labels[i]),
  ],
  failures: [
    for (final (i, result) in results.indexed)
      if (result is! String)
        results.length == 1 ? '$result' : 'Run ${i + 1}: $result',
  ],
);
