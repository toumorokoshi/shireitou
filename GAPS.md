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

- **Reference UI, remaining differences** (compared with
  `just screenshots`, see [docs/testing.md](docs/testing.md)): each
  finished turn keeps a small muted "Done · 1m 47s · tokens" footer
  (AV-067), which the reference does not have. The session header shows
  the session title, where the reference shows the current turn's
  message (intended). Codicons (`AppIcons`) cover the title bar, sidebar,
  session header and composer; menus' leading icons, the status dots,
  the timeline's cards, the review pane's actions and the phone page's
  back button are still Material icons. The title bar has the review
  pane toggle and the bell, not the reference's remote and account
  icons. The turn rail is always shown over the list's left padding, where
  the reference shows it on hover. The screenshots are checked by eye; there are no golden
  files, because the PNGs depend on the macOS fonts.
- **Docs screenshots** (`docs/images`, `just docs-screenshots`): they
  are re-rendered by hand, so they go stale after UI changes; nothing
  checks them in CI (they need the macOS fonts). They show no review
  pane, terminal panel, diff or new-session draft yet. The phone list's
  title bar reads "test host", the fake connection's host name, and
  the model chip shows the model's id rather than its name.
- **Session header and composer (AV-094, AV-096), remaining details:**
  the "+" button is disabled until attachments can be picked (AV-042).
  The "Details" popover (live, from the header's "…" menu) and the
  "Session details" page are separate; the popover could absorb the
  page's sections. The effort chip shows the context window only when
  the host sends `maxContextWindow` (pi does; the fake host does not),
  and nothing about the host's default model (no effort or context is
  known for it). The model chip's "key option" is the first choice
  option that is not the reasoning level, which may not be the one a
  host considers most meaningful (AHP has no such hint). Only the
  `mode` setting gets the agent icon (codicon `agent`); other settings get
  a generic one (`settings`).
  Chips scroll sideways in a narrow pane rather than wrapping. The
  new-session draft's folder is a borderless text field with Browse
  and recent-folder buttons beside the host and agent chips, not a
  chip of its own. The tooltips name the action ("Send", "Queue",
  "Send now", "Stop") without the shortcut; the placeholder no longer
  explains Enter and Cmd/Ctrl+Enter (README and AV-080 do).
