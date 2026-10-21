# Design Decision Log

## 2026-10-21: Skill completions show local items at once (AV-044)

Typing `/` in a session took a long time to show anything. The popup
started empty, waited out the 150 ms debounce, then waited for the
host's `completions` answer before it showed anything, even when the
session's skills were already in the mirrored state. pi answers the
first `completions` of a session whose agent is not running by starting
the agent to list its commands (`PiSession.completions` calls
`#ensureAgent`), which takes seconds for a session opened from history
or after a host restart; later answers come from pi's memory.

- **The completion source is a stream.** `resolveCompletions` yields the
  local items first and then the host's answer, and the popup shows each
  as it comes, so the popup opens at once and the host's items replace
  the local ones. A failed or empty host answer keeps the local items,
  as the fallback did before.
- **The host's answers are cached per connection.** `CompletionCache` on
  `HostConnection` keeps the answer for a bare trigger (the full list) by
  chat, start or later in the message (pi offers prompts only at the
  start), and the session's command names, so a change in the session's
  customizations retires it. Cached items are moved to the new word
  (`rebaseCompletions`) and filtered locally. It is in memory and
  bounded (64 answers, least recently used dropped first). A disk cache
  was not added, since the agent's and the session's customizations
  arrive with the host's state on connect anyway.
- **A session that lists no skills uses its agent's.** pi lists a
  session's skills only once its agent starts, but publishes its global
  skills on the agent, so these show while pi starts.
- **No debounce for a new word.** The first request for a word goes
  out at once; typing in the word is still debounced.
- **pi's slow first answer is not fixed here.** Listing commands without
  starting the agent belongs in pi-agent-host-protocol.

## 2026-10-20: The "Marked as done" snackbar times out (AV-024)

The snackbar shown after "Mark as done" never went away: Flutter's
`SnackBar.persist` defaults to true when the snackbar has an action, so
the Undo action kept it open until the user dismissed it.

- **Undo snackbars time out like the others.** `persist: false` with
  the default 4 s duration; the session stays archived, and Undo is
  still in the row's menu ("Unarchive").

## 2026-10-20: A bundled CC0 chime through flutter_soloud (AV-121)

The first chime ran each platform's sound player (`afplay`,
`canberra-gtk-play`, PowerShell), so it sounded different everywhere,
depended on programs a Linux desktop may not have, played nothing on
mobile, and could sound together with the notification's own sound.

- **`flutter_soloud`, not system players or `audioplayers`.** SoLoud on
  miniaudio, through FFI and a native build hook, plays one bundled file
  on all six platforms. On Linux it loads ALSA or PulseAudio at run time,
  so it needs no GStreamer and no build headers (the reason
  `audioplayers` was rejected); the `.deb` now depends on `libasound2`.
  Rejected: Flutter's `SystemSound.alert` (the engine maps it to
  `NSBeep`, `MessageBeep` and `gdk_display_beep`; nothing on mobile or the
  web) and direct `dart:ffi` calls to `NSSound`, `PlaySoundW` and
  libcanberra (three bindings to maintain, still desktop only).
- **The engine runs only while it plays.** `SoLoudChime` starts SoLoud,
  loads the asset, plays it and stops 200 ms after it ends. A stream
  left open keeps the audio hardware awake, and on macOS holds off idle
  sleep, for an app that runs all day. Starting takes about 70 ms
  (0.4 s the first time), measured on macOS.
- **Kenney's "confirmation_003" (CC0) as WAV.** Four rising pure tones
  in 0.32 s, picked over the other confirmation sounds as the least
  busy. Converted from OGG to a 28 KB mono WAV so every browser decodes
  it; the licence sits beside it in `assets/sounds/`. Rejected: Material
  product sounds (CC-BY 4.0 needs an attribution page this app does not
  have).
- **The web keeps Web Audio.** `WebAudioChime` decodes the same asset
  with `decodeAudioData`. SoLoud's web build would load a 1.9 MB
  WebAssembly engine and a script tag on every page load for one sound.
