/// Tests for the composer's box (AV-096): the placeholder, the chips and
/// their menus, the disabled "+", and the send, queue and stop buttons;
/// and the pure label helpers behind them.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/composer_labels.dart';
import 'package:shireitou/src/composer/config_fields.dart';
import 'package:shireitou/src/session_detail/session_detail_view.dart';

const _opus = SessionModelInfo(
  id: 'anthropic/claude-opus-5-5',
  provider: 'pi',
  name: 'Claude Opus 5.5',
  maxContextWindow: 1000000,
  configSchema: ConfigSchema(
    properties: {
      'thinkingLevel': ConfigPropertySchema(
        type: ConfigPropertySchemaType.string,
        title: 'Thinking',
        defaultValue: 'medium',
        enumValues: ['low', 'medium', 'high'],
      ),
      'lane': ConfigPropertySchema(
        type: ConfigPropertySchemaType.string,
        title: 'Lane',
        defaultValue: 'impl',
        enumValues: ['impl', 'review'],
        enumLabels: ['implementation lane', 'review lane'],
      ),
      'note': ConfigPropertySchema(
        type: ConfigPropertySchemaType.string,
        title: 'Note',
      ),
    },
  ),
);

const _fast = SessionModelInfo(id: 'fast', provider: 'pi', name: 'Fast');

const _mode = ConfigField(
  id: 'mode',
  title: 'Mode',
  kind: ConfigFieldKind.choice,
  defaultValue: 'agent',
  options: [ConfigOption('agent', 'Agent'), ConfigOption('plan', 'Plan')],
  sessionMutable: true,
);

/// What a [FollowUpInput] reported.
class _Calls {
  final sent = <({String text, bool sendNow, ModelSelection? model})>[];
  final settings = <(String, Object?)>[];
  var stops = 0;
}

Future<_Calls> _pump(
  WidgetTester tester, {
  bool working = false,
  List<String> history = const [],
  bool Function()? onEditQueued,
}) async {
  final calls = _Calls();
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FollowUpInput(
            working: working,
            history: history,
            onEditQueued: onEditQueued,
            hintText: composerPlaceholder(agent: 'Pi', folder: 'cruise'),
            models: const [_opus, _fast],
            initialModel: const ModelSelection(id: 'anthropic/claude-opus-5-5'),
            sessionFields: const [_mode],
            sessionValues: const {'mode': 'agent'},
            onSessionSettingChanged: (id, value) =>
                calls.settings.add((id, value)),
            onStop: () => calls.stops++,
            onSend: (text, {required sendNow, model, attachments = const []}) =>
                calls.sent.add((text: text, sendNow: sendNow, model: model)),
          ),
        ),
      ),
    ),
  );
  return calls;
}

IconButton _button(WidgetTester tester, String tooltip) => tester.widget(
  find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
);

