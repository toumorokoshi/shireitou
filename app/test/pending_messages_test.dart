/// Widget tests for clicking a queued message to edit it in place (AV-081).
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/pending_messages.dart';
import 'package:shireitou/src/session_detail/timeline_items.dart';

PendingMessageItem _queued(String id, String text) => PendingMessageItem(
  PendingMessageKind.queued,
  PendingMessage(id: id, message: userMessage(text)),
);

final _both = [_queued('q1', 'first'), _queued('q2', 'second')];

/// Pumps the panel showing [pending] and returns the dispatched actions.
Future<List<JsonMap>> _pump(
  WidgetTester tester,
  List<PendingMessageItem> pending, {
  List<JsonMap>? actions,
  Listenable? editNewestRequests,
  VoidCallback? onEditorClosed,
  ValueChanged<PendingMessage>? onSendNow,
}) async {
  final dispatched = actions ?? <JsonMap>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PendingMessagesPanel(
          pending: pending,
          onAction: dispatched.add,
          onSendNow: onSendNow,
          editNewestRequests: editNewestRequests,
          onEditorClosed: onEditorClosed,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return dispatched;
}

Finder get _editor => find.widgetWithText(TextField, 'Edit message');

void main() {
  testWidgets('clicking a message edits it in place; Enter saves', (
    tester,
  ) async {
    final actions = await _pump(tester, _both);
    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();
    expect(_editor, findsOneWidget);
    expect(find.text('first'), findsOneWidget);

    await tester.enterText(_editor, 'second, edited');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);
    expect(actions.single['type'], 'chat/pendingMessageSet');
    expect(actions.single['id'], 'q2');
    expect((actions.single['message']! as JsonMap)['text'], 'second, edited');
  });

  testWidgets('a request (↑ in the composer) edits the newest message; '
      'Enter re-queues it and hands focus back', (tester) async {
    final requests = ValueNotifier<int>(0);
    addTearDown(requests.dispose);
    var closed = 0;
    final actions = await _pump(
      tester,
      _both,
      editNewestRequests: requests,
      onEditorClosed: () => closed++,
    );
    requests.value++;
    await tester.pumpAndSettle();
    expect(_editor, findsOneWidget);
    expect(find.text('first'), findsOneWidget);

    await tester.enterText(_editor, 'second, edited');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(actions.single['id'], 'q2');
    expect((actions.single['message']! as JsonMap)['text'], 'second, edited');
    expect(closed, 1);
  });

  testWidgets('Escape cancels without sending', (tester) async {
    final actions = await _pump(tester, _both);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    await tester.enterText(_editor, 'changed');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);
    expect(find.text('first'), findsOneWidget);
    expect(actions, isEmpty);
  });

  testWidgets('saving an empty message removes it', (tester) async {
    final actions = await _pump(tester, _both);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    await tester.enterText(_editor, '   ');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(actions.single, {
      'type': 'chat/pendingMessageRemoved',
      'kind': 'queued',
      'id': 'q1',
    });
  });

  testWidgets('the menu and the drag handle do not open the editor', (
    tester,
  ) async {
    await _pump(tester, _both);
    await tester.tap(find.byIcon(Icons.drag_handle).first);
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);

    await tester.tap(find.byTooltip('Message actions').first);
    await tester.pumpAndSettle();
    expect(_editor, findsNothing);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(_editor, findsOneWidget);
  });

  testWidgets('the menu sends a queued message now', (tester) async {
    final sent = <PendingMessage>[];
    final actions = await _pump(tester, _both, onSendNow: sent.add);
    await tester.tap(find.byTooltip('Message actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send now'));
    await tester.pumpAndSettle();

    expect(sent.single.id, 'q2');
    expect(actions, isEmpty);
  });

  testWidgets('no Send now without a handler', (tester) async {
    await _pump(tester, _both);
    await tester.tap(find.byTooltip('Message actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Send now'), findsNothing);
  });

  testWidgets('a message the host sends while it is edited closes the editor', (
    tester,
  ) async {
    final actions = await _pump(tester, _both);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    await tester.enterText(_editor, 'too late');

    await _pump(tester, [_queued('q2', 'second')], actions: actions);
    expect(_editor, findsNothing);
    expect(
      find.text('The message was sent or removed before the edit was saved.'),
      findsOneWidget,
    );
    expect(actions, isEmpty);
  });
}
