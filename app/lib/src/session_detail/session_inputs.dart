/// Pure view logic for session-level state shown around the timeline:
/// input requests from `SessionState.inputNeeded`, background work, MCP
/// servers that need attention, and change counts.
library;

import 'package:ahp_client/ahp_client.dart';

/// The session's open input requests that the timeline of [chat] (the open
/// chat, if any) does not show, in the host's order.
///
/// A request whose tool call or input request is anywhere in the open
/// chat is left out: the timeline shows it, and once answered there (the
/// answer is applied at once, before the host removes the entry) it must
/// not come back here. Client tool execution entries are left out too:
/// they are work for a client that provides the tool, not questions.
List<SessionInputRequest> sessionPrompts(
  SessionState? session,
  ChatState? chat,
) {
  final parts = [
    for (final turn in chat?.turns ?? const <Turn>[]) ...turn.responseParts,
    ...?chat?.activeTurn?.responseParts,
  ];
  bool inChat(String entryChat, bool Function(ResponsePart) matches) =>
      entryChat == chat?.resource && parts.any(matches);
  bool hasToolCall(String entryChat, String id) => inChat(
    entryChat,
    (p) => p is ToolCallResponsePart && p.toolCall.toolCallId == id,
  );
  return [
    for (final entry in session?.inputNeeded ?? const <SessionInputRequest>[])
      if (switch (entry) {
        SessionToolClientExecutionRequest() => false,
        SessionChatInputRequest(:final chat, :final request) => !inChat(
          chat,
          (p) => p is InputRequestResponsePart && p.request.id == request.id,
        ),
        SessionToolConfirmationRequest(:final chat, :final toolCall) =>
          !hasToolCall(chat, toolCall.toolCallId),
        SessionToolAuthenticationRequest(:final chat, :final toolCall) =>
          !hasToolCall(chat, toolCall.toolCallId),
        SessionInputRequestUnknown() => true,
      })
        entry,
  ];
}

/// The action types that answer a "Waiting for you" entry: approve or
/// deny a tool call or its result, answer or decline input, or give up
/// on a sign-in.
const answerActionTypes = {
  'chat/toolCallConfirmed',
  'chat/toolCallResultConfirmed',
  'chat/inputCompleted',
  'chat/toolCallComplete',
};

/// An answer sent from the "Waiting for you" panel that the host has not
/// confirmed yet (by removing the entry): the chat it went to and its
/// `clientSeq`, so a rejection can be matched to it.
typedef AnsweredPrompt = ({String chat, int clientSeq});

/// [prompts] without the entries in [answered], which stay hidden while
/// the host has not removed them (the client may not mirror the chat the
/// answer went to, so nothing else would hide them).
List<SessionInputRequest> unansweredPrompts(
  List<SessionInputRequest> prompts,
  Map<String, AnsweredPrompt> answered,
) => [
  for (final p in prompts)
    if (!answered.containsKey(p.id)) p,
];

/// The ids in [answered] that [session] no longer lists: the host
/// resolved them, so they need no tracking.
Set<String> resolvedAnswers(
  Map<String, AnsweredPrompt> answered,
  SessionState? session,
) {
  final open = {
    for (final e in session?.inputNeeded ?? const <SessionInputRequest>[]) e.id,
  };
  return {
    for (final id in answered.keys)
      if (!open.contains(id)) id,
  };
}

/// The entry id of the answer in [answered] that [failure] undid, if any.
String? answerUndoneBy(
  Map<String, AnsweredPrompt> answered,
  ActionFailure failure,
) => answered.entries
    .where(
      (e) =>
          e.value.chat == failure.channel &&
          e.value.clientSeq == failure.clientSeq,
    )
    .firstOrNull
    ?.key;

/// The session's client tool executions (`toolClientExecution` entries):
/// running tools that a client, not the host, executes. They are not
/// questions, so they never show as "Waiting for you".
List<SessionToolClientExecutionRequest> clientExecutions(
  SessionState? session,
) => [...?session?.inputNeeded?.whereType<SessionToolClientExecutionRequest>()];

/// The tool executions delegated to this client ([clientId]). This app
/// provides no client tools, so a host should never delegate one; if it
/// does, the app reports failure ([declineClientExecutionAction]) rather
/// than leave the turn waiting.
List<SessionToolClientExecutionRequest> ownClientExecutions(
  SessionState? session,
  String? clientId,
) => [
  for (final e in clientExecutions(session))
    if (clientId != null && e.clientId == clientId) e,
];

/// Executions delegated to other clients, shown as "running on another
/// client".
List<SessionToolClientExecutionRequest> otherClientExecutions(
  SessionState? session,
  String? clientId,
) => [
  for (final e in clientExecutions(session))
    if (e.clientId != clientId) e,
];

/// The failed `chat/toolCallComplete` that turns down [entry]: the
/// execution path the protocol prescribes for the owning client, with
/// an error saying that this client has no tools.
JsonMap declineClientExecutionAction(SessionToolClientExecutionRequest entry) =>
    ChatToolCallCompleteAction(
      turnId: entry.turnId,
      toolCallId: entry.toolCall.toolCallId,
      result: const ToolCallResult(
        success: false,
        pastTenseMessage: PlainString('Not run: shireitou provides no tools'),
        error: ToolCallError(
          message: 'This client (shireitou) does not provide client tools.',
          code: 'unsupported',
        ),
      ),
    ).toJson();

/// The title of [chat] in [session], for labelling a request from a chat
/// that is not open.
String chatTitleOf(SessionState? session, String chat) =>
    session?.chats.where((c) => c.resource == chat).firstOrNull?.title ?? chat;

/// "+3 −1 · 1 file": [changes] for a header, or null when there are none.
String? changesLabel(ChangesSummary? changes) {
  if (changes == null) return null;
  final files = changes.files;
  return [
    '+${changes.additions ?? 0} −${changes.deletions ?? 0}',
    if (files != null) '$files ${files == 1 ? 'file' : 'files'}',
  ].join(' · ');
}

/// A short label for background [work]: "Shell: npm test" or
/// "Subagent: Explore".
String backgroundWorkLabel(BackgroundWork work) => switch (work) {
  BackgroundShellWork(:final label) => 'Shell: $label',
  BackgroundSubagentWork(:final label) => 'Subagent: $label',
  BackgroundWorkUnknown(:final label) => label,
};

/// An MCP server that needs the user: waiting for sign-in, or failed.
typedef McpServerAlert = ({McpServerCustomization server, String message});

/// The session's MCP servers (top-level or inside plugins and directories)
/// that need sign-in or failed to start.
List<McpServerAlert> mcpServerAlerts(SessionState? session) => [
  for (final server in _mcpServers(session?.customizations ?? const []))
    if (switch (server.state) {
          McpServerAuthRequiredState(:final description, :final resource) =>
            description ??
                'Sign in to ${resource.resourceName ?? resource.resource}',
          McpServerErrorState(:final error) => 'Failed: ${error.message}',
          _ => null,
        }
        case final message?)
      (server: server, message: message),
];

Iterable<McpServerCustomization> _mcpServers(
  List<Customization> customizations,
) sync* {
  for (final c in customizations) {
    switch (c) {
      case McpServerCustomization():
        yield c;
      case PluginCustomization(:final children) ||
          DirectoryCustomization(:final children):
        yield* (children ?? const []).whereType<McpServerCustomization>();
      case CustomizationUnknown():
        break;
    }
  }
}
