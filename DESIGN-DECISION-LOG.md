# Design Decision Log

## 2026-10-16: Turn markers in the chat (AV-074)

- **`super_sliver_list` for the timeline, not `scrollable_positioned_list`
  or estimated offsets.** A rail that jumps to any turn must reach rows
  that were never built. `SuperListView` is a drop-in for
  `ListView.builder` that keeps the `ScrollController`, `reverse`,
  `findChildIndexCallback` (so keyed rows keep their state while a turn
  streams) and `SelectionArea`, and its `ListController` measures or
  estimates every row's extent, jumps or animates to an index, and
  reports the visible range after layout. `scrollable_positioned_list`
  replaces the scroll controller with its own and has no
  `findChildIndexCallback`, so "Jump to latest", the follow-the-bottom
  behaviour (AV-066) and keyed rows would need rework; estimating
  offsets ourselves would duplicate what the package does.
- **Markers for loaded turns only, paging on demand.** AHP does not say
  how many turns a windowed chat holds back, so the rail shows the
  loaded ones. A "Load older turns" button above the dots, and the
  previous-turn key at the oldest loaded turn, call `loadOlderTurns`,
  then jump to the newest of the new turns once they are laid out.
- **The turn in view is the newest turn whose message is at or above
  the top of the timeline**, from the list's visible range after each
  layout (scroll listeners fire before layout, so they see the old
  range). Previous and next go to the nearest message above or below
  the oldest row on screen, so pressing previous inside a long turn
  first goes back to its own message.
- **Cmd/Ctrl+Alt+↑/↓ for previous and next turn.** Alt+↑/↓ already step
  through sessions, and Cmd/Ctrl+Alt+B toggles the review pane, so the
  turn keys add Cmd/Ctrl to the session keys. They are in the macOS
  Session menu. Some Linux desktops use Ctrl+Alt+↑/↓ for workspaces.
- **Pure logic apart from the widgets.** `turn_markers.dart` holds marker
  extraction (reusing `UserMessageItem` keys and `TimelineRows`), the
  current and stepped turn, the dot spacing (even, up to 24 dp, down to
  4 dp, then scrolling) and scrubbing; `turn_rail.dart` only draws.
- **Compact layouts keep a 14 dp rail**, where dragging along the dots
  scrubs through turns (touch targets for single dots are too small
  there). One-turn chats show no rail.

## 2026-10-16: Reorder workspace folders in the sidebar

- **The user's order wins over sorting and pins.** Once the user moves
  a folder, its place is kept: placed folders come first under their
  host, in the order placed, ahead of the sort and of the "folder with a
  pinned session first" rule. Pins still sort first inside their folder.
  Folders never placed (a new working directory) follow in the usual
  sort order. `orderFolders` applies the order to the output of
  `groupHostSessions`, before `sessionTree`, so next and previous
  session (Alt+↓/↑) follow it too.
- **A move places every shown folder of the host.** `movedFolder` first
  appends the host's shown, unplaced folders to the stored order, then
  swaps places only among the shown folders. The order is then exactly
  what the user sees, and folders hidden by a filter or on other hosts
  keep their places.
- **Ids, not indices, per device.** The order and the collapsed hosts
  and folders are lists of ids (`FolderGroup.id` is `'host|path'`, a
  host's id is its key) in `PrefsStore` (`folder_order`,
  `sidebar_collapsed`), loaded by one small notifier class
  (`StoredIds`). AHP has no folder order, so it is not synced. Ids are
  not pruned: a folder missing now may be on a host that is not open.
- **Drag and drop with Flutter's `Draggable` and `DragTarget`, not
  `ReorderableListView`.** The sidebar is one lazy list of host, folder
  and session rows; a folder must move with its sessions and only among
  its host's folders. Each folder row is a drag source and a drop
  target that accepts folders of its host, and the dropped folder takes
  the target's place (a line above or below the target shows where).
  With a pointer (dense rows) the drag starts from the row with a grab
  cursor; on touch it starts after a long press, which folder rows did
  not use before.
- **"Move up" and "Move down" without dragging.** Right-click on a
  folder row, the drag handle (shown on hover or keyboard focus) and the
  row's screen reader actions move a folder one place.

## 2026-10-16: Rename a session (AV-073)

- **The protocol's `session/titleChanged`, not a local title.** AHP
  1.0.0 documents `session/titleChanged` as "dispatched by a client to
  rename a session", and 0.9.0 has it too, so the rename goes to the
  host through the existing write-ahead `dispatch`: the session channel
  shows it at once, and a rejection, no echo, or a dropped connection
  rolls it back and shows a notice. No device-local title override is
  needed, and other clients see the new title.
- **The open session's row shows its channel's title.** The list reads
  the catalogue, which changes only when the host sends
  `root/sessionSummaryChanged`. `allSessionsProvider` now overlays the
  title of a mirrored session channel (`withMirroredTitle`), so a
  pending rename shows in the list and the header together. It watches
  `sessionChannels`, which changes with session actions, not with chat
  streaming.
- **Inline in the header, a dialog in the list.** The header title is a
  click target (pointer cursor, "Click to rename" tooltip) that becomes
  a text field with the title selected; Enter or losing focus saves, Esc
  cancels. A list row is dense and tap opens the session, so its
  "Rename…" asks in a dialog instead.
- **The typed text wins over a host title change while editing.** The
  field's text is set only when editing starts, so an auto-generated
  title arriving meanwhile does not overwrite what the user types.
- **Nothing is sent for an empty or unchanged title** (`renameAction`
  trims and compares), so leaving the field without changes is free.

## 2026-10-16: A collapsible review pane, closed by default (AV-003)

