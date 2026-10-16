# Gaps

Open issues and features not yet implemented.

## Implementation

Iteration 1 (2026-10-15) built the workspace, `ahp_client` core, CI, and an
app shell that connects and lists sessions. Remaining work, roughly in the
order needed for a usable app (connect, list, open, stream chat, send,
approve):

- **Session channel (AHP-024):** wire types and a pure reducer for
  `SessionState` and its `session/*` actions; subscribe when a session is
  opened (the subscription API exists, nothing calls it yet).
- **Chat channel (AHP-025):** wire types and reducer for turns,
  `chat/delta` streaming, reasoning, tool calls, usage and errors, plus
  `fetchTurns`. Then the timeline UI (AV-060 to AV-067). The detail pane is a
  placeholder.
- **Write-ahead dispatch (AHP-022):** `dispatchAction` with `clientSeq`,
  optimistic apply and rollback on `rejectionReason`. Needed for sending
  messages (AV-080), cancel (AV-082), approvals (AV-083, AHP-041) and
  input requests (AV-084, AHP-042), and mark read/archive (AHP-043).
- **Composer (AV-040, AV-041):** new-session UI. `AhpClient.createSession`
  exists but has no `-32003` retry or `session/creationFailed` handling, and
  the URI it returns differs from the catalogue key on pi (`pi:/<id>`).
- **Session list:** filters (AV-022), mark read on open (AV-023), archive
  (AV-024), attention count in the title (AV-120), and keyboard shortcuts
  (AV-140). Archived sessions are currently shown with everything else.
- **Hosts (AV-010):** persist host configs, and store tokens in secure
  storage (AHP-063). The URL and token are currently typed in each launch
  (or prefilled with `--dart-define=AHP_URL`).
- **Wire type generation:** types are hand-written freezed classes modeled on
  the 1.0.0 TypeScript types. A generator from the JSON Schemas in
  `schema/` is still to do.
- **Reconnect details (AHP-004):** report `missing` channels to observers,
  and send client-side liveness `ping`s so dead sockets are detected sooner.
- **Native token header (AHP-002):** only the `tkn` query parameter is
  supported.
- **0.9.0 degradation:** nothing yet checks the negotiated version.
- **Platforms:** this machine has no Xcode or Android SDK, so only the web
  build and tests were verified. `flutter build macos`/`ios`/`android`, and
  Windows/Linux builds, have not been run. CI builds web only.
- **Web transport:** the browser WebSocket path has not been tested against a
  real host (only the Dart VM integration test has). Check whether hosts
  check the `Origin` header.
- **App-level integration test:** no test drives the Flutter UI against a
  real host.
- Everything else in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)
  not listed as done in their status sections.

## Open questions

- **0.9.0 compatibility:** list exactly which 1.0.0 actions and fields are
  missing in 0.9.0, and which UI features need to degrade when 0.9.0 is
  negotiated.
- **Worktree metadata:** check whether hosts report repo and branch for a
  working directory. If they don't, folder labels fall back to the path only.
- **Agent/model selection:** confirm whether model and mode are set through
  `createSession.config` / `SessionConfigState` or through `AgentInfo`. This
  decides how the composer pickers (AV-041) are populated.
- **Message send/cancel:** confirm the exact chat actions or commands for
  sending a user turn, sending now vs. queuing, and cancelling (AV-080 to
  AV-082).
- **Todos/plans:** check whether AHP response parts carry structured todo or
  plan data (AV-046, AV-070).
- **PR/branch metadata:** check whether hosts expose a PR URL (AV-105). It may
  only be available through `_meta`.
- **Best-of-N (AV-045):** AHP has no notion of linked sessions, so linking and
  judging would be client-side. Decide where that state lives.
- **Mobile push (AV-123):** AHP only delivers events over a live socket, so
  background push needs a relay service. That is out of scope for now.
- **Web transport:** browsers cannot set WebSocket headers, so the token must
  go in the query string. Confirm hosts accept that, and check CORS/TLS for
  hosts on a LAN or tunnel.
- **`ahp_sdk` evaluation:** decide whether to fork, contribute to, or ignore
  the community Dart package.
