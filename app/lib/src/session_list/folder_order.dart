/// The order of the sidebar's workspace folders that the user dragged into
/// place, and the storage format of that order and of the collapsed hosts
/// and folders.
///
/// See `specs/agents-view.md`, "Sidebar tree".
library;

import 'dart:convert';

import 'folder_grouping.dart';

/// [groups] with the folders whose [FolderGroup.id] is in [order] first,
/// in that order, then the others in their order in [groups]. A placed
/// folder keeps its place over the sort and pins (pinned sessions still
/// come first inside it).
List<FolderGroup> orderFolders(List<FolderGroup> groups, List<String> order) {
  final rank = {for (final (i, id) in order.indexed) id: i};
  final placed = [
    for (final g in groups)
      if (rank.containsKey(g.id)) g,
  ]..sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
  return [
    ...placed,
    for (final g in groups)
      if (!rank.containsKey(g.id)) g,
  ];
}

/// [order] after moving `folders[from]` to index [to] of [folders], one
/// host's folders as shown ([orderFolders]).
///
/// Every folder in [folders] is placed, so the shown order is kept, and
/// the move only swaps places among them: the ids of folders that are not
/// shown (other hosts, filtered out) keep their places. [order] is
/// returned unchanged when [from] or [to] is out of range or they are
/// equal.
List<String> movedFolder(
  List<String> order,
  List<FolderGroup> folders,
  int from,
  int to,
) {
  if (from == to ||
      from < 0 ||
      to < 0 ||
      from >= folders.length ||
      to >= folders.length) {
    return order;
  }
  final ids = [for (final f in folders) f.id];
  final placed = order.toSet();
  final full = [
    ...order,
    for (final id in ids)
      if (!placed.contains(id)) id,
  ];
  final moved = [...ids]..removeAt(from);
  moved.insert(to, ids[from]);
  final shown = ids.toSet();
  var next = 0;
  return [for (final id in full) shown.contains(id) ? moved[next++] : id];
}

/// Encodes [ids] as a JSON list of strings.
String encodeIds(Iterable<String> ids) => jsonEncode([...ids]);

/// Decodes [encodeIds] output, skipping malformed entries and repeats.
List<String> decodeIds(String? text) {
  if (text == null || text.isEmpty) return const [];
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return const [];
  }
  if (json is! List) return const [];
  return {
    for (final id in json)
      if (id is String) id,
  }.toList();
}