- **Closed until the user opens it.** On wide layouts the review pane
  took 380 dp beside the timeline even when there was nothing to review.
  It now starts closed, so the timeline gets the width, and a button
  right of the header opens it. The button shows the change counts
  ("+3 −1 · 1 file", the header's `changesLabel`) so the user knows there
  is something to review, with a spoken label in words for screen
  readers. Medium and compact layouts keep their "Files changed" tab.
- **One choice per device, not per session.** Whether the pane is open
  is a single flag kept with `PrefsStore` (`review_pane_open`), like the
  pinned sessions. A per-session choice would make the layout jump when
  stepping through sessions with Alt+↓/↑.
- **Cmd/Ctrl+Alt+B.** The shortcut joins the AV-140 commands
  (`AppCommand.toggleReviewPane`) and the macOS Session menu (⌥⌘B). It is
  the key editors such as VS Code use for their secondary side bar, and
  the plain Cmd/Ctrl+B is left for the left sidebar. It acts only on
  wide layouts.
- **The button sits beside the header, not in it.** `_Header` is left
  unchanged; the wide layout puts the toggle in a row after it, at the
  right edge above the pane.
- **Animated by width, not built while closed.** `CollapsibleReviewPane`
  animates a width factor over 200 ms (none with reduced motion) and
  builds nothing at zero, so a closed pane subscribes to no changesets.

## 2026-10-16: Hosts and workspaces in a dense sidebar tree (AV-012, AV-025)

- **A tree replaces the host dropdown.** The sidebar lists every open
  host, its workspace folders under it and their sessions under those.
  The dropdown hid each host's status and errors behind a menu and made
  "Add host…" hard to find; on the tree's host rows the status, Retry
  and Remove are always visible, and "Add host…" is the last row.
- **Tapping a host still narrows the list; folders do not.** With
  several hosts, a host's sessions can be far down the list, so
  narrowing stays (it also scopes "New session" and "Disconnect" to that
  host). The other hosts stay listed without their folders, so another
  host is one tap away. Folders are not a filter: collapsing the other
  folders, or the `repo:` search qualifier, already narrows to one, and
  a second kind of selection on the same rows would be confusing. Folder
  rows toggle on tap; host rows toggle with their chevron.
- **Pure tree functions, rendered lazily.** `sessionTree` (hosts with
  their folders) and `sidebarRows` (the rows left after collapsing) are
  pure, and `SessionListView` draws the rows with `ListView.builder`
  instead of nested `ExpansionTile`s. The folders keep the order of
  `groupHostSessions`, so a user-defined folder order (drag and drop)
  only has to reorder the folders before `sessionTree`. Opening a
  session expands its host and folder (`revealSession`), so Alt+↓/↑ and
  notifications never land on a hidden row.
- **Custom rows instead of `ListTile`.** A two-line `ListTile` places
  its lines at fixed baselines and cannot go below about 48 px, so the
  rows are a small `InkWell` with the same button and selected
  semantics. With a pointer (medium and wide layouts) host and folder
  rows are 28 px and session rows 32 px (13 px title, 11 px details,
  16 px icons); compact layouts keep 48 px rows for touch. Status badges
  keep the 11 px label and lose padding instead.
- **Collapsed state is kept in memory.** Remembering it is left for
  later, with the folder order, so both can share one stored setting.

## 2026-10-16: Click a queued message to edit it in place (AV-081)

- **An inline editor in the row, not the follow-up box.** The follow-up
  box holds the chat's draft, synced to the host (`chat/draftChanged`),
  so loading a queued message into it would replace or mix with that
  draft, and sending from it starts a new message rather than editing
  the queued one. Editing in the row keeps the draft and the message's
  place in the queue, and matches how it is shown. The menu's "Edit"
  opens the same editor; the old edit dialog is gone.
- **Enter saves, Shift+Enter adds a line, Esc cancels, empty removes**,
  like the follow-up box's keys. Save and Cancel buttons do the same
  for touch and screen readers.
- **The tile and the trailing buttons are siblings.** Only the
  `ListTile` (icon, text, subtitle) opens the editor, so a tap on the
  menu or the drag handle never does.
- **A message the host sends or removes while being edited closes the
  editor and is not set again.** `savePendingEditAction` returns null
  for a message no longer pending, because `chat/pendingMessageSet` with
  its ID would queue it anew; the panel shows a notice instead. The
  pure function also skips unchanged text and turns blank text into
  `chat/pendingMessageRemoved`.

## 2026-10-16: Pinned sessions (AV-028)

- **Pinned sessions lead their folder, and that folder leads the list.**
  The list is always grouped by working directory (AV-025), so a
  separate "Pinned" section would show a session away from its folder
  and break the one-folder-per-directory rule. Instead the sort puts
  pinned sessions first (`compareHostSessions`), and since folders are
  ordered by their first session, a folder holding a pinned session
  moves to the top with no extra rule. Pinned sessions keep the chosen
  sort (AV-026) among themselves.
- **Kept on this device, by host and session.** AHP has no pin field, so
  the set is stored like run groups (AV-045): a JSON list of
  `{host, session}` in `shared_preferences` through `PrefsStore`, with
  the pure set and JSON functions in `pinned_sessions.dart` and the
  notifier in `pinned_store.dart`.

## 2026-10-16: Working indicator at the bottom of the timeline

- **A timeline row, not an overlay.** The indicator is a `WorkingItem`,
  the last row `timelineItems` returns while the chat works. The
  timeline is a reversed list, so the last row sits at scroll offset 0:
  it is in view whenever the user is at the bottom and scrolls away with
  the rest when they read back, without extra scroll code. Rejected: a
  `Stack` overlay, which would cover the newest output.
- **Working means `InProgress` or an active turn, but not
  `InputNeeded`.** `isChatWorking` checks the bits (never equality) and
  also the active turn, so the indicator shows as soon as a turn starts.
  While the agent waits on the user the approval or question is the
  call to action, so the indicator is hidden.
- **Pulsing dots, static under reduced motion.** Three dots pulse in
  turn (`typingDotOpacity`, a pure function of the animation's
  progress); with `MediaQuery.disableAnimationsOf` the row shows a
  static "…" and runs no ticker. The row is one semantics node labelled
  "Agent is working: <activity>". Widget tests that `pumpAndSettle`
  with a working chat ask for reduced motion (`reduceMotion` in
  `test/fixtures.dart`).

## 2026-10-16: Notify reliably when it is the user's turn (AV-121)

- **Root cause: permission was asked for lazily, inside the first
  notification, and the web build had none.** `LocalNotifier`
  initialized `flutter_local_notifications` (which on macOS, iOS and
  Android 13 shows the permission prompt) only when the first event was
  due, which is when the user is away in another app. Every
  notification waited on that prompt; if it was missed or refused, the
  failure was cached for the rest of the run without a log line or any
  sign in the UI, so nothing was ever posted. The web app (`just run`
  opens it in Chrome) posted no notifications at all. The status
  pipeline itself was sound: pi publishes every status change through
  `root/sessionSummaryChanged`, and the widget tests saw the events.
  Now the app asks at start (`AttentionNotifications.initState`), a
  refusal is logged and not cached (a later grant in System Settings
  works without a restart), and the bell menu offers "Allow
  notifications…" while permission is refused.
- **The browser's Notification API directly, not the plugin's web
  support.** `browser_notifier_web.dart` uses `package:web`'s
  `Notification` (page notifications) behind a conditional import, like
  the OAuth redirect receiver. Rejected: `flutter_local_notifications`'
  web implementation, which needs its own service worker in place of
  Flutter's. Page notifications are enough while the tab is open; push
  for a closed tab belongs to the relay (AV-123).
- **The turn ending is the trigger.** `attentionEvents` stays a pure
  function of two catalogue snapshots; a turn that ends (`InProgress`
  clears) is reported as failed when the new status has `Error`, else
  finished, so a host that keeps `Error` set into the next turn no
  longer hides that turn's failure. Defaults are unchanged: all three
  events notify.
- **Focus starts from the real lifecycle state** (`isForeground`)
  instead of assuming focus, and only the session on screen in a
  focused window is quiet. A clicked notification also raises the window
  (`bringWindowToFront`), since Linux and Windows do not.

## 2026-10-16: User-reported gaps take highest priority

- **Usability feedback goes first.** Pinning, renaming sessions from the
  title, a working indicator in the chat, a denser sidebar, hosts and
  workspaces listed in the sidebar instead of a dropdown, drag and drop
  workspace ordering, click to edit queued messages, desktop
  notifications when the user's turn comes, and a collapsible review
  pane closed by default, are listed at the top of
  `GAPS.md`, ahead of the protocol and platform work.

## 2026-10-16: Windows, iOS and Android in CI, app icon, AppImage and releases

- **Mobile OAuth through the app's URL scheme, with a little native code
  instead of a plugin.** iOS can suspend the app while the browser is in
  front, so the loopback redirect used on desktop is unreliable there.
  The redirect goes to `dev.shireitou.shireitou:/oauth/callback`, a
  private-use scheme (RFC 8252 §7.1) registered by dynamic registration
  like the loopback URI. iOS uses `ASWebAuthenticationSession` (one class
  in `AppDelegate.swift`), Android the system browser and an intent filter
  on `MainActivity` (now `singleTask`, Flutter deep linking off so the
  redirect is not pushed as a route). Rejected: `flutter_web_auth_2`,
  which pulls in `desktop_webview_window` and with it WebKitGTK on Linux,
  a heavy dependency for code the desktop apps do not use. Rejected:
  claimed `https` app links, which need a domain and its
  `assetlinks.json`/`apple-app-site-association`.
- **One mobile smoke test instead of the desktop flows on phones.** The
  fake host flows assume the wide layout (1400 x 1000); on a phone the
  app has the compact one. `mobile_smoke_test.dart` checks what is
  platform specific (secure storage round trip, the compact layout,
  approvals and input against the in-process fake host) on an API 34
  emulator and an iPhone simulator. The Windows job runs the full desktop
  smoke test against pi and the fake host flows, like Linux and macOS.
- **Panels take a share of the session view's height.** The emulator's
  default 320 x 640 screen showed the session view overflowing while an
  input request was pending: the "Waiting for you" panel was capped at
  45 % of the whole screen and the composer group below the timeline not
  at all. Both are now capped from the view's own height (35 % and 45 %,
  scrolling past it) and the timeline takes the rest. The emulator keeps
  its small default screen on purpose, as the smallest phone layout.
- **Windows reports drags when they end.** window_manager emits only
  `resized`/`moved` on Windows (at the end of a drag), so the placement
  saver listens to those too; the smoke test found the placement was
  never saved there.
- **Local notifications on iOS and Android too.** The notification plugin
  already needed desugaring on Android to build at all, and posting while
  the app runs (Android keeps it running a while in the background) is
  better than nothing until the push relay exists. Android asks for the
  permission on the first notification (13+), on its own channel, with a
  vector tower icon kept from resource shrinking.
- **Secure storage options per platform.** iOS: keychain items readable
  after the first unlock and never leaving the device
  (`first_unlock_this_device`), so a background reconnect can read a token
  and a restore to another phone does not carry it. Android: backups off,
  because a restore would bring the encrypted values without the Keystore
  key (the plugin would then wipe them anyway).
- **Cleartext allowed on mobile.** Most hosts are `ws://` on a LAN,
  `localhost` or a VPN address, which Android and iOS block by default;
  the app allows cleartext (`usesCleartextTraffic`, ATS
  `NSAllowsArbitraryLoads`) and declares local network usage on iOS, as
  the desktop apps already do.
