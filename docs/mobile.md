# iOS and Android

The same app runs on phones and tablets, in the compact (phone) and medium
(tablet) layouts. CI builds both (`android` and `ios` jobs in
[`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) and runs the
mobile smoke test on an Android emulator (API 34, x86_64) and an iPhone
simulator.

## Building

- Android: an Android SDK and JDK 17, then `scripts/package-android` (or
  `cd app && flutter build apk --release`). Release signing: see
  [packaging.md](packaging.md).
- iOS: Xcode, then `cd app && flutter build ios --release --no-codesign`.
  Running on a device needs a development team in Xcode
  (`ios/Runner.xcworkspace` > Signing & Capabilities); there is no
  App Store or TestFlight build yet (see GAPS.md).

## Installing the Android APK

Releases attach `shireitou-<v>-android.apk` (one APK for arm64, 32-bit
ARM and x86_64 devices) to the GitHub Release; see
[packaging.md](packaging.md) for how they are made. Download it on the
phone and open it, allowing the browser to install unknown apps when
Android asks, or install it from a computer with
`adb install shireitou-<v>-android.apk`. Later releases install over it
and keep the saved hosts, because they are signed with the same key.
APKs from CI runs on `main` are signed with other keys and cannot
update a release install (uninstall it first, losing the saved hosts).

## Connecting to hosts

- Hosts on a LAN, `localhost` or a VPN address are usually plain `ws://`,
  so cleartext traffic is allowed: `android:usesCleartextTraffic` on
  Android, `NSAllowsArbitraryLoads` and `NSAllowsLocalNetworking` in iOS's
  App Transport Security. iOS asks once for local network access
  (`NSLocalNetworkUsageDescription`) the first time the app reaches a LAN
  address.
- The connection token is sent as on desktop (header and `tkn`).
- iOS suspends a backgrounded app after a short time, and Android may
  stop its network; the connection drops and reconnects (with a replay)
  when the app comes back.

## Secure storage

Saved hosts and resource tokens use `flutter_secure_storage`:

- iOS: the keychain, with
  `KeychainAccessibility.first_unlock_this_device` (readable in the
  background after the first unlock, never synced to iCloud or restored to
  another device).
- Android: encrypted shared preferences with a Keystore key. The app opts
  out of Android backups (`allowBackup="false"`), because a restored
  backup would bring the encrypted values without the key.

## Sign-in to MCP servers (AHP-060)

Desktop apps receive the OAuth redirect on a loopback server. On iOS and
Android, the redirect goes to the app's own URL scheme instead (RFC 8252
§7.1), `dev.shireitou.shireitou:/oauth/callback`, registered with each
sign-in's dynamic client registration:

- iOS: `ASWebAuthenticationSession` (`WebAuthPlugin` in
  `ios/Runner/AppDelegate.swift`) shows the authorization page in a sheet
  that shares Safari's cookies and returns the redirect; closing the
  sheet cancels the sign-in.
- Android: `MainActivity` opens the system browser; the redirect comes
  back through the activity's intent filter on the scheme
  (`singleTask`, so the running app gets it in `onNewIntent`). Returning
  to the app without signing in cancels the sign-in.

Both answer the `dev.shireitou.shireitou/web_auth` method channel, used by
`lib/src/auth/app_scheme_redirect.dart`. Neither has been tried against a
real authorization server (see GAPS.md).

## Notifications (AV-121)

Local notifications work as on desktop while the app runs (Android also
for a while in the background): Android posts them on the "Sessions that
need you" channel and asks for permission on Android 13 and later; iOS
asks when the app starts. Nothing arrives once the system suspends
the app; that needs the push relay ([specs/push-relay.md](../specs/push-relay.md)).

## Mobile smoke test

`app/integration_test/mobile_smoke_test.dart` stores a host and a
resource token in secure storage and reads them back, then drives the
phone layout against the scripted fake host in the same process: connect,
open a session, approve a tool call and decline an input request.

```sh
just test-mobile emulator-5554           # Android emulator
just test-mobile <simulator UDID>        # iOS simulator (xcrun simctl list)
cd app && flutter test integration_test/mobile_smoke_test.dart -d flutter-tester  # headless, no storage
```

The emulator keeps its default 320 x 640 screen, the smallest phone the
layout has to fit. The full desktop fake host flows
(`fake_host_flows_test.dart`) assume the wide layout and are not run on
mobile.
