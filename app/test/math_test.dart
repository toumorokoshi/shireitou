/// Tests for TeX math in replies (AV-078): the markdown syntaxes that find
/// it and the widgets that typeset it.
library;

import 'package:flutter/gestures.dart';
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

    testWidgets('a mouse can hover over math', (tester) async {
      await tester.pumpWidget(app('\$\$ $_mse \$\$\n\nWith \$N\$ samples.'));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      for (final math in find.byType(Math).evaluate()) {
        final box = tester.getRect(find.byWidget(math.widget));
        for (var x = box.left; x <= box.right; x += 2) {
          await mouse.moveTo(Offset(x, box.center.dy));
        }
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('math in table cells lays out and can be hovered', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          '| a | b |\n|---|---|\n| \$x_i\$ | \$\$y\$\$ |\n'
          '| \$$_mse\$ | \$\\sqrt{2}\$ |\n'
          '| \$\\hat{x}\$ | \$\$\\boxed{\\sqrt{x}}\$\$ |',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Math), findsNWidgets(6));

      // The columns are re-measured once the math has been laid out.
      await tester.pump();
      final table = tester.getRect(find.byType(Table));
      for (final math in find.byType(Math).evaluate()) {
        final box = tester.getRect(find.byWidget(math.widget));
        expect(box.width, greaterThan(0));
        expect(table.contains(box.topLeft), isTrue);
        expect(table.contains(box.bottomRight - const Offset(1, 1)), isTrue);
      }
      expect(table.isEmpty, isFalse);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      for (var y = table.top; y <= table.bottom; y += 4) {
        for (var x = table.left; x <= table.right; x += 8) {
          await mouse.moveTo(Offset(x, y));
        }
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('inline math sits on the text baseline', (tester) async {
      await tester.pumpWidget(app(r'Height $x$ here.'));
      expect(tester.takeException(), isNull);

      final math = tester.getRect(find.byType(Math));
      final text = tester.getRect(
        find.textContaining('Height', findRichText: true),
      );
      expect(math.top, greaterThanOrEqualTo(text.top));
      expect(math.bottom, lessThanOrEqualTo(text.bottom));
    });
  });
}