- **The icon is an SVG rendered by Chromium.** A control tower (司令塔)
  sending signals, in the theme's indigo with amber signals.
  `scripts/render-icon` renders the full-bleed, rounded and foreground
  variants and the Linux sizes with Playwright's Chromium (already used
  by the browser tests), then `flutter_launcher_icons` writes every
  platform's files. Rejected: committing only PNGs (no editable source)
  and adding librsvg or Inkscape to the toolchain.
- **AppImage without bundled GTK.** The AppImage wraps the Flutter bundle
  and relies on the system's GTK 3 and libsecret, like the `.tar.gz`;
  every desktop distribution has them, and a bundled GTK breaks theming
  and input methods. appimagetool is pinned to 1.9.1 and run extracted
  (no FUSE in CI).
- **Releases from tags, signing only with secrets.** `release.yml` builds
  every package on `v*` tags (and on pushes to `main` that touch
  packaging, without publishing), checks the tag against the pubspec
  version, and publishes with `softprops/action-gh-release` plus
  `SHA256SUMS`. Each signing step (Developer ID and notarization, Windows
  Authenticode and MSIX, Android release key, GPG for the checksums) runs
  only when its secrets are set, so the owner only adds secrets. An
  unsigned `.msix` cannot be installed, so it is built in CI but left out
  of releases; the debug-signed APK is released so Android users can
  install something before a release key exists. iOS is not released on
  GitHub (App Store/TestFlight only). Linux arm64 is built on GitHub's arm
  runners from a Flutter checkout, since Flutter has no arm64 Linux SDK
  archive.
- **Wayland placement is not a gap.** Wayland clients cannot set or read
  their window position, so restoring only the size there is the correct
  behavior; it moved from GAPS.md to docs/desktop.md. The window's app ID,
  `WM_CLASS` and desktop entry are all `dev.shireitou.shireitou`
  (`StartupWMClass` added), so docks match the window to its icon, and
  the minimum size is checked under openbox in CI.

## 2026-10-16: App-level tests against pi, reconnects end to end, and the web app in a browser

- **pi's own faux model instead of an API key or a fake pi.** pi-ai ships a
  scripted `faux` provider, and pi-agent-host-protocol's tests run the host
  with it. `scripts/pi-faux-host.ts` does the same outside that repo: it
  imports the host's modules by file URL from the checkout CI already has
  (`npm ci`), embeds pi with the faux model registered, and answers by
  keyword (`tool`, `slow`, `think`, else an echo). Everything above the
  model is real pi: sessions on disk, titles, archive, queued messages,
  drafts, tool execution, `reconnect` and its replay buffer. Rejected: a
  real provider in CI (secrets, cost, flakiness) and pi's RPC mode with a
  fake `pi` (would skip pi's own session code). The price is a dependency
  on the host's internal module paths, noted in GAPS.md.
- **A TCP relay to break connections.** Real networks fail below
  WebSocket, so tests put `TcpRelay` (Dart, in `ahp_fake_host`) or `Relay`
  (Node, for Playwright) between client and host: `drop`, `refusing` and
  `hold` (lose what the client sends, for the write-ahead rollback). A
  host restart is a real `node` restart on the same port and state
  directory, which pi answers with `-32008`. The fake host got the same
  controls in process (`dropConnections`, `refuseConnections`,
  `loseActions`, `removeSession`, `connectInMemory`) and a real `reconnect`
  (replay buffer, snapshots past it, `missing`) instead of always `-32008`.
- **Playwright, not `flutter drive` with chromedriver.** Playwright drives a
  real browser from outside the app: real new tabs (so the OAuth redirect
  page and `BroadcastChannel` run for real), keys delivered by the browser,
  and Node can start, relay and restart hosts, which a test compiled into
  the web app cannot (`dart:io` is unavailable there). It installs its own
  Chromium on Linux x64 and arm64 without system Chrome or a matching
  chromedriver. The web build is made with
  `--dart-define=SHIREITOU_SEMANTICS=true`, which keeps Flutter's
  semantics tree on so widgets are found by role and accessible name
  instead of canvas coordinates.
- **Timeline text is plain `Text` inside the `SelectionArea`.** Driving the
  web app showed that `SelectableText` (and selectable markdown) inside
  the timeline's `SelectionArea` reach the browser's accessibility tree as
  empty read-only text fields, so screen readers (and the tests) could not
  read messages or replies. The area already makes plain `Text`
  selectable, so the inner selectable widgets were dropped.
- **Shared app harness.** `app/integration_test/harness.dart` holds the
  in-memory host store, the test OAuth browser and the frame-pumping
  helpers for both the fake host and the pi app tests.
- **CI layout.** `integration` runs the client flows against pi (seconds);
  `linux-desktop` adds the pi app flows under Xvfb after the fake host
  flows (one build, about two minutes more); a new `web` job builds the web
  app and runs Playwright with retries off locally and one retry in CI,
  uploading traces on failure. macOS keeps its existing steps.

## 2026-10-16: OAuth sign-in, re-authentication, and the rest of tool call interaction

- **OAuth client written on `http` and `crypto`, not the `oauth2`
  package.** The MCP authorization spec (2025-11-25), which AHP's
  `McpAuthRequirement` follows, needs RFC 8414/OpenID discovery, RFC 7591
  dynamic registration, PKCE `S256` (refusing servers that do not
  advertise it) and the RFC 8707 `resource` parameter in both the
  authorization and the token request. `oauth2` has none of discovery,
  registration or resource indicators and hides its PKCE verifier, so it
  would have been wrapped and patched around. `oauth.dart` in
  `ahp_client` is small, pure where it can be (PKCE, URLs, response
  parsing) and tested against RFC 7636's vector; `OAuthHttp` does the
  HTTP. Endpoints must be HTTPS except on loopback (for the fake server).
- **Clients: the host's `McpOAuthClient`, else dynamic registration.**
  When the challenge carries a pre-registered client the spec requires
  using it (confidential clients authenticate with
  `client_secret_basic`, or `client_secret_post` when that is all the
  server offers). Otherwise a public client is registered for the
  redirect URI on every sign-in; caching registrations was rejected
  because the loopback port changes each time. Client ID Metadata
  Documents need a hosted HTTPS document for shireitou and are left out
  (GAPS.md); without either, the user can still paste a token.
- **Redirects: loopback on `dart:io`, a callback page on the web.** The
  native apps listen on `http://127.0.0.1:<random port>/callback`
  (RFC 8252 §7.3; the macOS release build gains the
  `network.server` entitlement) and open the system browser with
  `url_launcher`. The web app redirects to its own
  `oauth_callback.html`, which posts the URL on a `BroadcastChannel`
  (sturdier than `window.opener`, which cross-origin pages often lose).
  `flutter_web_auth_2` was not added: it would add custom URL schemes on
  desktop that need registering per platform, and the loopback receiver
  is testable in-process.
- **`HostAuthenticator` in `ahp_client` owns tokens and re-auth
  (AHP-061).** `AhpClient` gained an `authRequired` stream
  (`auth/required`) and an `onAuthRequired` hook: commands go through
  `_request`, which on `-32007` lets the hook sign in to the error's
  resources and then retries once (not `initialize`, `reconnect`,
  `authenticate` or `ping`). The authenticator refreshes when it can,
  else asks the user through an injected `InteractiveSignIn`; it never
  replays a token the host called `expired`, replays a held unexpired
  token on `required`, refreshes a minute (or a fifth of the lifetime)
  before `expiresIn` runs out, and pushes held tokens after every
  (re)connect, which is how the spec's "re-check after reconnecting" is
  met. `authenticate` sends the remaining lifetime as `expiresIn`
  (elapsed time subtracted, as the spec requires) and the granted
  `scopes`. Concurrent renewals of one resource share one attempt.
- **Tokens persist per host in secure storage.** `HostStore` saves each
  host's tokens (refresh tokens included) under `tokens:<host key>`;
  the authenticator loads them before connecting. Keeping them in memory
  only was rejected: users would sign in again after every restart.
- **One dialog, two entry points.** "Sign in" buttons (tool cards, MCP
  server chips, the composer's notice for an agent's required
  `protectedResources`) call `signInFromUi`; prompts nobody clicked for
  (`auth/required`, `-32007`) open the same `SignInDialog` on a root
  `navigatorKey`. The dialog offers "Sign in with browser" when the
  resource names an authorization server, with "Use an access token
  instead" folded below it (or shown alone otherwise), and lists the
  scopes requested (the challenge's `requiredScopes`, else
  `scopes_supported`).
- **Fake OAuth authorization server in the fake host.** `FakeOAuthServer`
  runs in-process on a loopback port with metadata, registration, an
  authorization endpoint that approves at once (or refuses on cue) with a
  `302` back to the redirect URI, and a token endpoint that verifies the
  PKCE verifier, client, redirect URI and resource, and rotates refresh
  tokens. Tests play the browser by fetching the authorization URL with
  `http`, which follows the redirect into the app's loopback receiver.
  The host now checks `authenticate` tokens (its server's, or the
  `mcp-token` stand-in for a pasted one), answers `-32007` for a bad
  token, adds a "Secured agent" whose `protectedResources` make
  `createSession` fail with `-32007` until signed in, and an `expire`
  flow that sends `auth/required` (`expired`).
- **Tool call interaction completed against the fake host.** New flows:
  `choose` (grouped confirmation options and a risk assessment that
  loads, then completes), `command` (`editable` input), `result`
  (`requiresResultConfirmation`) and `draft` (another client's
  `chat/inputAnswerChanged`). The app's `ApprovalBar` renders options in
  the host's order with a divider between groups (the first approval
  filled, others tonal, denials outlined), the risk as a level (low from
  0.7, high under 0.4), safety percentage and reason, "Edit input" with a
  JSON check (the edit is sent compact, and only when it differs), and
  "Use result"/"Discard result". A denial option whose ID or label says
  "skip" is sent with reason `skipped`, since the protocol does not mark
  skip options. Input forms sync each answer as a draft 400 ms after the
  user stops typing, and take other clients' drafts for fields the user
  has not touched.

