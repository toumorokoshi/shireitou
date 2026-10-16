# Architecture

shireitou is split into a pure-Dart protocol client and a Flutter app. Both
follow the project's tenet of keeping state and I/O at the edges and protocol
logic in pure functions.

## packages/ahp_client

```
WebSocket ──► json_rpc_2 Peer ──► AhpClient (I/O edge)
                                     │  calls pure functions:
                                     │  applyInitializeResult, applyEnvelope,
                                     │  applySnapshot, applyDispatchedAction,
                                     │  applyRootNotification, applyReconnectResult
                                     ▼
                               HostState (immutable) ──► states stream
                                 root, sessions (catalogue),
                                 session, chat, terminal, changeset and
                                 canvas channels (ChannelMirror each)
```

- **Wire types:** generated from the protocol's 1.0.0 JSON Schemas into
  `lib/src/generated/` by `packages/ahp_wire_gen` (see
  [wire-types.md](wire-types.md)): immutable classes with
  `fromJson`/`toJson`/`copyWith`, sealed classes for `oneOf` unions (with
  an `…Unknown` fallback member), and enums. `wire.dart` re-exports them
  with a few hand-written helpers. Snapshots and action envelopes keep the
  channel state and action as JSON; the reducers decode them with
  `RootState`/`SessionState`/`ChatState` and the channel's action union
  (`RootAction`, `SessionAction`, `ChatAction`).
- **Transport and framing:** `web_socket_channel` opens the socket and
  `json_rpc_2`'s `Peer` handles JSON-RPC 2.0 in both directions (requests,
  responses, notifications). The connector is injectable, so tests use an
  in-memory `StreamChannelController` with a fake host peer.
- **Handshake:** `initialize` offers `['1.0.0', '0.9.0']` and subscribes to
  `ahp-root://`. The token is carried in the URL's `tkn` query parameter;
  `handshakeFor(uri, TokenTransport)` (pure) decides the upgrade request.
  On native platforms (`transport_io.dart`, `IOWebSocketChannel`) the token
  is also sent as `Authorization: Bearer <token>`; on web
  (`transport_web.dart`, chosen by a conditional import) it stays in `tkn`
  only, since browsers cannot set upgrade headers (AHP-002).
- **State:** `HostState` holds the connection status, the root state, the
  session catalogue, and the last `serverSeq`. It is advanced only by pure
  functions in `host_state.dart`, `root_reducer.dart` and
  `session_catalogue.dart`.
- **Session catalogue:** the root channel's `RootState` does not contain the
  session list. The client loads it with `listSessions` (following
  `nextCursor`) and keeps it current from the `root/sessionAdded`,
  `root/sessionRemoved` and `root/sessionSummaryChanged` notifications.
  Those notifications are not replayed by `reconnect`, so the client reloads
  the list after every reconnect.
- **Session and chat channels:** `openSession(uri)` subscribes to the
  session channel, then to its `defaultChat` (pi publishes it as
  `ahp-chat://default/<base64url(pi:/<id>)>`). Their snapshots become
  `ChannelMirror<SessionState>` and `ChannelMirror<ChatState>` entries in
  `HostState`, advanced by `reduceSession` and `reduceChat`, ports of the
  protocol's `sessionReducer` and `chatReducer` that handle every 1.0.0
  action: turns, `chat/delta` streaming, reasoning, the tool call
  lifecycle (including MCP `auth-required`), input requests, pending
  messages and their order, background work, changesets, canvases,
  working directories, drafts; and on the session, chats and their order,
  customizations and MCP server state, server tools, active clients,
  working directories, `_meta` and the session-level `inputNeeded` list,
  which also sets the `InputNeeded` status bit. Tool calls are the
  generated `ToolCallState` sealed union, one class per lifecycle status.
