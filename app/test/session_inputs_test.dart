import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/session_detail/session_inputs.dart';

import 'fixtures.dart';

void main() {
  test('sessionPrompts skips requests the open chat shows inline', () {
    final session = sessionWithRequests();
    final prompts = sessionPrompts(session, chatFixture());
    expect(prompts.map((p) => p.id), ['side']);
    // Without the chat mirrored, every request is shown.
    expect(sessionPrompts(session, null).map((p) => p.id), [
      'confirm-rm',
      'side',
    ]);
    // A chat without the tool call does not show it.
    expect(
      sessionPrompts(session, chatFixture(active: false)).map((p) => p.id),
      ['confirm-rm', 'side'],
    );
    // An answered (no longer blocking) call stays hidden.
    final approved = chatFixture().copyWith(
      activeTurn: chatFixture().activeTurn!.copyWith(
        responseParts: const [
          ToolCallResponsePart(
            toolCall: ToolCallRunningState(
              toolCallId: 'rm',
              toolName: 'bash',
              displayName: 'Bash',
              invocationMessage: PlainString('Run'),
              confirmed: ToolCallConfirmationReason.userAction,
            ),
          ),
        ],
      ),
    );
    expect(sessionPrompts(session, approved).map((p) => p.id), ['side']);
    expect(sessionPrompts(null, null), isEmpty);
  });

  test('sessionPrompts leaves out client tool execution', () {
    final session = sessionWithRequests().copyWith(
      inputNeeded: [
        SessionInputRequest.fromJson({
          'kind': 'toolClientExecution',
          'id': 'x',
          'chat': 'ahp-chat:/1',
          'turnId': 't',
          'clientId': 'c',
          'toolCall': {
            'status': 'running',
            'toolCallId': 'tc',
            'toolName': 'mine',
            'displayName': 'Mine',
            'invocationMessage': 'Run',
            'confirmed': 'not-needed',
            'contributor': {'kind': 'client', 'clientId': 'c'},
          },
        }),
      ],
    );
    expect(sessionPrompts(session, null), isEmpty);
  });

  test('chatTitleOf falls back to the URI', () {
    final session = sessionWithRequests();
    expect(chatTitleOf(session, 'ahp-chat:/side'), 'Reviewer');
    expect(chatTitleOf(session, 'ahp-chat:/x'), 'ahp-chat:/x');
  });

  test('changesLabel and backgroundWorkLabel', () {
    expect(changesLabel(null), isNull);
    expect(
      changesLabel(const ChangesSummary(additions: 3, deletions: 1, files: 2)),
      '+3 −1 · 2 files',
    );
    expect(changesLabel(const ChangesSummary(additions: 1)), '+1 −0');
    expect(
      backgroundWorkLabel(
        const BackgroundSubagentWork(
          id: 'a',
          label: 'Explore',
          startedAt: '',
          chat: 'ahp-chat:/sub',
        ),
      ),
      'Subagent: Explore',
    );
  });

  test('mcpServerAlerts finds servers that need sign-in or failed', () {
    final session = sessionWithRequests().copyWith(
      customizations: [
        Customization.fromJson({
          'type': 'mcpServer',
          'id': 'a',
          'uri': 'u',
          'name': 'Docs',
          'state': {
            'kind': 'authRequired',
            'reason': 'required',
            'resource': {'resource': 'https://docs'},
          },
        }),
        Customization.fromJson({
          'type': 'plugin',
          'id': 'p',
          'uri': 'u',
          'name': 'Plugin',
          'children': [
            {
              'type': 'mcpServer',
              'id': 'b',
              'uri': 'u',
              'name': 'Broken',
              'state': {
                'kind': 'error',
                'error': {'errorType': 'x', 'message': 'crashed'},
              },
            },
            {
              'type': 'mcpServer',
              'id': 'c',
              'uri': 'u',
              'name': 'Fine',
              'state': {'kind': 'ready'},
            },
          ],
        }),
      ],
    );
    final alerts = mcpServerAlerts(session);
    expect(alerts.map((a) => a.server.name), ['Docs', 'Broken']);
    expect(alerts.first.message, 'Sign in to https://docs');
    expect(alerts.last.message, 'Failed: crashed');
  });
}
