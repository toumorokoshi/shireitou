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