- **Terminal, changeset and canvas channels:** `subscribe(uri, kind:)`
  with `ChannelKind.terminal`, `.changeset` or `.canvas` mirrors them too,
  advanced by `reduceTerminal` (`terminal_reducer.dart`, a port of
  `terminalReducer`), `reduceChangeset` and `reduceCanvasJson`
  (`changeset_reducer.dart`). Every mirrored kind goes through one
  generic `updateMirror`. `changesets.dart` expands a `Changeset`'s URI
  template (`{turnId}`, `{originalTurnId}`/`{modifiedTurnId}`) and
  classifies file edits (created, deleted, renamed, modified).
  `readResource` (`resourceRead`), `invokeChangesetOperation` and
  `moveChat` (1.0.0 only; `UnsupportedFeatureError` under 0.9.0) are
  plain requests.
- **Windowed history (AHP-029):** a chat snapshot may hold only the
  newest turns and a `turnsNextCursor`; `loadOlderTurns(chat)` sends
  `fetchTurns` with it (one at a time per chat), and the host prepends
  the page with `chat/turnsLoaded` before answering.
- **Write-ahead dispatch (AHP-022):** `dispatch(channel, action)` sends a
  `dispatchAction` notification with the next `clientSeq` and applies the
  action to the channel's mirror at once. A `ChannelMirror` holds the
  confirmed state plus the pending `(clientSeq, action)` pairs; its visible
  `state` is the confirmed state with the pending actions replayed. The
  host's echo (same `origin.clientId` and `clientSeq`) removes the pending
  action and applies it to the confirmed state; a `rejectionReason` only
  removes it, which rolls the change back. Sending a message is
  `chat/turnStarted`, stopping is `chat/turnCancelled`, approvals are
  `chat/toolCallConfirmed` / `chat/toolCallResultConfirmed`, answers are
  `chat/inputCompleted`, and read/archive are `session/isReadChanged` /
  `session/isArchivedChanged`.
- **Undone actions:** a pending action is rolled back when the host
  rejects it, when no echo arrives within `pendingActionTimeout` (30 s; a
  one-shot timer per action calls the pure `expirePendingAction`), or when
  the client reconnects (`clearAllPendingActions`, after the replay has
  echoed whatever the host accepted; before a snapshot replaces the
  mirrors). Each one is an `ActionFailure` on `AhpClient.failures`, which
  the app shows as a snackbar (`connection_notices.dart`). A late echo
  still applies, since the host's state wins. `dispatch` is refused while
  reconnecting.
- **Protocol versions:** `protocol_version.dart` lists what 1.0.0 added
  over 0.9.0 (`actionsAddedIn100`, `ProtocolFeature`). Under 0.9.0,
  `applyEnvelope` ignores those actions and `dispatch` throws
  `UnsupportedActionError` for them; the app shows an "AHP 0.9.0" chip.
  See the spec's "0.9.0 compatibility" section.
- **Authentication:** `authenticate(resource, token)` pushes a token
  (AHP-060), which is how a client resumes a tool call waiting on MCP
  sign-in. `expiresIn` is dropped under 0.9.0.
- **Creating sessions:** `createSession` retries on `-32003`, then waits for
  the session in the catalogue and returns the URI the host lists
  (`resolveSessionResource` matches pi's `pi:/<id>` to the
  `ahp-session:/<id>` that was sent). Meanwhile it subscribes to the sent
  URI, so `session/creationFailed` (or a snapshot whose `lifecycle` is
  `failed`) throws `SessionCreationFailedError` at once; the pure
  `creationOutcome` (`session_creation.dart`) decides. A second subscriber
  to a channel waits for the first one's snapshot.
- **Composer commands:** `listDirectory` (`resourceList`),
  `resolveSessionConfig` and `sessionConfigCompletions` are plain
  requests; `isMethodNotFound` tells an optional command the host lacks.
