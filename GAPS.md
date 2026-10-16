# Gaps

Open issues and features not yet implemented.

## Implementation

Iteration 1 (2026-10-15) built the workspace, `ahp_client` core, CI, and an
app shell. Iteration 2 (2026-10-15) made the app usable end to end on web:
open a session, stream replies, send follow-ups, stop turns, approve tools,
answer input requests, and start sessions. Remaining work:

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
  auth (`chat/toolCallAuthRequired`), working-directory and draft actions
  are ignored. Session customizations, MCP servers, changesets and server
  tools are ignored.
- **Write-ahead edge cases:** pending actions are kept across a reconnect
  snapshot and are never timed out, so an action the host dropped silently
  stays applied locally.
- **Session list:** no "Done" filter (AV-022), archive only from the session
  header (AV-024), no attention count in the title (AV-120), no keyboard
  shortcuts (AV-140), no search or sort.
- **Hosts (AV-010):** only the last host is remembered. Secure storage was
  only exercised on web (where it is encrypted local storage); the macOS
  build will need the Keychain entitlement.
- **Wire type generation:** types are hand-written freezed classes modeled on
  the 1.0.0 TypeScript types. A generator from the JSON Schemas in
  `schema/` is still to do.
- **Reconnect details (AHP-004):** report `missing` channels to observers,
  and send client-side liveness `ping`s so dead sockets are detected sooner.
- **Native token header (AHP-002):** only the `tkn` query parameter is
  supported.
- **0.9.0 degradation:** nothing yet checks the negotiated version.
- **macOS and Linux desktop apps (priority):** shireitou must run as a
  desktop app on macOS and Linux, not only in the browser. Neither desktop
  build has been run yet.
  - macOS:
    - Building needs a full Xcode install (this machine only has the
      command line tools).
    - The sandbox entitlements (`app/macos/Runner/DebugProfile.entitlements`
      and `Release.entitlements`) lack `com.apple.security.network.client`,
      so WebSocket connections to hosts will fail until it is added.
    - `flutter_secure_storage` needs the Keychain sharing entitlement.
  - Linux:
    - Building needs the GTK 3, CMake, Ninja and clang toolchain.
    - `flutter_secure_storage` needs `libsecret` at build time and a running
      secret service (for example gnome-keyring) at runtime.
  - Both:
    - Use native window behavior: a sensible minimum window size, remembered
      window size and position, and a native menu bar on macOS.
    - On native platforms, send the connection token as a header
      (AHP-002), not only as the `tkn` query parameter.
  - CI: add `flutter build linux` on `ubuntu-latest` and `flutter build macos`
    on `macos-latest`. CI currently builds web only.
  - Packaging (later): a signed and notarized `.dmg` for macOS, and an
    AppImage or `.deb` for Linux.
- **Other platforms:** iOS, Android and Windows builds have not been run
  either (no Android SDK or Windows machine here).
- **App-level integration test in CI:** the web app was driven against a
  real pi host with a Playwright script kept outside the repo. A checked-in
  browser or `integration_test` suite against pi is still to do.
- Everything else in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)
  not listed as done in their status sections.

## Open questions

- **0.9.0 compatibility:** list exactly which 1.0.0 actions and fields are
  missing in 0.9.0, and which UI features need to degrade when 0.9.0 is
  negotiated.
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