- **Theme and title bar (AV-090, AV-091), remaining details:** the
  theme's tokens are in `app/lib/src/theme/` (`AppColors.of(context)`;
  see [docs/architecture.md](docs/architecture.md)). Contrast is checked
  for text, muted text, status dots, error text, links, diff text and
  the terminal's foreground; hairlines are left faint as decoration, so
  an unfocused field's border is under 3:1 (the field is found by its
  placeholder), and highlighted code on a removed or added diff line is
  held to 3:1, not 4.5:1, as in VS Code. The terminal's ANSI colours
  (VS Code's) are not checked, since the preview shows plain text. The
  timeline's tool call, error and todo cards and the composer's popups
  still use `Card` and `elevation:` (flat through the theme's
  `cardTheme`, but menus keep a 2 dp shadow). The font is the platform's system
  font (no Inter asset). On macOS the bar keeps the traffic lights'
  space in full screen too (where they are hidden), a double-click
  always zooms (the system's "double-click a window's title bar"
  setting is not read), and the traffic lights' placement is not
  checked by a test (CI cannot see native window chrome). New session
  and Disconnect moved from the title bar to the sidebar header's "New"
  and "…" menu (AV-092); the bar's search button and the header's
  search icon both open the search field. Back and forward have no shortcut and
  forget the history on restart; the compact layout has no back and
  forward (the system back button pops the session page).
- **Timeline look (AV-095), remaining details:** the steps line shows
  no elapsed time while a turn runs (only "Working… N steps"), and a
  finished turn's time comes from `Turn.duration`, so it is left out
  when the host does not send one (the fake host's turns finish in
  "0s"). AHP 1.0.0 does not provide timestamps or durations for individual
  reasoning, tool-call or interstitial-text steps, so the app cannot show
  authoritative per-step timings; it shows the turn start and total duration
  only. Failed tool calls fold into the steps line with a "N failed"
  count instead of staying in view. Steps rows remember being expanded
  only while the timeline is open. Bubbles show only the
  message text (no attachments). The rail has no
  keyboard focus of its own; the Cmd/Ctrl+Alt+↑/↓ shortcuts and the
  screen reader buttons are the non-pointer ways in.
- **Open in VS Code (AV-015), remaining details:** the `vscode://`
  URLs are tested only against a fake launcher. No test opens a real
  VS Code or Cursor, and the hex-encoded Remote - SSH authority (used
  for ports other than 22, capitals and IPv6) has not been checked in a
  real editor. Windows paths on a host (`C:\…`) are not opened, only
  POSIX paths. Hosts are not detected as WSL or dev containers (no
  `wsl+` or `dev-container+` authorities). A host reached through a
  forwarded loopback port is taken to be this computer until its editor
  settings say otherwise. The host menu cannot open the host without a
  folder. There is no editor on iOS or Android.
- **Terminal panel (AV-016), remaining details:** the SSH host is always
  the AHP URL's host, so a host reached through a tunnel or a forwarded
  `127.0.0.1` port opens `ssh 127.0.0.1` (an alias in `~/.ssh/config`
  is the way around it; there is no per-host setting). `ssh` asks for
  passwords, passphrases and new host keys in the terminal itself; the
  app adds nothing. Alt+T toggles the panel even inside the terminal,
  so the shell cannot get Alt+T, and the keys cannot be rebound.
  The remote command assumes a POSIX shell (`cd`,
  `$SHELL`) and a POSIX folder path. Terminals are not kept across app
  restarts, cannot be split, renamed or moved to their own window, and
  the panel has no find or zoom. Links are only `http` and `https` URLs
  found in the text: OSC 8 hyperlinks (xterm.dart 4.0 does not parse
  them), file paths (on the remote host) and the hover tooltip VS Code
  shows are not supported, and a click on the second cell of a wide
  character in a link opens nothing. On Windows the pty is only
  exercised by `ssh -V` in CI, the environment and working folder are
  passed as Latin-1 (non-ASCII values break), and starting a terminal
  waits one second (flutter_pty's `Sleep(1000)` before `CreateProcess`).
  Exit codes read 0 under `dart test` (the runner reaps children), so the
  package tests do not check them. The web, iOS and Android only open an
  `ssh://` link. Turning off the macOS sandbox rules out the Mac App
  Store.
- **Settings from the sandboxed macOS builds:** they are copied once
  into the unsandboxed location on the first start. A setting changed in
  an unsandboxed build without the migration keeps its new value, except
  the pins, which are merged, so pins removed there come back once.
  Secure storage (hosts and tokens) was not affected and is not
  migrated. Turning the sandbox back on would move the settings again,
  with no migration the other way.
- **`/` completions (AV-044), remaining details:** the new-session
  draft has no chat to send `completions` for, so it offers the skills
  and prompts the agent lists in `AgentInfo.customizations` (parsed
  `children` only; pi lists its global ones since 10ffeb9 of
  pi-agent-host-protocol), else those of a session of the same agent
  the app has loaded. Neither holds the chosen folder's project skills
  until a session in that folder has been opened. The fallback inserts
  `/name` with a skill reference: pi loads the skill from the reference,
  but a host that ignores `_meta.uri` and names skills differently would
  not. Accepted attachments are sent when their insert
  text is still in the message, without a `range`, and are not kept in
  the synced draft. The popup shows at most eight items (the window
  follows ↑/↓, but a mouse wheel does not scroll it), shows no icons or
  `displayKind`, and Cmd/Ctrl+Enter accepts an item rather than steering
  while it is open. The queued-message editor has no completions. Only
  `/` is verified: neither the fake host nor pi triggers on `@`.
  The cache of host answers is in memory only (lost on restart) and is
  filled only by an answer for a bare `/`; the first `/` in a session pi
  has not started still waits for pi to start (seconds) unless the
  session or its agent lists skills. While the host answers, the local
  items can differ from the host's (pi's `/skill:name` replaces
  `/name`), so the list may change under the pointer. Speeding up pi's
  first answer (listing commands without starting the agent, or
  publishing a resumed session's customizations from its last run) is
  host work in pi-agent-host-protocol.
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
  it before the edit is saved. "Send now" on a queued message sends two
  actions (set the steering message, then remove the queued one), so a
  host that takes the steering message between them still shows the
  queued copy until the removal lands; it is untested against pi, and a
  steering message the agent takes just before the merge is sent again
  with the queued text appended.
- **↑ to edit the previous message (AV-087), remaining details:** a
  recalled message is sent as a new turn; the earlier turn and its reply
  stay in the history (the edit button, AV-088, replaces the latest
  message instead). ↑ steps from the composer into only the newest queued message; ↑ and
  ↓ inside the inline editor do not move to other queued messages.
  Recall uses the loaded turns only (older windowed turns are not paged
  in), the composer's current model rather than the recalled message's,
  and drops its attachments. The new-session draft has no recall.
- **Edit and restart from the latest message (AV-088), remaining
  details:** only the latest message has the button; editing an earlier
  one (truncating several turns) is not offered. AHP has no capability
  for `chat/truncated`, so the button shows on every host: one that
  rejects it (older pi-agent-host-protocol, other hosts) rolls the drop
  back with a notice, and the edited `chat/turnStarted` then runs as a
  new turn when no turn was running. pi rejects it while a pi terminal
  drives the session. On pi the dropped turns stay in the session file
  on an abandoned branch (pi's `/tree` shows them); file changes the
  dropped turn made are not undone. The ↑ shortcut does not open this
  editor.
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
  - New-session drafts live in memory only: they are lost when the app
    restarts and are not synced to other clients (AHP has no session to
    hold a draft before `createSession`). The sidebar lists only the last
    opened draft; drafts for other hosts and folders come back by
    starting "New session" there again. Drafts with no text are dropped.
  - A session being started is listed atop the sidebar, not in its
    folder or the Pinned and Chats sections, until its host creates it;
    it has no menu (it cannot be renamed, pinned or cancelled), its
    pane has no composer, and it is kept in memory only (closing the
    app forgets it, though the host still creates the session).
    Listing it under its folder would need a placeholder catalogue
    entry the session list and the detail view understand.
  - The draft's compact pickers offer only choices: a model option that
    is a switch, number or text (none seen on pi or the fake host) is
    sent with its default, and session settings that are not choices
    (such as `branch`) are form fields in the timeline area rather than
    inline chips. There is no repository or base-branch chip like the
    GitHub agents view's, beyond what the agent's settings offer.
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
  - Drafts sync the follow-up text only (not the model picked with the
    composer's chips, agents or attachments); a draft from another client
    replaces the box's text only while the user has not typed since the
    last sync.
- **Review pane, remaining details (AV-100 to AV-105):** compare-turns
  changesets (`{originalTurnId}`/`{modifiedTurnId}`) always compare the
  oldest and the newest turn (there is no picker for the two turns);
  `range`-scoped operations are not offered (no line selection, and no
  diff comments, AV-104); a non-external operation follow-up is shown as
  plain text. Side-by-side diffs appear from 900 dp in the full diff page
  only. On wide layouts the pane opens and closes (one choice for all
  sessions, remembered on the device) and resizes by dragging its edge
  (AV-005); widths are changed by pointer only (no keyboard or screen
  reader action, and no menu item). The header's details
  still list the change counts, which the pane's toggle also shows.
- **Copy and find in conversation (AV-071):** each finished turn's
  footer has a "Copy as markdown" button (the reply as markdown, like VS
  Code's "Copy") and a "Copy as HTML" button (AV-076). Not built: find in conversation (Cmd/Ctrl+F); copying the
  running turn (it has no footer until it finishes); VS Code's context
  menu actions "Copy All" (the whole chat), "Copy Final Response" and
  copying a user message; copying only the selected text. Link labels
  keep their markdown (`[**a**](/x)` becomes `` `**a**` ``, where VS Code
  writes the plain text), reference-style links and indented code blocks
  are not recognized, and a resource part is shown by its file name only.
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
  The chime was played for real only on macOS (through `flutter_soloud`
  in a throwaway integration test); Linux, Windows, iOS, Android and
  the web were built in CI and checked with widget tests. There is no
  choice of sound or volume. Silent notifications were not checked by
  hand on any platform.
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
    grows with such leftovers. There is no `pinned:` search qualifier.
    The "Pinned" section keeps the order pinned; pinned sessions cannot
    be reordered by drag (the folder drag code is tied to folder rows),
    so re-pinning is the only way to move one to the end. A folder whose
    sessions are all pinned is not shown, so its "+" button is not
    either, and host and folder counts leave pinned sessions out.
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
- **Sidebar (AV-012, AV-025, AV-092, AV-093):** folder order and
  collapsed sections are kept per device, not synced. Their stored ids
  are never pruned: a folder whose sessions are all gone (or a host
  removed) keeps its id, since a host that is not open, or sessions not
  loaded yet, cannot be told from a deleted folder; host ids collapsed
  before hosts stopped being a level (2026-10-16) also stay. Dragging a
  folder does not scroll the list near its edges, so a long list needs
  "Move up" and "Move down" or a shorter drag; a folder dropped on a
  session row (not a folder header) does not move. Keyboard users reach
  "Move up" and "Move down" through the handle that shows when the
  folder header has focus on medium and wide layouts; on compact layouts
  only touch (long press) and screen reader actions move folders. The
  Pinned and Chats sections cannot be moved. Only the open hosts' sessions
  are listed; remembered hosts that are not open are listed under Recent
  hosts on the "Add host…" page. Folders do not narrow the list
  (collapsing the others or the `repo:` qualifier does). The other
  alternative grouping of AV-031, by time, is not built. Pointer-sized
  rows are chosen by layout width (medium and wide), not by input device,
  so a touch screen at desktop width gets the 28 and 44 px rows, and its
  rows show the pin and "Mark as done" icons only while focused (no
  hover). The hover card is a tooltip: it cannot be clicked (the path is
  not a link) and does not show on touch. The colours come from the
  AV-090 tokens (`AppColors`); unread has no status token, so its dot
  uses the text colour (`colorScheme.onSurface`). The reference's
  "Automations", "+N more" and "Customizations" footer are not built,
  by decision.
- **Hosts (AV-010 to AV-012):** the open hosts' keys are saved with the
  remembered hosts, so a host is only reopened after a restart when it is
  remembered (it connected once and secure storage works); with a locked
  keyring nothing is restored. A host that never connected is dropped
  when its connect fails (its error shows on the connect page); a
  remembered one stays open, failed, with Retry and Remove in its
  submenu of the sidebar's "…" menu (whose icon has a dot meanwhile). Secure storage per platform:
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
  APK has no release key yet (`scripts/android-keystore --upload` makes
  one; a tag is refused until it exists, and the signing path has only
  run in CI with a throwaway key) and `SHA256SUMS` is not GPG-signed. The
  APK is one universal file (about three ABIs' worth of native code);
  per-ABI APKs would be smaller. The release is all or nothing: a
  failing macOS or Windows build blocks the Android APK too. No apt repository, Flathub or Snap package, Homebrew cask,
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
  - Retrying a restored host that is not up yet, the handshake timeout
    and the foreground check are covered by client and widget tests with
    an in-memory host, not driven against the fake host app or pi (for
    example, starting the app before the host).
  - Reconnects react to the timeout, the liveness ping and the app
    returning to the foreground, not to network changes (no
    connectivity plugin); a desktop app that stays in the foreground
    while Wi-Fi comes back waits for its backoff (at most 30 s).
  - A host that comes back on another port or with a new token (pi
    prints a new `tkn` unless one is configured) cannot be reconnected
    automatically; the client retries every 30 s, showing the refusal,
    until the user edits the host. Once connected, a refused token
    (HTTP 401/403) is retried like any other error.
  - The browser tests run in Chromium only (no Firefox or Safari), cover
    a subset of the desktop flows (no approvals, input requests, review
    pane or composer settings), and use the semantics tree
    (`--dart-define=SHIREITOU_SEMANTICS=true`), which a normal build turns
    on only when a screen reader asks.
- Everything else in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md)
  not listed as done in their status sections.

## Dictation (AV-047)

- Not driven end to end with a microphone: the real model runs on a
  recorded sentence (`just test-whisper`, not in CI because of the
  161 MB and 662 MB downloads), and the button on fakes. Microphone capture
  (`record`) and the permission prompts are only checked by hand.
- No dictation in the web app. The model would have to run in WebAssembly
  (sherpa-onnx has a WASM build, but the model is fetched per origin and
  WebGPU or WASM decoding is slower), and the browser's Web Speech API
  sends audio to a server, against "on the device".
- Two models, Whisper base.en and Parakeet TDT 0.6B v2, both English
  only. Parakeet v3 (25 European languages), multilingual Whisper and a
  language setting are not offered; `SpeechModel` describes any
  sherpa-onnx Whisper or NeMo transducer export, so adding one is a
  constant in `speech_model.dart`.
- The "Dictation model" menu does not say which models are downloaded
  (only the first download's dialog does),
  and there is no way to delete one from the app (delete its folder
  under `models/`). Picking a model while dictating applies from the
  next dictation.
- No hybrid mode: a fast model for the live guesses and a more accurate
  one for the final text at each pause would keep guesses quick with
  Parakeet's accuracy, at the cost of both models in memory.
- The 662 MB Parakeet download is offered on phones as on desktops;
  there is no per-platform default or warning about mobile data.
- The model is checked by size, not by hash.
- Each dictation loads the model again in a new isolate (about a second;
  audio is kept meanwhile). Keeping the isolate warm between dictations
  would start faster, at the cost of holding the model in memory.
- The current guess looks like the rest of the text; the reference
  editors show it dimmed until it is final.
- No keyboard shortcut (Cursor uses a hold-to-talk key) and no level
  meter or waveform while listening.
- A download cannot be cancelled once started (closing the app stops it;
  the `.part` file is replaced next time).
- Typing during dictation stops it, rather than dictating around the
  edit.

## Appearance (AV-097)

- The "Appearance" submenu is only in the sidebar's "…" menu, so it
  cannot be changed from the connect screen before a host is open, and
  the macOS menu bar's View menu has no entry for it (`PlatformMenuItem`
  has no checked state to show the current choice).
- Themes are mapped from Base24 palettes, so a theme's own highlight
  rules (Doom One's blue keywords and magenta functions, say) are
  approximated by the Base16 styling roles, and its UI colours (VS
  Code's `sideBar.background` and so on) are derived rather than taken
  from the original theme files.
- Colours under WCAG AA are adjusted, so low-contrast themes (Zenburn,
  Solarized, Rosé Pine Dawn) look slightly crisper than the originals.
  There is no setting to show them unadjusted.
- No custom or imported themes: adding one needs a manifest entry and
  `just themes`. Loading a user's Base16/Base24 YAML at run time would
  fit the same `ThemeSpec`.
- Themes without a Base16/Base24 port beyond the four written by hand
  (Monokai Pro, Night Owl, Andromeda, Nightfox's other styles) are not
  included.

## Selecting text in the timeline (AV-061)

- Copying a selection reads only the rows the list has built: a
  selection dragged past rows scrolled far out of view loses them, as
  Flutter's own copy does.
- The selection workarounds in `timeline_selection.dart` should be
  dropped once Flutter fixes nested scroll views' selection edges and
  adds separators between selected widgets.

## Rich copy (AV-076)

- A selection's HTML is read back from the rendered spans, so headings,
  lists, tables and quotes paste as lines of text (headings and table
  heads in bold) rather than as their HTML elements; "Copy as HTML", which
  renders the markdown, keeps them. A selection has no choice of format:
  it always copies both, and the pasting app picks one. Formatting is guessed from styles:
  weight 600 and up is bold and the `monospace` family is code.
- The pieces of a selection that are not paragraphs (code blocks, tool
  output, terminals, diffs) all become `<pre>` blocks.
- The link dialog's "Copy link" and the code and tool output copy
  buttons still copy plain text only.
- The Linux, Windows, Android and iOS runners' `setHtml` handlers are
  built in CI but have no automated test; the Dart side is tested with
  a mocked channel.

## Link dialog (AV-075)

- Only a mouse right-click opens the link dialog. Touch has no
  equivalent: a long press on a link selects a word, as the timeline's
  selection does everywhere else.
- Links in menus (the header's "…" menu's pull request and branch
  items) and the URLs a changeset operation opens by itself are not
  covered.
- Right-clicking a markdown link (and copying one, AV-076) runs the
  link's tap callback with a flag set to learn its `href`, because `flutter_markdown_plus` creates
  the link's recognizer privately; a hook in the package for secondary
  taps would remove the workaround.

## Retrying a failed turn (AV-067)

- The fake host never ends a turn with a resumable error, so Retry and
  the resumed turn (its old error folding into the steps line) are
  covered by unit and widget tests only, not driven end to end.
- A folded error counts as one of the "N steps" and is shown as the
  same red banner when the steps are expanded; it has no "retried" label.

## Starting a session (AV-040)

- "Initializing…" covers only the host's `createSession` and
  `openSession`. Once the pane switches to the started session, its view
  opens the session again and shows a centred spinner until the host
  answers; handing the draft's subscription (and prompt) to the session
  view would make the switch seamless.
- The "Initializing…" timeline shows only the first run's prompt; the
  other parallel runs (AV-045) have no placeholder until they start.

## File viewer (AV-106)

- Only replies (markdown parts) and tool-call titles link their paths.
  Paths in tool input and output (such as `grep` results), user
  messages, notes and `resource` response parts stay text.
- Paths are recognised by shape, so a word with a slash and an
  extension (`React.js/Vue.js`) becomes a link, and a file the host
  cannot read shows "Could not open …" in the viewer rather than the
  link being left out. Checking with `resourceList` or
  `resourceResolve` before linking would avoid that, at a round trip per
  path.
- Windows paths (`C:\src\a.ts`) and `~/` paths are not recognised.
- The viewer is read-only and shows one file at a time: no tabs, no
  folder tree (a path to a folder is not linked), no "open in editor"
  for the file (AV-015 opens the folder), and no rendered view of
  markdown or images (binary files show a message).
- Files longer than 200 000 characters are shown without highlighting,
  and the whole file is laid out at once; a lazily built list of lines
  would scale to very large files.
- Reading over `ssh` needs non-interactive login (a key or the SSH
  agent, and an accepted host key); a host that asks for a password
  falls back to `resourceRead`. The read is `cat`, so it needs a POSIX
  shell on the host (not a Windows host's `cmd`), and no test runs a
  real `ssh` read (the reader is replaced in `ssh_file_read_test.dart`).
- Diffs and other `ContentRef` content are still read with
  `resourceRead` only; only the file viewer uses `ssh`.
- The fake host serves no `file:` reads, so the viewer is covered by
  widget tests (with `FakeHostConnection.contents`), not driven end to
  end.
