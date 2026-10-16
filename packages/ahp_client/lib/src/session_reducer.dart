/// Pure reducer for session channels (AHP-021, AHP-024), ported from
/// `sessionReducer` in `@microsoft/agent-host-protocol@1.0.0`
/// (`types/channels-session/reducer.ts`).
library;

import 'session_status.dart';
import 'wire.dart';

/// The activity bits of [SessionStatus] (`Idle` to `InputNeeded`).
const _activityMask = (1 << 5) - 1;

/// Applies [action] to [state], mirroring the protocol's `sessionReducer`.
///
/// Every 1.0.0 session action is handled. Unknown actions (from a newer
/// host) leave [state] unchanged.
SessionState reduceSession(
  SessionState state,
  SessionAction action,
) => switch (action) {
  SessionReadyAction() => state.copyWith(lifecycle: SessionLifecycle.ready),
  SessionCreationFailedAction(:final error) => state.copyWith(
    lifecycle: SessionLifecycle.failed,
    creationError: error,
  ),
  SessionChatAddedAction(:final summary) => state.copyWith(
    chats: _upsert(state.chats, summary, (c) => c.resource),
  ),
  SessionChatRemovedAction(:final chat) =>
    state.chats.any((c) => c.resource == chat)
        ? state.copyWith(
            chats: [
              for (final c in state.chats)
                if (c.resource != chat) c,
            ],
            defaultChat: state.defaultChat == chat ? null : state.defaultChat,
          )
        : state,
  SessionChatUpdatedAction(:final chat, :final changes) =>
    state.chats.any((c) => c.resource == chat)
        ? state.copyWith(
            chats: [
              for (final c in state.chats)
                c.resource == chat
                    ? ChatSummary.fromJson({
                        ...c.toJson(),
                        ...changes,
                        'resource': chat,
                      })
                    : c,
            ],
          )
        : state,
  SessionChatsReorderedAction(:final chats) => _chatsReordered(state, chats),
  SessionDefaultChatChangedAction(:final defaultChat) => state.copyWith(
    defaultChat: defaultChat,
  ),
  SessionTitleChangedAction(:final title) => state.copyWith(title: title),
  SessionIsReadChangedAction(:final isRead) => state.copyWith(
    status: state.status.withFlag(SessionStatus.isRead, enabled: isRead),
  ),
  SessionIsArchivedChangedAction(:final isArchived) => state.copyWith(
    status: state.status.withFlag(
      SessionStatus.isArchived,
      enabled: isArchived,
    ),
  ),
  SessionActivityChangedAction(:final activity) => state.copyWith(
    activity: activity,
  ),
  SessionChangesetsChangedAction(:final changesets) => state.copyWith(
    changesets: changesets,
  ),
  SessionConfigChangedAction(:final config, :final replace) => switch (state
      .config) {
    null => state,
    final current => state.copyWith(
      config: current.copyWith(
        values: replace ?? false ? {...config} : {...current.values, ...config},
      ),
    ),
  },
  SessionMetaChangedAction(:final meta) => state.copyWith(meta: meta),
  SessionServerToolsChangedAction(:final tools) => state.copyWith(
    serverTools: tools,
  ),
  SessionActiveClientSetAction(:final activeClient) => state.copyWith(
    activeClients: _upsert(
      state.activeClients,
      activeClient,
      (c) => c.clientId,
    ),
  ),
  SessionActiveClientRemovedAction(:final clientId) =>
    state.activeClients.any((c) => c.clientId == clientId)
        ? state.copyWith(
            activeClients: [
              for (final c in state.activeClients)
                if (c.clientId != clientId) c,
            ],
          )
        : state,
  SessionWorkingDirectorySetAction(:final directory) =>
    (state.workingDirectories ?? const []).contains(directory)
        ? state
        : state.copyWith(
            workingDirectories: [...?state.workingDirectories, directory],
          ),
  SessionWorkingDirectoryRemovedAction(:final directory) =>
    state.workingDirectories?.contains(directory) ?? false
        ? state.copyWith(
            workingDirectories: [...state.workingDirectories!]
              ..remove(directory),
          )
        : state,
  SessionWorkingDirectoryReplacedAction(:final directory, :final replacement) =>
    _workingDirectoryReplaced(state, directory, replacement),
  SessionInputNeededSetAction(:final request) => () {
    final inputNeeded = _upsert<SessionInputRequest>(
      state.inputNeeded ?? const [],
      request,
      (r) => r.id,
    );
    return state.copyWith(
      inputNeeded: inputNeeded,
      status: _withInputNeededStatus(state.status, inputNeeded),
    );
  }(),
  SessionInputNeededRemovedAction(:final id) => () {
    final list = state.inputNeeded;
    if (list == null || !list.any((r) => r.id == id)) return state;
    final remaining = [
      for (final r in list)
        if (r.id != id) r,
    ];
    return state.copyWith(
      inputNeeded: remaining.isEmpty ? null : remaining,
      status: _withInputNeededStatus(state.status, remaining),
    );
  }(),
  SessionCustomizationsChangedAction(:final customizations) => state.copyWith(
    customizations: customizations,
  ),
  SessionCustomizationToggledAction(:final id, :final enablement) =>
    _editCustomization(
      state,
      id,
      top: (c) =>
          Customization.fromJson(_withEnablement(c.toJson(), enablement)),
      child: (c) =>
          ChildCustomization.fromJson(_withEnablement(c.toJson(), enablement)),
      firstChildOnly: true,
    ),
  SessionCustomizationUpdatedAction(:final customization) => state.copyWith(
    customizations: _upsert(
      state.customizations ?? const [],
      customization,
      (c) => c.id,
    ),
  ),
  SessionCustomizationRemovedAction(:final id) => _editCustomization(
    state,
    id,
    top: (_) => null,
    child: (_) => null,
  ),
  SessionMcpServerStateChangedAction(
    :final id,
    state: final serverState,
    :final channel,
  ) =>
    _updateMcpServer(
      state,
      id,
      (entry) => entry.copyWith(state: serverState, channel: channel),
    ),
  SessionMcpServerStartRequestedAction(:final id) => _updateMcpServer(
    state,
    id,
    (entry) =>
        entry.copyWith(state: const McpServerStartingState(), channel: null),
  ),
  SessionMcpServerBackgroundRequestedAction(:final id) => _updateMcpServer(
    state,
    id,
    (entry) => switch (entry.state) {
      McpServerStartingState(blocking: true) => entry.copyWith(
        state: const McpServerStartingState(blocking: false),
      ),
      _ => entry,
    },
  ),
  SessionMcpServerStopRequestedAction(:final id) => _updateMcpServer(
    state,
    id,
    (entry) =>
        entry.copyWith(state: const McpServerStoppedState(), channel: null),
  ),
  SessionActionUnknown() => state,
};

