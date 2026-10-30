/// Tests for file paths in replies (AV-106): recognising and resolving
/// them, the markdown syntaxes that link them, tapping them, and the file
/// viewer.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shireitou/src/files/file_link_syntax.dart';
import 'package:shireitou/src/files/file_path_text.dart';
import 'package:shireitou/src/files/file_paths.dart';
import 'package:shireitou/src/files/file_viewer.dart';
import 'package:shireitou/src/files/open_file_store.dart';
import 'package:shireitou/src/files/ssh_file_read.dart';
import 'package:shireitou/src/host_connection.dart';
import 'package:shireitou/src/session_detail/link_menu.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';

/// The paths [findFileReferences] finds in [text].
List<String> _paths(String text) => [
  for (final m in findFileReferences(text)) text.substring(m.start, m.end),
];

/// [markdown] rendered to HTML with the file link syntaxes.
String _html(String markdown) => md.markdownToHtml(
  markdown,
  inlineSyntaxes: fileLinkSyntaxes,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

const _file = (
  uri: 'file:///work/app/lib/main.dart',
  label: 'lib/main.dart',
  line: 3,
  endLine: null,
);

void main() {
  group('looksLikeFilePath', () {
    test('accepts paths with folders, known names and extensions', () {
      for (final path in [
        'src/app.dart',
        './lib/a.ts',
        '../docs/guide.md',
        '/home/me/project/main.py',
        'README.md',
        'pubspec.yaml',
        'Makefile',
        'app/Dockerfile',
        'config/.env',
        'packages/ahp_client/lib/src/client.dart',
      ]) {
        expect(looksLikeFilePath(path), isTrue, reason: path);
      }
    });

    test('rejects words, versions, URLs and folders', () {
      for (final path in [
        'e.g',
        'v1.2.3',
        '1.5',
        'foo.bar',
        'and/or',
        'src/lib',
        'src/',
        'github.com/a/b.md',
        'www.example.com/a.html',
        'a//b.dart',
      ]) {
        expect(looksLikeFilePath(path), isFalse, reason: path);
      }
    });
  });

  test('parseFileReference reads line suffixes', () {
    expect(parseFileReference('src/a.dart:12'), (
      path: 'src/a.dart',
      line: 12,
      endLine: null,
    ));
    expect(parseFileReference('src/a.dart:12:4'), (
      path: 'src/a.dart',
      line: 12,
      endLine: null,
    ));
    expect(parseFileReference('src/a.dart:12-20'), (
      path: 'src/a.dart',
      line: 12,
      endLine: 20,
    ));
    expect(parseFileReference('src/a.dart#L3-L5'), (
      path: 'src/a.dart',
      line: 3,
      endLine: 5,
    ));
    expect(parseFileReference(' README.md '), (
      path: 'README.md',
      line: null,
      endLine: null,
    ));
    expect(parseFileReference('not a path'), isNull);
  });

  test('findFileReferences finds paths in prose and skips URLs', () {
    expect(
      _paths(
        'I changed lib/main.dart:3 and README.md. See '
        'https://example.com/docs/a.md or www.example.com/b.html, e.g. v1.2.',
      ),
      ['lib/main.dart:3', 'README.md'],
    );
    expect(_paths('Read app/test/a_test.dart, (src/b.ts)'), [
      'app/test/a_test.dart',
      'src/b.ts',
    ]);
    expect(_paths('package:path/path.dart'), isEmpty);
  });

  group('fileReferenceOfHref', () {
    test('reads relative, absolute, file: and app-made targets', () {
      expect(fileReferenceOfHref('docs/a.md'), (
        path: 'docs/a.md',
        line: null,
        endLine: null,
      ));
      expect(fileReferenceOfHref('src/my%20file.py#L7'), (
        path: 'src/my file.py',
        line: 7,
        endLine: null,
      ));
      expect(fileReferenceOfHref('lib/a.dart:9'), (
        path: 'lib/a.dart',
        line: 9,
        endLine: null,
      ));
      expect(fileReferenceOfHref('file:///home/me/a.dart#L2-L4'), (
        path: '/home/me/a.dart',
        line: 2,
        endLine: 4,
      ));
      expect(fileReferenceOfHref(filePathHref('a/b.rs:1')), (
        path: 'a/b.rs',
        line: 1,
        endLine: null,
      ));
    });

    test('leaves web links, anchors and other schemes alone', () {
      for (final href in [
        'https://example.com/a.md',
        'mailto:me@example.com',
        'vscode://file/a.dart',
        '#section',
        '?q=1',
        '//example.com/a.md',
        '',
      ]) {
        expect(fileReferenceOfHref(href), isNull, reason: href);
      }
    });
  });

  test('resolveFilePath joins relative paths to the working directory', () {
    expect(
      resolveFilePath('lib/a.dart', root: '/work/app'),
      '/work/app/lib/a.dart',
    );
    expect(resolveFilePath('../b.md', root: '/work/app'), '/work/b.md');
    expect(resolveFilePath('/etc/hosts', root: '/work/app'), '/etc/hosts');
    expect(resolveFilePath('lib/a.dart'), isNull);
    expect(fileUriOf('/work/my app/a.dart'), 'file:///work/my%20app/a.dart');
    expect(
      filePathLabel('/work/app/lib/a.dart', root: '/work/app'),
      'lib/a.dart',
    );
    expect(filePathLabel('/etc/hosts', root: '/work/app'), '/etc/hosts');
  });

  test('openedFileOf resolves a reference to a file: URI', () {
    expect(
      openedFileOf((
        path: 'lib/main.dart',
        line: 3,
        endLine: null,
      ), root: '/work/app'),
      _file,
    );
    expect(
      openedFileOf((path: 'lib/main.dart', line: null, endLine: null)),
      isNull,
    );
  });

  test('the markdown syntaxes link code spans and bare paths', () {
    expect(
      _html('Edit `lib/a.dart:3` and docs/b.md, not `x = 1`.'),
      '<p>Edit <a href="shireitou-file:lib/a.dart:3"><code>lib/a.dart:3</code></a>'
      ' and <a href="shireitou-file:docs/b.md">docs/b.md</a>, not <code>x = 1</code>.</p>\n',
    );
    expect(
      _html('See https://example.com/a.md and [the guide](docs/g.md).'),
      '<p>See <a href="https://example.com/a.md">https://example.com/a.md</a>'
      ' and <a href="docs/g.md">the guide</a>.</p>\n',
    );
  });

  test('a link whose text is a path keeps only its own target', () {
    expect(
      _html('See [main.dart](/home/me/p/lib/main.dart).'),
      '<p>See <a href="/home/me/p/lib/main.dart">main.dart</a>.</p>\n',
    );
    expect(
      _html('See [`main.dart`](/home/me/p/lib/main.dart:3).'),
      '<p>See <a href="/home/me/p/lib/main.dart:3"><code>main.dart</code></a>.</p>\n',
    );
    expect(
      _html('See [**lib/main.dart**](file:///home/me/p/lib/main.dart).'),
      '<p>See <a href="file:///home/me/p/lib/main.dart">'
      '<strong>lib/main.dart</strong></a>.</p>\n',
    );
  });

  test('the file viewer helpers', () {
    expect(fileLines('a\nb\n'), ['a', 'b']);
    expect(fileLines('a\nb'), ['a', 'b']);
    expect(fileLines(''), ['']);
    expect(looksBinary('a\u0000b'), isTrue);
    expect(lineLabel(_file), 'L3');
    expect(lineLabel((uri: 'u', label: 'l', line: 3, endLine: 9)), 'L3–9');
    expect(
      lineLabel((uri: 'u', label: 'l', line: null, endLine: null)),
      isNull,
    );
  });

  group('links', () {
    Widget app(Widget child, List<FileReference> opened) => MaterialApp(
      home: Scaffold(
        body: FileLinkScope(onOpen: opened.add, child: child),
      ),
    );

    testWidgets('tapping a path in a reply opens it', (tester) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        app(
          const MarkdownText('I edited `lib/a.dart:4` and docs/b.md.'),
          opened,
        ),
      );

      await tester.tapOnText(find.textRange.ofSubstring('lib/a.dart:4'));
      await tester.tapOnText(find.textRange.ofSubstring('docs/b.md'));

      expect(opened, [
        (path: 'lib/a.dart', line: 4, endLine: null),
        (path: 'docs/b.md', line: null, endLine: null),
      ]);
    });

    testWidgets('a markdown link to a file opens it', (tester) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        app(const MarkdownText('See [the guide](docs/guide.md#L2).'), opened),
      );

      await tester.tapOnText(find.textRange.ofSubstring('the guide'));

      expect(opened, [(path: 'docs/guide.md', line: 2, endLine: null)]);
    });

    testWidgets('a link named after a file opens its target', (tester) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        app(
          const MarkdownText('See [main.dart](/srv/app/lib/main.dart:7).'),
          opened,
        ),
      );

      await tester.tapOnText(find.textRange.ofSubstring('main.dart'));

      expect(opened, [
        (path: '/srv/app/lib/main.dart', line: 7, endLine: null),
      ]);
    });

    testWidgets('without a scope paths stay text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MarkdownText('See lib/a.dart.')),
        ),
      );

      expect(find.text('See lib/a.dart.'), findsOneWidget);
    });

    testWidgets('right-clicking a path offers to copy or open it', (
      tester,
    ) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        app(const MarkdownText('See lib/a.dart.'), opened),
      );

      final box = tester.renderObject<RenderBox>(find.byType(RichText).first);
      // The test font is 14 px a character: "See " ends at 56.
      final at = box.localToGlobal(const Offset(80, 8));
      await tester.tapAt(
        at,
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.text('File'), findsOneWidget);
      expect(find.text('Copy path'), findsOneWidget);
      await tester.tap(find.text('Open file'));
      await tester.pumpAndSettle();

      expect(opened, [(path: 'lib/a.dart', line: null, endLine: null)]);
    });

    testWidgets('a tool call summary links its paths', (tester) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        app(const FilePathText('Read src/app.ts, 40 lines'), opened),
      );

      await tester.tapOnText(find.textRange.ofSubstring('src/app.ts'));

      expect(opened, [(path: 'src/app.ts', line: null, endLine: null)]);
    });

    test('linkText shows the path of an app-made link', () {
      expect(linkText(filePathHref('a/b.dart')), 'a/b.dart');
      expect(linkText('https://example.com'), 'https://example.com');
    });
  });

  group('FileViewer', () {
    Widget viewer(Future<String> Function() read, {VoidCallback? onClose}) =>
        ProviderScope(
          overrides: [
            fileTextProvider((host: 'h', uri: _file.uri))
                .overrideWith((ref) => read()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HostScope(
                host: 'h',
                child: FileViewer(file: _file, onClose: onClose),
              ),
            ),
          ),
        );

    testWidgets('shows the file with line numbers and its path', (
      tester,
    ) async {
      var closed = false;
      await tester.pumpWidget(
        viewer(
          () async => 'void main() {\n  print(1);\n}\n',
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('lib/main.dart'), findsOneWidget);
      expect(find.text('L3'), findsOneWidget);
      expect(find.text('1\n2\n3'), findsOneWidget);
      expect(
        find.textContaining('print(1);', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close file'));
      expect(closed, isTrue);
    });

    testWidgets('says why a file could not be read', (tester) async {
      await tester.pumpWidget(
        viewer(() async => throw StateError('no such file')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not open lib/main.dart'),
        findsOneWidget,
      );
    });

    testWidgets('does not show binary files', (tester) async {
      await tester.pumpWidget(viewer(() async => 'PNG\u0000\u0001'));
      await tester.pumpAndSettle();

      expect(find.text('lib/main.dart is a binary file.'), findsOneWidget);
    });
  });
}
