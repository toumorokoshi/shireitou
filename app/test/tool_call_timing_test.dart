/// Client-observed tool call timings on the timeline's cards (AV-077).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';
import 'package:shireitou/src/session_detail/tool_call_timing.dart';

const _running = ToolCallRunningState(
  toolCallId: 'a',
  toolName: 'bash',
  displayName: 'Bash',
  invocationMessage: PlainString('Run ls'),
  confirmed: ToolCallConfirmationReason.notNeeded,
);

ToolCallState _done(String id) => ToolCallCompletedState(
  toolCallId: id,
  toolName: 'read',
  displayName: 'Read',
  invocationMessage: PlainString('Read $id'),
  pastTenseMessage: PlainString('Read $id'),
  confirmed: ToolCallConfirmationReason.notNeeded,
  success: true,
);

Future<void> _pump(
  WidgetTester tester,
  Map<String, ToolCallTiming> timings,
  Widget card,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ToolCallTimingScope(
        timings: timings,
        child: SingleChildScrollView(child: card),
      ),
    ),
  ),
);

void main() {
  testWidgets('a running call counts up every second', (tester) async {
    await _pump(tester, {
      'a': ToolCallTiming(
        ran: Duration.zero,
        runningSince: clock.now().subtract(const Duration(seconds: 4)),
      ),
    }, const ToolCallCard(turnId: 't', toolCall: _running));
    expect(find.text('Bash · Running · 4s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Bash · Running · 5s'), findsOneWidget);
  });

  testWidgets('a finished call shows its estimate', (tester) async {
    await _pump(tester, {
      'a': const ToolCallTiming(ran: Duration(seconds: 3)),
    }, ToolCallCard(turnId: 't', toolCall: _done('a')));
    expect(find.text('Read · Done · ~3s'), findsOneWidget);
  });

  testWidgets('a call the client never saw run shows no time', (tester) async {
    await _pump(
      tester,
      const {},
      ToolCallCard(turnId: 't', toolCall: _done('a')),
    );
    expect(find.text('Read · Done'), findsOneWidget);
  });

  testWidgets('a group shows its calls\' summed time', (tester) async {
    await _pump(tester, {
      'a': const ToolCallTiming(ran: Duration(seconds: 2)),
      'b': const ToolCallTiming(ran: Duration(seconds: 3)),
    }, ToolCallGroupCard(turnId: 't', calls: [_done('a'), _done('b')]));
    expect(find.text('Read a, Read b · Done · ~5s'), findsOneWidget);
  });
}
