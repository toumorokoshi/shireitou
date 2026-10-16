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
Iteration 6 (2026-10-16) completed the session and chat reducers, showed
session-level input requests, MCP sign-in, background work and change
counts, and added a scripted fake host (`packages/ahp_fake_host`) that
approvals and input requests are tested against. Iteration 7 (2026-10-16)
built the rest of the timeline (code highlighting, grouped tool calls,
live terminals, inline diffs, the chat switcher, queued message editing,
paging of windowed history) and UI for the mirrored session state
(review pane, drafts, canvases, session details), with terminal,
changeset and canvas channels mirrored by the client. Remaining work:

- **Approvals and input against a real host:** tool approvals (AV-083),
  input requests (AV-084), session-level requests and MCP sign-in are
  verified against the scripted fake host only (client flows in
  `just test`, the app in `just test-fake-host-app`; see
  [docs/fake-host.md](docs/fake-host.md)). No production host that asks
  (for example VS Code's agent host) has been tried; pi never asks. The
  fake host does not cover host-provided confirmation `options`, risk
  assessments, editable tool input, result confirmation
  (`pending-result-confirmation`) or `chat/inputAnswerChanged` drafts.
- **"Waiting for you" panel:** a request answered from the panel in a chat
  the client is not subscribed to stays visible (and can be submitted
  again) until the host sends `session/inputNeededRemoved`; a rejected
  answer only shows the usual snackbar. Client tool execution entries
  (`toolClientExecution`) are ignored because the app provides no tools.
- **Composer (AV-040, AV-041):** no host picker (one host), no directory
  browser (AV-043), no mode/thinking-level options from the model's
  `configSchema`, and no "+" button on folder headers. A session whose
  creation fails (`session/creationFailed`) is never listed by pi, so
  `createSession` waits for its 30 s timeout instead of showing the error.
- **Timeline, remaining details:**
  - Diff lines are highlighted one line at a time, so constructs that span
    lines (block comments, multi-line strings) can be coloured wrongly.
    Only 24 common languages are registered with `re_highlight`.
  - Terminals are shown as plain text: VT escape sequences are stripped
    (no colours, cursor movement only as far as `\r` line redraws), and
    there is no input, resize or claim (`terminal/input`,
    `terminal/resized`, `terminal/claimed`), so a terminal cannot be
    taken over.
  - Grouping (AV-064) folds consecutive finished-or-running calls with the
    same tool name only, and never calls with a terminal, diff or
    subagent preview; the label is "Read · 3 calls", not a verb phrase
    such as "Read 3 files" (hosts send no plural form).
  - Paged-in turns stay in memory: AHP 1.0.0 lets a host deliver a tail
    window (`turnsNextCursor`) and page older turns in with `fetchTurns`,
    but has no way to unload them again, and the host's chat state is
    shared by every client, so the client cannot drop turns it has loaded
    without diverging from the host. pi always sends full history, so
    paging is exercised only against the fake host's "Long session".
  - Hidden chats (`interactivity: hidden`) are not listed; chats can only
    be moved within their session (no move to another or a new session,
    `ChatMoveToNewSessionDestination`), and only "left/right" from a menu,
    not by dragging.
  - Drafts sync the follow-up text only (no model, agent or attachments,
    since the box has no pickers); a draft from another client replaces
    the box's text only while the user has not typed since the last sync.
- **Review pane, remaining details (AV-100 to AV-105):** compare-turns
  changesets (`{originalTurnId}`/`{modifiedTurnId}`) always compare the
  oldest and the newest turn (there is no picker for the two turns);
  `range`-scoped operations are not offered (no line selection, and no
  diff comments, AV-104); a non-external operation follow-up is shown as
  plain text; there is no PR/branch link (AV-105). Side-by-side diffs
  appear from 900 dp in the full diff page only.
- **Session details:** customizations are listed with MCP server
  start/stop and "Continue in background", but plugins cannot be enabled
  or disabled (`session/customizationToggled`), plugin children are not
  listed, and `_meta` is shown as raw JSON. The app does not announce
  itself in `activeClients` (it provides no tools).
- **Verified against the fake host only:** terminals, changesets and
  their operations, canvases, subagent chats, `moveChat`, drafts and
  windowed history are driven end to end against the scripted fake host
  (client flows in `just test`, the app in `just test-fake-host-app`);
  pi was not seen to provide any of them, and no other real host was
  tried.
- **MCP sign-in:** "Sign in" asks the user to paste a token and calls
  `authenticate`. There is no OAuth/PKCE flow from
  `ProtectedResourceMetadata`/`McpOAuthClient` (AHP-060), no handling of
  `auth/required` or `-32007` (AHP-061), and no `expiresIn` or scopes in
  the dialog.
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
    channel kind by `host_state.dart` and the reducers. Root, session,
    chat, terminal, changeset and canvas channels are mirrored; snapshots
    of annotations, resource watch and automation channels are not
    decoded, and `AnnotationsAction`, `ResourceWatchAction`,
    `AutomationAction` and `AutomationRunAction` have no reducers (no UI
    needs them).
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
  The background work chip, canvases, per-chat changesets in the review
  pane, moving chats and "Continue in background" for MCP servers check
  `supportsFeature`; per-chat read/archive have no UI yet and must check
  it when they get one. The fake host can
  negotiate 0.9.0 but its scripts still send 1.0.0-only actions
  (`chat/backgroundWorkSet`, `chat/canvasesChanged`), which the client
  drops under 0.9.0. No real host that speaks only
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
- **App-level integration tests in CI:** the desktop smoke test covers
  window setup, connecting with a token and saving the host against pi;
  `app/integration_test/fake_host_flows_test.dart` drives the connect
  screen, a session, approvals, input requests, the "Waiting for you"
  panel, MCP sign-in, code blocks, grouped calls, terminals, diffs, the
  review pane, subagent chats, queued messages, drafts and paging against
  the fake host, on Linux and macOS (and headless with
  `just test-fake-host-app flutter-tester`). The composer, session list
  filters, archive and reconnect are not driven end to end, and the web
  app is still only driven by a Playwright script kept outside the repo.
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