/// [reduceSession] over a raw JSON action, for [ChannelMirror]s.
SessionState reduceSessionJson(SessionState state, JsonMap action) =>
    reduceSession(state, SessionAction.fromJson(action));

/// Replaces the entry of [list] with [entry]'s key, or appends [entry].
List<T> _upsert<T>(List<T> list, T entry, Object Function(T) key) {
  final k = key(entry);
  return list.any((e) => key(e) == k)
      ? [for (final e in list) key(e) == k ? entry : e]
      : [...list, entry];
}

/// `session/chatsReordered`: only a permutation of the current chats is
/// applied.
SessionState _chatsReordered(SessionState state, List<String> order) {
  final list = state.chats;
  if (order.length != list.length || order.toSet().length != list.length) {
    return state;
  }
  final byResource = {for (final c in list) c.resource: c};
  final reordered = <ChatSummary>[];
  for (final resource in order) {
    final summary = byResource[resource];
    if (summary == null) return state;
    reordered.add(summary);
  }
  final unchanged = [
    for (var i = 0; i < list.length; i++) identical(reordered[i], list[i]),
  ].every((same) => same);
  return unchanged ? state : state.copyWith(chats: reordered);
}

SessionState _workingDirectoryReplaced(
  SessionState state,
  String directory,
  String replacement,
) {
  final list = state.workingDirectories;
  final index = list?.indexOf(directory) ?? -1;
  if (list == null || index < 0) return state;
  final replacementIndex = list.indexOf(replacement);
  if (replacementIndex >= 0 && replacementIndex < index) {
    return state.copyWith(workingDirectories: [...list]..removeAt(index));
  }
  return state.copyWith(
    workingDirectories: [
      for (var i = 0; i < list.length; i++)
        if (i == index) replacement else if (list[i] != replacement) list[i],
    ],
  );
}