- **Reconnect:** when the socket drops after a successful connect, the client
  retries with exponential backoff (0.5 s doubling to 30 s) using
  `reconnect`, and falls back to `initialize` when the host answers
  `-32008 NotFound` (pi does this after a host restart). Channels in the
  replay's `missing` list, and mirrored session or chat channels that a
  snapshot result or the `initialize` fallback has no snapshot for
  (`unresumedChannels`; only field-less channels may omit one), are
  unsubscribed, unmirrored and recorded in
  `HostState.missingChannels` (cleared by subscribing again); the session
  view then says the session is gone.
- **Liveness:** while connected the client sends `ping` every
  `pingInterval` (15 s). No answer within `pingTimeout` (10 s) drops the
  socket and starts the reconnect loop, so a dead socket (sleeping laptop,
  dropped Wi-Fi, a proxy that swallowed the close) is noticed within about
  25 s instead of waiting for TCP. Any JSON-RPC answer, even an error,
  counts as alive (`isLivenessFailure`).
- **URIs are opaque:** pi publishes sessions as `pi:/<id>` even when they
  were created as `ahp-session:/<id>`, so the catalogue is keyed by the
  `resource` the host sends.

## packages/ahp_fake_host

A scripted AHP host in Dart for tests, built on `ahp_client`'s generated
types and reducers. It asks for approvals, input, MCP sign-in, streams
terminals, edits files into changesets, spawns subagent chats and runs
background work when a message names the flow, and serves a windowed
long session. See [fake-host.md](fake-host.md).

## packages/ahp_wire_gen

A pure-Dart generator, run by `just codegen`, that reads the vendored JSON
Schemas (`schema/1.0.0/`) and writes the `ahp_client` wire types. It is
split into a pure `analyze` step (schemas to a model of classes, unions and
enums, using the settings in `config.dart`) and a pure `emit` step (model to
Dart source); `bin/generate.dart` does the file I/O. See
[wire-types.md](wire-types.md).

## app

- `lib/src/host_connection.dart`: `hostConnectionProvider`, a Riverpod
  `Notifier<HostState>` family keyed by host (the URL without its token),
  each owning one `AhpClient`, mirroring its `states` stream, and
  forwarding `openSession`, `dispatch`, the composer commands and
  `startSession` (create with settings, open, send the first prompt with
  the model). Widgets `select` the fields they need, so chat streaming only
  rebuilds the open timeline. `HostScope` (an `InheritedWidget`) tells the
  session view and everything under it which host it shows
  (`context.host`); pages and dialogs pushed from there wrap themselves in
  one.
- `lib/src/hosts/`: `saved_hosts.dart` is the pure host list logic
  (`rememberHost`, `forgetHost`, `hostKey` = URL without `tkn`, JSON
  encoding); `host_store.dart` keeps the list in `flutter_secure_storage`
  (migrating the single host older versions saved) behind the
  `savedHostsProvider` notifier, and reports storage errors (a locked
  keyring) to `hostStorageProblemProvider`, shown by `HostStorageBanner`
  with Retry. `open_hosts.dart` holds the connected hosts
  (`openHostsProvider`), their status and labels (`hostInfosProvider`,
  pure `hostLabels`) and the merged inbox (`allSessionsProvider` of
  `HostSession`s). The connect screen prefills the most recent host and
  lists the rest; "Add host…" in the host switcher pushes it again.
- `lib/src/composer/`: `config_fields.dart` is pure: a model's
  `configSchema` and a session config schema become `ConfigField`s, with
  `configValues`, `modelSelection` and `mutableSessionFields`.
  `config_form.dart` renders them (dropdowns, switches, text, and host
  suggestions for `enumDynamic`), and `directory_browser.dart` is the
  `resourceList` folder picker.
- `lib/src/desktop/`: native window setup. `window_bounds.dart` is pure
  (placement encoding, minimum size, whether a saved position is on a
  display); `desktop_window.dart` applies it with `window_manager` and
  saves the placement with `shared_preferences`; `app_menu.dart` is the
  macOS `PlatformMenuBar`. See [desktop.md](desktop.md).
