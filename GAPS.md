# Gaps

Open issues and features not yet implemented.

## Implementation

Iteration 1 (2026-10-15) built the workspace, `ahp_client` core, CI, and an
app shell. Iteration 2 (2026-10-15) made the app usable end to end on web:
open a session, stream replies, send follow-ups, stop turns, approve tools,
answer input requests, and start sessions. Iteration 3 (2026-10-16) added
the macOS and Linux desktop apps (CI builds, smoke tests and packages),
the native token header, and remembered hosts. Iteration 4 (2026-10-16)
finished reconnect (`missing` channels, liveness pings), write-ahead
rollback on timeout and reconnect, and 0.9.0 degradation. Iteration 5
(2026-10-16) generated the wire types from the AHP 1.0.0 JSON Schemas.
Remaining work:

- **Not verified against a host:** tool approvals (AV-083) and input
  requests (AV-084) are covered by reducer and widget tests only, because pi
  runs tools without confirmation and sends no elicitations. Test them
  against a host that asks (for example VS Code's agent host or a fake host
  script).
- **Session-level input requests:** `SessionState.inputNeeded` is kept as
  raw JSON and not shown.
- **Composer (AV-040, AV-041):** no host picker (one host), no directory
  browser (AV-043), no mode/thinking-level options from the model's
  `configSchema`, and no "+" button on folder headers. A session whose
  creation fails (`session/creationFailed`) is never listed by pi, so
  `createSession` waits for its 30 s timeout instead of showing the error.
- **Timeline:** no syntax highlighting or code-block copy button (AV-061),
  no grouping of similar tool calls (AV-064), no terminal output or inline
  diffs (AV-065), no subagent/chat switcher (AV-069). Queued messages cannot
  be edited or reordered (AV-081). Older turns are not paged in on scroll
  (AV-068; pi always sends full history). Very long chats rebuild the whole
  `ChatState` per delta; windowed delivery (AHP-029) is not built.
- **Chat reducer coverage:** background work, canvases, changesets, MCP
  auth (`chat/toolCallAuthRequired`/`chat/toolCallAuthResolved`), working
  directories, queued-message reordering and draft actions are ignored
  (listed explicitly as no-ops in `reduceChat`). Session customizations,
  MCP servers, changesets, server tools, active clients, input requests,
  chat reordering and `_meta` are ignored (`reduceSession` falls through).
  The generated types for all of them exist.
- **Session list:** no "Done" filter (AV-022), archive only from the session
  header (AV-024), no attention count in the title (AV-120), no keyboard
  shortcuts (AV-140), no search or sort.
- **Hosts (AV-010):** up to 20 hosts are remembered, but the app holds one
  connection at a time, so there is no host switcher in the session list
  and no host picker in the composer. Secure storage per platform:
  - Web: encrypted local storage; verified.
  - Linux: libsecret; verified by the desktop smoke test with a fresh
    gnome-keyring. A locked keyring or no Secret Service means hosts are
    not saved; the app only logs a warning and does not tell the user.
  - macOS: login keychain (`usesDataProtectionKeychain: false`, so no
    `keychain-access-groups` entitlement or provisioning profile); verified
    only by the CI smoke test, never on a developer Mac.
  - iOS, Android, Windows: not run.
