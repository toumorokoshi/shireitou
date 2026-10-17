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
changeset and canvas channels mirrored by the client. Iteration 8
(2026-10-16) connected several hosts at once (merged session list, host
switcher, keyring problems shown to the user) and completed the composer
(host picker, folder browser, model options, session settings, immediate
creation errors) and the in-session model and mode pickers. Iteration 9 (2026-10-16) finished the
session list (Done filter, search, sort, archive and mark read from the
row menu, swipe and multi-select, the attention count in the title), the
AV-140 keyboard shortcuts (and the macOS Session menu), optimistic
answers in the "Waiting for you" panel, client tool executions, and
restoring the open hosts after a restart. Iteration 10 (2026-10-16)
answered the open questions (see `DESIGN-DECISION-LOG.md`): todo lists
and plan reviews, pull request and branch links from `_meta`, parallel
runs with a comparison page, desktop notifications, clearer connection
errors for LAN and tunnel hosts, and the push relay design. Iteration
11 (2026-10-16) added OAuth sign-in for protected resources (discovery,
dynamic registration, PKCE, the browser and a loopback or web redirect,
refresh), `auth/required` and `-32007` handling, and the remaining tool
call interaction (host options, risk, edited input, result
confirmation, input drafts), with a fake OAuth authorization server in
the fake host. Iteration 12 (2026-10-16) drove the app end to end against
pi with its scripted faux model (no API key) in CI, drove reconnects
(replay, snapshots, `missing`, rollback, host restart) against the fake
host and pi, and drove the web build in Chromium with Playwright (see
[docs/testing.md](docs/testing.md)). Iteration 13 (2026-10-16) built and
smoke-tested Windows, iOS and Android in CI, added the app icon, the
AppImage and the release workflow (see
[docs/packaging.md](docs/packaging.md)). Remaining work:

- **Highest priority (user feedback, 2026-10-16):** do these before the
  items below.

  - **SSH terminal:** open an interactive SSH TTY to a host from the app.
    Prefer a maintained third-party SSH client and terminal emulator
    library over writing one from scratch.
  - **`/` completions (AV-044):** typing `/` in the composer or follow-up
    box does not offer the agent's skills and commands.

