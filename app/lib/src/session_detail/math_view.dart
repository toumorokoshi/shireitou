/// Renders the `math` elements of `math_syntax.dart` with
/// `flutter_math_fork` (AV-078).
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Renders math elements: display math on its own line, scrolling
/// sideways when wide, and inline math as a span that flows with the
/// paragraph's text. TeX that does not parse shows as written.
class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final display = element.attributes['display'] == 'true';
    final math = Math.tex(
      element.textContent,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: parentStyle,
      onErrorFallback: (_) =>
          Text(element.attributes['source'] ?? '', style: parentStyle),
    );
    if (display) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: math,
      );
    }
    // A text widget, so flutter_markdown_plus merges it into the paragraph.
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: math,
      ),
    );
  }
}
