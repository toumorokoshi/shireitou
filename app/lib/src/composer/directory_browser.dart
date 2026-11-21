/// A folder picker over the host's filesystem (`resourceList`, AV-043).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_connection.dart';
import '../session_list/folder_grouping.dart';

/// A working-directory URI for [input]: `file:` URIs are kept, paths are
/// converted to `file://` URIs.
String directoryUri(String input) {
  final text = input.trim();
  return text.startsWith('file:') ? text : Uri.file(text).toString();
}

/// Normalizes a typed or pasted folder [input] (trimming whitespace and
/// decoding `file://` URIs / stripping trailing slashes via
/// [normalizeFolderKey]), or returns null when empty.
String? normalizeFolderInput(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  return normalizeFolderKey(trimmed);
}

/// The folder above [path], or null at the root.
String? parentFolder(String path) {
  if (path == '/' || path.isEmpty) return null;
  final index = path.lastIndexOf('/');
  return index <= 0 ? '/' : path.substring(0, index);
}

/// [name] inside [path].
String childFolder(String path, String name) =>
    path.endsWith('/') ? '$path$name' : '$path/$name';

/// The sub-folders in [entries], by name.
List<String> folderNames(List<DirectoryEntry> entries) => [
  for (final e in entries)
    if (e.type == DirectoryEntryType.directory) e.name,
]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

/// Opens the folder picker on [host] at [initial]; returns the chosen path,
/// or null when cancelled.
Future<String?> showDirectoryBrowser(
  BuildContext context, {
  required String host,
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (_) => DirectoryBrowser(host: host, initial: initial),
);

/// Lists one folder at a time: tap a folder to open it, go up, and choose
/// the folder shown.
class DirectoryBrowser extends ConsumerStatefulWidget {
  /// Creates a [DirectoryBrowser].
  const DirectoryBrowser({
    super.key,
    required this.host,
    required this.initial,
  });

  /// The host key.
  final String host;

  /// The folder to start in.
  final String initial;

  @override
  ConsumerState<DirectoryBrowser> createState() => _DirectoryBrowserState();
}

class _DirectoryBrowserState extends ConsumerState<DirectoryBrowser> {
  late String _path = normalizeFolderInput(widget.initial) ?? '/';
  late final TextEditingController _controller = TextEditingController(
    text: _path,
  );
  late Future<List<String>> _folders = _list(_path);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _typedPath => normalizeFolderInput(_controller.text);

  Future<List<String>> _list(String path) async => folderNames(
    await ref
        .read(hostConnectionProvider(widget.host).notifier)
        .listDirectory(directoryUri(path)),
  );

  void _open(String path) {
    final normalized = normalizeFolderInput(path);
    if (normalized == null) return;
    setState(() {
      _path = normalized;
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      _folders = _list(normalized);
    });
  }

  @override
  Widget build(BuildContext context) {
    final parent = parentFolder(_path);
    return AlertDialog(
      title: const Text('Choose a folder'),
      content: SizedBox(
        width: 480,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: 'Folder path',
              child: TextField(
                controller: _controller,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: '/path/to/folder',
                  prefixIcon: const Icon(Icons.folder_outlined, size: 18),
                  suffixIcon: IconButton(
                    tooltip: 'Open folder',
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    onPressed: _typedPath == null
                        ? null
                        : () => _open(_typedPath!),
                  ),
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: _open,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _folders,
                builder: (context, snapshot) {
                  final items = <Widget>[
                    if (parent != null)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.arrow_upward),
                        title: const Text('..'),
                        onTap: () => _open(parent),
                      ),
                  ];
                  if (snapshot.hasError) {
                    items.add(
                      ListTile(
                        title: Text(
                          'Could not list this folder: ${snapshot.error}',
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData) {
                    items.add(
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  } else {
                    for (final name in snapshot.data!) {
                      items.add(
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(name),
                          onTap: () => _open(childFolder(_path, name)),
                        ),
                      );
                    }
                    if (snapshot.data!.isEmpty) {
                      items.add(const ListTile(title: Text('No sub-folders')));
                    }
                  }
                  return ListView(children: items);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _typedPath == null
              ? null
              : () => Navigator.pop(context, _typedPath),
          child: const Text('Choose this folder'),
        ),
      ],
    );
  }
}
