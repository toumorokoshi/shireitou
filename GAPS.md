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
errors for LAN and tunnel hosts, and the push relay design. Remaining
work:

- **Approvals and input against a real host:** tool approvals (AV-083),
  input requests (AV-084), session-level requests and MCP sign-in are
  verified against the scripted fake host only (client flows in
  `just test`, the app in `just test-fake-host-app`; see
  [docs/fake-host.md](docs/fake-host.md)). No production host that asks
  (for example VS Code's agent host) has been tried; pi never asks. The
  fake host does not cover host-provided confirmation `options`, risk
  assessments, editable tool input, result confirmation
  (`pending-result-confirmation`) or `chat/inputAnswerChanged` drafts.
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
    has no mode. That `createSession` sees pi's `session/creationFailed`
    relies on pi accepting a subscription to the `ahp-session:/` URI it
    was created with (true in pi 0.1.0's code; not run against pi).
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
  only.
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
- **Notifications (AV-121 to AV-123):** desktop only. Linux needs a
  freedesktop notification daemon (none in CI, where failures are
  logged); macOS asks for permission on the first notification and was
  only built in CI, never shown on a real Mac; Windows was not built. The
  web build has none (the plugin's web support replaces Flutter's
  service worker), and mobile has none. "Focused" comes from the app
  lifecycle (`resumed`), which on Linux depends on the embedder reporting
  window focus. There is no app-icon badge (AV-122). Push for a closed
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
- **Session list and shortcuts, remaining details:**
  - Search matches titles and the `agent:`, `status:`, `repo:` and
    `host:` qualifiers only, not chat content; there is no negation
    (`-status:done`) and the query is not remembered across restarts.
    Pinning (AV-028) is not built.
  - An archive or read change from the list is sent to the session
    channel without subscribing; the row moves only when the host's
    catalogue update arrives (the root catalogue is not written ahead). A
    rejection is reported, but nothing times out for a session that is
    not open, since the client has no mirror to roll back.
  - Shortcuts: Alt+↑/↓ also apply while a text field has focus (they win
    over the field's own Alt+arrow navigation). On the web, browsers keep
    Ctrl+N for a new window, so the shortcut only works in the desktop
    apps there; the web shortcuts were not tried in a browser. There is
    no shortcut help overlay (the spec has none); tooltips and the
    search hint name the keys, and macOS lists them in the menu.
- **Hosts (AV-010 to AV-012):** the open hosts' keys are saved with the
  remembered hosts, so a host is only reopened after a restart when it is
  remembered (it connected once and secure storage works); with a locked
  keyring nothing is restored. A host that never connected is dropped
  when its connect fails (its error shows on the connect page); a
  remembered one stays open, failed, with Retry and Remove in the host
  switcher. Secure storage per platform:
  - Web: encrypted local storage; verified.
  - Linux: libsecret; verified by the desktop smoke test with a fresh
    gnome-keyring. A locked keyring (`KeyringLocked`) or no Secret Service
    is shown as a banner with Retry; the banner's wording was checked
    against the plugin's error codes, not against a real locked keyring.
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
    bar (including the Session menu's key equivalents, which the app
    relies on instead of Flutter shortcuts there), the window title and
    the keychain were exercised only by CI, and CI cannot press menu keys
    (the integration test sends the commands the menu items send).
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
  `just test-fake-host-app flutter-tester`), and a second fake host with
  the host switcher, the composer (host picker, folder browser, model
  options, session settings, creation failure) and the mode picker, and a
  fourth test drives the session list (search, filters, archive from the
  list, multi-select), the shortcuts, a rejected panel answer, client
  tools and a restart that restores the open host. Reconnecting after a
  dropped connection is not driven end to end, and the web app is still
  only driven by a Playwright script kept outside the repo.
- Everything else in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)
  not listed as done in their status sections.
