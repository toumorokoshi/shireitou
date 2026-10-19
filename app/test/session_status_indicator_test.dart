import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_list/session_status_indicator.dart';
import 'package:shireitou/src/theme/app_theme.dart';

import 'fixtures.dart';

ThemeData _theme() => buildTheme(defaultTheme(Brightness.dark));

void main() {
  group('isSessionWorking', () {
    test('in progress without input', () {
      expect(isSessionWorking(status: const SessionStatus(8 | 32)), isTrue);
    });

    test('input needed is not working', () {
      expect(isSessionWorking(status: SessionStatus.inputNeeded), isFalse);
    });

    test('active turn counts when status is not in progress', () {
      expect(
        isSessionWorking(status: const SessionStatus(33), hasActiveTurn: true),
        isTrue,
      );
    });

    test('idle with no active turn', () {
      expect(isSessionWorking(status: const SessionStatus(33)), isFalse);
    });
  });

  testWidgets('working status shows a spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionStatusLeading(status: const SessionStatus(8 | 32)),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('idle status shows the dot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionStatusLeading(status: const SessionStatus(33)),
        ),
      ),
    );
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('with reduced motion the spinner is a static icon', (
    tester,
  ) async {
    reduceMotion(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionStatusLeading(status: const SessionStatus(8 | 32)),
        ),
      ),
    );
    expect(find.byIcon(Icons.autorenew), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('header icon announces Working', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SessionWorkingIcon(
            size: 18,
            color: _theme().extension<AppColors>()!.statusColors.running,
            semanticLabel: 'Working',
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(SessionWorkingIcon)),
      matchesSemantics(label: 'Working'),
    );
  });
}
