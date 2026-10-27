/// The file open in a session's side pane (AV-106), and the scope through
/// which links in the session open files.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/open_hosts.dart';
import 'file_paths.dart';

/// A file to show: its `file:` [uri] on the host, its [label] (the path
/// relative to the working directory when inside it) and the lines a
/// reply pointed at.
typedef OpenedFile = ({String uri, String label, int? line, int? endLine});

/// [ref] resolved against [root] (the session's working directory) as an
/// [OpenedFile]; null when it is relative and there is no [root].
OpenedFile? openedFileOf(FileReference ref, {String? root}) {
  final path = resolveFilePath(ref.path, root: root);
  if (path == null) return null;
  return (
    uri: fileUriOf(path),
    label: filePathLabel(path, root: root),
    line: ref.line,
    endLine: ref.endLine,
  );
}

/// The file shown in a session's side pane instead of "Files changed",
/// by session; kept while the app runs, so going back to a session shows
/// the file it had open.
final openFileProvider =
    NotifierProvider.family<OpenFileNotifier, OpenedFile?, SessionRef>(
      OpenFileNotifier.new,
    );

/// Holds the file open in one session's side pane.
class OpenFileNotifier extends Notifier<OpenedFile?> {
  /// Creates the holder for [session].
  OpenFileNotifier(this.session);

  /// The session.
  final SessionRef session;

  @override
  OpenedFile? build() => null;

  /// Shows [file].
  void open(OpenedFile file) => state = file;

  /// Goes back to "Files changed".
  void close() => state = null;
}

/// Opens a file a reply names.
typedef OpenFile = void Function(FileReference ref);

/// Gives the links below it a way to open the files they name: without
/// one, paths in replies are plain text.
class FileLinkScope extends InheritedWidget {
  /// Creates a [FileLinkScope] that opens files with [onOpen].
  const FileLinkScope({super.key, required this.onOpen, required super.child});

  /// Opens a file.
  final OpenFile onOpen;

  /// The nearest scope's [onOpen], or null.
  static OpenFile? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FileLinkScope>()?.onOpen;

  @override
  bool updateShouldNotify(FileLinkScope oldWidget) =>
      onOpen != oldWidget.onOpen;
}