- **No double sound.** When the chime plays, `OsNotifier.show` gets
  `silent: true` (Android `silent`, Darwin `presentSound: false`, Linux
  `suppressSound`, Windows silent audio, the web's `silent`). Mobile
  chimes only in the foreground (`chimeNeedsForeground`), since a
  backgrounded app may be suspended mid-sound; there the notification
  keeps its sound. iOS uses the `ambient` session category through
  `audio_session`, so the chime mixes with other audio and follows the
  silent switch.

## 2026-10-20: Alt+T toggles the terminal panel (AV-016, AV-140)

The terminal panel only toggled with Ctrl+\`, and Alt+T was asked for
as the key that opens and closes it in a session.

- **Alt+T is the main key, Ctrl+\` stays.** Alt+T (⌥T on macOS) is the
  key in the tooltip and the macOS Session menu; Ctrl+\` keeps working
  for VS Code habits. Commands now have `extraActivatorsFor` keys beside
  `activatorFor`.
- **Extra keys are handled by the app on macOS too.** A native menu item
  takes one key, so `AppShortcuts` maps only the extra keys there while
  the menu keeps the main ones.
- **The terminal swallows Alt+T.** Inside the terminal both keys toggle
  the panel instead of reaching the shell, so readline's Alt+T
  ("transpose words") is Esc then T there.

## 2026-10-20: A chime when it is the user's turn (AV-121)

The app posted notifications when a session needed input, finished or
failed, but made no sound of its own, and when the system refused
notifications (for example the ad hoc signed macOS app) nothing at all
told the user it was their turn.

- **The chime follows the notifications, not their permission.**
  `shouldChime` is true when the sound is on and any event of one
  catalogue change passes `shouldNotify`, so the per-event switches and
  "quiet for the session on screen in a focused window" apply, and
  several sessions changing at once chime once. It plays even when
  notification permission is refused.
- **The system's own sound, no audio plugin.** `chimeCommands` maps
  each desktop platform to its sound player (`afplay` with Glass on
  macOS; `canberra-gtk-play`, `paplay` or `pw-play` with the freedesktop
  `message-new-instant` on Linux; PowerShell's `Media.SoundPlayer` on
  Windows), and `ProcessChime` runs the first that succeeds. The web
  build synthesizes two notes with Web Audio. Rejected: `audioplayers`
  (its Linux backend needs GStreamer headers in CI and the release
  build, and GStreamer in the `.deb` and AppImage) and `flutter_soloud`
  (a native build and script tags in `index.html` for one sound).
  Mobile plays none: its notifications already make the system sound.
- **One switch.** `NotificationSettings.sound` (saved as `"sound"`;
  missing means on, so existing settings keep the chime) is toggled by
  "Play a sound" in the bell menu, which now also shows where there is
  a chime but no notifier. Tests get no chime unless they pass one to
  `hostOverrides`, and `platformChime` needs the real platform to match
  the target, so a widget test pretending to be macOS plays nothing.

## 2026-10-20: Round send and stop buttons in the composer

The composer's send and stop buttons were bare 18 px glyphs, unlike
Cursor's composer, where the lower right corner holds a filled round
button: a light disc with a dark up-arrow, dimmed while there is nothing
to send, that becomes the same disc with a solid square while the agent
works.

- **One widget.** `ComposerActionButton` draws the send, queue and stop
  states. Its colours come from the theme (`onSurface` fill, the
  composer's `raisedSurface` glyph), so every colour theme gets a disc
  that contrasts with the box: light in dark themes, dark in light ones.
- **A drawn stop square.** The codicon font has only outlined squares
  (`debugStop`, `primitiveSquare`), so `StopSquare` is a small rounded
  box in the button's icon colour. The unused `AppIcons.stop` is removed.
- **Behaviour unchanged.** The button still switches between send,
  queue and stop as before. "Send now" stays a plain muted icon to its
  left. The composer has no mic button.

## 2026-10-19: Turn timestamps use host time; step timings wait for AHP

Each user-message bubble shows its turn's `startedAt` in the device's local
date and time conventions, with the original ISO 8601 value in a tooltip.
Finished turns continue to show the host-reported `duration` in their steps
summary and footer.

The app does not infer durations for individual reasoning, tool-call or
interstitial-text steps. AHP 1.0.0 does not give those response parts start
times or durations, and measuring action arrival times in one client would
omit historical sessions, vary with network latency and disagree between
clients. Per-step timing therefore remains unavailable until the protocol
and host report it.

## 2026-10-20: Restore the settings saved while the macOS app was sandboxed

Pins disappeared after upgrading to the build that turned off the macOS
sandbox (AV-016). The pins were still saved, but a sandboxed app's
`UserDefaults` are in its container, so the unsandboxed build read an
empty `~/Library/Preferences/dev.shireitou.shireitou.plist`. The folder
order, theme and pane settings were lost the same way.

- **Migrate once, at start.** `main` runs `migrateSandboxPrefs` before
  the window and the providers read any setting. A
  `sandbox_prefs_migrated` flag stops it running again, so a pin removed
  later does not come back.
- **Fill gaps, merge pins.** A setting that exists only in the container
  is copied; one the user has set since keeps its new value; the pins
  are merged (the old ones first, in order, then the new ones), since
  users re-pin a few sessions after losing them. Non-string values
  belong to plugins and are skipped.
- **`plutil` over a plist parser.** The container's plist is binary.
  `plutil -convert json` ships with macOS and needs no dependency, and
  the app can run it now that it is not sandboxed.

## 2026-10-20: "Send now" for queued messages (AV-081)

The composer's "Send now" steers only with newly typed text. Once a
message was queued, the only way to deliver it sooner was to copy it,
remove it and type it again. Queued rows now have a "Send now" button
(the composer's lightning icon) and a matching menu item.

- **Promote to steering, then dequeue.** It dispatches
  `chat/pendingMessageSet` (steering) and then
  `chat/pendingMessageRemoved` (queued), so a failure between the two
  leaves a duplicate rather than losing the message. The steering
  message reuses the queued message's ID.
- **Merge into a waiting steering message.** The chat holds a single
  steering message, and setting it again replaces the earlier one. When
  one is already waiting, the queued text (after a blank line) and
  attachments are appended to it, keeping its ID, model and agent.
- **Idle chats start a turn.** With no turn running, steering means
  nothing, so it sends `chat/turnStarted` with `queuedMessageId`, which
  also takes the message out of the queue.

## 2026-10-20: A VS Code-style terminal panel on the system `ssh` (AV-016)

Opening a folder in an editor (AV-015) left no quick way to run a
command on an agent's host from the app. The terminal removed the day
before (AV-014) had its own SSH client, settings and secrets. The new
panel instead runs the user's own `ssh` in a pseudo-terminal under the
session, as VS Code's terminal panel does.

- **The system `ssh`, configured by the user.** The destination is the
  AHP URL's host and nothing else: the user, keys, port, jump hosts and
  host key checks come from `~/.ssh/config`, `known_hosts` and the
  agent. The app stores no SSH settings or secrets, and the arguments
  are `-t -- <host> 'cd <folder> 2>/dev/null; exec "$SHELL" -l'`, with
  hosts that could be read as options refused.
- **A panel in the session pane, with terminals per host.** The panel
  sits under the conversation (`TerminalDock`), resizes from its top
  edge, maximizes over the conversation (kept mounted, so scroll
  position and drafts survive) and hides without ending terminals.
  Terminals belong to an AHP host, so switching between that host's
  sessions keeps them. Ctrl+\` toggles it on every platform, as in VS
  Code, and is caught inside the terminal, which otherwise takes every
  key.
- **The macOS sandbox is off.** A sandboxed child `ssh` cannot read
  `~/.ssh` or reach the agent. The app ships as a notarized `.dmg`, which
  needs the hardened runtime but not the sandbox. The alternative, the
  `ssh://` link to Terminal.app, would not be inline.
- **flutter_pty vendored and built by a build hook.** Of the pty
  packages, flutter_pty (the xterm.dart authors') has small, readable C
  that forks and execs in C. pty2 forks the Dart VM from Dart, and
  portable_pty (WezTerm's Rust library) is at 0.0.x and needs Rust. The
  published flutter_pty is 21 months old, builds through CocoaPods on
  macOS (no Swift Package Manager), bundles into iOS and Android, and on
  Windows repeated the executable on the command line without quoting.
  The copy in `packages/flutter_pty` compiles its C with a Dart build
  hook on the desktops only, calls it through `@Native` bindings, and
  fixes the Windows command line. xterm.dart stays the emulator.
- **No pty, an `ssh://` link.** The web, iOS and Android open
  `ssh://<host>` in an installed SSH app instead.

## 2026-10-20: A starting session shows "Initializing…" instead of a progress bar (AV-040)

Starting a session from the draft showed a thin progress bar above the
composer, with the prompt still in the box, until the host had created
the session and accepted the first turn. It read as a stall, as if the
app would not move on.

- **Look started at once.** While the host works, the draft's timeline
  is replaced by `StartingTimeline`: the prompt as the first message
  (the timeline's `UserMessageBubble`) and the working dots
  (`WorkingIndicatorRow`) reading "Initializing…". The pickers and the
  hint go, and the prompt leaves the box, so the pane looks like the
  session it is about to become.
- **No fake session state.** The placeholder is the draft's own widget
  state, not an optimistic session in the client's state: the session's
  URI is not known until `createSession` answers, and a failed start
  would otherwise need rolling back in the session list.
- **Failures restore the draft.** On a failure the timeline goes back
  to the draft, the prompt returns to the box and the error shows above
  it, as before.

## 2026-10-19: Open in VS Code, Insiders or Cursor replaces the SSH terminal (AV-014, AV-015)

The in-app SSH terminal (dartssh2 and xterm.dart) gave a bare shell on
the host. It also kept passwords and private keys in the app, and could
not use `~/.ssh/config`, jump hosts or (outside Linux) the SSH agent.
Users who want to work on an agent's folder by hand already have an
editor that does remote work better. The same day, "Open in VS Code"
(AV-015, below) was added to the session header, building its URL from
the SSH terminal's settings. Now it is the only remote feature: the
terminal (AV-014) is removed, and the module is `editor/` instead of
`vscode/`.

- **A URL, not an SSH client.** "Open in VS Code" hands
  `vscode://vscode-remote/ssh-remote+<authority><folder>` to the system
  with `url_launcher`. VS Code's Remote - SSH extension connects with
  the system `ssh`, so the user's config, keys, agent and host key
  checks apply, and the app keeps no SSH secrets. The alternative,
  running `code --remote ssh-remote+… <folder>`, needs the `code`
  command on the PATH, a process spawn (not possible in the macOS
  sandbox or on the web) and a different command per editor. The URL
  works the same in the sandbox, on Windows and in the browser.
- **The authority survives lowercasing.** VS Code lowercases URL
  authorities. So `user@host` is used only when it is already lowercase,
  on port 22 and not IPv6. Otherwise the authority is the hex-encoded
  JSON (`hostName`, `user`, `port`) that Remote - SSH also accepts.
- **The editor is a choice.** VS Code, VS Code Insiders and Cursor
  handle the same URLs under their own schemes, so the choice is just
  the scheme. It applies to every host.
- **Loopback hosts open locally.** A host on `127.0.0.1`, `localhost` or
  `::1` opens `vscode://file<folder>` without asking. A host reached
  through a forwarded loopback port can be switched to SSH in its
  editor settings.
- **Folders only; no host-level open.** The session header (a button
  and a menu item) and folder headers (a hover button and a menu item)
  open a path. The host menu only has "Editor settings…", since it has
  no folder to open.
- **Prefs, not secure storage.** With no secrets left, the targets
  (location, host, port, user) and the editor go in the prefs store. On
  first load, a host's old `ssh:<host key>` entry is copied over (host,
  port, user only) and deleted from secure storage, along with
  `ssh_known_hosts`. This way old passwords and keys do not stay
  behind.
- **Not on iOS or Android.** No desktop editor runs there, so the
  buttons and settings are hidden. The web app keeps them, because the
  browser can hand the URL to an installed editor.
- **The SSH host is asked for, not guessed.** The first AV-015 used the
  AHP URL's host and let `~/.ssh/config` fill in the rest. Now, the
  first time a non-loopback host is opened, the editor settings dialog
  appears, starting from that same guess. The user confirms the host
  and can add a port or user, and the dialog is also where the editor
  is picked.
- **Dependencies removed:** dartssh2, file_selector (it loaded key
  files), async, the macOS user-selected file entitlement and the CI
  `sshd` install. xterm stays: the colour themes (AV-097) describe the
  AHP terminal preview's ANSI colours as its `TerminalTheme`.

## 2026-10-19: "Open in VS Code" opens the session folder over Remote - SSH

There was no way to open a session's code in an editor; the SSH
terminal was the closest. The session header now has an "Open in VS
Code" icon button beside its "…" menu (an exception to the header
holding only the title, what needs the user, and the menu, since it is
a frequent action), and the menu has the same item (AV-015).

The app does not run VS Code itself: it opens a `vscode://` link with
`url_launcher`, which works the same on macOS, Linux, Windows and the
web. A loopback AHP host gets `vscode://file/<folder>`; any other host
gets `vscode://vscode-remote/ssh-remote+<authority>/<folder>`, with the
authority from the host's SSH terminal settings (`user@host`, or
hex-encoded JSON for a port other than 22), so one set of SSH settings
serves both. Without settings it falls back to the AHP URL's host and
lets `~/.ssh/config` fill in the rest instead of asking for them. The
link logic is pure (`vscode/vscode_link.dart`); the launcher is a
provider so tests can record the links. iOS and Android have no VS
Code, so the button is hidden there.

## 2026-10-19: Working sessions show a spinner in the list and header

Working sessions used the same small coloured dot as idle ones, so a
running agent was easy to miss in the inbox. The reference Agents view
and Cursor's Agents Window use a spinner on running rows instead.

`SessionStatusLeading` (in `session_status_indicator.dart`) replaces
the row's status dot with a 12 px `CircularProgressIndicator` in the
theme's running colour while `isSessionWorking` is true (`InProgress`,
or an open chat's active turn before the catalogue sets the bit; not
while `InputNeeded`). Reduced motion shows a static `Icons.autorenew`
icon; both have a "Working" tooltip. The session header shows the same
icon at 18 px beside the title (alongside the existing error icon).

