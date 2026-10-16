/// Syntax highlighting (AV-061, AV-101) with `re_highlight`, a Dart port
/// of highlight.js, and the code block widget with a copy button used in
/// markdown replies.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github-dark.dart';
import 'package:re_highlight/styles/github.dart';

/// The languages this app highlights, a common subset of highlight.js
/// (the full set would add every grammar to the web build).
final Highlight _highlighter = Highlight()
  ..registerLanguages({
    'bash': langBash,
    'c': langC,
    'cpp': langCpp,
    'csharp': langCsharp,
    'css': langCss,
    'dart': langDart,
    'diff': langDiff,
    'dockerfile': langDockerfile,
    'go': langGo,
    'java': langJava,
    'javascript': langJavascript,
    'json': langJson,
    'kotlin': langKotlin,
    'markdown': langMarkdown,
    'php': langPhp,
    'python': langPython,
    'ruby': langRuby,
    'rust': langRust,
    'shell': langShell,
    'sql': langSql,
    'swift': langSwift,
    'typescript': langTypescript,
    'xml': langXml,
    'yaml': langYaml,
  });

/// Whether [language] (a name or alias such as `js`) can be highlighted.
bool canHighlight(String? language) =>
    language != null && _highlighter.getLanguage(language) != null;

/// The highlight.js language for a file [path], from its name or
/// extension; null when unknown.
String? languageForPath(String path) {
  final name = path.split('/').last.toLowerCase();
  if (name == 'dockerfile') return 'dockerfile';
  final dot = name.lastIndexOf('.');
  if (dot < 0) return null;
  final ext = name.substring(dot + 1);
  final language = switch (ext) {
    'html' || 'htm' || 'svg' || 'xml' || 'plist' => 'xml',
    'yml' => 'yaml',
    'sh' || 'zsh' => 'bash',
    'h' => 'c',
    'hpp' || 'cc' || 'cxx' => 'cpp',
    'cs' => 'csharp',
    'kt' || 'kts' => 'kotlin',
    'md' => 'markdown',
    'mjs' || 'cjs' || 'jsx' => 'javascript',
    'tsx' => 'typescript',
    _ => ext,
  };
  return canHighlight(language) ? language : null;
}

/// The highlight theme for [brightness].
Map<String, TextStyle> highlightTheme(Brightness brightness) =>
    brightness == Brightness.dark ? githubDarkTheme : githubTheme;

/// [code] as styled spans for [language] on [brightness], or plain text in
/// [base] when the language is unknown.
TextSpan highlightCode(
  String code, {
  required String? language,
  required TextStyle base,
  required Brightness brightness,
}) {
  if (!canHighlight(language)) return TextSpan(text: code, style: base);
  final result = _highlighter.highlight(code: code, language: language!);
  final theme = {...highlightTheme(brightness)}..remove('root');
  final renderer = TextSpanRenderer(base, theme);
  result.render(renderer);
  return renderer.span ?? TextSpan(text: code, style: base);
}

/// The monospace style code is shown in.
TextStyle codeStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .bodySmall!
    .copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'DejaVu Sans Mono'],
      height: 1.4,
    );

/// A highlighted code block with its language and a copy button (AV-061).
class CodeBlock extends StatelessWidget {
  /// Creates a [CodeBlock] for [code] in [language].
  const CodeBlock({super.key, required this.code, this.language});

  /// The code, without a trailing newline.
  final String code;

  /// The fence's language, if any.
  final String? language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = codeStyle(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Text(language ?? 'code', style: theme.textTheme.labelSmall),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy code',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.maybeOf(
                        context,
                      )?.showSnackBar(const SnackBar(content: Text('Copied')));
                    }
                  },
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text.rich(
              highlightCode(
                code,
                language: language,
                base: base,
                brightness: theme.brightness,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders fenced and indented code blocks in markdown as [CodeBlock]s.
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.children?.whereType<md.Element>().firstOrNull;
    final language = switch (code?.attributes['class']) {
      final String c when c.startsWith('language-') => c.substring(9),
      _ => null,
    };
    var text = element.textContent;
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    return CodeBlock(code: text, language: language);
  }
}
