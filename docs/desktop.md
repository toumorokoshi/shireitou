# Desktop apps (macOS, Linux and Windows)

shireitou runs as a native desktop app on macOS, Linux and Windows (AV-007),
as well as in the browser and on phones ([mobile.md](mobile.md)). All three
desktop builds are built, smoke-tested and packaged in CI (`linux-desktop`,
`macos-desktop` and `windows-desktop` jobs in
[`.github/workflows/ci.yml`](../.github/workflows/ci.yml)); packages,
signing and releases are in [packaging.md](packaging.md).

## Linux

### Build dependencies

```sh
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev
cd app && flutter build linux --release
```

The terminal panel's pty (`packages/flutter_pty`) is compiled by a Dart
build hook with the same C compiler; macOS uses Xcode's and Windows
Visual Studio's. The bundle is in `app/build/linux/<x64|arm64>/release/bundle/`.
`scripts/package-linux` turns it into a `.tar.gz`, a `.deb` and an AppImage
in `app/build/dist/` (CI uploads them as the `shireitou-linux` artifact; see
[packaging.md](packaging.md)).

#### Without root

If you cannot install packages, the toolchain can live in your home
directory (this is how the build was first verified on an Ubuntu 24.04
arm64 machine):

- Flutter: `git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git ~/sdk/flutter`.
- CMake: unpack a release tarball from <https://cmake.org/download/>.
- Headers: `apt-get download` the missing `-dev` packages
  (`libgtk-3-dev`, `libsecret-1-dev` and their `-dev` dependencies), unpack
  them with `dpkg -x` into a sysroot, point the `prefix=` lines of their
  `.pc` files at the sysroot, and repoint the dangling `lib*.so` symlinks to
  the runtime libraries in `/usr/lib/<triplet>/`.
