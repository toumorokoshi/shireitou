/// Renders the `math` elements of `math_syntax.dart` with
/// `flutter_math_fork` (AV-078).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
    final math = _MeasuredMath(
      child: Math.tex(
        element.textContent,
        mathStyle: display ? MathStyle.display : MathStyle.text,
        textStyle: parentStyle,
        onErrorFallback: (_) =>
            Text(element.attributes['source'] ?? '', style: parentStyle),
      ),
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

/// Answers intrinsic and dry layout queries for [child] from its last
/// layout, so they never reach `flutter_math_fork`'s render objects:
/// `RenderLine` has no dry baseline, and the layout builders behind
/// `\sqrt`, `\left…\right` and accents assert on intrinsic sizes. A
/// markdown table's intrinsic column widths ask for both.
class _MeasuredMath extends SingleChildRenderObjectWidget {
  const _MeasuredMath({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasuredMath();
}

/// Lays [child] out at its natural width, since math does not wrap, and
/// remembers that size and baseline. Queries before the first layout are
/// answered with zero; when a layout finds a size that differs from an
/// answer already given, the next frame lays out again so ancestors such
/// as a table re-measure.
class _RenderMeasuredMath extends RenderProxyBox {
  Size _measured = Size.zero;
  double? _baseline;
  bool _answered = false;

  Size _answer() {
    _answered = true;
    return _measured;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _answer().width;

  @override
  double computeMaxIntrinsicWidth(double height) => _answer().width;

  @override
  double computeMinIntrinsicHeight(double width) => _answer().height;

  @override
  double computeMaxIntrinsicHeight(double width) => _answer().height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_answer());

  @override
  double computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final measured = _answer();
    return _baseline ?? measured.height;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(
      constraints.copyWith(maxWidth: double.infinity),
      parentUsesSize: true,
    );
    size = constraints.constrain(child.size);
    final baseline = child.getDistanceToBaseline(
      TextBaseline.alphabetic,
      onlyReal: true,
    );
    if (child.size == _measured && baseline == _baseline) return;
    _measured = child.size;
    _baseline = baseline;
    if (!_answered) return;
    _answered = false;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) markNeedsLayout();
    });
  }
}