/// Whether [request] waits on the user. Client tool execution is work
/// delegated to a client, not a prompt.
bool _awaitsUser(SessionInputRequest request) =>
    request is! SessionToolClientExecutionRequest;

/// Reflects the session's input queue in the activity bits of [status]:
/// any entry that waits on the user means `InputNeeded`; draining them
/// falls back to `InProgress` (an idle session stays idle).
SessionStatus _withInputNeededStatus(
  SessionStatus status,
  List<SessionInputRequest> inputNeeded,
) {
  if (inputNeeded.any(_awaitsUser)) {
    return SessionStatus(
      (status.bits & ~_activityMask) | SessionStatus.inputNeeded.bits,
    );
  }
  final inputOnly =
      SessionStatus.inputNeeded.bits & ~SessionStatus.inProgress.bits;
  return SessionStatus(status.bits & ~inputOnly);
}

/// The JSON of a customization with [enablement] applied: plugins and MCP
/// servers take the decisions as-is, the rest keep the legacy `enabled`
/// flag, taken from the first decision.
JsonMap _withEnablement(
  JsonMap json,
  List<CustomizationEnablement> enablement,
) => switch (json['type']) {
  'plugin' || 'mcpServer' => {
    for (final e in json.entries)
      if (e.key != 'enablement') e.key: e.value,
    if (enablement.isNotEmpty)
      'enablement': [for (final e in enablement) e.toJson()],
  },
  _ => {...json, 'enabled': enablement.firstOrNull?.enabled ?? true},
};

List<ChildCustomization>? _childrenOf(Customization c) => switch (c) {
  PluginCustomization(:final children) ||
  DirectoryCustomization(:final children) => children,
  _ => null,
};

Customization _withChildren(
  Customization c,
  List<ChildCustomization> children,
) => switch (c) {
  PluginCustomization() => c.copyWith(children: children),
  DirectoryCustomization() => c.copyWith(children: children),
  _ => c,
};

/// Edits the customization [id]: the top-level entry with [top] when there
/// is one, else the matching child of each container (only the first one
/// with [firstChildOnly]) with [child]. MCP server containers have no
/// children. An edit returns the replacement, or null to remove the entry.
SessionState _editCustomization(
  SessionState state,
  String id, {
  required Customization? Function(Customization entry) top,
  required ChildCustomization? Function(ChildCustomization entry) child,
  bool firstChildOnly = false,
}) {
  final list = state.customizations;
  if (list == null) return state;
  final topIndex = list.indexWhere((c) => c.id == id);
  if (topIndex >= 0) {
    final updated = top(list[topIndex]);
    if (identical(updated, list[topIndex])) return state;
    return state.copyWith(
      customizations: [
        for (var i = 0; i < list.length; i++)
          if (i != topIndex) list[i] else ?updated,
      ],
    );
  }
  var changed = false;
  final next = [
    for (final container in list)
      switch (_childrenOf(container)) {
        final children?
            when !(firstChildOnly && changed) &&
                children.any((c) => c.id == id) =>
          () {
            final index = children.indexWhere((c) => c.id == id);
            final updated = child(children[index]);
            if (identical(updated, children[index])) return container;
            changed = true;
            return _withChildren(container, [
              for (var i = 0; i < children.length; i++)
                if (i != index) children[i] else ?updated,
            ]);
          }(),
        _ => container,
      },
  ];
  return changed ? state.copyWith(customizations: next) : state;
}

/// Updates the MCP server customization [id], top-level or a container's
/// child. Other customization kinds with that ID are left alone.
SessionState _updateMcpServer(
  SessionState state,
  String id,
  McpServerCustomization Function(McpServerCustomization entry) update,
) => _editCustomization(
  state,
  id,
  top: (c) => c is McpServerCustomization ? update(c) : c,
  child: (c) => c is McpServerCustomization ? update(c) : c,
);
