# Fake host

`packages/ahp_fake_host` is a scripted AHP 1.0.0 host written in Dart. It
exists because pi-agent-host-protocol runs tools without asking and sends
no elicitations, so tool approvals (AV-083), input requests (AV-084),
session-level input requests and MCP sign-in (AHP-062) could not be
exercised against a real host.

## How it works

- `FakeAhpHost` serves JSON-RPC over WebSocket (`dart:io` `HttpServer`,
  `json_rpc_2` `Peer`), or over any `StreamChannel<String>` with `serve`.
  It answers `initialize` (1.0.0 or 0.9.0), `reconnect` (see
  "Reconnects" below), `listSessions`, `subscribe`,
  `unsubscribe`, `createSession`, `fetchTurns`, `authenticate`, `ping`,
  `dispatchAction`, `resourceRead` (the two sides of scripted file edits),
  `invokeChangesetOperation`, `moveChat` (reorders a movable chat
  within its session; other destinations are refused), `resourceList`,
  `resolveSessionConfig` and `sessionConfigCompletions` (see "Starting
  sessions" below).
- It keeps real protocol state (`RootState`, `SessionState`, `ChatState`,
  `TerminalState`, `ChangesetState`, `CanvasState`, catalogue
  `SessionSummary`s) and advances it with the client package's own
  reducers, so its envelopes are what a reducer-faithful host would send. Catalogue entries follow the default
  chat's status and the session's `inputNeeded` list
  (`root/sessionSummaryChanged`).
- Client actions from `clientDispatchable` are echoed with their
  `origin`; anything else (or an unknown channel, or a second
  `chat/turnStarted` while a turn runs, or a type in the mutable
  `rejectTypes` set, which tests use to check a client's rollback) is
  echoed with a `rejectionReason` to the sender only.
- A token, when set, is accepted in the `tkn` query parameter or an
  `Authorization: Bearer` header.
- `authenticate` checks the token: one issued by the host's fake
  authorization server (below) for that resource, or `fakePersonalToken`
  (`mcp-token`, a stand-in for a pasted personal access token), unless
  the `expire` flow expired it. Anything else is `-32007` with
  `AuthRequiredErrorData`; an unknown resource is `-32602`; an empty
  token signs the connection out (recorded as `#revoke`). Accepted
  tokens are kept per connection and recorded as `#authenticate` (with
  `expiresIn`, `scopes` and the `clientId`).
- `name` sets `serverInfo.name` and `titlePrefix` prefixes the seeded
  sessions' titles, so a second instance (for multi-host tests) is told
  apart: `FakeAhpHost(name: 'second-host', titlePrefix: 'Other ')`.
- It starts with two sessions and two agents: `fake`, and `fake-secure`
  ("Secured agent"), whose `protectedResources` require a token for
  `https://agent.example.com`; `createSession` for it on a connection
  without one fails with `-32007`. The sessions:
  - `ahp-session:/scripted` ("Scripted session") with chat
    `ahp-chat:/scripted`, where the flows below run.
  - `ahp-session:/long` ("Long session") with 60 finished turns, of which
    the chat state holds the newest 20 plus `turnsNextCursor`;
    `fetchTurns` pages in 20 more each time (`chat/turnsLoaded`), so
    clients can test windowed history (AHP-029, AV-068).
- Every session advertises two changesets: `Session changes`
  (`ahp-changeset:/<id>/session`, with per-file review and the operations
  `commit` (changeset scope, asks for confirmation; clears the changeset)
  and `revert` (file scope; removes the file)), and `Turn changes`
  (`ahp-changeset:/<id>/turn/{turnId}`). It also lists two server tools
  and a ready MCP server customization ("Example Docs").

## Fake OAuth authorization server

`FakeOAuthServer` (`fake_oauth_server.dart`) runs in the same process
and starts with the host (`start`), on another loopback port; the
protected resources' metadata name it in `authorization_servers`. It
serves:

- `/.well-known/oauth-authorization-server` (RFC 8414): `S256` only, the
  scopes `docs.read`, `docs.search` and `agent`, and client
  authentication `none`, `client_secret_basic` or `client_secret_post`.
- `POST /register` (RFC 7591): registers a public client for its
  `redirect_uris`. A confidential client, `preregisteredClientId` with
  `preregisteredClientSecret`, is always known, for a host-provided
  `McpOAuthClient`.
- `GET /authorize`: checks the client and redirect URI (loopback
  redirects match on everything but the port, RFC 8252), requires PKCE
  `S256`, and approves at once with a `302` to the redirect URI (or
  refuses with `access_denied` while `denyNext` is set). A test plays
  the browser by fetching this URL and following the redirect.
- `POST /token`: `authorization_code` (verifies the client, the redirect
  URI, the PKCE verifier against the challenge and the `resource`) and
  `refresh_token` (rotates the refresh token). Access tokens live for
  `tokenLifetime` (the host's `tokenLifetime`, one hour by default).

`log` lists what happened (`register`, `authorize`, `token`, `refresh`,
`deny`, `reject …`), `accepts(token, resource)` checks a token and
`expire(token)` ends one early. Responses allow any origin (CORS), so
the web app can use it.

## Starting sessions

- **Models:** the agent offers `scripted`, whose `configSchema` has a
  `thinkingLevel` choice (`low`, `medium` (default), `high`; the property
  name VS Code's and pi's agents use), and `scripted-fast` without options.
- **Filesystem:** `resourceList` serves an in-memory tree around
  `defaultDirectory` (`/workspace` with `README.md`, `packages/api`,
  `packages/web`) plus `/srv/scratch`; other URIs are `-32008`.
- **Session settings:** `resolveSessionConfig` returns `mode`
  (`interactive`/`plan`/`autopilot`, `sessionMutable`, as VS Code's agent
  host names it) and, for folders inside `/workspace` (a "repository"),
  `branch` (`enumDynamic`; `sessionConfigCompletions` filters `main`,
  `feature/login`, `fix/crash`). `values` fills in the defaults. The
  session keeps them as `SessionState.config`; `session/configChanged` is
  accepted for `sessionMutable` settings and rejected otherwise.
- **Worktree metadata:** sessions in the repository list `project`
  (`/workspace`, "workspace") and the branch and GitHub repository in
  `_meta.git` (`branchName`, `githubOwner: example`,
  `githubRepo: workspace`), the shape VS Code's agent host uses.
- **Creation failure:** `createSession` in a folder the tree does not have
  succeeds, then the host dispatches `session/creationFailed`
  ("No such folder: …") on the session channel a step later and never
  lists the session, the way pi fails.

## Scripted flows

`chat/turnStarted` runs the flows whose keyword is a word of the message
(`scenariosFor`), in this order, then completes the turn. Queued messages
start the next turn, like a real host. A message without a keyword gets an
echo that lists the keywords.

| Keyword      | What the host does                                                                                                                                                                                                                                                                                                                                                                  |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tool`       | Starts a `bash` call that waits for confirmation, and lists it in `SessionState.inputNeeded` (`toolConfirmation`). Approved: completes it and says "The folder has 3 entries."; denied: "OK, I did not run it."                                                                                                                                                                     |
| `ask`        | `chat/inputRequested` with text (required), single-select (required), boolean and integer questions, also in `inputNeeded` (`chatInput`). Replies with the answers (`name=v1, env=staging, ...`) or "You declined, so I stopped."                                                                                                                                                   |
| `side`       | Adds a second, movable chat ("Reviewer", origin `sideChat`) and asks a boolean question there. The client is not subscribed to it, so the question only arrives through the session's `inputNeeded`; the answer is dispatched to that chat.                                                                                                                                         |
| `auth`       | An MCP tool call (`search_docs`) that goes `running` then `auth-required` (`chat/toolCallAuthRequired`, `requiredScopes: [docs.search]`, the fake authorization server in `authorization_servers`), listed as `toolAuthentication`. An accepted `authenticate` for `https://mcp.example.com` resumes it (`chat/toolCallAuthResolved`); a failed `chat/toolCallComplete` cancels it. |
| `background` | `chat/backgroundWorkSet` (a shell with a terminal that prints a line every few steps), then `chat/backgroundWorkRemoved` after `backgroundDuration` (3 s by default).                                                                                                                                                                                                               |
| `edit`       | An `edit` call whose result is a `fileEdit` diff of `README.md` (+3 −1; `resourceRead` serves both sides), which also lands in the session and turn changesets; catalogue change counts `+3 −1` in 1 file.                                                                                                                                                                          |
| `shell`      | A `bash` call running `npm test` whose output streams through a terminal channel (`ahp-terminal:/…`, command detection, `terminal/exited`); the result carries the exit code and a preview.                                                                                                                                                                                         |
| `read`       | Three `read` calls in a row, for tool call grouping.                                                                                                                                                                                                                                                                                                                                |
| `subagent`   | A `task` call that adds a read-only, movable worker chat ("Explorer", origin `tool`), links it with `subagent` content and background work, runs a turn in it, then finishes.                                                                                                                                                                                                       |
| `canvas`     | `chat/canvasesChanged` with a canvas channel ("App preview", with a URL).                                                                                                                                                                                                                                                                                                           |
| `code`       | A markdown reply with a fenced Dart block.                                                                                                                                                                                                                                                                                                                                          |
| `slow`       | Streams a reply with `chat/delta`, then keeps the turn running for `slowDuration` (4 s by default) unless stopped, so messages can be queued, edited and reordered.                                                                                                                                                                                                                 |
| `cd`         | Adds `packages/api` to the session's and the chat's working directories.                                                                                                                                                                                                                                                                                                            |
| `settings`   | Replies with the message's model and options (`Model: scripted`, `thinkingLevel: high`) and the session's settings (`mode: plan`, `branch: …`).                                                                                                                                                                                                                                     |
| `client`     | An `open_browser` call delegated to another client (`fake-ide`, a client `ToolCallContributor`), listed as `toolClientExecution` (which does not set `InputNeeded`); that client completes it a few steps later ("fake-ide opened the preview.").                                                                                                                                   |
| `delegate`   | The same call delegated to the client that sent the message; waits for its `chat/toolCallComplete` and replies with the result ("… could not open the preview: <error>").                                                                                                                                                                                                           |
| `todo`       | Three `TodoWrite` calls (Claude's input shape: `todos[]` with `content`, `activeForm`, `status`) that create a three-step list and work through it, then "All 3 steps are done." (AV-070).                                                                                                                                                                                          |
| `plan`       | A markdown plan, then a plan review like VS Code's host asks it: a required single-select with described options ("Implement Plan", recommended; "Approve Plan Only") and `allowFreeformInput`; replies with the answer, free-form text after a `+` (AV-046).                                                                                                                       |
| `expire`     | Expires this client's Example Docs token and sends it `auth/required` (`expired`), then waits for a new accepted token and says "Signed in to Example Docs again." (AHP-061).                                                                                                                                                                                                       |
| `choose`     | A `bash` call (`rm -rf build`) with confirmation `options` in two groups ("Allow once", "Allow in this session"; "Skip this step", "Deny") and a judge `riskAssessment` that is `loading`, then `complete` (safety 0.35) a step later; replies with the chosen option.                                                                                                              |
| `command`    | A `bash` call (`git push origin main`) that is `editable`; runs the edited input (`editedToolInput`) and says so.                                                                                                                                                                                                                                                                   |
| `result`     | A `fetch` call that completes with `requiresResultConfirmation` (`pending-result-confirmation`, listed as `toolConfirmation`); replies differently when the result is accepted or discarded (`chat/toolCallResultConfirmed`).                                                                                                                                                       |
| `draft`      | An input request (summary, notes); a step later the host relays another client's draft for "notes" (`chat/inputAnswerChanged`), and the reply lists the answers and how many drafts this client synced.                                                                                                                                                                             |
| `pr`         | Publishes pull request #42 for the session's branch: `session/metaChanged` and a catalogue update with `_meta["copilot.githubReferences"]` (the `headBranch` entry), and says so (AV-105).                                                                                                                                                                                          |

If the user stops the turn while the script waits, the script ends and the
session-level entry is removed.

## Running it

```sh
just fake-host                     # random token; prints the URL
just fake-host --port 63999 --no-token
```

Paste the printed `ws://…?tkn=…` URL into the app's connect screen, open
"Scripted session" and send, for example, `tool` or `ask`.

## Tests that use it

- `packages/ahp_fake_host/test/fake_host_flows_test.dart` (in `just test`):
  `AhpClient` over a real loopback WebSocket with a token: approve, deny,
  stop while waiting, answer and decline input, a request from another
  chat, MCP sign-in and cancel, background work, change counts, queued
  messages and rejected actions, terminals (tool calls and background
  shells), diffs, changesets with review and operations, subagent chats,
  `moveChat`, canvases, queued message editing and reordering, paging a
  windowed chat, host-provided confirmation options and risk, edited
  input, result confirmation, relayed input drafts,
  `resourceList`, `resolveSessionConfig` and completions,
  a session started with settings and a model with options (and a mode
  changed mid-session), a creation failure that `createSession`
  reports at once, a rejected answer to another chat, and client tool
  executions (another client's, and one delegated to the test client).
- `packages/ahp_fake_host/test/oauth_flows_test.dart` (in `just test`):
  `HostAuthenticator` and `signInWithBrowser` against the host and its
  authorization server over loopback HTTP: registration, PKCE and the
  token exchange resuming a tool call, a host-provided client, a refusal,
  a wrong PKCE verifier, a forged token, a pasted token, `-32007` from
  `createSession` (signed in and retried, or cancelled), `auth/required`
  refreshed silently or asked again for a pasted token, a token
  refreshed before it expires, and saved tokens pushed on connect.
- `app/integration_test/fake_host_flows_test.dart` (`just
test-fake-host-app [linux|macos]`, run by CI on both desktops): the real
  app, with the host in the same process, connects through the connect
  screen and drives approve, deny, answer, decline, the "Waiting for you"
  panel and MCP sign-in through the UI. Another test signs in with the
  browser (the test's `OAuthBrowser` fetches the authorization URL, and
  the redirect reaches the app's loopback receiver), lets an expired
  token refresh, picks a host option after the risk assessment, edits a
  tool's input, accepts a result, syncs an input draft and gets another
  client's, and starts a session with the secured agent (the composer
  asks for sign-in; `-32007` prompts it and the start is retried). A third test adds a second fake
  host from "Add host…" in the sidebar, checks the merged list and
  narrows it by tapping the host in the sidebar tree,
  starts a session from a folder's "+" button with the host picker,
  folder browser, a model option, the mode and a branch suggestion, changes
  the mode from the follow-up bar, and checks that a session in a missing
  folder fails with the host's error at once. A fourth test drives the
  session list (search, archiving from the row menu, unarchiving with a
  swipe, the Done filter, multi-select "Mark unread" and the attention
  count in the title), the shortcuts (search, next session, stop, focus
  composer; on macOS through the commands the menu sends, which simulated
  keys do not reach), an answer the host rejects in the "Waiting for you"
  panel coming back, the `client` and `delegate` flows, and a restart
  that reconnects the open host without the connect screen. Remembered
  hosts (and which are open) are kept in
  memory (an overridden `hostStoreProvider`), so it needs no keyring or
  keychain; secure storage is the desktop smoke test's job. Linux needs a
  display (`xvfb-run -a just test-fake-host-app linux`).

## Reconnects

The host keeps its newest envelopes (`replayLimit`, 1000 by default) and
the clients it initialized, so `reconnect` behaves like a real host's:

- a client it initialized gets a `replay` of the envelopes after its
  `lastSeenServerSeq` on the channels it names (its own rejections
  included), with channels the host no longer has in `missing`;
- a client further behind than the buffer gets a `snapshot` result
  (`replayLimit = 0` forces one);
- a client it never initialized gets `-32008` and runs `initialize`.

Tests break the connection with:

- `dropConnections()`: closes every connection, as a network drop would;
- `refuseConnections`: while true, WebSocket upgrades are answered `503`,
  so clients stay in "Reconnecting…";
- `loseActions`: while true, `dispatchAction` messages are dropped unread,
  so the client's write-ahead copy is rolled back after the reconnect;
- `removeSession(uri)`: removes a session and its chats
  (`root/sessionRemoved`), so a client that had it open finds it
  `missing`;
- `connectInMemory`: a `ChannelConnector` for a second client that reaches
  the host while socket clients are refused (another client's turn,
  replayed to the first).

`packages/ahp_fake_host/test/reconnect_flows_test.dart` checks the client
against these, and the last test of
`app/integration_test/fake_host_flows_test.dart` checks the app (the
"Reconnecting…" chip, a replayed turn, a rolled-back message with its
notice, a running turn stopped after the reconnect, and "This session is no
longer available on the host."). The same cases against pi are in
[testing.md](testing.md).

`dart run ahp_fake_host` also takes `--slow-seconds N` (how long the `slow`
flow runs; the browser tests use 30).
