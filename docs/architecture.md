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
- **Connection problems (web transport):** `connection_problems.dart` is
  pure: `normalizeHostUri` takes `http(s)://` as `ws(s)://`,
  `transportProblem` refuses `ws://` to another machine from an `https`
  page (mixed content), and `describeTransportError` explains handshake
  failures (HTTP 401/403, TLS, refused, and on the web the causes a
  browser hides). `webSocketConnector` throws a `ConnectionProblem` with
  that message, which becomes `HostState.error`.
- **Authentication:** `authenticate(resource, token, expiresIn, scopes)`
  pushes a token (AHP-060), which is how a client resumes a tool call
  waiting on MCP sign-in. `expiresIn` is dropped under 0.9.0.
  `oauth.dart` gets tokens: pure helpers (PKCE, metadata URLs,
  `authorizationUrl`, `authorizationCodeFrom`, `tokenFromResponse`,
  `ResourceToken.remainingSeconds`) plus `OAuthHttp` (RFC 8414 discovery,
  RFC 7591 registration, the token endpoint, refresh) and
  `signInWithBrowser`, which runs the authorization code flow with PKCE
  and the RFC 8707 `resource` through a `RedirectReceiver`
  (`LoopbackRedirectReceiver` on `dart:io`). `auth.dart`'s
  `HostAuthenticator` keeps one client's resources signed in: it answers
  `-32007` (the client's `onAuthRequired` hook, after which `_request`
  retries the command once) and `auth/required` (the client's
  `authRequired` stream), refreshes tokens before they expire, pushes
  held tokens after every (re)connect and saves them in a `TokenStore`.
  An interactive callback asks the user when no refresh is possible.
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
  `HostSession`s). `OpenHosts` saves the open hosts' keys
  (`HostStore.saveOpenHosts`) and `restore()` (called by `HomeScreen` on
  start) reconnects them; a remembered host whose connect fails stays
  open, failed, with Retry and Remove on its sidebar row (and its error
  under Recent hosts on the connect screen), while a host that never
  connected is dropped again. The connect screen prefills the most recent
  host and lists the rest; "Add host…" at the end of the sidebar pushes it
  again.
