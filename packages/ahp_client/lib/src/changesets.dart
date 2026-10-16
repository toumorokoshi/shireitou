/// Changeset catalogue helpers (AHP-027): which kind of slice a
/// [Changeset] entry describes, and expanding its URI template into the
/// channel URI to subscribe to.
library;

import 'dart:convert';

import 'wire.dart';

/// The protocol-defined shapes of a changeset URI template.
enum ChangesetScope {
  /// No variables: the template is itself the channel URI.
  fixed,

  /// `{turnId}`: one turn's changes.
  turn,

  /// `{originalTurnId}` and `{modifiedTurnId}`: a diff between two turns.
  compareTurns,
}

final _variable = RegExp(r'\{([^{}]*)\}');

/// The variable names in [template] (RFC 6570 simple `{name}`
/// expressions), in order.
List<String> templateVariables(String template) => [
  for (final m in _variable.allMatches(template)) m.group(1)!,
];

/// The scope of [changeset], from the variables its template uses.
/// Variables the protocol does not define are ignored, as it requires.
ChangesetScope changesetScopeOf(Changeset changeset) {
  final names = templateVariables(changeset.uriTemplate).toSet();
  if (names.contains('originalTurnId') || names.contains('modifiedTurnId')) {
    return ChangesetScope.compareTurns;
  }
  if (names.contains('turnId')) return ChangesetScope.turn;
  return ChangesetScope.fixed;
}

/// Expands [changeset]'s URI template (RFC 6570 simple expansion), or
/// returns null when a variable its [changesetScopeOf] needs is missing.
/// Variables the protocol does not define expand to nothing, as undefined
/// RFC 6570 variables do.
String? expandChangesetUri(
  Changeset changeset, {
  String? turnId,
  String? originalTurnId,
  String? modifiedTurnId,
}) {
  final values = {
    'turnId': ?turnId,
    'originalTurnId': ?originalTurnId,
    'modifiedTurnId': ?modifiedTurnId,
  };
  final needed = switch (changesetScopeOf(changeset)) {
    ChangesetScope.fixed => const <String>[],
    ChangesetScope.turn => const ['turnId'],
    ChangesetScope.compareTurns => const ['originalTurnId', 'modifiedTurnId'],
  };
  if (needed.any((name) => values[name] == null)) return null;
  return changeset.uriTemplate.replaceAllMapped(
    _variable,
    (m) => _encodeUnreserved(values[m.group(1)] ?? ''),
  );
}

/// Percent-encodes everything but RFC 3986 unreserved characters.
String _encodeUnreserved(String value) {
  final out = StringBuffer();
  for (final byte in utf8.encode(value)) {
    final unreserved =
        (byte >= 0x41 && byte <= 0x5a) ||
        (byte >= 0x61 && byte <= 0x7a) ||
        (byte >= 0x30 && byte <= 0x39) ||
        byte == 0x2d ||
        byte == 0x2e ||
        byte == 0x5f ||
        byte == 0x7e;
    out.write(
      unreserved
          ? String.fromCharCode(byte)
          : '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
    );
  }
  return out.toString();
}

/// How a changed file changed, from its [FileEdit] sides.
enum FileChangeKind {
  /// Only `after`.
  created,

  /// Only `before`.
  deleted,

  /// Both sides, different URIs.
  renamed,

  /// Both sides with the same URI.
  modified,
}

/// The kind of change [edit] describes (`FileEdit` semantics: creates have
/// only `after`, deletes only `before`, renames differ in URI).
FileChangeKind fileChangeKindOf(FileEdit edit) =>
    switch ((edit.before, edit.after)) {
      (null, _?) => FileChangeKind.created,
      (_?, null) => FileChangeKind.deleted,
      (final b?, final a?) when b.uri != a.uri => FileChangeKind.renamed,
      _ => FileChangeKind.modified,
    };

/// The URI to show for [edit]: the new side, else the old one.
String fileEditUri(FileEdit edit) => edit.after?.uri ?? edit.before?.uri ?? '';

/// Lines added and removed over [files], from their diff stats.
({int added, int removed}) changesetLineCounts(Iterable<ChangesetFile> files) =>
    files.fold(
      (added: 0, removed: 0),
      (sum, f) => (
        added: sum.added + (f.edit.diff?.added ?? 0),
        removed: sum.removed + (f.edit.diff?.removed ?? 0),
      ),
    );

/// How many of [files] are reviewed (absent counts as not reviewed).
int reviewedCount(Iterable<ChangesetFile> files) =>
    files.where((f) => f.reviewed ?? false).length;

/// Whether [changeset] advertises the per-file review workflow.
bool supportsReview(Changeset changeset) =>
    changeset.capabilities?.review != null;
