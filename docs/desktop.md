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

The bundle is in `app/build/linux/<x64|arm64>/release/bundle/`.
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
- Entitlements: both `DebugProfile.entitlements` and `Release.entitlements`
  have `com.apple.security.network.client`, which the app sandbox needs for
  outgoing WebSocket connections to hosts, and
  `com.apple.security.network.server`, which the loopback server that
  receives the browser's OAuth redirect needs (MCP sign-in, AHP-060).
- Secure storage: `flutter_secure_storage` is configured with
  `MacOsOptions(usesDataProtectionKeychain: false)`, so tokens go in the
  login keychain. That needs no `keychain-access-groups` entitlement and so
  no provisioning profile, and an ad-hoc or Developer ID signed build can
  store tokens. Switch to the data protection keychain (and add the
  entitlement) only if the app ever shares items with another app.

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
  Focus Composer ⌘L), Host > Disconnect All (Cmd+Shift+D), View > Enter
  Full Screen, and the Window menu. On macOS the menu owns those keys (the
  Flutter `Shortcuts` for them are left out, so a key press cannot run a
  command twice); on Linux, Windows and the web the same keys, with Ctrl,
  are Flutter shortcuts (`lib/src/shortcuts.dart`). Linux uses the GTK
  header bar.
- The window title carries the attention count (sessions that need
  input, failed or are unread), like "(3) shireitou" (AV-120), set with
  `window_manager`; on the web it is the tab title.

## Notifications (AV-121)

The desktop apps post a notification when a session needs input,
finishes its turn or fails, using
[`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
(`lib/src/notifications/`). Each event can be turned off from the bell
menu in the session list's app bar (saved with `shared_preferences`).
Nothing is posted for the session on screen while the window has focus,
or for sessions that appear when a host connects. Clicking a
notification brings up that session.

- Linux: through the freedesktop notification service over D-Bus (the
  plugin is pure Dart, so the `.deb` needs no new library). Without a
  notification daemon (a bare X server, CI) the app logs
  `notifications are not available` and carries on.
- macOS: through UserNotifications; macOS asks for permission on the
  first notification. No entitlement is needed for local notifications.
- Windows: toast notifications; built in CI, but never shown (the tests
  turn notifications off).
- iOS and Android: see [mobile.md](mobile.md). The web build posts none
  (see GAPS.md).

Notifications come from this process, so they stop when the app quits;
push for a closed app needs the relay in
[specs/push-relay.md](../specs/push-relay.md).

## Connection token (AHP-002)

On native platforms the token is sent in the WebSocket upgrade request as
`Authorization: Bearer <token>` and also kept in the `tkn` query parameter,
because pi-agent-host-protocol reads only `tkn`. Browsers cannot set upgrade
headers, so web sends only `tkn`. `webSocketConnector(tokenTransport: ...)`
in `ahp_client` selects query, header or both.

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
