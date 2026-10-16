# Fake host

`packages/ahp_fake_host` is a scripted AHP 1.0.0 host written in Dart. It
exists because pi-agent-host-protocol runs tools without asking and sends
no elicitations, so tool approvals (AV-083), input requests (AV-084),
session-level input requests and MCP sign-in (AHP-062) could not be
exercised against a real host.

## How it works

- `FakeAhpHost` serves JSON-RPC over WebSocket (`dart:io` `HttpServer`,
  `json_rpc_2` `Peer`), or over any `StreamChannel<String>` with `serve`.
  It answers `initialize` (1.0.0 or 0.9.0), `reconnect` (always `-32008`,
  so clients fall back to `initialize`), `listSessions`, `subscribe`,
  `unsubscribe`, `createSession`, `fetchTurns`, `authenticate`, `ping`,
  `dispatchAction`, `resourceRead` (the two sides of scripted file edits),
  `invokeChangesetOperation` and `moveChat` (reorders a movable chat
  within its session; other destinations are refused).
- It keeps real protocol state (`RootState`, `SessionState`, `ChatState`,
  `TerminalState`, `ChangesetState`, `CanvasState`, catalogue
  `SessionSummary`s) and advances it with the client package's own
  reducers, so its envelopes are what a reducer-faithful host would send. Catalogue entries follow the default
  chat's status and the session's `inputNeeded` list
  (`root/sessionSummaryChanged`).
- Client actions from `clientDispatchable` are echoed with their
  `origin`; anything else (or an unknown channel, or a second
  `chat/turnStarted` while a turn runs) is echoed with a
  `rejectionReason` to the sender only.
- A token, when set, is accepted in the `tkn` query parameter or an
  `Authorization: Bearer` header.
- It starts with two sessions and one agent, `fake`:
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

## Scripted flows

`chat/turnStarted` runs the flows whose keyword is a word of the message
(`scenariosFor`), in this order, then completes the turn. Queued messages
start the next turn, like a real host. A message without a keyword gets an
echo that lists the keywords.

| Keyword      | What the host does                                                                                                                                                                                                                                                           |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tool`       | Starts a `bash` call that waits for confirmation, and lists it in `SessionState.inputNeeded` (`toolConfirmation`). Approved: completes it and says "The folder has 3 entries."; denied: "OK, I did not run it."                                                              |
| `ask`        | `chat/inputRequested` with text (required), single-select (required), boolean and integer questions, also in `inputNeeded` (`chatInput`). Replies with the answers (`name=v1, env=staging, ...`) or "You declined, so I stopped."                                            |
| `side`       | Adds a second chat ("Reviewer") and asks a boolean question there. The client is not subscribed to it, so the question only arrives through the session's `inputNeeded`; the answer is dispatched to that chat.                                                              |
| `auth`       | An MCP tool call (`search_docs`) that goes `running` then `auth-required` (`chat/toolCallAuthRequired`), listed as `toolAuthentication`. `authenticate` for `https://mcp.example.com` resumes it (`chat/toolCallAuthResolved`); a failed `chat/toolCallComplete` cancels it. |
| `background` | `chat/backgroundWorkSet` (a shell with a terminal that prints a line every few steps), then `chat/backgroundWorkRemoved` after `backgroundDuration` (3 s by default).                                                                                                        |
| `edit`       | An `edit` call whose result is a `fileEdit` diff of `README.md` (+3 −1; `resourceRead` serves both sides), which also lands in the session and turn changesets; catalogue change counts `+3 −1` in 1 file.                                                                   |
| `shell`      | A `bash` call running `npm test` whose output streams through a terminal channel (`ahp-terminal:/…`, command detection, `terminal/exited`); the result carries the exit code and a preview.                                                                                  |
| `read`       | Three `read` calls in a row, for tool call grouping.                                                                                                                                                                                                                         |
| `subagent`   | A `task` call that adds a read-only, movable worker chat ("Explorer", origin `tool`), links it with `subagent` content and background work, runs a turn in it, then finishes.                                                                                                |
| `canvas`     | `chat/canvasesChanged` with a canvas channel ("App preview", with a URL).                                                                                                                                                                                                    |
| `code`       | A markdown reply with a fenced Dart block.                                                                                                                                                                                                                                   |
| `slow`       | Streams a reply with `chat/delta`, then keeps the turn running for `slowDuration` (4 s by default) unless stopped, so messages can be queued, edited and reordered.                                                                                                          |
| `cd`         | Adds `packages/api` to the session's and the chat's working directories.                                                                                                                                                                                                     |

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
  `moveChat`, canvases, queued message editing and reordering, and
  paging a windowed chat.
- `app/integration_test/fake_host_flows_test.dart` (`just
test-fake-host-app [linux|macos]`, run by CI on both desktops): the real
  app, with the host in the same process, connects through the connect
  screen and drives approve, deny, answer, decline, the "Waiting for you"
  panel and MCP sign-in through the UI. Remembered hosts are kept in
  memory (an overridden `hostStoreProvider`), so it needs no keyring or
  keychain; secure storage is the desktop smoke test's job. Linux needs a
  display (`xvfb-run -a just test-fake-host-app linux`).