## 2026-10-19: Selected code copies as written

Copying text selected in a code block pasted the wrong text. Flutter's
`SelectionArea` has two gaps that caused it, and both are worked around
in the app (`timeline_selection.dart`) rather than by replacing the
selection system:

- A scroll view nested in a selection (code blocks scroll sideways,
  tool output up and down) treats any drag point left of it as before
  it, even when the point is below it. Code blocks and tool output are
  indented, so a drag starting at the left of the code or text below
  them also selected them from their start. `ScrollSelection` wraps
  those scroll views and, for a drag that started outside, moves an
  edge above or below the view to before its start or past its end, so
  only the row decides.
- The selection joins the text of each widget with nothing between, so
  code pasted glued to its "python" label and the paragraphs around it.
  The labels are excluded with `SelectionContainer.disabled`, and
  `LineSelection` (one per timeline row) starts a new line between
  pieces whose bounds are on different lines, which keeps a list's
  bullet on the same line as its text. Rows are still joined with
  nothing between them (see GAPS.md).

## 2026-10-19: Copying a reply works like VS Code's chat "Copy"

AV-071 asked to copy a turn as markdown. VS Code's agents view has a
copy button in each response's footer, so its source
(`chatCopyActions.ts`, `chatModel.ts`, `chatClipboard.ts`) was read to
see what it copies rather than guessing.

- The button copies the reply only, not the user's message, as VS
  Code's footer button does. It sits at the start of the finished turn's
  footer; the running turn has none, as in VS Code.
- The text is markdown built from the response parts: markdown as
  written, each tool call's past-tense summary (plus its error when it
  failed or was cancelled) as its own paragraph, errors and system
  notes. Reasoning is left out, as VS Code drops thinking parts. VS
  Code joins adjacent markdown parts with nothing between them; AHP
  hosts send separate parts for separate messages, so each part is a
  paragraph here.