## 2026-10-16: Open questions answered: todos, PR links, best-of-N, notifications, web transport, `ahp_sdk`

Researched against AHP 1.0.0 and its main branch
(microsoft/agent-host-protocol), VS Code's agent host
(`src/vs/platform/agentHost`), pi-agent-host-protocol and `ahp_sdk` 0.1.0.

- **Todos and plans (AV-070, AV-046): read todo tools, not response
  parts.** AHP has no todo or plan response part, and none is proposed
  upstream. Agents keep their list with a tool whose input is the whole
  list (Claude `TodoWrite`, Copilot CLI `update_todo`, VS Code
  `manage_todo_list`, Codex `update_plan`), which hosts pass through as a
  tool call. The client recognizes these tool names and input shapes
  (pure `todo_list.dart`), renders each call as a checklist card instead
  of a JSON tool card, never groups them, and pins the newest unfinished
  list above the follow-up box. Matching on tool names is a heuristic,
  but it is how VS Code itself renders them; an unknown shape falls back
  to the normal tool card. Plan mode stays the agent's `mode` setting;
  plan reviews are input requests, so the input form now lists
  described single-select options and sends `allowFreeformInput` text as
  `freeformValues` (or a text answer when nothing is selected), matching
  how VS Code's host reads plan review answers. VS Code's extra
  `planReview` field is non-standard and dropped by the generated types;
  keeping unknown fields was rejected for one host's extension.
- **PR and branch links (AV-105): `_meta` conventions.** AHP has no
  field. The client reads `_meta["copilot.githubReferences"]` (only the
  entry with the `headBranch` relation, and only a GitHub pull request
  URL) and `_meta.git` (`branchName`, `githubOwner`, `githubRepo`), from
  the session state, else the catalogue summary, and shows header chips
  that open them. VS Code's folder-keyed `githubData` is not read: its
  host already publishes the Copilot convention for the current branch.
- **Best-of-N (AV-045): run groups live on the device.** AHP has no
  linked sessions and `_meta` is host-owned, so the link is client state:
  a `RunGroup` (prompt, members as host + session + label, winner) in
  `shared_preferences` behind a `PrefsStore` interface, newest 50 kept.
  The composer starts up to five runs (agent and model per run, same
  prompt and folder, session settings only for runs of the same agent)
  in parallel; failures of some runs are reported and the rest are
  grouped. A comparison page shows each run's status, changes and latest
  reply, marks a winner and can archive the others. Rejected: encoding
  the group in session titles or `_meta` (not ours to write), and a
  server-side group (needs a service).
- **Notifications (AV-121 done, AV-123 deferred).** Push for a closed app
  needs a relay; it is designed in `specs/push-relay.md` (a Dart relay
  next to the hosts that watches catalogues and sends APNs/FCM) and not
  built, because it needs Apple/Google accounts and signing the project
  does not have. Instead the desktop apps post local notifications with
  `flutter_local_notifications` 22.3.1 (Linux D-Bus, macOS
  UserNotifications, Windows toasts; well maintained, one API). Events
  come from catalogue status transitions only (pure
  `attentionEvents`): needs input, finished, failed; new or archived
  sessions never notify, so connecting does not flood. Nothing is posted
  for the session on screen while the window has focus. Each event can be
  turned off from a bell menu (saved with `PrefsStore`); clicking a
  notification opens the session through `openSessionRequestsProvider`.
  The web build is left out: the plugin's web support replaces Flutter's
  service worker. Its transitive packages are pinned to releases at least
  two weeks old.
- **Web transport: explain, don't work around.** WebSockets have no CORS;
  pi and VS Code check only `tkn` (403 otherwise) and ignore `Origin`,
  listen on 127.0.0.1 and serve no TLS. So the client normalizes
  `http(s)://` to `ws(s)://`, refuses `ws://` to another machine from an
  https page up front (mixed content), and turns handshake errors into
  readable `ConnectionProblem`s (native: 401/403, other statuses, TLS,
  refused, lookup; web: the causes a browser hides). `wss://` already
  worked; tunnels and TLS proxies are documented in the client spec.
- **`ahp_sdk`: ignore (keep as a reference).** 0.1.0 (2026-08-01) still
  negotiates protocol 0.7.0, has no subscription refcounting or reconnect,
  one maintainer, no stars and no releases since. Forking would mean
  replacing its generated types and reducers with ours, and contributing
  would mean porting our reconnect, write-ahead and 1.0.0 work into a
  different code generator and API. Our client covers more of 1.0.0 and
  is tested against pi and the fake host. Revisit if it reaches 1.0.0
  with reconnect and gains maintainers; the protocol repo's reducer
  fixtures are the better shared reference.

## 2026-10-16: Session list actions, keyboard shortcuts, optimistic panel answers and restored hosts

- **Done filter:** "Done" is a non-archived session whose agent is
  finished: not in progress, not waiting for input and not failed, read
  or unread (an unread finished session is both Done and Needs
  attention). The chips are Active, Needs attention (with its count),
  Done, Archived, All.
- **Search and sort live in the list, not in the URL or storage:** a
  GitHub-style query (`parseSessionQuery`): words must all appear in the
  title, and `agent:`, `status:`, `repo:`, `host:` qualifiers narrow it
  (`status:input,error` lists alternatives; an unknown `key:value` is a
  title word). `repo:` matches the folder path, the project URI or name,
  or the repository `worktreeInfoOf` reports, because AHP has no repo
  field. Sorting orders sessions in a folder and folders by their first
  session, so the worktree grouping (AV-025) stays; "needs attention
  first" ranks input, error, unread, then the rest.
- **Row actions without subscribing:** the row menu (right-click,
  long-press, screen reader custom actions), a left swipe and the
  multi-select bar dispatch `session/isArchivedChanged` and
  `session/isReadChanged` straight to the session channel, which AHP
  allows without a subscription. The swipe never removes the row
  (`confirmDismiss` returns false): the host's catalogue update moves it,
  so nothing disappears before the host agrees. The screen keeps the
  `clientSeq` of what it sent (`HostConnection.dispatch` now returns it)
  and reports rejections of those, unless the session is open, whose view
  reports failures of its own session and chats.
- **Attention count (AV-120):** one `attentionCountProvider` over every
  live host; it is the "Needs attention (n)" chip and the window title
  "(n) shireitou" (MaterialApp's title on the web; `window_manager` on
  desktop).
- **Shortcuts as commands (AV-140):** keys map to `AppCommand`s sent on a
  broadcast (`appCommandsProvider`); the sessions screen handles new
  session, search and next/previous, and the visible session view handles
  stop and focus composer, each only when its route is on top (a pushed
  composer or dialog swallows them). Cmd on Apple platforms (also in a
  browser on a Mac), Ctrl elsewhere. On macOS the native menu bar owns the
  keys: a new Session menu lists the commands with their key equivalents,
  and the Flutter `Shortcuts` are left out there so a press cannot run a
  command twice; elsewhere `AppShortcuts` sits above the navigator, so the
  keys work wherever focus is, including text fields (Alt+↑/↓ win over a
  field's own Alt+arrow navigation). Next/previous follow the visible list
  order and stop at the ends; on compact layouts they replace the open
  session page instead of stacking pages. The spec asks for no help
  overlay, so none was built; tooltips and the search hint name the keys.
- **Optimistic answers in the "Waiting for you" panel:** an answer
  (confirm, input completed, or a failed `chat/toolCallComplete`) hides
  its entry at once, because the client may not mirror the chat and so
  cannot apply the answer itself. The entry comes back when an
  `ActionFailure` with the answer's channel and `clientSeq` arrives (a
  rejection), or when the host has not removed it after 30 s (the
  client's pending-action timeout, which does not run for unmirrored
  channels). Hidden ids are dropped once the host removes the entry.