- `lib/src/auth/`: sign-in (AHP-060 to AHP-062). `sign_in_dialog.dart`
  is the dialog ("Sign in with browser" when the resource names an
  authorization server, or paste a token), `signInFromUi` for buttons and
  `promptSignIn` for prompts nobody clicked for (`auth/required`,
  `-32007`), shown on `rootNavigatorKey`. `oauth_browser.dart`
  (`oauthBrowserProvider`) opens the system browser with `url_launcher`
  and starts the platform's redirect receiver: a loopback server on
  native platforms, or `web/oauth_callback.html`, which posts the
  redirect on a `BroadcastChannel`, on the web. `HostConnection` creates
  a `HostAuthenticator` per connection with a `HostTokenStore` (tokens
  per host in the `HostStore`'s secure storage).
- `lib/src/composer/`: `config_fields.dart` is pure: a model's
  `configSchema` and a session config schema become `ConfigField`s, with
  `configValues`, `modelSelection` and `mutableSessionFields`.
  `config_form.dart` renders them (dropdowns, switches, text, and host
  suggestions for `enumDynamic`), and `directory_browser.dart` is the
  `resourceList` folder picker.
- `lib/src/desktop/`: native window setup. `window_bounds.dart` is pure
  (placement encoding, minimum size, whether a saved position is on a
  display); `desktop_window.dart` applies it with `window_manager` and
  saves the placement with `shared_preferences`, and sets the window
  title; `app_menu.dart` is the macOS `PlatformMenuBar` (with the Session
  menu of shortcuts). See [desktop.md](desktop.md).
- `lib/src/shortcuts.dart`: the AV-140 commands (`AppCommand`), their keys
  (`activatorFor`: Cmd on Apple platforms, Ctrl elsewhere) and labels, and
  `appCommandsProvider`, a broadcast of commands. `AppShortcuts` maps the
  keys to commands above the navigator (except on macOS, where the menu
  sends them); the sessions screen handles new session, search and
  next/previous, and the visible session view handles stop and focus
  composer, each only while its route is on top.
- `lib/src/app.dart`: `MaterialApp` with light and dark themes that follow
  the system, titled with the attention count (`windowTitle`, AV-120).
  Shows the connect screen until connected, and restores the hosts that
  were open.
- `lib/src/screens/`: the connect screen and the sessions screen. The
  sessions screen picks a layout tier with `layoutTierFor(width)`:
  compact (< 700 dp) pushes the session onto a new page, medium shows list
  plus detail, wide (≥ 1200 dp) adds a review pane.
- `lib/src/session_list/`: pure, tested view logic:
  `groupHostSessions` (one folder per host and working directory, with
  repository and branch from `project` and `_meta.git`, AV-025),
  `badgesFor` / `needsAttention` (AV-021), `filterSessions` (Active,
  Needs attention, Done, Archived, All; AV-022), `attentionCount` and
  `windowTitle` (AV-120), `session_query.dart` (`SessionSort` and
  `compareSessions`, AV-026; `compareHostSessions`, which puts pinned
  sessions first, AV-028; `parseSessionQuery` and `matchesQuery` for
  title words and `agent:`, `status:`, `repo:`, `host:` qualifiers,
  AV-027), `pinned_sessions.dart` (`withPinned` and the pin set's JSON,
  AV-028), and `formatRelativeTime`. `pinned_store.dart` keeps the pinned
  sessions (by host and session) on this device with `PrefsStore`.
  `session_tree.dart` builds the sidebar tree: `sessionTree` puts each
  open host's folders under it, `sidebarRows` flattens it into host,
  folder, session and empty rows while skipping collapsed hosts and
  folders, and `revealSession` expands the ones holding an opened
  session. `session_list_view.dart` renders the rows lazily (thin rows
  on medium and wide layouts, touch-sized ones on compact layouts);
  host rows show the status with Retry and Remove, and each session row has a menu
  (right-click, long-press, and screen reader actions) to rename (a
  dialog, AV-073), archive, mark read or unread, pin or unpin and select,
  swipes left to archive or
  unarchive, shows a pin marker on pinned rows, and shows checkboxes while
  selecting (AV-024, AV-028, AV-029). The sessions screen adds the search field, sort menu, filter
  chips (with the attention count) and the bulk action bar.
- `lib/src/session_detail/`: the session view. `timeline_items.dart` and
  `chat_commands.dart` are pure: `timelineItems(ChatState)` flattens turns
  into rows, and the command builders return the chat actions to dispatch.
  `session_detail_view.dart` holds the header (the title, which
  `editable_title.dart` turns into a text field when clicked or on
  "Rename…", AV-073; status, activity, Stop,
  archive, mark unread, pin, session details, change counts, background work,
  canvases and MCP server alerts), the chat switcher, the "Waiting for
  you" panel, the reversed timeline that follows new output (AV-066), the
  queued messages and the follow-up box (which syncs the chat's draft),
  with the review pane beside it (wide) or as a tab. On wide layouts a
  `ReviewPaneToggle` right of the header (or Cmd/Ctrl+Alt+B) opens and
  closes the `CollapsibleReviewPane`; whether it is open is
  `reviewPaneOpenProvider` (`review/review_pane_store.dart`), kept with
  `PrefsStore` and closed by default (AV-003).
  `timeline_items.dart` memoizes each finished turn's rows and the rows
  of a whole `turns` list (the reducer keeps both objects while a turn
  streams), so a delta only rebuilds the active turn's rows;
  `TimelineRows` indexes them without copying and finds rows by key for
  the keyed, lazily built list. It also groups consecutive calls of one
  tool (AV-064), adds a "load older turns" row while the host holds
  turns back (AV-068), and ends with a `WorkingItem` while the chat
  works (`isChatWorking`: the `InProgress` bit or an active turn, not
  `InputNeeded`; AV-072). Being the last row of the reversed list, the
  indicator sits at scroll offset 0, so it stays in view whenever the
  user is at the bottom.
  `approval_bar.dart` is the bar under a waiting tool call: Approve/Deny
  or the host's options in groups, the risk assessment, "Edit input" for
  `editable` calls and "Use result"/"Discard result" for results that
  need confirmation. Input request forms sync drafts
  (`chat/inputAnswerChanged`) and take other clients' drafts.
  `tool_previews.dart` renders tool call previews: live terminals,
  mini-diffs and subagent cards. `diff_lines.dart` (pure, with
  `diffutil_dart`) and `diff_view.dart` show diffs, unified or side by
  side, with collapsible unchanged lines; `code_highlight.dart`
  highlights code with `re_highlight` and renders markdown code blocks
  with a copy button; `terminal_text.dart` turns terminal output into
  plain text. `chat_switcher.dart`, `pending_messages.dart` and
  `session_info.dart` are the chat switcher (AV-069), the queued messages
  panel (AV-081; clicking a message opens an inline editor, saved with
  the pure `savePendingEditAction`) and the session details page (working directories,
  canvases, customizations, server tools, active clients).
  `session_inputs.dart` is pure: `sessionPrompts` picks the session's `inputNeeded` entries the
  open chat does not already show (requests from other chats, or not yet
  mirrored), and `mcpServerAlerts` the MCP servers that need sign-in or
  failed. `session_status_widgets.dart` renders them; answers go to the
  request's own chat even when it is not subscribed. The view hides an
  answered entry until the host removes it (`unansweredPrompts`), and
  shows it again when the answer is rejected (`answerUndoneBy`) or the
  host does not remove it within 30 s. `toolClientExecution` entries are
  never prompts: other clients' ones show as "N tools running on another
  client", and one delegated to this app (which provides no tools) is
  turned down with a failed `chat/toolCallComplete`
  (`declineClientExecutionAction`).
  `timeline_parts.dart` renders markdown (`flutter_markdown_plus`), collapsed reasoning, tool call cards with
  Approve/Deny (and Sign in / Cancel for `auth-required` calls, with a
  token dialog), input request forms, errors, grouped tool calls and the
  working indicator (pulsing dots, a static "…" when
  `MediaQuery.disableAnimationsOf` asks for reduced motion);
  markdown code blocks go through `code_highlight.dart`.
- `lib/src/session_detail/todo_list.dart` (pure) recognizes todo tools
  (`TodoWrite`, `update_todo`, `manage_todo_list`, `update_plan`) and
  parses their input into a `TodoList`; `latestTodoList` finds the
  newest one (finished turns searched once per `turns` list).
  `todo_widgets.dart` renders a todo call as a checklist card and the
  open list as a panel above the follow-up box (AV-070).
  `source_links.dart` (pure) reads the pull request
  (`copilot.githubReferences`, `headBranch`) and branch (`git`) from
  `_meta`, shown as header chips (AV-105). The input form lists
  described single-select options and sends free-form text
  (`allowFreeformInput`) with the choice, for plan reviews (AV-046).
- `lib/src/runs/`: parallel runs (AV-045). `run_groups.dart` is pure
  (`RunGroup` of `RunMember`s and a winner, `withGroup`, `withWinner`,
  `groupOf`, `labelsOfRuns`, JSON, `lastReplyOf`); `run_group_store.dart`
  keeps the groups with `PrefsStore`; `runs_editor.dart` is the
  composer's "Add a run" section; `compare_screen.dart` shows the runs
  side by side (subscribing to each run's default chat), picks a winner
  and archives the others.
- `lib/src/notifications/`: local notifications (AV-121).
  `attention_events.dart` is pure (`attentionEvents` from two session
  lists, `NotificationSettings`, `shouldNotify`, `isForeground`,
  payloads); `os_notifier.dart` is the `OsNotifier` interface
  (`requestPermission`, `show`); `notifications.dart` has the
  `LocalNotifier` (on `flutter_local_notifications`, desktop and
  mobile), picks `browser_notifier_web.dart` (the browser's Notification
  API) on the web through a conditional import, and has the permission
  and settings stores, the
  `visibleSessionProvider` the sessions screen keeps current,
  `openSessionRequestsProvider` (sessions to open, from clicks and the
  run comparison) and `AttentionNotifications`, which the app wraps
  around everything to ask for permission at start and watch the merged
  session list. `notification_menu.dart` is the bell menu, with "Allow
  notifications…" while permission is refused.
- `lib/src/prefs.dart`: `PrefsStore`, small non-secret settings in
  `shared_preferences` (memory in tests).
- `lib/src/review/`: the "Files changed" pane (AV-100 to AV-103),
  the wide layout's collapsible pane and its toggle, and
  `review_pane_store.dart` (whether the pane is open, AV-003).
  `review_logic.dart` is pure (which changesets to offer, the URI for the
  chosen turn, counts); `changes_pane.dart` lists files with their change
  kind, counts and "reviewed" boxes and runs host operations.
- `lib/src/session_title.dart` (pure): `renameAction` builds the
  `session/titleChanged` action for a typed title (null when it is empty
  or unchanged), `sessionTitleOf` picks the title to show (the session
  channel's, which carries a pending rename, then the catalogue's), and
  `withMirroredTitle` gives an open session's row that title, so
  `allSessionsProvider` shows a rename in the list before the host
  updates its catalogue (AV-073).
- `lib/src/channels.dart`: `ChannelSubscriber`, which keeps a channel
  subscribed while a widget is mounted, and `resourceTextProvider`, which
  reads `ContentRef` text with `resourceRead`.
- `lib/src/screens/new_session_screen.dart`: the composer (host, agent,
  model and its options, working directory with folder browser and recent
  folders, the agent's session settings from `resolveSessionConfig`,
  prompt). In a session, `message_settings.dart` is the bar above the
  follow-up box that picks the next message's model and options and
  changes `sessionMutable` settings.
