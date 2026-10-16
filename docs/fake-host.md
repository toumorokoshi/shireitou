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
  `unsubscribe`, `createSession`, `fetchTurns`, `authenticate`, `ping` and
  `dispatchAction`.
- It keeps real protocol state (`RootState`, `SessionState`, `ChatState`,
  catalogue `SessionSummary`s) and advances it with the client package's
  own reducers (`reduceSession`, `reduceChat`), so its envelopes are what a
  reducer-faithful host would send. Catalogue entries follow the default
  chat's status and the session's `inputNeeded` list
  (`root/sessionSummaryChanged`).
- Client actions from `clientDispatchable` are echoed with their
  `origin`; anything else (or an unknown channel, or a second
  `chat/turnStarted` while a turn runs) is echoed with a
  `rejectionReason` to the sender only.
- A token, when set, is accepted in the `tkn` query parameter or an
  `Authorization: Bearer` header.
- It starts with one session, `ahp-session:/scripted` ("Scripted session")
  with chat `ahp-chat:/scripted`, and one agent, `fake`.

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
| `background` | `chat/backgroundWorkSet` (a shell), then `chat/backgroundWorkRemoved` after `backgroundDuration` (3 s by default).                                                                                                                                                           |
| `edit`       | An `edit` tool call, then catalogue change counts `+3 −1` in 1 file.                                                                                                                                                                                                         |

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
  messages and rejected actions.
- `app/integration_test/fake_host_flows_test.dart` (`just
test-fake-host-app [linux|macos]`, run by CI on both desktops): the real
  app, with the host in the same process, connects through the connect
  screen and drives approve, deny, answer, decline, the "Waiting for you"
  panel and MCP sign-in through the UI. Linux needs a display and a
  Secret Service, as for the desktop smoke test (see
  [desktop.md](desktop.md)); with a fresh keyring, also point
  `XDG_DATA_HOME` at an empty directory so gnome-keyring does not prompt.