- **Client tool executions per spec:** `toolClientExecution` entries are
  not questions (they do not raise `InputNeeded`), so they never appear in
  the panel. Other clients' executions show as "N tools running on
  another client" in the header. This app provides no client tools and
  does not announce any, so a host should never delegate one to it; if
  one does (the entry's `clientId` is this client's), the app completes
  the call once with a failed result (`code: unsupported`), the
  protocol's path for the owning client, instead of leaving the turn
  waiting forever.
- **Restored hosts:** the keys of the open hosts are saved next to the
  remembered hosts (`open_hosts` in secure storage, updated on connect
  and disconnect, so quitting keeps them and "Disconnect" clears them).
  On start `OpenHosts.restore()` reconnects those that are still
  remembered, in their old order. A remembered host whose connect fails
  now stays open with its error, Retry and Remove in the host switcher,
  and under Recent hosts on the connect screen (shown while no host is
  live); a host that never connected is still dropped, so a mistyped URL
  does not linger.
- **Fake host:** `rejectTypes` makes the host refuse chosen client action
  types; `client` and `delegate` flows delegate a tool call to another
  client (which completes it) or to the sender.
- **Flaky headless draft step (fixed):** the fourth integration test's
  draft step typed into `find.byType(TextField).last`. Headless, frames
  only come from pumps, and the queued message's Edit dialog was often
  still running its exit transition, so `.last` was the dialog's field,
  which can no longer take focus (its route is popping); the text never
  reached the follow-up box and no draft was sent. The test now waits for
  the dialog to close and types into the `FollowUpInput`'s field.

## 2026-10-16: Several hosts at once, the full composer, and model and mode pickers

- **One client per host, scoped by an InheritedWidget:**
  `hostConnectionProvider` became a Riverpod family keyed by the host key
  (the URL without `tkn`, as for remembered hosts), each entry owning one
  `AhpClient`. `openHostsProvider` lists the connected hosts in the order
  they were added; `hostInfosProvider` derives status and labels, and
  `allSessionsProvider` merges the catalogues into `HostSession`s. Rather
  than threading a host argument through every widget of the session view,
  a `HostScope` `InheritedWidget` above the view names the host
  (`context.host`); views are keyed by `(host, session)`, so the lookup
  registers no dependency. Pushed pages and dialogs wrap themselves in a
  `HostScope`. Alternative considered: Riverpod scoped overrides, which
  need `dependencies` declared on every provider that reads them.
- **Host switcher, not host tabs:** the app bar title is a menu showing
  "All hosts" or one host, each host's status and error, and "Add host…"
  (the connect page, pushed). The list shows every host by default (AV-012),
  folders are keyed by host and folder (the same path on two hosts is two
  folders), and folder headers name the host when several are listed.
  Labels prefer the user's name, then `serverInfo.name`, then the URL, and
  append the address when two would read the same. A host whose first
  connect fails is dropped again (its error stays on the connect page);
  which hosts were open is not restored after a restart (GAPS.md).
- **Storage problems are shown, not just logged:** `HostStore` now throws;
  `SavedHosts` keeps the list in memory, reports the error to
  `hostStorageProblemProvider`, and `retry()` merges the stored and
  in-memory lists and saves. `describeStorageError` maps the Linux plugin's
  `KeyringLocked` code and a missing `org.freedesktop.secrets` service to
  plain advice; the banner (connect page and session list) has Retry and
  Dismiss.
- **Agent/model selection (open question answered):** surveyed pi 0.1.0
  and VS Code's agent host (`src/vs/platform/agentHost`). Both put the
  model on each message (`Message.model`, ids from `AgentInfo.models`) and
  its options in `SessionModelInfo.configSchema`, both using a
  `thinkingLevel` property (pi: off…xhigh; VS Code Claude "Effort Level"
  low…max; Copilot and Codex add `reasoningEffort`, `contextTier`,
  `contextSize`). The mode is a session setting from `resolveSessionConfig`
  in VS Code (`mode`: interactive/plan/autopilot, `sessionMutable`; also
  `autoApprove`, `isolation`, `branch` with `sessionConfigCompletions`),
  not `Message.agent`, which selects custom agents. pi stubs
  `resolveSessionConfig` with an empty schema and has no mode. So: the
  composer renders the selected model's `configSchema` as a form and sends
  `ModelSelection {id, config}` with the first message, and renders
  whatever `resolveSessionConfig` returns (re-resolving when the agent,
  folder or a setting changes; `enumDynamic` properties get host
  suggestions) and passes the values as `createSession` `config`. No
  setting names are hard-coded. In a session, a bar above the follow-up
  box picks the next message's model and options (starting from the last
  message's `Message.model`) and offers the `sessionMutable` choice
  settings, changed with `session/configChanged`; all settings are listed
  in session details. `ConfigPropertySchema` and
  `SessionConfigPropertySchema` are mapped to one pure `ConfigField`.
- **Worktree metadata (open question answered):** AHP 1.0.0 has no repo or
  branch fields. VS Code's host sets `SessionSummary.project` to the git
  repository root (named by `displayName`) and puts the branch in
  `_meta.git.branchName` (a documented VS Code convention); pi reports
  neither. Folder labels therefore stay the folder name and path, plus the
  repository when `project` names one other than the folder (a worktree or
  sub-folder) and the branch from `_meta.git` when present; pi's folders
  show the path only.
- **Creation failures surface at once:** pi answers `createSession`, then
  dispatches `session/creationFailed` on the session channel and never
  lists the session; VS Code lists it with an error status. `createSession`
  now subscribes to the URI it sent while waiting (pi accepts its
  `ahp-session:/` alias) and the pure `creationOutcome` returns a failure
  for `lifecycle: failed`, keeps waiting while `creating`, and otherwise
  waits for the catalogue. A second subscriber to a channel now waits for
  the first one's snapshot, which `openSession` right after
  `createSession` needed.
- **Folder browser and recent folders:** "Browse…" uses `resourceList`
  (one folder at a time, folders only). Recent folders are the host's
  sessions' folders, newest first, instead of a separate stored list.
- **Fake host:** `name` and `titlePrefix` tell a second instance apart; an
  in-memory filesystem answers `resourceList`; the `scripted` model has a
  `thinkingLevel` option; `resolveSessionConfig` returns `mode` and, in the
  repository, a dynamic `branch`; sessions there carry `project` and
  `_meta.git`; creating a session in a missing folder fails like pi; the
  `settings` keyword echoes the model, options and settings.

## 2026-10-16: Timeline previews, review pane, chat switcher and windowed history