- Export `PKG_CONFIG_PATH` (the sysroot's `pkgconfig` directories) and
  `LIBRARY_PATH` (its library directory) before `flutter build linux`.
  Delete `app/build/linux` after changing them; CMake caches the paths.

### Runtime requirements

- GTK 3 and libsecret (the `.deb` depends on `libgtk-3-0` and
  `libsecret-1-0`).
- `parecord` (`pulseaudio-utils`, with PulseAudio or PipeWire's Pulse
  server) for dictation (AV-047, [dictation.md](dictation.md)); the
  `.deb` recommends it.
- A running, unlocked Secret Service for saved hosts, for example
  gnome-keyring or KWallet. Without one, the app still connects, but logs
  `could not save the hosts` and forgets hosts on exit. On a headless
  session the default keyring is usually locked and libsecret would prompt;
  the smoke test starts its own keyring instead (see below).

## macOS

- Building needs a full Xcode install (`flutter build macos --release`).
  `scripts/package-macos` makes a `.dmg` in `app/build/dist/` (CI uploads
  it as the `shireitou-macos` artifact). It is signed and notarized only
  when the signing secrets are set ([packaging.md](packaging.md));
  otherwise Gatekeeper blocks it on other Macs (right-click > Open, or
  `xattr -d com.apple.quarantine`).
- The app is not sandboxed (no `com.apple.security.app-sandbox`): the
  terminal panel (AV-016) runs the system `ssh`, which inherits the
  sandbox and could not read `~/.ssh` or reach the SSH agent there. The
  `.dmg` is signed with the hardened runtime and notarized, which do not
  need the sandbox; only the Mac App Store does. Both
  `DebugProfile.entitlements` and `Release.entitlements` keep
  `com.apple.security.network.client` and
  `com.apple.security.network.server` (the loopback server for the
  browser's OAuth redirect, AHP-060), which matter again if the sandbox
  comes back.
- Settings from the sandboxed builds: a sandboxed app keeps its
  `UserDefaults` (where `shared_preferences` writes) in
  `~/Library/Containers/dev.shireitou.shireitou/Data/Library/Preferences`,
  an unsandboxed one in `~/Library/Preferences`. So the pins, folder
  order, theme and pane settings are not lost, the first start of an
  unsandboxed build reads the container's plist (`plutil -convert json`)
  and copies the settings the new location lacks, merging the pins
  (`lib/src/desktop/sandbox_prefs.dart`, run from `main` before the
  window is set up). It then sets `sandbox_prefs_migrated` and does not
  run again; the container's plist is left in place.
- Secure storage: `flutter_secure_storage` is configured with
  `MacOsOptions(usesDataProtectionKeychain: false)`, so tokens go in the
  login keychain. That needs no `keychain-access-groups` entitlement and so
  no provisioning profile, and an ad-hoc or Developer ID signed build can
  store tokens. Switch to the data protection keychain (and add the
  entitlement) only if the app ever shares items with another app.

### Microphone

Dictation (AV-047) needs the `com.apple.security.device.audio-input`
entitlement and `NSMicrophoneUsageDescription` in `Info.plist`; macOS
asks for microphone access the first time the button is pressed, and the
answer is in System Settings > Privacy & Security > Microphone. See
[dictation.md](dictation.md).

## Windows

- Building needs Visual Studio 2022 with "Desktop development with C++"
  (`flutter build windows --release`); the build is in
  `app/build/windows/x64/runner/Release/`. `scripts/package-windows` (Git
  Bash) zips it and makes an `.msix` (CI uploads both as the
  `shireitou-windows` artifact), signed only when the signing secrets are
  set ([packaging.md](packaging.md)).
- Secure storage: `flutter_secure_storage` encrypts the values with DPAPI
  for the current user.
- The OAuth redirect uses the same loopback server as the other desktops;
  Windows Firewall does not prompt for loopback-only listeners.
- Notifications are toasts (`flutter_local_notifications`); an unpackaged
  app (the `.zip`) shows them under the app user model ID
  `Shireitou.Shireitou.Desktop`.
- The window is shown when the first frame is drawn and its saved
  placement is applied right after (there is no hidden-at-launch window
  like macOS's), so it can jump once at start.

## Window behavior (AV-008)

- [`window_manager`](https://pub.dev/packages/window_manager) sets a minimum
  window size of 480 x 360 (the compact layout still fits) and opens the
  window at 1280 x 800 on first launch, centered. On Linux the minimum is a
  GTK geometry hint, which GTK applies to the app's own resizes and the
  window manager to the user's; the smoke test checks it under openbox.
  On Windows it is applied through `WM_GETMINMAXINFO`. On macOS AppKit
  applies it to the user's resizing only.
- The window's normal size, position and maximized state are saved with
  `shared_preferences` 0.5 s after it stops moving or resizing, and
  restored on the next launch. A saved position whose title area is not on
  any current display (for example after unplugging a monitor) is dropped
  and the window is centered instead. On Wayland, the compositor places
  windows (the protocol has no way for a client to set or read its
  position), so only the size and maximized state are restored; this is
  by design, not a missing feature.
- On macOS the window stays hidden until Dart has restored its placement
  (`hiddenWindowAtLaunch` in `MainFlutterWindow.swift`).
- macOS has a native menu bar (`PlatformMenuBar`): the app menu (About,
  Services, Hide, Quit), the Session menu with the AV-140 shortcuts (New
  Session ⌘N, Search Sessions ⌘K, Next/Previous Session ⌥↓/⌥↑, Stop ⌘.,
  Focus Composer ⌘L, Previous Turn ⌥⌘↑, Next Turn ⌥⌘↓, Toggle Review
  Pane ⌥⌘B), Host > Disconnect All (Cmd+Shift+D), View > Enter Full
  Screen, and the Window menu. On macOS the menu owns those keys (the
  Flutter `Shortcuts` for them are left out, so a key press cannot run a
  command twice); on Linux, Windows and the web the same keys, with Ctrl,
  are Flutter shortcuts (`lib/src/shortcuts.dart`). Linux uses the GTK
  header bar.
- The app draws its own title bar (AV-091, `lib/src/title_bar/`). On
  macOS `MainFlutterWindow.swift` makes the native title bar transparent
  and hidden-titled, runs the content view under it
  (`fullSizeContentView`), and adds an empty `.unifiedCompact` toolbar so
  the title bar is 38 pt tall, as the app's bar is, with the traffic
  lights centred in it. The app's bar leaves 76 px for them
  (`drawsInWindowTitleBar` in `desktop_window.dart`), and its empty
  space moves the window when dragged and zooms it on a double-click
  (`window_manager`'s `DragToMoveArea`, behind the buttons so their
  clicks do not wait for a double-click). Windows and Linux keep the
  native frame (the GTK header bar on Linux) with the app's bar under
  it.
- The window title carries the attention count (sessions that need
  input, failed or are unread), like "(3) shireitou" (AV-120), set with
  `window_manager`; on the web it is the tab title. macOS hides the
  title text (the app's bar is drawn there), but it still names the
  window in the Window menu and Mission Control.

## Notifications (AV-121)

The desktop apps post a notification whenever it is the user's turn in
a session: it needs input or an approval, its turn finished (the
`InProgress` bit cleared) or it failed, using
[`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
(`lib/src/notifications/`). All three are on by default; each can be
turned off from the bell menu in the title bar (saved with
`shared_preferences`). Nothing is posted for the session on screen while
the window has focus (other sessions still notify), or for sessions that
appear when a host connects. Clicking a notification brings the window
to the front and opens that session.

The app asks for permission when it starts, not when the first
notification is due: a prompt that appears while the user is in another
app is easy to miss, and nothing was posted until it was answered. When
permission is refused, the bell menu shows "Allow notifications…",
which asks again and otherwise says to allow them in the system
settings; a permission granted there later takes effect without a
restart.

- Linux: through the freedesktop notification service over D-Bus (the
  plugin is pure Dart, so the `.deb` needs no new library). Without a
  notification daemon (a bare X server, CI) the app logs
  `notifications are not available` and carries on.
- macOS: through UserNotifications; macOS asks for permission when the
  app starts. No entitlement is needed for local notifications. If the
  bell menu keeps offering "Allow notifications…", check System
  Settings > Notifications > shireitou.
- Windows: toast notifications; built in CI, but never shown (the tests
  turn notifications off).
- iOS and Android: see [mobile.md](mobile.md).
- Web: the browser's Notification API (page notifications, no service
  worker), while the tab is open. The browser asks for permission at
  start; browsers that only ask after a click (Firefox, Safari) ask from
  "Allow notifications…" in the bell menu. Clicking one focuses the tab
  and opens the session.

The same events play a chime, once per change however many sessions
changed, under the same rules (quiet for the session on screen in a
focused window). It does not need the notification permission, so it
still plays when the system refuses notifications or the ad hoc signed
macOS app is not authorized. "Play a sound" in the bell menu turns it
off. When the chime plays, the notification is posted silent, so the
two never both make a sound.

The sound is Kenney's "confirmation_003" from
[Interface Sounds](https://kenney.nl/assets/interface-sounds) (CC0,
`assets/sounds/LICENSE-kenney.txt`), converted to a 28 KB mono WAV
(`assets/sounds/chime.wav`) so every platform and browser decodes it.
It plays through
[`flutter_soloud`](https://pub.dev/packages/flutter_soloud)
(`lib/src/notifications/chime_io.dart`), SoLoud on miniaudio, built by
the package's native build hook:

- The engine starts for each chime and stops 200 ms after it ends
  (about 70 ms to start, 0.4 s the first time): an open output stream
  would keep the audio hardware awake, and on macOS hold off idle
  sleep, for an app that runs all day.
- Linux: miniaudio loads ALSA (`libasound.so.2`) or PulseAudio at run
  time, so the build needs no audio headers; the `.deb` depends on
  `libasound2`.
- Web: the browser's Web Audio API decodes and plays the same file
  (`chime_web.dart`), so the web build does not load SoLoud's 1.9 MB
  WebAssembly engine.
- iOS and Android: see [mobile.md](mobile.md).

Notifications come from this process, so they stop when the app quits;
push for a closed app needs the relay in
[specs/push-relay.md](../specs/push-relay.md).

## Connection token (AHP-002)

On native platforms the token is sent in the WebSocket upgrade request as
`Authorization: Bearer <token>` and also kept in the `tkn` query parameter,
because pi-agent-host-protocol reads only `tkn`. Browsers cannot set upgrade
headers, so web sends only `tkn`. `webSocketConnector(tokenTransport: ...)`
in `ahp_client` selects query, header or both.

## Error log (AV-145)

Flutter prints a run's first error in full and every later one as a
single "Another exception was thrown" line. Some errors set off a
cascade: one thrown in a hover callback or a hit test leaves the mouse
tracker failing `'!_debugDuringDeviceUpdate': is not true` (and, after
the pointer leaves and re-enters the window,
`(event is PointerAddedEvent) == (lastEvent is PointerRemovedEvent)`)
on every mouse move, so the report that names the cause scrolls away.

Debug builds (`just run macos`, `flutter run`) therefore write the full
report and stack of each distinct error to `logs/errors.log` in the app's
support folder, up to 50 a run, and log its path at start ("Full error
reports go to …"). The previous run's file is kept as
`logs/errors.previous.log`. The support folder is:

| Platform | Folder                                                  |
| -------- | ------------------------------------------------------- |
| macOS    | `~/Library/Application Support/dev.shireitou.shireitou` |
| Linux    | `~/.local/share/dev.shireitou.shireitou`                |
| Windows  | `%APPDATA%\dev.shireitou\shireitou`                     |

For a mouse tracker cascade, the first entry in the file is the bug.

## Smoke test

`app/integration_test/desktop_smoke_test.dart` runs the real app: it checks
the window opens at least at the minimum size and that its placement is
saved, that the window cannot be made smaller than the minimum (Linux and
Windows), then (when `AHP_URL` is set) connects to a host and checks the
host was saved in secure storage. `just test-desktop [linux|macos|windows]` (see
`scripts/test-desktop`) starts pi-agent-host-protocol from
`PI_AHP_HOST_DIR` with a connection token and runs it. On Linux, give it a
display and a fresh unlocked keyring, as CI does:

```sh
xvfb-run -a dbus-run-session -- bash -c \
  'echo -n pw | gnome-keyring-daemon --unlock --components=secrets >/dev/null && (openbox &) && just test-desktop linux'
```

CI runs it under openbox, a real window manager, so window manager
behavior (the minimum size hint) is exercised; without one, Xvfb applies
whatever the app asks for.

`just test-fake-host-app [linux|macos|windows]` runs
`app/integration_test/fake_host_flows_test.dart` the same way: the app
against the scripted fake host (approvals, input requests, MCP sign-in;
see [fake-host.md](fake-host.md)). CI runs it as its own step after the
smoke test on all three desktops. It keeps remembered hosts in memory, so it
needs a display but no keyring or keychain.
