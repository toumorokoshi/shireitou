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
                                 sessionChannels, chatChannels (ChannelMirror)
```

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
  `HostState`, advanced by `reduceSession` and `reduceChat` (a port of the
  protocol's `chatReducer`: turns, `chat/delta` streaming, reasoning, the
  tool call lifecycle, input requests, pending messages, errors). The
  seven `ToolCallState` variants are one flattened `ToolCall` class keyed by
  `status`.
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
- **Creating sessions:** `createSession` retries on `-32003`, then waits for
  the session in the catalogue and returns the URI the host lists
  (`resolveSessionResource` matches pi's `pi:/<id>` to the
  `ahp-session:/<id>` that was sent).
- **Reconnect:** when the socket drops after a successful connect, the client
  retries with exponential backoff (0.5 s doubling to 30 s) using
  `reconnect`, and falls back to `initialize` when the host answers
  `-32008 NotFound` (pi does this after a host restart).
- **URIs are opaque:** pi publishes sessions as `pi:/<id>` even when they
  were created as `ahp-session:/<id>`, so the catalogue is keyed by the
  `resource` the host sends.

## app

- `lib/src/host_connection.dart`: a Riverpod `Notifier<HostState>` that owns
  the `AhpClient`, mirrors its `states` stream, and forwards `openSession`,
  `dispatch` and `startSession` (create, open, send the first prompt).
  Widgets `select` the fields they need, so chat streaming only rebuilds the
  open timeline.
- `lib/src/hosts/`: `saved_hosts.dart` is the pure host list logic
  (`rememberHost`, `forgetHost`, `hostKey` = URL without `tkn`, JSON
  encoding); `host_store.dart` keeps the list in `flutter_secure_storage`
  (migrating the single host older versions saved) behind the
  `savedHostsProvider` notifier. The connect screen prefills the most
  recent host and lists the rest.
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
  `groupSessionsByFolder` (one folder per working directory, AV-025),
  `badgesFor` / `needsAttention` (AV-021), `filterSessions` (Active,
  Needs attention, Archived, All; AV-022), and `formatRelativeTime`.
- `lib/src/session_detail/`: the session view. `timeline_items.dart` and
  `chat_commands.dart` are pure: `timelineItems(ChatState)` flattens turns
  into rows, and the command builders return the chat actions to dispatch.
  `session_detail_view.dart` holds the header (status, activity, Stop,
  archive, mark unread), the reversed timeline that follows new output
  (AV-066), and the follow-up box. `timeline_parts.dart` renders markdown
  (`flutter_markdown_plus`), collapsed reasoning, tool call cards with
  Approve/Deny, input request forms and errors.
- `lib/src/screens/new_session_screen.dart`: the composer (agent, model,
  working directory, prompt).
