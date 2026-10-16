/// Session-level widgets around the timeline: the "Waiting for you" panel
/// for `SessionState.inputNeeded`, the background work chip and MCP server
/// alerts.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/material.dart';

import '../auth/sign_in_dialog.dart';
import 'session_inputs.dart';
import 'timeline_parts.dart';
import 'tool_previews.dart';

/// Sends [action], an answer to [entry], to the entry's chat.
typedef AnswerPrompt = void Function(SessionInputRequest entry, JsonMap action);

/// The session's open input requests that the timeline does not show
/// (from other chats, or not mirrored in the open chat yet), each
/// answerable in place. Answers go to the request's own chat, which need
/// not be subscribed; the view hides an answered entry until the host
/// removes it, and shows it again if the answer is undone.
class SessionInputPanel extends StatelessWidget {
  /// Creates a [SessionInputPanel] for [prompts] (see [sessionPrompts]).
  const SessionInputPanel({
    super.key,
    required this.prompts,
    required this.session,
    required this.openChat,
    required this.onAnswer,
    this.onSignIn,
  });

  /// The requests to show.
  final List<SessionInputRequest> prompts;

  /// The session, for chat titles.
  final SessionState? session;

  /// The chat the timeline shows.
  final String? openChat;

  /// Dispatches an answer to a request's chat.
  final AnswerPrompt onAnswer;

  /// Pushes an MCP sign-in token.
  final SignIn? onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.45,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.front_hand_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for you (${prompts.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              for (final entry in prompts) _entry(context, entry),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, SessionInputRequest entry) {
    final chat = entry.chat;
    void dispatch(JsonMap action) => onAnswer(entry, action);
    final Widget body = switch (entry) {
      SessionChatInputRequest(:final request) => InputRequestCard(
        key: ValueKey(entry.id),
        part: InputRequestResponsePart(request: request),
        onAction: dispatch,
      ),
      SessionToolConfirmationRequest(:final turnId, :final toolCall) =>
        switch (toolCall) {
          final ToolCallState call => ToolCallCard(
            key: ValueKey(entry.id),
            turnId: turnId,
            toolCall: call,
            onAction: dispatch,
          ),
          _ => const Text('A tool call needs confirmation.'),
        },
      SessionToolAuthenticationRequest(:final turnId, :final toolCall) =>
        ToolCallCard(
          key: ValueKey(entry.id),
          turnId: turnId,
          toolCall: toolCall,
          onAction: dispatch,
          onSignIn: onSignIn,
        ),
      SessionToolClientExecutionRequest() => const SizedBox.shrink(),
      SessionInputRequestUnknown(:final kind) => Text(
        'The host is waiting for input this app cannot show ($kind).',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chat != openChat)
            Text(
              'In ${chatTitleOf(session, chat)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          body,
        ],
      ),
    );
  }
}

/// "1 tool running on another client": tool calls of this session that
/// another client executes (`toolClientExecution` entries). They need
/// nothing from the user, so they are not in the "Waiting for you" panel;
/// the tooltip names the tools and the chats they run in.
class ClientExecutionChip extends StatelessWidget {
  /// Creates a [ClientExecutionChip] for non-empty [executions].
  const ClientExecutionChip({
    super.key,
    required this.executions,
    required this.session,
  });

  /// The executions to show.
  final List<SessionToolClientExecutionRequest> executions;

  /// The session, for chat titles.
  final SessionState? session;

  @override
  Widget build(BuildContext context) {
    final count = executions.length;
    return Tooltip(
      message: [
        for (final e in executions)
          '${e.toolCall.displayName} in ${chatTitleOf(session, e.chat)} '
              '(client ${e.clientId})',
      ].join('\n'),
      child: Chip(
        avatar: const Icon(Icons.devices_other, size: 18),
        label: Text(
          '$count ${count == 1 ? 'tool' : 'tools'} running on another client',
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// "2 in background": the chat's background shells and subagents, listed
/// in a menu. A shell with a terminal opens its live output; a subagent
/// opens its chat (AV-065, AV-069).
class BackgroundWorkChip extends StatelessWidget {
  /// Creates a [BackgroundWorkChip] for non-empty [work].
  const BackgroundWorkChip({super.key, required this.work, this.onOpenChat});

  /// The running background work.
  final List<BackgroundWork> work;

  /// Opens a subagent's chat.
  final OpenChat? onOpenChat;

  VoidCallback? _open(BuildContext context, BackgroundWork w) {
    final onOpenChat = this.onOpenChat;
    return switch (w) {
      BackgroundShellWork(:final terminal?, :final label) => () => openTerminal(
        context,
        terminal: terminal,
        title: label,
      ),
      BackgroundSubagentWork(:final chat) when onOpenChat != null =>
        () => onOpenChat(chat),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: 'Background work',
    onSelected: (open) => open(),
    itemBuilder: (context) => [
      for (final w in work)
        if (_open(context, w) case final open?)
          PopupMenuItem<VoidCallback>(
            value: open,
            child: Text(backgroundWorkLabel(w)),
          )
        else
          PopupMenuItem<VoidCallback>(
            enabled: false,
            child: Text(backgroundWorkLabel(w)),
          ),
    ],
    child: Chip(
      visualDensity: VisualDensity.compact,
      avatar: const Icon(Icons.motion_photos_on_outlined, size: 16),
      label: Text('${work.length} in background'),
    ),
  );
}

/// A chip per MCP server that needs sign-in or failed. Tapping one that
/// needs sign-in asks for a token.
class McpServerAlertChips extends StatelessWidget {
  /// Creates [McpServerAlertChips] for [alerts].
  const McpServerAlertChips({super.key, required this.alerts, this.onSignIn});

  /// The servers that need attention.
  final List<McpServerAlert> alerts;

  /// Pushes a sign-in token.
  final SignIn? onSignIn;

  @override
  Widget build(BuildContext context) {
    final onSignIn = this.onSignIn;
    return Wrap(
      spacing: 4,
      children: [
        for (final (:server, :message) in alerts)
          Tooltip(
            message: message,
            child: ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                server.state is McpServerAuthRequiredState
                    ? Icons.key
                    : Icons.error_outline,
                size: 16,
              ),
              label: Text(server.name),
              onPressed: switch (server.state) {
                final McpServerAuthRequiredState state when onSignIn != null =>
                  () => onSignIn(AuthChallenge.fromServerState(state)),
                _ => null,
              },
            ),
          ),
      ],
    );
  }
}
