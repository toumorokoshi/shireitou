/// Tool call interaction: host-provided options and risk assessments,
/// editable input, result confirmation, input drafts and the sign-in
/// dialog (AV-083, AV-084, AHP-060).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/auth/sign_in_dialog.dart';
import 'package:shireitou/src/hosts/host_store.dart';
import 'package:shireitou/src/session_detail/chat_commands.dart';
import 'package:shireitou/src/session_detail/timeline_items.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';

const _options = [
  ConfirmationOption(
    id: 'once',
    label: 'Allow once',
    kind: ConfirmationOptionKind.approve,
    group: 1,
  ),
  ConfirmationOption(
    id: 'session',
    label: 'Allow in this session',
    kind: ConfirmationOptionKind.approve,
    group: 1,
  ),
  ConfirmationOption(
    id: 'skip',
    label: 'Skip this step',
    kind: ConfirmationOptionKind.deny,
    group: 2,
  ),
];

ToolCallPendingConfirmationState _pending({
  List<ConfirmationOption>? options,
  ToolCallRiskAssessment? risk,
  bool? editable,
}) => ToolCallPendingConfirmationState(
  toolCallId: 'tc1',
  toolName: 'bash',
  displayName: 'Bash',
  invocationMessage: const PlainString('Run `git push`'),
  toolInput: const InlineToolInput('{"command":"git push"}'),
  confirmationTitle: const PlainString('Allow Bash?'),
  options: options,
  riskAssessment: risk,
  editable: editable,
);

Future<List<JsonMap>> _pumpCard(WidgetTester tester, ToolCallState call) async {
  final actions = <JsonMap>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ToolCallCard(
            turnId: 't1',
            toolCall: call,
            onAction: actions.add,
          ),
        ),
      ),
    ),
  );
  return actions;
}