void main() {
  group('labels', () {
    test('the placeholder names the agent and the workspace folder', () {
      expect(
        composerPlaceholder(agent: 'Pi', folder: 'cruise'),
        'Chat with Pi [cruise]',
      );
      expect(composerPlaceholder(agent: 'Pi'), 'Chat with Pi');
      expect(composerPlaceholder(folder: 'cruise'), 'Describe a task…');
    });

    test('the model chip shows the model id and one option', () {
      expect(
        modelChipLabel(_opus, const ModelSelection(id: _opusId)),
        'anthropic/claude-opus-5-5 · implementation lane',
      );
      expect(
        modelChipLabel(
          _opus,
          const ModelSelection(id: _opusId, config: {'lane': 'review'}),
        ),
        'anthropic/claude-opus-5-5 · review lane',
      );
      // An id without a provider shows the model's name.
      expect(modelChipLabel(_fast, const ModelSelection(id: 'fast')), 'Fast');
      expect(modelChipLabel(null, null), hostDefaultModelLabel);
    });

    test('context windows are written as K and M', () {
      expect(contextWindowLabel(null), isNull);
      expect(contextWindowLabel(0), isNull);
      expect(contextWindowLabel(1000000), '1M');
      expect(contextWindowLabel(1048576), '1M');
      expect(contextWindowLabel(1500000), '1.5M');
      expect(contextWindowLabel(200000), '200K');
      expect(contextWindowLabel(131072), '131K');
      expect(contextWindowLabel(32768), '33K');
      expect(contextWindowLabel(8192), '8.2K');
      expect(contextWindowLabel(512), '512');
    });

    test('the effort chip joins the level and the context window', () {
      expect(
        effortChipLabel(effort: 'Medium', contextWindow: '1M'),
        'Medium · 1M',
      );
      expect(effortChipLabel(contextWindow: '200K'), '200K');
      expect(effortChipLabel(), isNull);
      expect(capitalized('medium'), 'Medium');
    });

    test('the reasoning level is found by id or title', () {
      final fields = modelConfigFields(_opus.configSchema);
      expect([for (final f in fields) isEffortField(f)], [true, false, false]);
      expect(
        isEffortField(
          const ConfigField(
            id: 'x',
            title: 'Reasoning effort',
            kind: ConfigFieldKind.choice,
          ),
        ),
        isTrue,
      );
    });
  });

  testWidgets('one box with the placeholder, "+", the chips and send', (
    tester,
  ) async {
    final calls = await _pump(tester);
    expect(find.text('Chat with Pi [cruise]'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(
      find.text('anthropic/claude-opus-5-5 · implementation lane'),
      findsOneWidget,
    );
    expect(find.text('Medium · 1M'), findsOneWidget);
    // Attachments are not supported yet (AV-042).
    expect(_button(tester, attachmentsUnsupportedLabel).onPressed, isNull);
    // Nothing to send yet.
    expect(_button(tester, 'Send').onPressed, isNull);

    // The effort chip picks the thinking level.
    await tester.tap(find.text('Medium · 1M'));
    await tester.pumpAndSettle();
    expect(find.text('Low'), findsOneWidget);
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    expect(find.text('High · 1M'), findsOneWidget);

    // The model chip lists the models, the other choice options and the
    // options a menu cannot hold.
    await tester.tap(find.byTooltip('Model'));
    await tester.pumpAndSettle();
    expect(find.text(hostDefaultModelLabel), findsOneWidget);
    expect(find.text('Claude Opus 5.5'), findsOneWidget);
    expect(find.text('Fast'), findsOneWidget);
    expect(find.text('Lane: implementation lane'), findsOneWidget);
    expect(find.text('More options…'), findsOneWidget);
    await tester.tap(find.text('More options…'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Note'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // The mode chip changes the session setting.
    await tester.tap(find.text('Agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(calls.settings, [('mode', 'plan')]);

    await tester.enterText(find.byType(TextField), 'Go');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(calls.sent.single.text, 'Go');
    expect(calls.sent.single.sendNow, isFalse);
    expect(calls.sent.single.model?.config?['thinkingLevel'], 'high');
  });

  testWidgets('while working, an empty box stops; typed text queues or '
      'sends now', (tester) async {
    final calls = await _pump(tester, working: true);
    expect(find.byTooltip('Send'), findsNothing);
    await tester.tap(find.byTooltip('Stop'));
    expect(calls.stops, 1);

    await tester.enterText(find.byType(TextField), 'Also this');
    await tester.pump();
    expect(find.byTooltip('Stop'), findsNothing);
    expect(find.byTooltip('Queue'), findsOneWidget);
    await tester.tap(find.byTooltip('Send now'));
    await tester.pump();
    expect(calls.sent.single.sendNow, isTrue);
    // Sent, so the box is empty and stops again.
    expect(find.byTooltip('Stop'), findsOneWidget);
  });

  group('↑ and ↓ (AV-087)', () {
    String boxText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('recall earlier messages; Enter sends the edit again', (
      tester,
    ) async {
      final calls = await _pump(tester, history: ['first', 'second']);
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(boxText(tester), 'second');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(boxText(tester), 'first');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(boxText(tester), 'first');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(boxText(tester), 'second');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(boxText(tester), isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.enterText(find.byType(TextField), 'second, edited');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls.sent.single.text, 'second, edited');
      expect(boxText(tester), isEmpty);
    });

    testWidgets('typed text is never replaced', (tester) async {
      await _pump(tester, history: ['first']);
      await tester.enterText(find.byType(TextField), 'my draft');
      await tester.pump();
      expect(boxText(tester), 'my draft');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(boxText(tester), 'my draft');
    });

    testWidgets('a queued message is edited before history is recalled', (
      tester,
    ) async {
      var queuedEdits = 0;
      await _pump(
        tester,
        working: true,
        history: ['first'],
        onEditQueued: () {
          queuedEdits++;
          return true;
        },
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(queuedEdits, 1);
      expect(boxText(tester), isEmpty);
    });
  });
}

const _opusId = 'anthropic/claude-opus-5-5';