- **Generated wire types, limits** (see [docs/wire-types.md](docs/wire-types.md)):
  - `Snapshot.state` and `ActionEnvelope.action` stay raw JSON, decoded per
    channel kind by `host_state.dart` and the reducers; snapshots of
    channels the client does not mirror (terminal, changeset, canvas,
    annotations, resource watch, automation) are not decoded at all yet.
    `TerminalState`, `ChangesetState`, `CanvasState`, ... and their action
    unions (`TerminalAction`, `ChangesetAction`, ...) exist but have no
    reducers.
  - The partial summaries (`session/chatUpdated` and
    `root/sessionSummaryChanged` `changes`) are `JsonMap` and merged as
    JSON, because hosts clear a field with an explicit `null`.
  - Decoding is lenient only where it must be: unknown union members and
    enum values have fallbacks, and missing required lists or maps decode
    as empty, but any other missing required field throws (a `TypeError`
    from a cast) and fails the whole snapshot or action. Re-encoding drops
    properties the schema does not have (pi's `SessionChatSummary.modifiedAt`)
    and an unknown enum value is re-encoded as an empty string.
  - Lists in generated objects are ordinary (mutable) `List`s; nothing
    enforces immutability beyond `final` fields.
  - Inline enums are not de-duplicated by shape (for example
    `ChangesetOperationTargetResourceSide` and
    `ChangesetOperationTargetRangeSide`), and a few inline classes still
    have derived names (`AhpMcpUiHostCapabilitiesSampling`).
  - Only the 1.0.0 schemas are vendored. The 0.9.0 differences in
    `protocol_version.dart` were checked against the v0.9.0 schemas once,
    by hand; a test only checks that each listed action exists in 1.0.0.
- **1.0.0-only features:** under 0.9.0 the client ignores the ten
  1.0.0-only actions and refuses to dispatch them, and the app shows an
  "AHP 0.9.0" chip (see "0.9.0 compatibility" in
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)).
  None of the 1.0.0-only UI exists yet; when per-chat read/archive,
  background work, per-chat changes, chat moving/reordering or canvases are
  built, they must check `supportsFeature`. No real host that speaks only
  0.9.0 was tested: pi was made to negotiate 0.9.0 by offering only that.
- **Write-ahead and liveness tuning:** the pending-action timeout (30 s),
  ping interval (15 s) and ping timeout (10 s) are fixed defaults, not
  user settings, and were not tuned on slow or mobile networks. A long
  `chat/turnStarted` round trip on a slow link could be rolled back and
  then reapplied by its late echo.
- **macOS and Linux desktop apps (priority):** both build, pass the desktop
  smoke test and are packaged in CI (see [docs/desktop.md](docs/desktop.md)).
  Remaining:
  - macOS has never been run on a developer Mac (this machine has no
    Xcode): the window placement restore, `hiddenWindowAtLaunch`, the menu
    bar and the keychain were exercised only by CI.
  - The macOS menu bar has no items for the AV-140 shortcuts (new session,
    search, next/previous session, stop, focus composer); they wait for
    AV-140 itself.
  - On Linux the minimum window size is a GTK geometry hint that the window
    manager enforces; it was not checked under a real window manager
    (the smoke test runs under Xvfb with none). On Wayland only the size is
    restored, since clients cannot place windows.
  - Packaging: the `.dmg` is unsigned and not notarized (needs a Developer
    ID certificate and notarization secrets in CI). No AppImage, no apt
    repository, and the `.deb` is unsigned. The app icon is still the
    Flutter default (the `.deb` uses the web icon).
  - Release builds are uploaded as CI artifacts only; there is no release
    workflow publishing them on tags.
- **Other platforms:** iOS, Android and Windows builds have not been run
  either (no Android SDK or Windows machine here).
- **App-level integration test in CI:** the desktop smoke test
  (`app/integration_test/desktop_smoke_test.dart`) covers window setup,
  connecting with a token and saving the host, on Linux and macOS. It does
  not drive the UI (sessions, chat). The web app is still only driven by a
  Playwright script kept outside the repo.
- Everything else in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)
  not listed as done in their status sections.

## Open questions

- **Worktree metadata:** check whether hosts report repo and branch for a
  working directory. If they don't, folder labels fall back to the path only.
- **Agent/model selection:** pi takes the model per message
  (`Message.model`, ids from `AgentInfo.models`) and has no session config.
  Check how other hosts expose mode and model through `SessionConfigState`
  before adding those pickers.
- **Todos/plans:** check whether AHP response parts carry structured todo or
  plan data (AV-046, AV-070).
- **PR/branch metadata:** check whether hosts expose a PR URL (AV-105). It may
  only be available through `_meta`.
- **Best-of-N (AV-045):** AHP has no notion of linked sessions, so linking and
  judging would be client-side. Decide where that state lives.
- **Mobile push (AV-123):** AHP only delivers events over a live socket, so
  background push needs a relay service. That is out of scope for now.
- **Web transport:** pi accepts the token in the query string from a
  browser, and does not check `Origin`. Check CORS/TLS for hosts on a LAN or
  tunnel, and other hosts' `Origin` checks.
- **`ahp_sdk` evaluation:** decide whether to fork, contribute to, or ignore
  the community Dart package.