void main() {
  group('pure helpers', () {
    test('options are grouped by consecutive group number', () {
      expect(
        [
          for (final g in confirmationOptionGroups(_options))
            [for (final o in g) o.id],
        ],
        [
          ['once', 'session'],
          ['skip'],
        ],
      );
    });

    test('risk levels from the safety score', () {
      expect(riskLevel(0.9), RiskLevel.low);
      expect(riskLevel(0.5), RiskLevel.medium);
      expect(riskLevel(0.1), RiskLevel.high);
    });

    test('edited input: compact JSON, null when unchanged', () {
      const original = '{"command":"ls"}';
      expect(editedToolInput(original, '{\n  "command": "ls"\n}'), isNull);
      expect(
        editedToolInput(original, '{ "command": "ls -la" }'),
        '{"command":"ls -la"}',
      );
      expect(editedToolInput('ls', 'ls -la'), 'ls -la');
      expect(toolInputEditError(original, '{oops'), startsWith('Not valid'));
      expect(toolInputEditError('ls', '{oops'), isNull);
      expect(prettyToolInput(original), '{\n  "command": "ls"\n}');
    });

    test('approvals carry the edited input; a skip option is skipped', () {
      final approve = confirmToolCallAction(
        't1',
        _pending(),
        approve: true,
        editedInput: '{"command":"x"}',
      );
      expect(approve['editedToolInput'], '{"command":"x"}');
      final skip = confirmToolCallAction(
        't1',
        _pending(),
        approve: false,
        option: _options[2],
      );
      expect(skip['reason'], 'skipped');
      expect(skip['selectedOptionId'], 'skip');
    });

    test('input drafts round-trip between the form and the wire', () {
      const text = ChatInputTextQuestion(id: 'q', title: 'Q', message: 'Q?');
      final draft = inputAnswerChangedAction(
        const ChatInputRequest(id: 'r', questions: [text]),
        text,
        'hello',
      );
      expect(draft['type'], 'chat/inputAnswerChanged');
      expect(draft['answer'], {
        'state': 'draft',
        'value': {'kind': 'text', 'value': 'hello'},
      });
      final cleared = inputAnswerChangedAction(
        const ChatInputRequest(id: 'r', questions: [text]),
        text,
        '',
      );
      expect(cleared.containsKey('answer'), isFalse);
      expect(
        answerFormValue(
          text,
          ChatInputAnswer.fromJson(draft['answer']! as JsonMap),
        )?.value,
        'hello',
      );
      const select = ChatInputSingleSelectQuestion(
        id: 's',
        title: 'S',
        message: 'S?',
        options: [ChatInputOption(id: 'a', label: 'A')],
        allowFreeformInput: true,
      );
      expect(
        answerFormValue(
          select,
          const ChatInputAnswered(
            state: 'draft',
            value: ChatInputSelectedAnswerValue(
              value: 'a',
              freeformValues: ['more'],
            ),
          ),
        ),
        (value: 'a', freeform: 'more'),
      );
    });

    test('tokens are stored per resource and garbage is ignored', () {
      final token = ResourceToken(
        token: 'at',
        obtainedAt: DateTime.utc(2026, 10, 16),
        expiresIn: 60,
        refreshToken: 'rt',
      );
      final decoded = decodeTokens(encodeTokens({'https://r': token}));
      expect(decoded['https://r']?.toJson(), token.toJson());
      expect(decodeTokens('not json'), isEmpty);
      expect(decodeTokens(jsonEncode({'x': 1})), isEmpty);
      expect(decodeTokens(null), isEmpty);
    });
  });

  testWidgets('host options are buttons in groups, with the risk', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _pending(
        options: _options,
        risk: const ToolCallRiskAssessmentLoadingState(
          kind: ToolCallRiskAssessmentKind.judge,
        ),
      ),
    );
    expect(find.text('Assessing risk…'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Allow once'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);

    final actions = await _pumpCard(
      tester,
      _pending(
        options: _options,
        risk: const ToolCallRiskAssessmentCompleteState(
          kind: ToolCallRiskAssessmentKind.judge,
          safety: 0.2,
          reason: PlainString('Deletes files'),
        ),
      ),
    );
    expect(find.textContaining('High risk (safety 20%)'), findsOneWidget);
    expect(find.textContaining('Deletes files'), findsOneWidget);
    await tester.tap(find.text('Allow in this session'));
    expect(actions.single['selectedOptionId'], 'session');
    expect(actions.single['approved'], isTrue);
  });

  testWidgets('an editable input is edited before approving', (tester) async {
    final actions = await _pumpCard(tester, _pending(editable: true));
    await tester.tap(find.text('Edit input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Input'),
      '{"command": "git push --dry-run"}',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Edited input'), findsOneWidget);
    await tester.tap(find.text('Approve edited'));
    expect(
      actions.single['editedToolInput'],
      '{"command":"git push --dry-run"}',
    );
  });

  testWidgets('invalid JSON is not accepted as an edit', (tester) async {
    await _pumpCard(tester, _pending(editable: true));
    await tester.tap(find.text('Edit input'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Input'), '{');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not valid JSON'), findsOneWidget);
  });

  testWidgets('a result waiting for confirmation is used or discarded', (
    tester,
  ) async {
    final actions = await _pumpCard(
      tester,
      const ToolCallPendingResultConfirmationState(
        toolCallId: 'tc1',
        toolName: 'fetch',
        displayName: 'Fetch',
        invocationMessage: PlainString('Fetch'),
        confirmed: ToolCallConfirmationReason.notNeeded,
        success: true,
        pastTenseMessage: PlainString('Fetched'),
        content: [ToolResultTextContent(text: 'Status: ok')],
      ),
    );
    expect(find.textContaining('Review result'), findsWidgets);
    expect(find.text('Status: ok'), findsOneWidget);
    await tester.tap(find.text('Discard result'));
    expect(actions.single, {
      'type': 'chat/toolCallResultConfirmed',
      'turnId': 't1',
      'toolCallId': 'tc1',
      'approved': false,
    });
  });

  group('input drafts', () {
    const request = ChatInputRequest(
      id: 'r1',
      message: 'Describe the release',
      questions: [
        ChatInputTextQuestion(
          id: 'summary',
          title: 'Summary',
          message: 'One line',
          required: true,
        ),
        ChatInputTextQuestion(id: 'notes', title: 'Notes', message: 'More'),
      ],
    );

    Widget card(ChatInputRequest request, List<JsonMap> actions) => MaterialApp(
      home: Scaffold(
        body: InputRequestCard(
          part: InputRequestResponsePart(request: request),
          onAction: actions.add,
        ),
      ),
    );

    testWidgets('typing syncs a draft after a pause', (tester) async {
      final actions = <JsonMap>[];
      await tester.pumpWidget(card(request, actions));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Summary *'),
        'Fast',
      );
      expect(actions, isEmpty);
      await tester.pump(draftSyncDelay);
      expect(actions.single['type'], 'chat/inputAnswerChanged');
      expect(actions.single['questionId'], 'summary');
    });

    testWidgets('another client\'s draft fills untouched fields only', (
      tester,
    ) async {
      final actions = <JsonMap>[];
      await tester.pumpWidget(card(request, actions));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Summary *'),
        'Mine',
      );
      ChatInputAnswer draft(String text) => ChatInputAnswered(
        state: 'draft',
        value: ChatInputTextAnswerValue(value: text),
      );
      await tester.pumpWidget(
        card(
          request.copyWith(
            answers: {'summary': draft('Theirs'), 'notes': draft('From IDE')},
          ),
          actions,
        ),
      );
      expect(find.text('Mine'), findsOneWidget);
      expect(find.text('Theirs'), findsNothing);
      expect(find.text('From IDE'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      final completed = actions.last;
      expect(completed['type'], 'chat/inputCompleted');
      expect((completed['answers']! as JsonMap).keys, ['summary', 'notes']);
    });
  });

  group('sign-in dialog', () {
    const withServer = AuthChallenge(
      resource: ProtectedResourceMetadata(
        resource: 'https://mcp.example.com',
        resourceName: 'Example Docs',
        authorizationServers: ['https://as.example.com'],
      ),
      requiredScopes: ['docs.search'],
      expired: true,
    );

    Future<Future<ResourceToken?> Function()> open(
      WidgetTester tester,
      AuthChallenge challenge,
      Future<ResourceToken> Function(AuthChallenge) browser,
    ) async {
      late Future<ResourceToken?> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showSignInDialog(
                context,
                challenge,
                browserSignIn: browser,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => result;
    }

    testWidgets('signs in with the browser', (tester) async {
      final token = ResourceToken(token: 'at', obtainedAt: DateTime.now());
      final asked = <AuthChallenge>[];
      final pending = await open(tester, withServer, (c) async {
        asked.add(c);
        return token;
      });
      expect(find.textContaining('expired'), findsOneWidget);
      expect(find.text('Access requested: docs.search'), findsOneWidget);
      await tester.tap(find.text('Sign in with browser'));
      await tester.pumpAndSettle();
      expect(await pending(), same(token));
      expect(asked.single, same(withServer));
    });

    testWidgets('a browser failure is shown and a token can be pasted', (
      tester,
    ) async {
      final pending = await open(
        tester,
        withServer,
        (_) async => throw const OAuthException('access_denied', 'No'),
      );
      await tester.tap(find.text('Sign in with browser'));
      await tester.pumpAndSettle();
      expect(find.textContaining('access_denied: No'), findsOneWidget);
      await tester.tap(find.text('Use an access token instead'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Access token'),
        'pasted',
      );
      await tester.tap(find.text('Use token'));
      await tester.pumpAndSettle();
      expect((await pending())?.token, 'pasted');
    });
  });
}
