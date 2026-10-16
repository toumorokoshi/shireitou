# Examples

- [`ahp/pi-host-root-catalogue.json`](ahp/pi-host-root-catalogue.json):
  traffic recorded from pi-agent-host-protocol 0.3.0 (protocol 1.0.0):
  `initialize`, `listSessions` (one page), `createSession` with the
  resulting `root/sessionAdded`, `subscribe` to the session, a
  `session/titleChanged` dispatch with its `action` echoes and
  `root/sessionSummaryChanged`, `disposeSession` with `root/sessionRemoved`,
  `ping`, and a `-32005 UnsupportedProtocolVersion` error. Each entry is
  `{ "dir": "client->host" | "host->client", "message": <JSON-RPC> }`. Paths
  and titles were anonymized and the session snapshot's `customizations`
  were removed.

`packages/ahp_client/test/session_catalogue_test.dart` replays the
host-to-client messages through the pure reducers.

- [`ahp/pi-host-chat-turns.json`](ahp/pi-host-chat-turns.json): traffic
  recorded from pi-agent-host-protocol 0.3.0 (protocol 1.0.0) in embedded
  mode: `createSession`, `subscribe` to the session and its default chat
  (`ahp-chat://default/<base64url(pi:/<id>)>`), then two client-dispatched
  `chat/turnStarted` turns with every streamed action (reasoning, markdown
  `chat/delta`, a `bash` tool call from `chat/toolCallStart` to
  `chat/toolCallComplete`, `chat/usage`, `chat/turnComplete`), a rejected
  `chat/turnCancelled`, `session/isReadChanged`, and an empty `fetchTurns`.
  Paths and the model name were anonymized, the agent's model list was cut to
  one entry, and `session/customizationsChanged` actions were removed.

`packages/ahp_client/test/chat_reducer_test.dart` replays it, including the
client's own `dispatchAction`s as write-ahead actions.
