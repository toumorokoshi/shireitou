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