- **More mirrored channel kinds, one code path:** `HostState` now mirrors
  terminal, changeset and canvas channels (`ChannelKind.terminal`,
  `.changeset`, `.canvas`) next to sessions and chats, each as a
  `ChannelMirror`, so write-ahead works for `changeset/filesReviewChanged`
  like any chat action. The per-kind `switch`es in `host_state.dart`
  became one generic `updateMirror` (a `MirrorUpdate` is a generic
  function over the mirror's state type), used by dispatch, envelopes,
  expiry and reconnect. `reduceTerminal` ports the protocol's
  `terminalReducer`; the changeset and canvas reducers are now wired.
  Annotations, resource watch and automation channels stay unmirrored (no
  UI needs them).
- **Subscriptions follow the widgets:** a `ChannelSubscriber` widget
  subscribes while it is mounted and releases on dispose (the client's
  reference counting makes nested and repeated subscriptions cheap), so a
  terminal is only streamed while its card (or page) is on screen, a
  changeset while the review pane shows it, and another chat while the
  switcher has it open. `ContentRef` text (diff sides) is read with
  `resourceRead` through an auto-disposing family provider, so it is
  fetched once while visible.
- **Windowed delivery is the protocol's, plus cheap rendering:** AHP 1.0.0
  windowing is host-driven: a snapshot may carry only the newest turns and
  `turnsNextCursor`; `fetchTurns` makes the host dispatch `chat/turnsLoaded`.
  The client adds `loadOlderTurns` (one fetch per chat at a time), and the
  timeline's oldest row is a "Loading older turns…" row that asks for the
  next page when the list builds it, which happens as the user scrolls
  near the top. The protocol cannot unload turns, and the host's state is
  shared, so the client keeps what it loaded (see GAPS.md). Long chats
  stay cheap without a separate window: the reducer already shares the
  `turns` list while a turn streams, so the app memoizes each finished
  turn's rows and the flattened rows of the whole `turns` list
  (`Expando`s keyed on the immutable objects); a delta rebuilds only the
  active turn's rows, `TimelineRows` indexes the two parts without
  copying, the reversed `ListView.builder` builds visible rows only, and
  rows are keyed with a `findChildIndexCallback` so expanded cards keep
  their state when rows are added below or paged in above. Session usage
  is memoized the same way.
- **Third-party packages:** `re_highlight` (a Dart port of highlight.js
  11.9, the highlighter `re_editor` uses; synchronous, so tests and
  streaming need no async setup) highlights fenced code and diff lines;
  only 24 common grammars are registered to keep the web build small.
  `diffutil_dart` (Myers' algorithm) computes line diffs; the app replays
  its edit script to get unified lines, collapses unchanged stretches and
  pairs lines for side-by-side. `flutter_markdown_plus` renders code
  blocks through a `pre` builder with a copy button. Terminal output is
  shown as plain text with a small escape-sequence stripper rather than a
  terminal emulator package, since the app does not send input.
- **Tool call previews instead of more cards:** terminal output
  (`ToolResultTerminalContent`, live while the call runs, else the
  result's `preview`), file edits (`ToolResultFileEditContent` and pending
  confirmations' `edits`, as a 12-line mini-diff with a full diff page)
  and subagents (`ToolResultSubagentContent`, with "Open chat") render
  under the tool call's card. Consecutive calls of the same tool without
  such previews fold into one expandable "Read · 3 calls" row (AV-064).
- **Chats:** the switcher lists the session's chats in catalogue order
  (hidden workers left out, read-only ones marked and without a follow-up
  box). Reordering uses `moveChat` within the session, because
  `session/chatsReordered` is a host-only convergence signal (the
  compatibility table said "client"; fixed). Moving needs 1.0.0, so the
  menu is hidden under 0.9.0. Background subagents open their chat and
  background shells their terminal from the background chip.
- **Queued messages above the input (AV-081):** pending messages moved out
  of the timeline into a panel over the follow-up box: edit
  (`chat/pendingMessageSet` with the same ID), remove, drag or "Move
  up/down" (`chat/queuedMessagesReordered`).
- **Drafts:** the follow-up box starts from `ChatState.draft`, syncs its
  text back after 800 ms without typing (`chat/draftChanged`), clears the
  draft on send, and adopts another client's draft only while the user
  has not typed since the last sync, so remote edits never overwrite
  local typing.
- **Review placement:** the review pane (`ChangesPane`) is a side pane on
  wide layouts and a "Files changed" tab on medium and compact ones (only
  when the host lists changesets). It shows the session's changesets and,
  on 1.0.0, the chat's; turn templates are expanded with a turn picker.
  Operations ask for confirmation when the host says so, and report the
  result message in a snackbar.
- **Session details page:** working directories (session and chat),
  canvases, customizations (MCP start/stop, "Continue in background" on
  1.0.0), server tools, active clients and `_meta` are on one page from
  the session menu rather than more header chips; canvases also show as
  header chips that open their URL.
- **Fake host:** new keywords `shell` (a terminal channel streaming a
  command), `read` (three reads), `subagent` (a read-only worker chat
  linked from a `task` call, plus background work), `canvas`, `code`,
  `slow` (keeps the turn running so messages can be queued), `cd`, and
  `edit` now carries a diff (`resourceRead` serves both sides) and fills
  the session and per-turn changesets, whose `commit` and `revert`
  operations work. A seeded "Long session" holds 60 turns behind a
  20-turn window. `moveChat` reorders movable chats. The app integration
  test grew a second test for these flows, and it now also runs headless
  on the flutter-tester device when no window plugin is available.

## 2026-10-16: Full reducers, session-level input and a scripted fake host

- **Reducers mirror the protocol for every action:** `reduceSession` and
  `reduceChat` now port all of `sessionReducer` and `chatReducer` from
  `@microsoft/agent-host-protocol@1.0.0`, including the edge cases
  (`session/chatsReordered` only applies a permutation, a replaced working
  directory that already exists earlier is dropped, `inputNeeded` drives
  the `InputNeeded` bit except for client tool execution, toggling a
  plugin or MCP server sets `enablement` while other customizations keep
  the legacy `enabled`, `chat/toolCallAuthRequired` only applies to
  running MCP calls, an `auth-required` call only completes with a
  failure). The switch is exhaustive over the generated unions, so a new
  protocol action is a compile error rather than a silent no-op; only the
  `…Unknown` member (a newer host) is ignored. Customization edits go
  through JSON (`toJson` + `fromJson`) where the TypeScript reducer
  spreads objects, so unknown kinds are handled the same way.
- **Changeset and canvas reducers without subscriptions:** ported now
  (`changeset_reducer.dart`) because they are small and the review pane
  (AV-100 to AV-103) needs them, but the client does not subscribe to
  those channels yet; change counts in the UI come from the catalogue's
  `SessionSummary.changes` (present in 0.9.0 too). The terminal, resource
  watch, annotations and automation reducers are not ported (no UI).
- **1.0.0 gating:** the client already ignores 1.0.0-only actions under
  0.9.0, so the reducers need no version checks. UI built on 1.0.0-only
  state checks `supportsFeature` (the background work chip);
  `authenticate` drops `expiresIn` without `tokenExpiry`.
- **Session-level input requests:** a "Waiting for you" panel above the
  timeline shows `SessionState.inputNeeded` entries the open chat does not
  already show. An entry is hidden when its tool call or input request is
  anywhere in the open chat, so a request answered inline (write-ahead
  makes the call `running` at once) does not reappear before the host
  removes the entry. Answers are dispatched to the entry's own chat even
  when the client is not subscribed to it; there is no mirror to update,
  so nothing is pending and the host's `session/inputNeededRemoved` is the
  confirmation. Client tool execution entries are not shown (this client
  provides no tools).
- **MCP sign-in without OAuth:** `auth-required` tool calls (and MCP
  servers in `authRequired` state, as header chips) offer "Sign in", which
  asks the user to paste a token and calls the new
  `AhpClient.authenticate`, and "Cancel tool call", a failed
  `chat/toolCallComplete` (the only completion the protocol allows from
  `auth-required`). A real OAuth/PKCE flow (AHP-060) needs a redirect
  handler per platform and is left for later.
- **Minimal UI for the rest:** background work is a header chip with a
  menu of labels, change counts are added to the header details. Drafts,
  canvases, working directory changes, server tools, active clients,
  customizations other than MCP alerts, chat order and `movable` are
  mirrored but have no UI yet (see GAPS.md).
- **A fake host in Dart, in the workspace:** `packages/ahp_fake_host`
  reuses `ahp_client`'s generated types and reducers to keep real state,
  so it costs little code and cannot drift from the client's model of the
  protocol. It is driven by keywords in the user's message (`tool`, `ask`,
  `side`, `auth`, `background`, `edit`) rather than a config file, so the
  same host serves automated tests and manual runs (`just fake-host`).
  Reconnect always answers `-32008`, so clients re-initialize. The risk of
  sharing reducers (a reducer bug the host and client agree on) is
  covered by the reducer unit tests against the TypeScript semantics and
  by the recorded pi traffic.
- **Where its tests run:** client-level flows run over a real loopback
  WebSocket with a token in `just test` (fast, no display). The app-level
  integration test starts the host in the app's own process (no extra
  process to manage) and drives the UI through the connect screen; it is a
  separate `just test-fake-host-app` recipe and CI step on Linux (Xvfb,
  fresh keyring) and macOS, so a failure is attributed to it rather than to
  the desktop smoke test, which `scripts/test-desktop` now runs alone.
  It replaces the host store with an in-memory one, so it needs no keyring
  or keychain (secure storage is the smoke test's job), and it calls
  `setUpDesktopWindow()` itself: the macOS runner starts with the window
  hidden until `main()` shows it, a hidden window renders no frames, and
  every `pump()` then waits forever (which is how the first CI runs hung).
  `scripts/annotate-test-failure` turns its failures into annotations,
  since job logs need a GitHub token to read.

## 2026-10-16: Wire type generation

- **Generated from the JSON Schemas, output committed:** a new pure-Dart
  workspace package, `packages/ahp_wire_gen`, reads the AHP 1.0.0 schemas
  (`actions`, `commands`, `errors`, `notifications`, `state`) and writes
  `packages/ahp_client/lib/src/generated/` (one library, one part per
  schema file). The output is committed rather than built on the fly, so
  the package stays a plain Dart dependency, reviews show type changes, and
  IDEs need no build step. `just codegen` regenerates it (then
  `dart format` and freezed for `host_state.dart`); CI runs
  `just fetch-schema` and `just codegen` and fails on any working-tree
  change, which also catches hand edits and stale vendored schemas.
- **Vendored schemas:** the five files from tag `v1.0.0` of
  `microsoft/agent-host-protocol` live in
  `packages/ahp_wire_gen/schema/1.0.0/` (about 2 MB; each file repeats the
  shared defs). Generation needs no network; `just fetch-schema` re-downloads
  them. A def found in several files is generated once, into the part of
  the first file (state, actions, commands, notifications, errors).
- **Own emitter, not freezed:** the generator emits plain Dart (immutable
  `final class`es with `fromJson`/`toJson`/typed `copyWith`/deep equality,
  `sealed class` unions, enums) instead of freezed sources. The schemas
  need things freezed unions cannot express: a member in two unions
  (`ChatTurnStartedAction` is a `ChatAction` and a `StateAction`;
  `ToolCallPendingConfirmationState` is a `ToolCallState` and a
  `ToolCallConfirmationState`), nested unions (`chat/toolCallConfirmed` is
  itself a union on `approved`), discriminators with several values
  (`number`/`integer` questions), and untagged string-or-object unions.
  Sealed classes that members `implement` handle all of them, and the
  build goes from ~17 k lines of freezed output for a subset of the
  protocol to ~37 k lines for all of it, generated in under a second.
  freezed stays for `host_state.dart`; `json_serializable` and
  `json_annotation` are gone.
- **Whole schema, faithful shapes:** every `$def` is generated (canvases,
  changesets, terminals, customizations, MCP servers, automations,
  background work), so extending the reducers needs no new types. The
  flattened hand-written `ToolCall`, `ChatInputQuestion` and raw-JSON
  fields are replaced by the protocol's unions (`ToolCallState`,
  `ChatInputQuestion`, `ToolResultContent`, `ChatInputAnswer`, ...), and
  the chat reducer now builds the next tool call state per status, like
  the TypeScript reducer.
- **Forward compatibility:** each tagged union decodes unknown
  discriminators to `<Union>Unknown` (keeping the JSON and decoding the
  fields all members share), each enum has `$unknown`, and missing required
  lists/maps decode as empty. Unknown action types stay no-ops, as before.
  An unknown `reconnect` result kind makes the client run `initialize`
  again.
- **Shared fields on unions:** fields every member has (same type, or
  member types of one union) are abstract getters on the sealed class
  (`ToolCallState.toolCallId`, `.contributor`, `.invocationMessage`), and
  `ToolCallStateFields` in `wire.dart` adds the few that only some states
  have (`toolInput`, `content`, `confirmed`, `selectedOption`).
- **Explicit departures, all in `config.dart`:** `Snapshot.state` and
  `ActionEnvelope.action` stay JSON (no discriminator for the former;
  write-ahead and the reducers already work on JSON); the partial
  `changes` of `session/chatUpdated` and `root/sessionSummaryChanged` stay
  JSON because pi clears fields with an explicit `null`; `RootAction`,
  `SessionAction` and the other per-channel action unions are synthesized
  from `StateAction` by type prefix (the schemas only export `ChatAction`);
  `Icon`/`TextPosition`/`TextRange`/`TextSelection` get an `Ahp` prefix to
  avoid clashing with Flutter and `dart:ui`; `number` is `int` except for a
  short list of fractional fields; `SessionStatus` maps to the existing
  bitset extension type. Two upstream schema defects (an empty `$ref` in
  `StateAction`, and `approved` without its `true`/`false` literal types)
  are patched, and each patch throws once upstream fixes it.
- **0.9.0:** the v0.9.0 schemas were fetched once to confirm that their
  `StateAction` differs from 1.0.0 by exactly the ten actions in
  `protocol_version.dart`. They are not vendored: the client only offers
  0.9.0 as a fallback and generates 1.0.0 types, so a test checks the list
  against the generated `StateAction.discriminatorValues` instead.

## 2026-10-16: Reconnect details, write-ahead rollback, and 0.9.0 degradation

- **0.9.0 vs 1.0.0, from the releases:** the list of 1.0.0 additions comes
  from diffing the `src/types` TypeScript of
  `@microsoft/agent-host-protocol@0.9.0` and `@1.0.0` (interfaces, enums
  and action types, with the TypeScript compiler API), not from the
  protocol's `ACTION_INTRODUCED_IN` registry. The registry dates
  `chat/isReadChanged`, `chat/backgroundWork*`, `session/chatsReordered`
  and others `0.9.0`, and the canvas actions `0.10.0` (never released),
  but none of them is in the 0.9.0 package; the 1.0.0 changelog agrees
  with the diff. The result is ten actions, one command (`moveChat`) and a
  set of optional fields, listed in the spec.
- **Degradation is a version check, not per-feature capability probing:**
  0.9.0 and 1.0.0 are the only versions offered, so one pure module
  (`protocol_version.dart`) holds the added actions and a
  `ProtocolFeature` enum; `isActionKnownToVersion` and `supportsFeature`
  compare versions. Under 0.9.0, incoming 1.0.0-only actions are ignored
  (a safety net; hosts should not send them) and dispatching one throws
  `UnsupportedActionError` (a `StateError`, which the UI already catches)
  rather than sending something the host would reject. Fields need no
  handling, since all of them are optional and nothing reads them yet. The
  app shows an "AHP 0.9.0" chip whose tooltip lists the missing features,
  instead of a dismissable banner, because nothing the user can do today
  is affected.
- **`AhpClient.protocolVersions`:** the offered list is a constructor
  option (default `['1.0.0', '0.9.0']`) so the integration test can make
  pi negotiate 0.9.0.
- **Pending actions are rolled back, and the user is told:** the
  write-ahead guide says a client clears `pendingActions` after a
  reconnect. The client does that after applying a replay (which echoes
  whatever the host accepted) and before applying snapshots (which carry
  no echoes). It also rolls back an action not echoed within 30 s (the
  TypeScript client's default request timeout), with a one-shot timer per
  action calling a pure function. Each rollback, and each host rejection,
  is an `ActionFailure` on `AhpClient.failures`; the app shows a snackbar
  per failure. After a snapshot the action may in fact have been applied,
  so that message says it "may not have gone through" instead of claiming
  it was lost. A late echo is still applied (the host's state wins).
  `dispatch` is refused while reconnecting, so an action cannot be sent on
  the new socket and then cleared by the reconnect.
- **Missing channels:** the replay's `missing` channels are released
  (subscription counts dropped, so later `unsubscribe` calls are no-ops),
  unmirrored, and listed in `HostState.missingChannels` instead of a
  separate event stream, so widgets observe them like any other state.
  Subscribing again clears the entry. A snapshot result or the
  `initialize` fallback has no `missing` list; since a host may only omit
  snapshots of field-less channels, a session or chat mirror without a
  snapshot is treated as missing too.
- **Liveness pings:** `ping` every 15 s with a 10 s timeout, so a dead
  socket is found within about 25 s. Only a timeout or a closed peer
  counts as dead; any JSON-RPC answer, including `MethodNotFound` from a
  host without `ping`, counts as alive. A failed ping starts the normal
  reconnect loop. Protocol-level pings were chosen over WebSocket ping
  frames because browsers cannot send those.

## 2026-10-16: Desktop apps, native token header, and remembered hosts

- **Token header (AHP-002):** the AHP spec leaves connection gating to the
  transport and names no header. On native platforms the client sends
  `Authorization: Bearer <token>`, the header the protocol repo's Swift
  client uses, **and** keeps `tkn` in the URL, because pi-agent-host-protocol
  (and the Swift sample app) read only `tkn`. Web sends `tkn` only.
  `TokenTransport` (`query`, `header`, `queryAndHeader`) and the pure
  `handshakeFor` make the choice explicit; the platform default comes from
  a conditional import (`transport_io.dart` / `transport_web.dart`), so
  `ahp_client` stays pure Dart and web-safe.
- **Window management:** [`window_manager`](https://pub.dev/packages/window_manager)
  (maintained by LeanFlutter, macOS/Linux/Windows) for minimum size, size,
  position and maximize, with `screen_retriever` (its dependency) to check
  a saved position is still on a display. `window_size` from
  flutter-desktop-embedding is unpublished and unmaintained. Placement is
  saved in `shared_preferences`, since it is not secret; it is debounced
  and keeps the last normal bounds while maximized.
- **macOS menu bar:** Flutter's built-in `PlatformMenuBar`, no package. It
  is only created on macOS; other platforms keep their native title bars.
- **macOS keychain:** `MacOsOptions(usesDataProtectionKeychain: false)`
  instead of the `keychain-access-groups` entitlement. The entitlement
  needs a provisioning profile, which would tie development builds to one
  Mac and break unsigned CI builds; shireitou shares no keychain items with
  other apps, so the login keychain is enough. `network.client` is added to
  both entitlement files.
- **Remembered hosts (AV-010):** a list of up to 20 hosts (name, URL,
  token), most recent first, as one JSON value in secure storage. A host is
  identified by its URL without `tkn`, so pi's per-run token rotation
  updates the entry instead of adding one. The single host saved by
  iteration 2 is migrated. One connection at a time remains.
- **Desktop CI:** `linux-desktop` (ubuntu-latest) and `macos-desktop`
  (macos-latest) build release apps, run an `integration_test` smoke test
  against pi with a token (Linux under `xvfb-run` with a throwaway
  gnome-keyring), and upload a `.tar.gz` + `.deb` and an unsigned `.dmg`.
  AppImage, signing and notarization are left for later.
- **Local Linux toolchain:** this machine has no root, so Flutter, CMake
  and the GTK/libsecret headers were installed under `~/sdk` (see
  [docs/desktop.md](docs/desktop.md)) rather than via apt.

## 2026-10-15: macOS and Linux desktop are priority platforms

- shireitou must run as a desktop app on macOS and Linux, in addition to the
  web build. The remaining work is tracked in [GAPS.md](GAPS.md) under
  "macOS and Linux desktop apps".

## 2026-10-15: Session and chat channels, write-ahead dispatch, and the session view

- **Chat reducer:** port the protocol's `chatReducer` to Dart rather than
  apply host snapshots only, so streaming (`chat/delta`) and optimistic
  actions work without a round trip. It is tested by replaying recorded pi
  traffic (`examples/ahp/pi-host-chat-turns.json`).
- **Flattened tool calls:** the seven `ToolCallState` variants are one
  freezed `ToolCall` class keyed by `status`, with fields that do not apply
  left null. The reducer builds each transition from a `_base` copy, like
  the TypeScript `tcBase`, so stale fields do not leak between statuses.
- **Write-ahead state:** a generic `ChannelMirror<S>` holds the confirmed
  state, pending `(clientSeq, action)` pairs, and the visible state
  (confirmed plus pending). Echoes are matched by `origin.clientId` and
  `clientSeq`; rejections drop the pending action, which rolls it back. The
  functions are pure and generic over the reducer.
- **State placement:** session and chat mirrors live in `HostState`
  (`sessionChannels`, `chatChannels`), keyed by the URI the client
  subscribed with, so the app has one state stream. Widgets use Riverpod
  `select` so streaming only rebuilds the open timeline.
- **Opening sessions:** subscribe to the session channel, then its
  `defaultChat` (or first chat). The session list's status comes from the
  catalogue, because pi keeps the live status on the chat and summary.
- **Sending messages:** idle sends `chat/turnStarted` with a client-chosen
  turn ID; while a turn runs, Enter sends a queued `chat/pendingMessageSet`
  and Cmd/Ctrl+Enter a steering one, as pi implements. The model is chosen
  per message (`Message.model`), which is how pi takes it.
- **Markdown:** `flutter_markdown_plus`, the maintained fork of the
  discontinued `flutter_markdown`, as a drop-in `MarkdownBody`.
- **Saved host:** the last URL and token go in `flutter_secure_storage`
  (the URL too, since pi's URL carries `?tkn=`). Only the last host is kept.
- **Read state:** a session is marked read when opened and again when a new
  turn clears `IsRead` while it is open, unless the user chose "Mark
  unread".
- **Model test tag:** a real-turn test is tagged `model` and run with
  `just test-model`; `just test-integration` and CI exclude it, so CI needs
  no model provider. Both start pi with a temp `--session-dir` and settings
  directory.

## 2026-10-15: Bootstrapping the workspace, AHP client, and app shell

- **Repo layout:** a [pub workspace](https://dart.dev/tools/pub/workspaces)
  at the root with `packages/ahp_client` (pure Dart) and `app` (Flutter, all
  six platforms). One `flutter pub get` resolves both and they share one
  lockfile.
- **JSON-RPC:** use `json_rpc_2` (dart-lang) `Peer` over a
  `StreamChannel<String>`, instead of a hand-written JSON-RPC layer. It
  handles requests and notifications in both directions.
- **Transport:** `web_socket_channel`, which works on native and web. The
  connector is a function parameter, so tests use an in-memory channel.
- **Wire types:** freezed + json_serializable, hand-modeled on the
  `@microsoft/agent-host-protocol@1.0.0` TypeScript types, covering only the
  root channel and session catalogue. Schema-driven generation is deferred
  (see GAPS.md). Generated files are committed, and CI checks they are
  current. Raw JSON maps are kept for structures the client does not read
  (config schemas, terminals, protected resources).
- **SessionStatus:** a Dart extension type over `int`, so the bitset has no
  runtime cost and is decoded with bitwise checks only.
- **Session catalogue:** an unmodifiable `Map<String, SessionSummary>` keyed
  by the host's `resource`, advanced by pure functions. Partial
  `root/sessionSummaryChanged` updates are merged at the JSON level and
  re-decoded. The list is reloaded after every reconnect because catalogue
  notifications are not replayed.
- **State management:** Riverpod 3 (`flutter_riverpod`), with one
  `Notifier<HostState>` that mirrors the client's `states` stream. No Riverpod
  code generation, to keep one layer between widgets and the client.
- **Logging:** the `logging` package in both packages; the app routes records
  to `debugPrint`.
- **Lints:** `lints`/`flutter_lints` recommended plus strict analyzer modes,
  run with `--fatal-infos`.
- **Integration test:** tagged `integration`, launches pi-agent-host-protocol
  in `--pi-mode embedded` with temp settings and agent directories, so it
  needs no `pi` CLI and does not touch the user's sessions. CI runs it in a
  separate job against the public pi repo.

## 2026-10-15: Protocol version and worktree grouping

- **Protocol version:** target the versions supported by
  [pi-agent-host-protocol](https://github.com/toumorokoshi/pi-agent-host-protocol),
  which uses `@microsoft/agent-host-protocol` 1.0.0. Generate types from
  1.0.0 and offer `['1.0.0', '0.9.0']` in `initialize`.
- **Worktree grouping:** the session list groups sessions into one folder per
  working directory, so each git worktree is its own folder (GitHub/VS Code
  style). We rejected Cursor's approach of merging worktree agents under the
  parent repo because it makes it hard to tell which checkout a session is
  changing. This is now P0 (AV-025); time and host grouping moved to AV-031
  (P1).

## 2026-10-15: Initial requirements for the agents view

- **Product scope:** shireitou is a client-only, cross-platform agents view
  (desktop, mobile, web) in Flutter/Dart. It does not run agents itself.
- **Backend protocol:** use Microsoft's Agent Host Protocol (AHP) as the only
  backend interface. Hosts normalize many agents (Copilot, Claude, Codex, ...)
  into one presentation model, so the UI stays agent-agnostic.
- **UX baseline:** combine the GitHub Agents view (inbox with status and
  filters, session log, steering, Files changed) with Cursor's Agents Window
  (workspace-grouped sidebar, queue vs. send-now, review pane, best-of-N).
  Requirements are tracked as `AV-*` and `AHP-*` IDs with P0/P1/P2 priority.
- **Dart AHP client:** build our own pure-Dart package with wire types
  generated from the official JSON Schemas, rather than depend on the
  immature community `ahp_sdk` (protocol 0.7.0, no reconnect). Use `ahp_sdk`
  as a reference.
- **State architecture:** AHP's reducer model is mirrored directly. Protocol
  state is immutable and updated by pure reducers; I/O stays at the edges.
  This matches the project's functional-programming tenet.
- **Status modeling:** `SessionStatus` is decoded as a bitset, and UI badges
  are derived from it, never from equality checks.
- **Layout:** three responsive tiers (three panes, two panes, stacked) that
  always use the full screen.
- **Tooling:** until Dart code exists, `just lint` / `just fix` run prettier
  over markdown.
