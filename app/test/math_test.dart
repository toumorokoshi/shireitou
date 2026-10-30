/// Tests for TeX math in replies (AV-078): the markdown syntaxes that find
/// it and the widgets that typeset it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shireitou/src/session_detail/math_syntax.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';

const _mse =
    r'\text{MSE} = \frac{1}{N}\sum_{i=1}^{N} \left(\hat{y}_i - y_i\right)^2';

/// The math elements of [markdown], as (TeX, display) pairs, in order.
List<(String, bool)> _math(String markdown) {
  final found = <(String, bool)>[];
  void visit(md.Node node) {
    if (node is! md.Element) return;
    if (node.tag == mathTag) {
      found.add((node.textContent, node.attributes['display'] == 'true'));
    }
    node.children?.forEach(visit);
  }

  md.Document(
    blockSyntaxes: mathBlockSyntaxes,
    inlineSyntaxes: mathInlineSyntaxes,
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  ).parse(markdown).forEach(visit);
  return found;
}

void main() {
  group('math syntaxes', () {
    test(r'a $$…$$ line is display math', () {
      expect(_math('The loss:\n\n\$\$ $_mse \$\$\n\nDone.'), [(_mse, true)]);
    });

    test(r'$$ and \[ on their own lines open display math', () {
      expect(_math('\$\$\na = b\n+ c\n\$\$'), [('a = b\n+ c', true)]);
      expect(_math('\\[\nx^2\n\\]'), [('x^2', true)]);
    });

    test('unclosed display math before a blank line stays text', () {
      expect(_math('\$\$\na = b\n\nmore'), isEmpty);
    });

    test(r'inline \(…\), $…$ and $$…$$ within a paragraph', () {
      expect(_math(r'So \(a+b\) and $x_i$ and $$y$$ hold.'), [
        ('a+b', false),
        ('x_i', false),
        ('y', true),
      ]);
    });

    test('prices and spaced dollars stay text', () {
      expect(_math(r'It costs $5 and $10, or $ 3 $.'), isEmpty);
      expect(_math(r'Escaped \$x\$ stays.'), isEmpty);
    });

    test('math in code spans and fenced code stays code', () {
      expect(_math(r'Run `echo $HOME$`.'), isEmpty);
      expect(_math('```\n\$\$\nx\n\$\$\n```'), isEmpty);
    });
  });

  group('rendering', () {
    Widget app(String data) =>
        MaterialApp(home: Scaffold(body: MarkdownText(data)));

    testWidgets('display and inline math are typeset', (tester) async {
      await tester.pumpWidget(app('\$\$ $_mse \$\$\n\nWith \$N\$ samples.'));

      final math = tester.widgetList<Math>(find.byType(Math)).toList();
      expect(math.map((m) => m.mathStyle), [MathStyle.display, MathStyle.text]);
      expect(math.every((m) => m.parseError == null), isTrue);
      expect(find.textContaining('samples.', findRichText: true), findsOne);
    });

    testWidgets('TeX that does not parse shows as written', (tester) async {
      await tester.pumpWidget(app(r'Bad: $\frac{1$ here.'));

      expect(find.textContaining(r'$\frac{1$', findRichText: true), findsOne);
    });
  });
}
