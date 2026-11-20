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
  void Function(String id, String text)? onEditClientQueued,
  ValueChanged<String>? onRemoveClientQueued,
  void Function(int from, int to)? onReorderClientQueued,
}) async {
  final dispatched = actions ?? <JsonMap>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PendingMessagesPanel(
          pending: pending,
          onAction: dispatched.add,
          onSendNow: onSendNow,
          onEditClientQueued: onEditClientQueued,
          onRemoveClientQueued: onRemoveClientQueued,
          onReorderClientQueued: onReorderClientQueued,
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

  testWidgets('"Send now" on a queued message, by button or menu', (
    tester,
  ) async {
    final sent = <String>[];
    final actions = await _pump(tester, [
      PendingMessageItem(
        PendingMessageKind.steering,
        PendingMessage(id: 's', message: userMessage('steer')),
      ),
      ..._both,
    ], onSendNow: (message) => sent.add(message.id));
    // Only the queued messages offer it, not the steering one.
    expect(find.byTooltip('Send now'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Send now').last);
    await tester.pumpAndSettle();
    expect(sent, ['q2']);
    expect(_editor, findsNothing);

    await tester.tap(find.byTooltip('Message actions').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send now'));
    await tester.pumpAndSettle();
    expect(sent, ['q2', 'q1']);
    expect(actions, isEmpty);
  });

  testWidgets('no "Send now" without a handler', (tester) async {
    await _pump(tester, _both);
    expect(find.byTooltip('Send now'), findsNothing);
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

  testWidgets(
    'client-side queued items show local icon, subtitle, and edit/remove/reorder',
    (tester) async {
      final edited = <(String, String)>[];
      final removed = <String>[];
      final reordered = <(int, int)>[];
      final actions = await _pump(
        tester,
        [
          PendingMessageItem(
            PendingMessageKind.queued,
            PendingMessage(id: 'c1', message: userMessage('local first')),
            clientQueued: true,
          ),
          PendingMessageItem(
            PendingMessageKind.queued,
            PendingMessage(id: 'c2', message: userMessage('local second')),
            clientQueued: true,
          ),
        ],
        onSendNow: (_) {},
        onEditClientQueued: (id, text) => edited.add((id, text)),
        onRemoveClientQueued: removed.add,
        onReorderClientQueued: (from, to) => reordered.add((from, to)),
      );

      expect(find.byIcon(Icons.cloud_off), findsNWidgets(2));
      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(
        find.text('Queued locally · Waiting to connect'),
        findsNWidgets(2),
      );
      // Client-side queued items cannot be "Send now"'d while disconnected.
      expect(find.byTooltip('Send now'), findsNothing);

      await tester.tap(find.text('local first'));
      await tester.pumpAndSettle();
      await tester.enterText(_editor, 'local first, edited');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(edited, [('c1', 'local first, edited')]);

      await tester.tap(find.byTooltip('Message actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();
      expect(reordered, [(0, 1)]);

      await tester.tap(find.byTooltip('Message actions').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(removed, ['c2']);
      expect(actions, isEmpty);
    },
  );
}