- Links to absolute paths and non-web schemes become their label as
  inline code (VS Code's `toPortableMarkdown`), since agents link to
  files on the host and a pasted link would be broken and would leak
  the path. The rewrite is a small pure function over the source (code
  fences and spans skipped) rather than a markdown round trip, which
  would reformat the rest of the text.
- The feedback is VS Code's: a check icon and "Copied" tooltip for
  1.2 s and a "Copied to clipboard" announcement. The code block and tool
  input/output copy buttons use the same `CopyButton`, replacing the
  code block's "Copied" snack bar.

## 2026-10-19: The colour schemes are the popular editor themes, from Base24

The first colour schemes only tinted one grey ramp, which was too subtle
to notice. Users know and want the themes they use in their editors.

- The themes are the most used ones in VS Code (Marketplace installs),
  Neovim (Dotfyle) and Emacs (MELPA) in 2026: 47 in all, light and
  dark, plus Graphite, the app's own default (the previous greys).
- Each theme is a Base24 palette rather than a hand-written set of app
  tokens. Base16/Base24 is the common format that ports exist in for
  nearly every editor theme ([tinted-theming/schemes](https://github.com/tinted-theming/schemes),
  MIT), with a defined styling guide for syntax and ANSI colours, so one
  mapping (`themeColors`) covers every theme and adding one is a line in
  a manifest. The ports are vendored at a pinned commit and turned into
  a `const` Dart table by a generator, like the AHP wire types: no
  runtime asset loading or YAML parsing, and a test fails when the table
  is stale. Themes without a port (Doom One, Modus, Nightfox) are
  written in the same format from their upstream palettes.
- A theme now sets the syntax highlighting and terminal colours too, not
  only surfaces, so code looks like it does in the editor. The VS Code
  Dark+/Light+ highlight themes are gone.
- WCAG AA (AV-141) still holds for every theme: colours under it are
  moved along their lightness only as far as needed (`readable`), and a
  mid-tone selection fill is pulled towards the background. This keeps
  the existing contrast test meaningful across 47 themes, at the cost of
  low-contrast themes looking a little crisper than the originals.
- Light and dark get separate theme choices, like VS Code's preferred
  light and dark themes, so "System" keeps working with custom themes.
  Picking a theme of the other brightness switches the mode to it, so a
  pick is always visible.
- Prefs moved from `color_scheme` to `dark_theme` and `light_theme`; the
  old key (released the same day) is ignored.

## 2026-10-19: Selectable colour schemes, and greyer default greys

The theme always followed the system light or dark setting, with one
set of greys and an accent sampled from VS Code, so the app looked like
VS Code and its forks and could not be changed.

- The user picks light, dark or the system's setting, and a colour
  scheme, from "Appearance" in the sidebar's "…" menu; both are kept in
  `PrefsStore` per device, like the pane widths.
- A scheme is not a full list of tokens but a hue, a tint and an accent
  applied to one grey ramp per brightness (`paletteSurfaces`). New
  schemes are a line each and keep the same surface hierarchy, and the
  contrast test checks every scheme instead of two hand-picked sets.
- The default, "Graphite", is neutral grey (equal RGB) and a little
  lighter than before in dark mode (background #1C1C1C, was #191A1B)
  and a little greyer in light mode (background #F6F6F6, was white),
  with a steel-blue accent (#7AA7E0 dark, #2F64A8 light) instead of VS
  Code's #3794FF/#0066CC, to set the app apart from VS Code.
- The running status dot follows the scheme's accent; attention, done,
  error and idle stay the same in every scheme so their meaning does
  not shift. The dark error red is lightened (#F65F5F) to keep 4.5:1 on
  the lighter raised surface.
- The filled button text picks white or near-black by contrast
  (`onColor`), since light accents in dark mode cannot carry white text.
- The greyer code fills pushed a few Light+/Dark+ highlight colours
  under 4.5:1; they are darkened or lightened slightly (light comment,
  number, added; dark regexp) instead of keeping lighter fills.

## 2026-10-18: Android releases are signed with one kept key

The release workflow already attached an APK to a `v*` tag's GitHub
Release, but no keystore secret was set, so the APK would have been
signed with the runner's throwaway debug key: it installs, but no later
release could update it, and the Gradle fallback to the debug key is
silent.

- `scripts/android-keystore` (`just android-keystore <file>`) creates a
  PKCS12 RSA 4096 keystore with a random password and uploads it, its
  password and alias as Actions secrets through stdin. The owner keeps
  the only copies; nothing is committed. keytool, not openssl, because
  the build already needs a JDK 17 and keytool's PKCS12 is what Gradle
  and apksigner expect.
- A tag fails without `ANDROID_KEYSTORE`, rather than publishing an APK
  that strands its users. Builds on `main` still fall back to the debug
  key, so the workflow stays testable without secrets.
- `scripts/package-android` compares the APK's signer (apksigner) with
  the keystore's certificate, so a misconfigured signing config fails
  the build instead of shipping a debug-signed APK.
- A tag's build number (Android's `versionCode`) must be above the
  previous tag's, since Android refuses a downgrade; on `main` this is
  a warning.
- CI's `android` job signs with a throwaway key from the same script,
  so the release signing path runs on every push.
- One universal APK, not per-ABI ones: one file to download is simpler
  for a sideloaded app, at the cost of size.

## 2026-10-18: Edit the latest message and restart from it (AV-088)

Recalling a message with ↑ (AV-087) sends the edit as a new turn, so the
agent still sees the message it replaces, and a wrong instruction the
agent is already working on has to be stopped and then corrected.

- **`chat/truncated`, then `chat/turnStarted`**, as AHP describes for
  editing a message: truncate back to the turn before the edited one
  (which also drops it if it is running), then start a turn with the
  edited text, keeping the original's model and attachments. Both are
  write-ahead, so the timeline changes at once.
- **The host does the real work.** A truncation that only changed the
  client's view would leave the dropped turn in the model's context.
  pi-agent-host-protocol (the host we use) rejected `chat/truncated`, so
  it learned it in the same change: it aborts a running turn and moves
  pi's session leaf back with pi's own `navigateTree` (what pi's `/tree`
  re-edit does), so nothing is deleted from the session file. The fake
  host accepts it too, and an integration test checks what pi's model
  sees afterwards (the faux model's new `history` keyword).
- **Only the latest message** (the running turn, else the latest) gets
  the button: that is the asked-for case, it keeps the timeline quiet,
  and it avoids truncating a long tail by accident. Not the oldest loaded
  turn while older turns are unloaded, since a truncation without a
  `turnId` would drop those too.
- **No capability check.** AHP has none for truncation; a host that
  rejects it rolls the drop back with a notice (`Restarting from your
edited message was undone`). Hiding the button per host would need a
  host-specific guess.
- **One inline editor** (`InlineMessageEditor`) now serves queued
  messages and this, instead of a second copy.

## 2026-10-18: ↑ edits the queued or previous message (AV-087)

Fixing a typo in a message just sent, or in one waiting in the queue,
meant retyping it or reaching for the mouse to click the queued row.

- **Queued messages first.** ↑ in an empty box opens the newest pending
  message (the last queued, else the steering one) in the existing AV-081
  inline editor, so Enter re-queues it with `chat/pendingMessageSet`
  under the same ID and its place in the queue is kept. The composer
  asks the panel through a counter (`editNewestRequests`), as the
  Cmd/Ctrl+L focus request already does, and the panel hands focus back
  when its editor closes.
- **Sent messages are recalled, not rewritten.** With nothing pending, ↑
  steps back through the chat's sent messages like a shell history, and
  Enter sends the edit as a new message. AHP's `chat/truncated` followed
  by `chat/turnStarted` would replace the earlier turn, but neither pi
  nor the fake host accepts `chat/truncated` from a client, and a
  rejected optimistic truncation would briefly wipe the history, so it
  is left for when hosts support it (see `GAPS.md`).
- **Typed text is never replaced.** Recall starts only from an empty box,
  and continues only while the box holds the recalled text unchanged and
  the caret is on its first (↑) or last (↓) line; otherwise the keys
  move the caret. Modified arrows keep their shortcuts (Alt+↑/↓,
  Cmd/Ctrl+Alt+↑/↓), and the open completion popup keeps ↑/↓.
- **Pure helpers** (`composer/message_history.dart`) hold the history and
  the steps; the widget holds only the recalled index.

## 2026-10-17: Reconnects that do not get stuck (AHP-004)

A host that dropped could stay disconnected for good. The reconnect loop
awaited the socket and the `reconnect`, `initialize` and `listSessions`
requests with no timeout, so one attempt the host never answered (a
device waking from sleep, a changed network, a proxy holding the socket
open) left the client in "Reconnecting…" forever. And `connect` gave up
after one failure, so a remembered host restored on start while it was
not up yet (the laptop just woke, the host was restarting) stayed failed
until the user pressed Retry.

- **A `handshakeTimeout` (20 s) per step** (opening the socket and each
  handshake request) rather than one timeout around the whole attempt:
  a timed-out step closes its socket, and a socket that opens after the
  timeout is closed again. 20 s is above `pingInterval` + `pingTimeout`
  and a slow host's `listSessions`; the timeout raises a
  `ConnectionProblem` naming the step, which the host menu shows.
- **A connection generation** (bumped by `connect` and `close`) instead
  of the `_reconnecting` flag: with attempts now abandoned, a late socket
  or a loop from an earlier connection must not replace the current one,
  and a stale loop must not block a new one from starting.
- **`connect(retry: true)` reuses the reconnect loop**, sending
  `initialize` until the host has initialized once (it has no state to
  resume). Only errors retrying can fix are retried
  (`isTransientConnectError`: unreachable, dropped, timed out); a
  JSON-RPC error such as an unsupported version, a URL that cannot work,
  a refused token (HTTP 401/403) or a TLS failure still ends in `failed`.
  The status while retrying is `reconnecting`, so the session list shows
  with "Reconnecting…" rather than the connect screen.
- **Only restored hosts retry.** A host added or picked on the connect
  screen still fails at once, so the user sees the error where they
  typed the URL. Rejected: retrying every remembered host, which would
  leave the connect screen with no error to show.
- **`checkConnection()` on returning to the foreground.** After a sleep
  the backoff may have reached its 30 s cap, or the socket may be dead
  with the next ping 15 s away; resuming retries or pings at once.
  Rejected: a connectivity plugin (`connectivity_plus`) to react to
  network changes, as a new dependency for what the timeout, ping and
  resume check already cover.

## 2026-10-17: Persistent app name in the title bar (AV-091)

With a session open, the title bar's centre box showed only the
workspace and the app's name disappeared. Users could not see which app
they were in while reviewing a session.

- **A muted `appName` label** sits after the back and forward buttons
  and before the centred search box, styled with `labelMedium` and
  `mutedText`, on every medium and wide layout. The centre box still
  names the workspace or the connected host(s); compact layouts keep the
  list app bar unchanged.
- **Plain `Text` on the row** keeps macOS window dragging (`DragToMoveArea`
  under the row) working; the label uses `ValueKey('title-bar-app-name')`
  for tests.

## 2026-10-17: Skill completions in the new-session draft and when the host answers nothing (AV-044)

Typing `/` in the new-session composer completed nothing against pi.
The draft has no chat to send `completions` for and falls back to
`AgentInfo.customizations`, which pi did not publish (it lists skills
only on a session, once its pi starts). The follow-up box also showed
nothing when the host's `completions` failed with anything other than
"method not found", or answered no items (pi answers none when it cannot
list its commands), even though the session listed its skills.

- **pi publishes its global skills on the agent** (pi-agent-host-protocol
  10ffeb9): `refreshAgents` lists the commands an agent started in an
  empty folder would list, so project skills are left out. This is where
  AHP puts an agent's customizations before a session exists, and other
  clients (VS Code) benefit too.
- **The app falls back to a loaded session's skills** (`draftCommands`)
  when the agent lists none, preferring a session in the chosen folder,
  for hosts that, like pi before, publish skills only on sessions. It
  uses only state the app already mirrors; asking another session's chat
  for `completions` was rejected, since it would load that session on the
  host for an unrelated draft.
- **Fallback skills carry a skill reference.** Customizations name pi's
  skills without the `skill:` prefix pi expands, so inserting `/greet`
  alone would reach pi as text. The item's attachment has VS Code's
  skill-reference `_meta` (`uri`, `name`, `description`), which pi
  resolves to the skill; the new-session draft now sends accepted
  attachments with the first message.
- **Any failed or empty host answer falls back** to the session's
  commands, rather than only "method not found". The popup showed nothing
  in those cases before, so the fallback can only add items.

## 2026-10-17: Resizable panes, codicons and the reference's remaining differences (AV-005, AV-067, AV-090 to AV-096)

The screenshots against the reference left a list of differences in
GAPS.md: a fixed 380 px sidebar, the agent's provider id on the hover
card, a "Done · 107.0 s" footer, heavy Material icons, two bars on a
phone's session page, a jump button in the pane's corner, and a review
toggle that did not look like the reference's.

- **Panes resize by dragging their edge (AV-005).** A 7 px strip over
  the one-pixel divider (`PaneResizeHandle`) with a resize-column cursor;
  a double-click resets it. Widths are clamped to 240–600 px and to the
  room left beside the pane (`clampedPaneWidth`), so a narrow window
  keeps space for the session. `StoredWidth` (`prefs.dart`) keeps the
  width in `PrefsStore` and writes it when the drag ends, not on every
  pointer move. The sidebar defaults to 486 px, the reference's width
  measured at its 120% zoom (it takes about a third of the window). The
  review pane got the same handle (default 380 px). The drag counts from
  pointer down (`DragStartBehavior.down`), so the edge follows the
  pointer exactly. At the 240 px minimum the sidebar header drops the
  "⌘N" key cap (still in the tooltip) and uses 30 px icon buttons, as the
  reference does, so it does not overflow.
- **Agent names come from one pure helper.** `agentDisplayName` picks
  the host's `AgentInfo.displayName`, else the provider id; the hover
  card (the sessions screen passes each host's agents to the list) and
  both composers' placeholders use it.
- **The turn footer stays, quieter.** AV-067 asks for tokens per turn,
  so the footer remains on every finished turn, in `labelSmall` at
  regular weight in the muted colour, with the steps line's duration
  format ("1m 47s", `formatStepsDuration`). Showing it only on hover was
  rejected: touch screens have no hover, and screen readers would lose
  it.
- **Icons are VS Code's codicons, via `vscode_codicons`.** Candidates:
  `codicon` (flutter/devtools' third-party package; MIT code and
  CC-BY-4.0 font, but last published December 2024 with an older
  codicon set missing `layout-sidebar-right`, `sparkle` and
  `bell-slash`), `vscode_codicons` 0.0.45 (generated from the current
  `@vscode/codicons` npm package, published July 2026 and updated with
  each codicons release, null safe, 155 pub points, CC-BY-4.0 like
  Microsoft's font, but one maintainer and few likes) and
  `lucide_icons_flutter` (popular, MIT, but not the reference's icons).
  `vscode_codicons` was chosen because it is the reference's own icon
  set at its current version; it is a font and a generated table of
  constants, so it is cheap to replace or vendor if it stops being
  updated. Flutter's licence registry shows its CC-BY-4.0 notice. Every
  chrome icon is named in `AppIcons` (`theme/app_icons.dart`), so the set
  changes in one file. Menus' leading icons, status dots and timeline
  cards keep Material icons for now.
- **One bar on a phone's session page.** The pushed page has no
  `AppBar`; `SessionDetailView.showBackButton` puts a `BackButton` at the
  start of the session header (back, title, "…"). `BackButton` is kept,
  rather than a codicon, so the platform's back icon and
  `tester.pageBack` still apply. The draft page keeps its app bar: it
  has no header of its own.
- **The jump button lines up with the column.** It sits at
  `timelineEndInset(width)` from the pane's right: the list's padding
  plus half the room beside the centred column, so its edge meets the
  messages' and the composer's.
- **Title bar right side:** the review toggle uses `layout-sidebar-right`
  (`-off` while closed) and shows on wide layouts with or without an
  open session, next to the bell, as in the reference. Its menus' icons
  are 18 px like its buttons.

## 2026-10-17: Screenshots of the app against the reference UI, and the fixes they showed (AV-090 to AV-096)

The restyle to the reference UI (AV-090 to AV-096) had been built and
tested, but nobody had looked at the result on screen.

- **Screenshots come from a tagged widget test.** `screencapture` is
  not available to agents, and an integration test needs a desktop
  window, so `app/test/screenshots/reference_layout_test.dart` pumps the
  real `SessionsScreen` (macOS platform, fake host fixtures like the
  reference) and writes PNGs with `captureImage`. It is tagged
  `screenshots`: `just test` excludes it and `just screenshots` runs it.
  It loads the macOS system fonts and the SDK's Material icons, because
  widget tests draw text with a box font, and skips elsewhere. No golden
  files: the pixels depend on the installed fonts, so goldens would fail
  in CI; the layout facts behind the fixes are asserted in widget tests
  instead.
- **The reference is at 120% zoom.** Its 13 px text measures 15.6
  points, so the desktop shots render 1484×927 logical pixels at a 1.2
  pixel ratio, half the reference's pixels, and sizes are compared at
  that scale rather than by enlarging the app's fonts.
- **Fixes:** session rows are 56 px (the reference's, not the 44 px the
  spec had guessed) with 12 px details and a 4 px gap; section headers
  are semibold; toolbar and row icons are muted through the theme's
  `iconButtonTheme` and `popupMenuTheme`; the "New" button is neutral
  with a key cap for ⌘N; the session header has no divider and a muted
  "…"; the timeline's rows share the composer's centred column
  (`timelineMaxWidth`), and the turn rail floats over the list's end so
  the two stay aligned; user bubbles may take 90% of the column; table
  headers are start-aligned with outline-coloured borders and tighter
  cells; the composer's text field no longer draws the theme's border
  inside the box (a double border); the hover card opens beside the row,
  past its buttons (`hoverCardPosition`), instead of below it; and the
  debug banner is off.
- **Kept on purpose:** the turn footer (tokens per turn, AV-067) and the
  fixed sidebar width; see GAPS.md.

## 2026-10-17: Diff, terminal and highlight colours come from the theme; contrast is tested (AV-090)

The diff view, the AHP terminal preview and the SSH terminal used fixed
colours (a dark terminal in the light theme, GitHub's diff colours), and
the status dot and muted text colours had not been checked for contrast.

- **VS Code's colours.** The app's greys are VS Code's, so the new
  tokens are VS Code's defaults: diff lines use its translucent
  inserted and removed line fills (`#9BB95533`, `#FF000033`) over the
  diff area, line numbers its `editorLineNumber.foreground`, and
  terminals its integrated terminal palette, on the sidebar's grey so a
  terminal reads as an inset box in both themes. Code is highlighted in
  Dark+ and Light+ (`highlight_themes.dart`) instead of GitHub's themes.
- **The terminal palette is xterm.dart's `TerminalTheme`.** It already
  has the fields the SSH terminal needs, so `AppColors.terminal` holds
  one instead of a copy of the type; it has no lerp, so it switches
  halfway through a theme change.
- **Contrast is a test, not a review.** `contrastRatio` (WCAG 2.x, with
  translucent colours composited first) is checked against the tokens
  of both themes in `test/contrast_test.dart`. Text, muted text, error
  text and links need 4.5:1 and status dots 3:1 on every surface they
  sit on (including the selected and hovered rows). To pass, the muted
  text became `#999999` (dark) and `#616166` (light), the idle dot
  `#808080` and `#787878`, and the light attention dot `#9A6700`; five
  highlight colours were nudged (dark comment and regexp, light number,
  type and attribute).
- **Hairlines stay decorative.** Making dividers and box borders 3:1
  would make them heavy, unlike the reference, and WCAG 1.4.11 does not
  ask it of borders that are not needed to identify a control; fields
  have placeholders and an accent border when focused (3:1). The test
  only keeps hairlines visible (1.1:1).
- **Diff fills keep syntax colours at 3:1.** On a tinted line some
  highlight colours fall under 4.5:1 (as in VS Code); the plain code
  text stays at 4.5:1 and the line numbers, which repeat the position,
  at 3:1.

## 2026-10-17: A title-only session header and the reference composer (AV-094, AV-096)

The user asked for the session header and the chat box at the bottom to
look like the reference screenshot
([design/reference/agents-window.md](design/reference/agents-window.md)).

- **Header details move into the "…" menu and a "Details" popover.**
  The header is now the title (still click-to-rename, AV-073) and the
  "…" menu. The menu starts with plain lines (agent and model, folder
  and branch, tokens, change counts, status) so the common facts are one
  click away, then "Details…", Stop, the pull request and branch links
  and the existing actions. "Details…" opens a `MenuAnchor` popover
  instead of a dialog because a popover is rebuilt with the header, so
  background work, canvases and tools on other clients stay current
  while it is open (a dialog would show a snapshot). It has a close
  button so tests and keyboard users can dismiss it without tapping
  elsewhere.
- **Attention stays in view.** A failed turn shows an error icon beside
  the title, and MCP servers that need sign-in (or failed) keep their
  chips there, since hiding them in a menu would let a session stall
  unnoticed. Input requests already have the "Waiting for you" panel.
  Live activity left the header; the timeline's "Working…" line
  (AV-072, AV-095) shows it.
- **One composer box, also for new sessions.** `FollowUpInput` draws
  the box (8 px radius, hairline border, `raisedSurface`, at most 960 px
  wide with 20 px margins) with the text on top and "+", the chips and
  the send button along its bottom. The new-session draft keeps its
  host and agent chips and the folder field in a row above the box,
  so the bottom row matches a session's and the folder can still be
  typed.
- **Chips are `MenuAnchor`s with flat, muted labels.** Each chip's
  tooltip is its setting's title ("Mode", "Model", "Thinking"), so
  tests and screen readers keep finding them by name. The model chip
  reads the model id when it names its provider (pi's
  "anthropic/claude-opus-5-5"), else the model's name, plus the first
  choice option that is not the reasoning level; the reasoning option
  (matched by `thinking`, `reasoning` or `effort` in its id or title)
  moves to the effort chip with the context window ("Medium · 1M").
  Other choice options are submenus of the model chip, and options a
  menu cannot hold (text, numbers, switches) open from "More options…".
- **Send, queue, send now and stop share one place.** The arrow is
  disabled while the box is empty (no empty sends), reads "Queue" while
  the agent works, gains a "Send now" button beside it for typed text
  (touch users have no Cmd/Ctrl+Enter), and becomes a stop square while
  the agent works and the box is empty. The header's Stop button is
  gone; Stop is also in the "…" menu and Cmd/Ctrl+. still works.
- **Placeholder instead of a label.** The box has no "Prompt" label;
  its placeholder is "Chat with <agent> [<folder>]", or "Describe a
  task…" without an agent. Tests find the box as the `FollowUpInput`'s
  text field and the web tests by the placeholder.

## 2026-10-16: Hosts are no longer a level of the sidebar (AV-092, AV-093)

The user decided the sidebar should follow the reference UI
([design/reference/agents-window.md](design/reference/agents-window.md)):
sections for Pinned, Chats and each workspace, with the host shown on
rows rather than as a tree level.

- **Merge every host into the same sections.** The host tree made a
  user with one or two hosts expand a host to reach a workspace, and
  repeated the host's name on every level. Sessions of all open hosts
  now fill the same Pinned, Chats (no working directory) and folder
  sections. Folders stay keyed by host and exact working directory
  (AV-025), so the same path on two hosts is two sections; their
  headers and rows show the host's label only when more than one host
  is open (`hostLabelsOf`).
- **Host status and actions move to the "…" menu.** Each open host gets
  a submenu labelled with its status or error, holding Retry and Remove
  (when not connected), "Open SSH terminal" and "SSH settings…", so
  every action of the old host row stays reachable. A failed host puts a
  dot on the "…" icon, since its row no longer shows it.
- **Narrowing to one host is kept, in the "…" menu** ("Show only this
  host"). The `host:` search qualifier and the host labels cover most
  uses, but narrowing also picks the host for "New session" and
  "Disconnect", so dropping it would have lost those.
- **Folder order is global.** With no host level, folders are dragged
  across hosts. `folder_order` already stores `'host|path'` ids, and the
  per-host orders were saved into one list, so the stored list is read
  as one global order with no migration: each host's placed folders keep
  their relative order.
- **Header icons replace the chips and the search box.** The filter icon
  opens one menu of filters and sorts (the attention count moves to its
  "Needs attention" item; the window title keeps it too, AV-120). The
  search field shows from the search icon or Cmd/Ctrl+K and hides again
  when closed. "New session" and "Disconnect" left the title bar
  (AV-091) for the header, so they are not shown twice.
- **One status dot per row.** `dotBadgeFor` reuses `badgesFor`'s order
  (needs input, working, error), then unread, else idle;
  `statusDotColor` maps it onto the theme's status tokens (AV-090), with
  the text colour for unread, which has no token. The sidebar's other
  colours come from `AppColors` too, so it has no hard-coded colours.
- **The sidebar flag gets its own key.** The title bar's sidebar toggle
  (AV-091) saved its flag under `sidebar_collapsed`, the key of the
  collapsed sections, so each erased the other; the flag moves to
  `sidebar_hidden`. A toggle saved before reads as shown once.
  The title stays in regular weight; screen readers hear the status
  after the title, so rows are still named by their title first.
- **"Mark as done" is archive, with Undo.** The hover icon archives
  (AV-024) and shows a snackbar with Undo; the row menu and swipe do not,
  so their snackbars do not queue ahead of a rejected action's message.
- **The hover card is a `Tooltip` with a rich message** that waits
  500 ms and never triggers on touch, as a long press opens the row menu
  and drags folders.
- **Relative times read like the reference** ("10 hrs ago", "1 wk ago")
  instead of "10h".

## 2026-10-16: Reference theme and title bar (AV-090, AV-091)

- **Colours sampled from the screenshot.** The dark theme's greys come
  from `design/reference/agents-window.png`: the title bar and sidebar
  `#121314`, the main pane `#191A1B`, the composer and menus `#202122`,
  the user bubble `#292A2B`, the selected row `#2C2D2E`, hairlines
  `#2A2B2C`, muted text `#8C8C8C`; text is `#CCCCCC` and the accent a
  VS Code-like blue (`#3794FF`). The light theme mirrors the structure
  with light greys and `#0066CC`. They replace a Material indigo seed
  scheme, which tinted surfaces and looked nothing like the reference.
- **`ColorScheme` first, a `ThemeExtension` for the rest.** The greys
  go into the scheme's slots (`surface`, `surfaceContainer*`,
  `outlineVariant`, `secondaryContainer`) so stock Material widgets
  pick them up; tokens with no slot (sidebar and title bar background,
  bubble, hover and selected fills, muted text, status colours) are in
  `AppColors`, read with `AppColors.of(context)`, which falls back to
  the scheme so widgets also work under a plain `ThemeData` (widget
  tests). Other agents restyling the sidebar and timeline use the same
  tokens.
- **Flat, compact desktop.** Elevation 0 and a transparent
  `surfaceTint` for cards, app bars, dialogs and sheets; menus keep an
  elevation of 2 with a hairline border so they stand off the page.
  Desktop gets `VisualDensity.compact` and 13 px body text; mobile keeps
  the standard density and sizes for touch. The font is the platform's
  system font (SF on macOS, Segoe on Windows): adding Inter would grow
  every package for little gain.
- **The selected-tile fill is not themed.** A theme-wide
  `selectedTileColor` paints checked popup menu items, which Flutter
  asserts against; selected rows set their fill themselves.
- **macOS title bar from the runner, not a plugin.** Four lines in
  `MainFlutterWindow.swift` (transparent title bar, hidden title,
  full-size content, an empty `.unifiedCompact` toolbar to make the
  title bar 38 pt so the traffic lights centre in the app's bar) set it
  before the first frame; `window_manager`'s `setTitleBarStyle` would
  apply it only after Dart starts, and `macos_window_utils` is a new
  dependency for the same calls. Dragging and double-click zoom use
  `window_manager`'s `DragToMoveArea`, placed behind the bar's buttons:
  wrapped around them, its double-tap recogniser would hold every click
  for the double-tap timeout.
- **History as pure functions.** Back and forward are a list of opened
  `SessionRef`s and an index (`session_history.dart`), capped at 100;
  opening a session after going back drops the forward entries, as a
  browser does. Drafts are not entries.
- **What moved where.** The review pane toggle moved from beside the
  session header to the title bar as an icon (counts in the tooltip,
  the file count in a badge); it shows on wide layouts, where the pane
  exists. The app bar's protocol and reconnecting chips became plain
  text on the bar's right, New session and the bell stay icons, and
  Disconnect moved into a "…" menu (a one-click destructive icon in a
  slim bar is easy to hit by mistake). The centre box names the open
  session's workspace as "folder [repo]", else the host title the app
  bar showed ("All hosts", the host's name), which keeps that context.
- **Sidebar toggle and search.** The collapsed sidebar is remembered in
  `PrefsStore` through a new `StoredFlag` notifier, which the review
  pane's setting now uses too. Search (Cmd/Ctrl+K or the centre box)
  expands a collapsed sidebar first, since the search field is in it.

## 2026-10-16: The timeline matches the reference UI (AV-095)

The reference screenshot reads as a conversation: the user's bubble,
one muted "Completed 25 steps in 1m 47s" line, then the answer. Our
timeline showed every tool call as a card, so a long turn buried its
reply.

- **What a step is.** Reasoning and tool calls are steps, and so is
  markdown between the first and last step (the agent's narration,
  "Now the tests."), as in Cursor's agents window. Markdown before the
  first step and after the last (the reply) stays in view. The steps
  row sits where the first step was, so nothing is reordered except the
  folded parts. A part-by-part line per run of steps was rejected: a
  turn that alternates narration and calls would show many lines,
  unlike the reference.
- **Never hide what needs the user.** Calls waiting for approval,
  result confirmation or sign-in (`isBlocking`), input requests and
  errors are not steps; when they fall between steps they are listed
  right after the steps row. Todo lists (AV-070) and subagent cards
  (AV-069) also stay in view: they are the turn's progress and the way
  into child chats. A failed tool call is folded in, with "· N failed"
  on the line, because agents routinely run commands that fail (a
  `grep` with no match), and showing each one would undo the collapse.
- **The count and the time.** N counts the folded parts (each call of
  a grouped "Read · 3 calls" counts), so it matches what expanding
  shows. The time is `Turn.duration`, the host's own measure, formatted
  "12s", "1m 47s" or "1h 3m"; it is left out when the host sends none.
  A running turn shows "Working… N steps" without a live clock, which
  would rebuild the row every second.
- **The working indicator moves onto the line.** When the active turn
  has steps, its steps row carries the AV-072 dots and activity text
  (and keeps the "Agent is working: …" screen reader label) instead of
  a separate last row; without steps the `WorkingItem` row stays. The
  steps row is near the bottom, so the indicator is still in view.
- **Expansion lives in the timeline.** The lazy list disposes rows
  scrolled out of view, so an expanded steps row is remembered by key
  in the timeline's state (for as long as the chat is open), not in the
  row.
- **Rail on hover.** The rail is 16 dp and fades in when the pointer is
  within 64 dp of the timeline's right edge; it keeps its width so the
  text does not reflow. Compact layouts, touch platforms and a touch on
  the timeline keep it visible, since there is no hover there. Hidden,
  it stays in the semantics tree, and Cmd/Ctrl+Alt+↑/↓ still work.
- **Colours.** The timeline reads the AV-090 `AppColors` tokens:
  `bubbleFill` for bubbles, `hairline` for table borders, code blocks,
  the expanded steps' left rule and the jump button's ring, and
  `mutedText` for the steps line, so both themes follow the reference.
- **Tests.** The app flows and the harness's `send` now scroll the
  timeline to the newest row first, and `expandSteps` opens the newest
  turn's steps before the flows look for tool calls, terminals or
  diffs.

## 2026-10-16: One shared Pinned section at the top of the sidebar (AV-028)

This reverses the earlier "pins lead their folder" decision (see
"Pinned sessions (AV-028)" below) because of user feedback: pinned
sessions should sit together above every host and workspace.

- **Pinned sessions move, not copy.** A pinned session is listed only
  in the "Pinned" section, as GitHub's and Slack's pinned sections do,
  so the list has no duplicate rows, next and previous session
  (Alt+↓/↑) visit each session once, and multi-select has one checkbox
  per session. `splitPinned` takes the pinned sessions out before
  `groupHostSessions`, so a folder holding only pinned sessions is not
  shown, and the "folder with a pinned session first" rule and the
  pin-first sort inside folders (`compareHostSessions`) are gone.
- **The order pinned, not drag and not the sort.** The stored pin set
  is already an insertion-ordered list, so keeping that order needs no
  new storage and the `pinned_sessions` key and format stay the same.
  The folder drag code (`_FolderHeader`, `movedFolder`) is built around
  folder rows within one host; reusing it for session rows across
  hosts was not cheap, so drag reordering is left as a gap. Using the
  active sort was rejected because pinned rows would jump as sessions
  update.
- **A compact place label.** Pinned rows from several hosts and
  folders need context, so the row's second line starts with the
  host's label (only when several hosts are open) and the folder name
  (`pinnedPlace`).
- **One more collapsed id.** The section collapses like hosts and
  folders, stored as `pinned` in `sidebar_collapsed`; host keys are URLs
  and folder ids contain `|`, so the id cannot clash. Opening a pinned
  session expands the section instead of its host and folder.

## 2026-10-16: New sessions are drafted in the session pane (AV-040)

- **Start a session where its timeline will be.** The GitHub agents view
  (github.com/copilot/agents and the Agents panel) starts a task from
  its prompt box: the repository, base branch, agent and model pickers
  sit in the prompt field, Enter or "Start task" submits, and the new
  session appears in the list right away. "New session" (the toolbar
  button, a folder's "+", Cmd/Ctrl+N, the macOS menu) now opens a draft
  in the session pane instead of pushing a separate screen: a "New
  session" header, an empty timeline with a hint, and the same
  `FollowUpInput` as an open session, used as the prompt. On compact
  layouts the draft is the session page, and the started session
  replaces it, so Back returns to the list.
- **Reuse the follow-up box and its pickers.** `FollowUpInput` takes an
  optional `controller` (the caller then owns and clears the text, so a
  failed start keeps the prompt), a label, a hint and a send tooltip
  ("Start session", "Start 3 runs"). Its `MessageSettingsBar` picks the
  model, the model's choice options and the dropdown session settings
  (such as `mode`); `compactPicker` was pulled out of it for the draft's
  host and agent pickers. The working directory stays a text field (with
  "Browse…" and a recent folders menu) because paths are often typed.
  Settings that are not choices (such as `branch` with host suggestions)
  and the parallel runs editor sit in the empty timeline area rather
  than crowd the prompt. `isPickerField` decides which go where.
- **Drafts in memory, listed in the sidebar.** The sessions screen keeps
  what was typed per `NewSessionTarget` (the host and folder "New
  session" preselected; `withDraft` drops empty drafts), so switching to
  another session and back keeps the prompt, host, agent and folder. The
  open draft is a "New session" row atop the session list, highlighted
  while shown, with "Discard the draft". It is not stored or synced:
  AHP has no session to hold a draft before `createSession`.
- **Switch in place on success.** `onStarted` drops the draft and
  selects the first started session, as a click in the list would; the
  host's `createSession` plus the first `chat/turnStarted` put the
  prompt in its timeline. Starting runs and splitting their results is
  the pure `runOutcome`. The old `new_session_screen.dart` was removed.

## 2026-10-16: `/` completions in the composer and follow-up box (AV-044)

- **The host's `completions` first, the session's skills second.** AHP
  1.0.0 (and 0.9.0) has a `completions` command on a chat channel, and
  `InitializeResult.completionTriggerCharacters` says which characters
  should ask for it. The client keeps the characters in `HostState` and
  asks the host for them. pi answers `/` with its skills
  (`/skill:<name>`) and prompt templates, with the description in the
  attachment's `_meta.description`. A host with no trigger characters,
  or one that answers `-32601`, gets the user-invocable skills and
  prompts of `SessionState.customizations` (`slashCommands`) inserted
  as `/name `. The new-session composer has no chat yet, so it can only
  use the agent's `AgentInfo.customizations`.
- **Insert what the host returns, and send its attachment.** Accepting
  replaces `[rangeStart, rangeEnd)` with `insertText` (or inserts at the
  cursor without a range), as the protocol says. When the user typed
  more after the host answered, the end moves by the change in length.
  The item's attachment, with its `_meta` unchanged as the protocol
  requires, goes in `Message.attachments` when its text is still in the
  message: pi uses it to add skills referenced after the start of a
  message.
- **Pure logic in two places, one widget.** `completionToken` and
  `slashCommands` live in `ahp_client` (pure Dart), so the fake host
  answers `completions` with the same code. The app's
  `composer/completions.dart` holds the popup items, filtering
  (prefix matches first, then in-order characters), `applyCompletion`
  and the host-or-fallback choice. `CompletionPopup` holds the state
  (debounce of 150 ms, a generation counter, and a check that the text
  has not changed, so stale answers are dropped) and is shared by both
  text fields. The fields' existing key handlers call its `handleKey`
  first, so Enter, queue and steer still work when it is closed.
- **Anchored with `OverlayPortal` and `CompositedTransformFollower`.**
  The popup sits above the caret at the start of the word, measured
  from the field's `RenderEditable` when the popup changes (not during
  build), and it is a `TextFieldTapRegion` so a click does not unfocus
  the field. It shows at most eight items in a `Column` inside a
  `SemanticsRole.list` node, each item a `listItem`: a scroll view would
  put a scroll node between the list and its items, which the semantics
  roles do not allow. The result count is announced with
  `SemanticsService.sendAnnouncement`.

## 2026-10-16: SSH terminal to a host (AV-014)

- **dartssh2 for SSH, xterm.dart for the terminal.** Both are pure Dart,
  MIT licensed, maintained, and by the same original author, and
  xterm.dart's own example drives a dartssh2 shell. dartssh2 (4.1)
  supports password, keyboard-interactive and public key login
  (Ed25519, ECDSA, RSA with SHA-2; OpenSSH keys with bcrypt
  passphrases), pty requests and window changes, keepalives, and gives
  the host key's SHA256 fingerprint to a callback, so trust on first use
  needs no crypto of ours. Its custom `SSHIdentity` lets the agent sign,
  so the SSH agent needed only a small message codec over the Unix
  socket (`ssh_agent_codec.dart`). xterm.dart (4.0) is a full VT
  emulator with scrollback, selection, copy and paste shortcuts, mouse
  modes, resize and the platform text input (soft keyboards). The app
  had no terminal emulator before: live AHP terminals are plain text with
  escapes stripped (`terminal_text.dart`), so there was nothing to
  reuse. Alternatives: `ssh2` (a plugin wrapping native libssh2 on iOS
  and Android only, no desktop), spawning the system `ssh` in a pty with
  `flutter_pty` (no iOS, Android or sandboxed macOS, and the host key
  and secrets would live outside the app), and `flutter_terminal` or a
  `WebView` with xterm.js (heavier, and a web view per terminal).
  `file_selector` (flutter.dev) loads a key file; the macOS app gains
  the `files.user-selected.read-only` entitlement for it.
- **Settings per AHP host, all in secure storage.** One JSON entry per
  host key (`ssh:<host key>`) holds host, port, user, method and the
  secrets, like host tokens. The SSH host defaults to the AHP URL's
  host, since the agents run there. The known host keys are one map by
  `host:port` (`ssh_known_hosts`), so two AHP hosts on one machine share
  it.
- **Trust on first use, shown, not asked.** A new key is accepted,
  remembered and printed into the terminal with its fingerprint (as
  `ssh` does with `StrictHostKeyChecking=accept-new`). A changed key is
  refused with both fingerprints, and "Forget host key" in the SSH
  settings is the way to accept a new one.
- **`cd` typed into the shell, not a command.** Opening from a session
  types `cd '<folder>' && clear` into the login shell, so the user keeps
  their normal interactive shell and its startup files; `exec`-ing a
  command would change the shell's behavior. The folder is quoted for a
  POSIX shell.
- **Tabs on one screen.** `sshTerminalsProvider` holds the open
  `SshTerminal`s; each owns its xterm `Terminal` (so switching tabs
  keeps the screen and scrollback) and its shell. Terminals keep
  running when the screen is closed. A disconnected terminal stays open
  with Reconnect.
- **Ctrl on touch keyboards.** A key row adds Esc, Tab, arrows and a
  sticky Ctrl. The latch lives in `SshTerminal` and applies to the next
  character the terminal sends (`withControl`), because text from the
  soft keyboard does not go through xterm's key handler.
- **Not on the web.** Browsers cannot open TCP sockets.
  `ssh_connect.dart` exports `ssh_connect_io.dart` or
  `ssh_connect_web.dart` by conditional import; the web one sets
  `sshSupported` to false and explains why when asked to open a
  terminal.
- **Tested against a real sshd.** dartssh2 has no server, so
  `ssh_sshd_test.dart` starts OpenSSH's `sshd` as the current user on a
  free port with generated keys (CI installs `openssh-server` on Linux).
  The rest is tested against a fake `SshShell` through
  `sshConnectorProvider`.

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
- **Older turns also page in from the scroll position.** Unlike
  `ListView`, `SuperListView` builds no rows past the end of the list
  while it is overscrolled, so with bouncing physics (macOS, iOS) a long
  drag past the top never built the "load older" row and paging stalled.
  The timeline now also loads older turns when the scroll position comes
  within 250 dp of (or past) the oldest row.
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
  (Superseded the same day by "One shared Pinned section at the top of
  the sidebar (AV-028)" above.)
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