- **Renaming a session (AV-073), remaining details:** the session list
  renames in a dialog, not in place. A rename from the list of a session
  that is not open is not shown until the host updates its catalogue
  (the client mirrors only open sessions' channels), and a host that
  rejects it reports the rejection only to subscribers of the session's
  channel, so the list may not hear of it. Renaming is verified against
  the scripted fake host only; pi's support for a client
  `session/titleChanged` is untested.
- **Editing queued messages in place (AV-081), remaining details:** when
  the host sends or removes a message while it is open in the editor, the
  editor closes with a notice and the typed text is lost (it is not
  copied or re-queued). A change to the message's text from another
  client while it is being edited is not shown; saving overwrites it.
  Clicking the steering message also edits it, though the agent may take
  it before the edit is saved.
- **Approvals and input against a real host:** tool approvals (AV-083)
  with host options, risk assessments, edited input and result
  confirmation, input requests (AV-084) with synced drafts,
  session-level requests and MCP sign-in are verified against the
  scripted fake host only (client flows in `just test`, the app in
  `just test-fake-host-app`; see [docs/fake-host.md](docs/fake-host.md)).
  No production host that asks (for example VS Code's agent host) has
  been tried; pi never asks. Editing a tool input held by reference
  (`ContentRef`, read with `resourceRead` when "Edit input" is pressed)
  is implemented but no fake host flow sends one. A denial option is
  sent as `skipped` when its ID or label says "skip" (the protocol does
  not say which options skip), otherwise `denied`; no `userSuggestion`
  or `reasonMessage` is offered.
- **"Waiting for you" panel and client tools:** an answered entry is
  hidden until the host removes it and comes back when the host rejects
  the answer or does not remove the entry within 30 s (a fixed timeout,
  like the client's pending-action timeout). Both, and
  `toolClientExecution` entries (another client's shown as "running on
  another client"; one delegated to this app turned down with a failed
  `chat/toolCallComplete`, since the app provides no tools), are verified
  against the fake host only. The app does not announce tools in
  `activeClients`, so a host following the protocol never delegates one
  to it.
- **Composer and settings, remaining details (AV-040 to AV-043):**
  - Settings are edited only when they are JSON primitives: `array` and
    `object` properties of a model `configSchema` or session config are
    sent with their defaults and not shown. Custom agents
    (`Message.agent`, `AgentSelection` from `AgentCustomization`) have no
    picker, and `chatMutable` settings (in the protocol's main branch, not
    1.0.0) are not offered per chat.
  - A re-resolved `resolveSessionConfig` adds and removes fields, but a
    field already on screen keeps the value it showed when it appeared
    (the host's new default for it is still sent unless the user changed
    it).
  - Recent folders are derived from the host's sessions, not stored, so a
    folder browsed to but never used is not remembered.
  - Only the fake host was seen to answer `resolveSessionConfig` with
    settings and `session/creationFailed`; pi answers an empty schema and
    has no mode, and refuses a folder it does not have with `-32602` from
    `createSession` itself (checked in `pi_faux_flows_test.dart`), so no
    real host was seen to send `session/creationFailed`.
- **Timeline, remaining details:**
  - Turn markers (AV-074) cover the loaded turns only: while the host
    holds older turns back, turns are numbered from the oldest loaded
    one, and the rail's "Load older turns" button (or stepping back past
    the oldest turn) pages one window in at a time. Jumping to a row that
    was never built lands on an estimated offset that is corrected as the
    rows are laid out, so a long jump may end a few pixels off. The
    Cmd/Ctrl+Alt+↑/↓ keys are taken by some Linux desktops (workspace
    switching); there is no way to change them. The rail is not tried in
    the web build's Playwright tests.
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
  - Drafts sync the follow-up text only (not the model picked in the
    follow-up bar, agents or attachments); a draft from another client
    replaces the box's text only while the user has not typed since the
    last sync.
- **Review pane, remaining details (AV-100 to AV-105):** compare-turns
  changesets (`{originalTurnId}`/`{modifiedTurnId}`) always compare the
  oldest and the newest turn (there is no picker for the two turns);
  `range`-scoped operations are not offered (no line selection, and no
  diff comments, AV-104); a non-external operation follow-up is shown as
  plain text. Side-by-side diffs appear from 900 dp in the full diff page
  only. On wide layouts the pane opens and closes (one choice for all
  sessions, remembered on the device) but cannot be resized (AV-005),
  and the left sidebar does not collapse yet. The header's details
  still list the change counts, which the pane's toggle also shows.
- **Todo lists and plans (AV-070, AV-046):** todo tools are recognized
  by name (`TodoWrite`, `todo_write`, `update_todo`, `manage_todo_list`,
  `update_plan`); a host that renames them, or an agent with another todo
  tool, gets ordinary tool cards. Only Claude's shape is produced by the
  fake host; the VS Code and Codex shapes are tested from their
  documented inputs, and the Copilot CLI's markdown checklist is an
  assumption (its tool schema is not public), none from a real host. A todo call waiting for
  approval keeps the normal card. Plan reviews show the question only:
  VS Code's non-standard `planReview` (plan text, plan file URI) and
  `_meta.purpose` on the input request are not in the schema and are
  dropped by the generated types, and there is no editor for the plan
  itself (AHP has no command to change it).
- **Working indicator (AV-072):** it follows the open chat only, so a
  parent chat waiting on a working subagent shows it only while its own
  turn runs. It is hidden while the chat needs input, and is checked by
  widget tests only (not the fake host, pi or browser flows). Unlike
  Copilot's, it does not show the elapsed time of the turn.
- **PR and branch links (AV-105):** only GitHub URLs and VS Code's
  `_meta` conventions (`copilot.githubReferences` with `headBranch`,
  `git.githubOwner`/`githubRepo`); VS Code's folder-keyed `githubData`,
  GitLab or other forges, and the PR's checks or review state are not
  shown. Verified against the fake host's `pr` flow only.
- **Parallel runs (AV-045):** groups are stored on this device only
  (another client or a reinstall loses them), and all runs of a group
  use one host and folder. Runs of another agent get that agent's
  default session settings (the form shows the first agent's); a run's
  model options (such as the thinking level) are the host's defaults.
  The comparison shows each run's latest reply and change counts, not a
  diff between runs. A run that is removed on the host stays in its
  group as "Not available".
- **Notifications (AV-121 to AV-123):** desktop, iOS, Android and the
  web, while the app (or tab) runs. None was ever shown outside Linux:
  the app tests turn notifications off, so macOS's and iOS's permission
  prompts (now asked at start), Windows toasts (as an unpackaged app and
  from the `.msix`), Android's channel and Android 13 permission
  request, and the browser's Notification API were only built in CI and
  checked with widget tests; each needs a check by hand on a real
  machine. The macOS app is signed ad hoc; if macOS refuses
  authorization to it, the bell menu keeps offering "Allow
  notifications…" (a Developer ID signature would be the fix). Linux
  needs a freedesktop notification daemon (none in CI, where failures
  are logged). Web notifications are page notifications: none from
  Chrome on Android (it only allows service worker ones) and none once
  the tab is closed, and Firefox and Safari only ask for permission from
  the bell menu's "Allow notifications…" click. A suspended mobile app
  gets none. "Focused" comes from the app lifecycle (`resumed`), which
  on Linux depends on the embedder reporting window focus. A click
  arriving while the connect screen is shown (no host connected) is
  dropped. There is no app-icon badge (AV-122). Push for a closed
  app needs the relay in [specs/push-relay.md](specs/push-relay.md),
  which is not built (it needs Apple/Google push credentials and a
  signed app).
- **Web transport:** a browser reports every failed handshake the same
  way, so the web app lists likely causes instead of the real one. The
  mixed content check runs before connecting, but Chrome's local network
  access prompt (an https page reaching a private address) is not
  detected. No tunnel (VS Code dev tunnels, Cloudflare, ngrok, Tailscale)
  was tried end to end; `wss://` is covered by `normalizeHostUri` and
  the existing transport only.
- **Session details:** customizations are listed with MCP server
  start/stop and "Continue in background", but plugins cannot be enabled
  or disabled (`session/customizationToggled`), plugin children are not
  listed, and `_meta` is shown as raw JSON. The app does not announce
  itself in `activeClients` (it provides no tools).
- **Verified against the fake host only:** terminals in tool calls,
  changesets and their operations, canvases, subagent chats, `moveChat`
  and windowed history are driven end to end against the scripted fake
  host only (client flows in `just test`, the app in
  `just test-fake-host-app`), because pi 0.3.0 cannot provide them: its
  `bash` tool does not run in an AHP terminal (pi's own `createTerminal`
  terminals exist, but the app has no UI that creates or lists them), and
  it has no changesets, canvases, subagent chats, `createChat`/`moveChat`
  or `fetchTurns` paging. Drafts, queued messages, the folder browser,
  archive and reconnects are now also driven against pi
  (`just test-pi-app`). No other real host was tried.
- **Sign-in (AHP-060, AHP-061), remaining details:**
  - Verified only against the fake host's in-process authorization
    server; no real authorization server (GitHub, Entra ID, Auth0, …) or
    real MCP server challenge was tried.
  - Clients come from the challenge's `McpOAuthClient` or dynamic
    registration only. Client ID Metadata Documents (the MCP 2025-11-25
    alternative to registration) are not supported, so a server that
    offers neither can only be used with a pasted token. A client is
    registered on every browser sign-in (the loopback port, and so the
    redirect URI, changes each time); registrations are not reused.
  - Web: the redirect page (`oauth_callback.html`, `BroadcastChannel`)
    is driven in Chromium by `just test-web` against the fake
    authorization server (which allows CORS). A real server must allow
    CORS for its metadata, registration and token endpoints, and a
    browser with its popup blocker on may block the new tab, because it
    opens after the discovery and registration requests rather than
    directly on the click; Playwright's Chromium does not block popups,
    so that was not checked.
  - iOS and Android redirect to the app's URL scheme
    (`ASWebAuthenticationSession`, the browser and an intent filter; see
    [docs/mobile.md](docs/mobile.md)). Only the Dart side is unit
    tested; the native code is compiled in CI, but no sign-in was driven
    through a browser on a simulator or emulator. On Android, a sign-in is
    lost if the system kills the app while the browser is in front (the
    redirect then starts the app fresh, with no sign-in waiting for it).
    An authorization server that only accepts `https` or loopback
    redirect URIs cannot be used from mobile except with a pasted token.
  - Tokens are refreshed only while the app runs (a minute, or a fifth
    of the lifetime, before expiry); after a restart an expired token is
    refreshed on connect. There is no UI to list or sign out of
    resources (`HostAuthenticator.signOut` sends the empty-token
    revocation), and a step-up challenge (`insufficientScope`) requests
    only its `requiredScopes`, not the union with scopes granted before.
  - `auth/required` and `-32007` open the sign-in dialog on their own
    (on the root navigator) when no refresh is possible; there is no
    quieter notice for a resource the user is not using right now.
- **Session list and shortcuts, remaining details:**
  - Search matches titles and the `agent:`, `status:`, `repo:` and
    `host:` qualifiers only, not chat content; there is no negation
    (`-status:done`) and the query is not remembered across restarts.
  - Pins (AV-028) are kept on this device only (AHP has no pin field), so
    other devices and clients do not see them. A pin is not dropped when
    its session is disposed or its host removed; the stored set only
    grows with such leftovers. There is no `pinned:` search qualifier,
    and no separate "Pinned" section above the folders (pinned sessions
    lead their folder, which then leads the list).
  - An archive or read change from the list is sent to the session
    channel without subscribing; the row moves only when the host's
    catalogue update arrives (the root catalogue is not written ahead). A
    rejection is reported, but nothing times out for a session that is
    not open, since the client has no mirror to roll back.
  - Shortcuts: Alt+↑/↓ also apply while a text field has focus (they win
    over the field's own Alt+arrow navigation). On the web, browsers keep
    Ctrl+N for a new window, so the shortcut only works in the desktop
    apps there. Ctrl+K, Alt+↓, Ctrl+L and Ctrl+. are driven in Chromium
    by `just test-web` (Ctrl+Alt+B, the review pane, only in the widget
    and fake host app tests; on Windows, Ctrl+Alt can be AltGr), but Playwright sends keys through the DevTools
    protocol, so whether a real Chrome or Firefox lets the page have
    Ctrl+K and Ctrl+L before its own address bar was not checked. Keys
    only reach the app while the Flutter view has the focus: when the
    focused element goes away (the Connect button as the connect page
    closes), the focus is on the page body until the user clicks into
    the app. There is
    no shortcut help overlay (the spec has none); tooltips and the
    search hint name the keys, and macOS lists them in the menu.
- **Sidebar tree (AV-012, AV-025):** folder order and collapsed hosts
  and folders are kept per device, not synced. Their stored ids are
  never pruned: a folder whose sessions are all gone (or a host removed)
  keeps its id, since a host that is not open, or sessions not loaded
  yet, cannot be told from a deleted folder; the lists only grow by
  folders the user moved or collapsed. Dragging a folder does not
  scroll the list near its edges, so a long list needs "Move up" and
  "Move down" or a shorter drag; a folder dropped on a session row (not
  a folder row) does not move. Keyboard users reach "Move up" and "Move
  down" through the handle that shows when the folder row has focus on
  medium and wide layouts; on compact layouts only touch (long press)
  and screen reader actions move folders. Hosts cannot be reordered. Only the open hosts are in the tree; remembered hosts that
  are not open are listed under Recent hosts on the "Add host…" page.
  Folders do not narrow the list (collapsing the others or the `repo:`
  qualifier does). The tree's top level replaces grouping by host; the
  other alternative grouping of AV-031, by time, is not built. Thin rows
  are chosen by layout width (medium and wide), not by input device, so
  a touch screen at desktop width gets the 28 to 32 px rows.
- **Hosts (AV-010 to AV-012):** the open hosts' keys are saved with the
  remembered hosts, so a host is only reopened after a restart when it is
  remembered (it connected once and secure storage works); with a locked
  keyring nothing is restored. A host that never connected is dropped
  when its connect fails (its error shows on the connect page); a
  remembered one stays open, failed, with Retry and Remove on its row in
  the sidebar tree. Secure storage per platform:
  - Web: encrypted local storage; verified.
  - Linux: libsecret; verified by the desktop smoke test with a fresh
    gnome-keyring. A locked keyring (`KeyringLocked`) or no Secret Service
    is shown as a banner with Retry; the banner's wording was checked
    against the plugin's error codes, not against a real locked keyring.
  - macOS: login keychain (`usesDataProtectionKeychain: false`, so no
    `keychain-access-groups` entitlement or provisioning profile); verified
    only by the CI smoke test, never on a developer Mac.
  - Windows (DPAPI), iOS (keychain, `first_unlock_this_device`) and
    Android (Keystore, backups off): verified only by the CI smoke tests
    (desktop smoke test on `windows-latest`, mobile smoke test on an iPhone
    simulator and an API 34 emulator), never on a real device.
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
- **Desktop apps (macOS, Linux, Windows):** all three build, pass the
  desktop smoke test and the fake host app flows, and are packaged in CI
  (see [docs/desktop.md](docs/desktop.md)). Remaining:
  - macOS has never been run on a developer Mac (this machine has no
    Xcode): the window placement restore, `hiddenWindowAtLaunch`, the menu
    bar (including the Session menu's key equivalents, which the app
    relies on instead of Flutter shortcuts there), the window title and
    the keychain were exercised only by CI, and CI cannot press menu keys
    (the integration test sends the commands the menu items send).
  - Windows has only run on CI runners: the window is shown on its first
    frame and then moved to its saved placement (no hidden-at-launch
    window as on macOS), and high-DPI and multi-monitor placement were
    not tried.
  - Linux: the minimum size is checked under openbox only, not under
    GNOME's or KDE's window managers or a Wayland compositor.
- **Packaging and releases** (see [docs/packaging.md](docs/packaging.md)):
  the release workflow builds every package on each packaging change, but
  has never published a release (no `v*` tag was pushed), and no signing
  secrets are set, so every signing step has never run: the `.dmg` is
  unsigned and not notarized (needs a Developer ID Application
  certificate and an Apple ID with an app-specific password, which need
  a paid Apple Developer account), the Windows `.zip` is unsigned and the
  `.msix` left out of releases (needs a code signing certificate), the
  APK is debug-signed (needs a release keystore) and `SHA256SUMS` is not
  GPG-signed. No apt repository, Flathub or Snap package, Homebrew cask,
  winget manifest, Play Store bundle (`.aab`) or auto-update. The
  AppImage uses the system's GTK 3 and libsecret and carries no update
  information (zsync).
- **iOS and Android** (see [docs/mobile.md](docs/mobile.md)): built in CI
  and smoke-tested on an iPhone simulator and an API 34 emulator (secure
  storage, connect, approve, decline in the phone layout) only; never run
  on a device. The longer desktop app flows (review pane, composer,
  terminals, reconnects, …) are not driven on mobile. iOS is built
  without signing and not distributed: an App Store or TestFlight build
  needs an Apple Developer account, a distribution certificate,
  provisioning profile and an App Store Connect API key, none of which
  exist. A suspended app drops its connections (reconnecting when it
  comes back) and gets no notifications until the push relay exists.
- **App-level and browser tests, remaining limits** (see
  [docs/testing.md](docs/testing.md)):
  - pi runs with its scripted faux model (`scripts/pi-faux-host.ts`, which
    imports the host from a pi-agent-host-protocol checkout and embeds pi);
    a real model turn is still only `just test-model`, by hand. The faux
    host depends on pi-agent-host-protocol's internal module paths
    (`src/host/agent-host.ts` and the like) and on pi-ai's faux provider,
    so a refactor there breaks it.
  - The pi app flows run on Linux (and headless) only; macOS and Windows
    CI run the fake host flows and the smoke test, not `just test-pi-app`
    (the test starts `node` from inside the app, which the macOS sandbox
    was not checked to allow, and the faux host script was not tried on
    Windows).
  - Reconnect cases not driven: snapshots instead of a replay against pi
    (its replay buffer would need thousands of missed actions), and a
    `missing` channel in the app against pi (covered by the client test;
    the app's handling is driven against the fake host).
  - The browser tests run in Chromium only (no Firefox or Safari), cover
    a subset of the desktop flows (no approvals, input requests, review
    pane or composer settings), and use the semantics tree
    (`--dart-define=SHIREITOU_SEMANTICS=true`), which a normal build turns
    on only when a screen reader asks.
- Everything else in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)
  not listed as done in their status sections.
