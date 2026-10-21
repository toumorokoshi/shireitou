/// Tests for the composer's round send, queue and stop button and its
/// stop square (AV-096).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/composer_action_button.dart';
import 'package:shireitou/src/theme/app_colors.dart';
import 'package:shireitou/src/theme/app_icons.dart';

Future<void> _pump(WidgetTester tester, VoidCallback? onPressed) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ComposerActionButton(
              tooltip: 'Send',
              icon: const Icon(AppIcons.send),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );

ButtonStyle _style(WidgetTester tester) =>
    tester.widget<IconButton>(find.byType(IconButton)).style!;

void main() {
  testWidgets('a filled circle in the foreground colour', (tester) async {
    var presses = 0;
    await _pump(tester, () => presses++);
    expect(
      tester.getSize(find.byType(IconButton)),
      const Size.square(composerActionButtonSize),
    );
    expect(_style(tester).shape?.resolve({}), isA<CircleBorder>());
    final context = tester.element(find.byType(IconButton));
    expect(
      _style(tester).backgroundColor?.resolve({}),
      Theme.of(context).colorScheme.onSurface,
    );
    await tester.tap(find.byTooltip('Send'));
    expect(presses, 1);
  });

  testWidgets('the stop square is solid, in the glyph colour', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ComposerActionButton(
              tooltip: 'Stop',
              icon: const StopSquare(),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final square = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(StopSquare),
        matching: find.byType(DecoratedBox),
      ),
    );
    final context = tester.element(find.byType(StopSquare));
    expect(
      (square.decoration as BoxDecoration).color,
      AppColors.of(context).raisedSurface,
    );
  });

  testWidgets('dimmed and inert without onPressed', (tester) async {
    await _pump(tester, null);
    final context = tester.element(find.byType(IconButton));
    final fill = Theme.of(context).colorScheme.onSurface;
    expect(
      _style(tester).backgroundColor?.resolve({WidgetState.disabled}),
      fill.withValues(alpha: 0.3),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