- `lib/src/app.dart`: `MaterialApp` with light and dark themes that follow
  the system. Shows the connect screen until connected.
- `lib/src/screens/`: the connect screen and the sessions screen. The
  sessions screen picks a layout tier with `layoutTierFor(width)`:
  compact (< 700 dp) pushes the session onto a new page, medium shows list
  plus detail, wide (≥ 1200 dp) adds a review pane.
- `lib/src/session_list/`: pure, tested view logic:
  `groupHostSessions` (one folder per host and working directory, with
  repository and branch from `project` and `_meta.git`, AV-025),
  `badgesFor` / `needsAttention` (AV-021), `filterSessions` (Active,
  Needs attention, Archived, All; AV-022), and `formatRelativeTime`.
- `lib/src/session_detail/`: the session view. `timeline_items.dart` and
  `chat_commands.dart` are pure: `timelineItems(ChatState)` flattens turns
  into rows, and the command builders return the chat actions to dispatch.
  `session_detail_view.dart` holds the header (status, activity, Stop,
  archive, mark unread, session details, change counts, background work,
  canvases and MCP server alerts), the chat switcher, the "Waiting for
  you" panel, the reversed timeline that follows new output (AV-066), the
  queued messages and the follow-up box (which syncs the chat's draft),
  with the review pane beside it (wide) or as a tab.
  `timeline_items.dart` memoizes each finished turn's rows and the rows
  of a whole `turns` list (the reducer keeps both objects while a turn
  streams), so a delta only rebuilds the active turn's rows;
  `TimelineRows` indexes them without copying and finds rows by key for
  the keyed, lazily built list. It also groups consecutive calls of one
  tool (AV-064) and adds a "load older turns" row while the host holds
  turns back (AV-068).
  `tool_previews.dart` renders tool call previews: live terminals,
  mini-diffs and subagent cards. `diff_lines.dart` (pure, with
  `diffutil_dart`) and `diff_view.dart` show diffs, unified or side by
  side, with collapsible unchanged lines; `code_highlight.dart`
  highlights code with `re_highlight` and renders markdown code blocks
  with a copy button; `terminal_text.dart` turns terminal output into
  plain text. `chat_switcher.dart`, `pending_messages.dart` and
  `session_info.dart` are the chat switcher (AV-069), the queued messages
  panel (AV-081) and the session details page (working directories,
  canvases, customizations, server tools, active clients).
  `session_inputs.dart` is pure: `sessionPrompts` picks the session's `inputNeeded` entries the
  open chat does not already show (requests from other chats, or not yet
  mirrored), and `mcpServerAlerts` the MCP servers that need sign-in or
  failed. `session_status_widgets.dart` renders them; answers go to the
  request's own chat even when it is not subscribed.
  `timeline_parts.dart` renders markdown (`flutter_markdown_plus`), collapsed reasoning, tool call cards with
  Approve/Deny (and Sign in / Cancel for `auth-required` calls, with a
  token dialog), input request forms, errors and grouped tool calls;
  markdown code blocks go through `code_highlight.dart`.
- `lib/src/review/`: the "Files changed" pane (AV-100 to AV-103).
  `review_logic.dart` is pure (which changesets to offer, the URI for the
  chosen turn, counts); `changes_pane.dart` lists files with their change
  kind, counts and "reviewed" boxes and runs host operations.
- `lib/src/channels.dart`: `ChannelSubscriber`, which keeps a channel
  subscribed while a widget is mounted, and `resourceTextProvider`, which
  reads `ContentRef` text with `resourceRead`.
- `lib/src/screens/new_session_screen.dart`: the composer (host, agent,
  model and its options, working directory with folder browser and recent
  folders, the agent's session settings from `resolveSessionConfig`,
  prompt). In a session, `message_settings.dart` is the bar above the
  follow-up box that picks the next message's model and options and
  changes `sessionMutable` settings.
