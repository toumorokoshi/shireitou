# Packaging and releases

Every platform's package is built by a script in `scripts/`, which CI runs
on each push (the `ci.yml` jobs upload them as artifacts) and the release
workflow runs for version tags
([`.github/workflows/release.yml`](../.github/workflows/release.yml)).

| Platform | Script                    | Output in `app/build/dist/`                                                                            |
| -------- | ------------------------- | ------------------------------------------------------------------------------------------------------ |
| Linux    | `scripts/package-linux`   | `shireitou-<v>-linux-<arch>.tar.gz`, `shireitou_<v>_<arch>.deb`, `shireitou-<v>-linux-<arch>.AppImage` |
| macOS    | `scripts/package-macos`   | `shireitou-<v>-macos.dmg` (universal)                                                                  |
| Windows  | `scripts/package-windows` | `shireitou-<v>-windows-x64.zip`, `shireitou-<v>-windows-x64.msix`                                      |
| Android  | `scripts/package-android` | `shireitou-<v>-android.apk`                                                                            |

`<v>` is the `version` in `app/pubspec.yaml` without the build number.
iOS is built in CI (`flutter build ios --no-codesign`) but not packaged:
an iOS app is distributed through the App Store or TestFlight, which needs
an Apple Developer account (see GAPS.md).

## Making a release

Once, before the first release, create the Android release key (needs a
JDK 17, e.g. `brew install --cask temurin@17`, and `gh` signed in):

```sh
just android-keystore ~/secrets/shireitou-release.jks
```

`scripts/android-keystore` writes the keystore and a `.password` file
next to it, prints the certificate's SHA-256 fingerprint and sets the
`ANDROID_KEYSTORE`, `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_ALIAS`
secrets. Back up both files (a password manager holds them well) and
keep them out of the repository: they are the only copies, and Android
only installs an update signed with the same key. The release workflow
refuses to publish a tag without the keystore.

Then, for each release:

1. Set `version:` in `app/pubspec.yaml` (for example `0.2.0+2`) and
   commit. The build number after `+` is Android's `versionCode` and
   iOS's build number; it must be above the previous release's, or
   Android refuses the update.
2. Optionally, run the Release workflow on `main` from the Actions tab
   (or `gh workflow run release.yml`): it builds everything without
   publishing, and the APK is in the `release-android` artifact.
3. Tag the commit `v<version>` (`git tag v0.2.0 && git push origin v0.2.0`).
4. The Release workflow checks the tag matches the pubspec version and
   the build number went up, builds Linux x64 and arm64, macOS, Windows
   and Android (checking the APK is signed with the release key), writes
   `SHA256SUMS` (and `SHA256SUMS.asc` when a GPG key is set), and
   publishes a GitHub Release with generated release notes. The APK is
   `shireitou-<v>-android.apk` among its assets.

Pushes to `main` that change the release workflow, a packaging script,
`app/pubspec.yaml` or the icon run the same builds without publishing, so
a broken release shows up before tagging. CI's `android` job signs its
APK with a throwaway key made by `scripts/android-keystore`, so the
release signing path runs on every push.

## Signing secrets

Every signing step is skipped, and the package left unsigned, when its
secrets are not set. Add them under the repository's Settings > Secrets
and variables > Actions.

| Secret                         | Used for                                                                 |
| ------------------------------ | ------------------------------------------------------------------------ |
| `MACOS_CERTIFICATE`            | base64 of a "Developer ID Application" certificate and key (`.p12`)      |
| `MACOS_CERTIFICATE_PASSWORD`   | the `.p12` password                                                      |
| `MACOS_SIGNING_IDENTITY`       | e.g. `Developer ID Application: Jane Doe (ABCDE12345)`                   |
| `APPLE_ID`                     | the Apple ID that notarizes                                              |
| `APPLE_TEAM_ID`                | the team ID (`ABCDE12345`)                                               |
| `APPLE_APP_PASSWORD`           | an app-specific password for that Apple ID                               |
| `WINDOWS_CERTIFICATE`          | base64 of a code signing certificate (`.pfx`)                            |
| `WINDOWS_CERTIFICATE_PASSWORD` | the `.pfx` password                                                      |
| `WINDOWS_PUBLISHER`            | the certificate's subject, e.g. `CN=Jane Doe, O=Jane Doe, C=US`          |
| `ANDROID_KEYSTORE`             | base64 of the release keystore (`.jks`)                                  |
| `ANDROID_KEYSTORE_PASSWORD`    | the keystore password                                                    |
| `ANDROID_KEY_ALIAS`            | the key's alias                                                          |
| `ANDROID_KEY_PASSWORD`         | the key's password (defaults to the keystore password)                   |
| `GPG_PRIVATE_KEY`              | an ASCII-armored private key; signs `SHA256SUMS` (covers .deb, AppImage) |
| `GPG_PASSPHRASE`               | its passphrase                                                           |

Encode files with `base64 -i file.p12 | pbcopy` (macOS) or
`base64 -w0 file.jks` (Linux).

What each produces:

- **macOS:** with the certificate, the frameworks and the app are signed
  with the hardened runtime and `Release.entitlements`, then the `.dmg`;
  with the three Apple secrets too, the `.dmg` is notarized
  (`notarytool --wait`) and stapled, so Gatekeeper opens it without a
  warning. Without them the `.dmg` is unsigned: right-click > Open, or
  `xattr -d com.apple.quarantine shireitou.app`.
- **Windows:** with the certificate, `shireitou.exe` is signed (with a
  timestamp) before zipping and the `.msix` is signed for
  `WINDOWS_PUBLISHER`. Without it, the `.zip` is unsigned (SmartScreen
  warns once) and the unsigned `.msix`, which Windows refuses to install,
  is built in CI to check the packaging but left out of releases.
- **Android:** with the keystore, the APK is release-signed, and
  `scripts/package-android` fails unless `apksigner` shows the keystore's
  certificate signed it (Gradle would otherwise fall back to the debug
  key silently). Without it, it is signed with the runner's debug key,
  which installs but cannot update, or be updated by, any other build;
  such APKs come only from builds on `main`, never from a tag. Keep the
  keystore safe: Android only accepts updates signed with the same key.
  To check a download, `apksigner verify --print-certs` shows the
  certificate's SHA-256, which should match the fingerprint
  `scripts/android-keystore` printed.
- **Linux:** the `.deb` and AppImage are not signed themselves (apt
  verifies repositories, not `.deb` files, and AppImage signatures are
  rarely checked); `SHA256SUMS.asc` covers every file instead.

## Linux packages

- `.deb`: the bundle in `/opt/shireitou`, `/usr/bin/shireitou`, the
  desktop entry `dev.shireitou.shireitou.desktop` and hicolor icons from 48
  to 512 px. Depends on GTK 3 and libsecret, recommends gnome-keyring.
- AppImage: the bundle at the AppDir's root, started by `AppRun`, made
  with [appimagetool](https://github.com/AppImage/appimagetool) 1.9.1
  (downloaded by the script, or `APPIMAGETOOL=/path/to/appimagetool`). GTK
  3 and libsecret come from the system, like the `.tar.gz`; they are on
  every desktop distribution, and bundling GTK would break theming. Run it
  with `chmod +x` and, without FUSE, `--appimage-extract-and-run`.
- `.tar.gz`: the bundle as built, with the window icon in
  `data/app_icon.png`.

The desktop entry's name, the GTK application ID (Wayland `app_id`) and
the X11 `WM_CLASS` are all `dev.shireitou.shireitou`, so docks and task
bars match the window to its entry and icon.

The release workflow builds Linux for x64 (`ubuntu-latest`) and arm64
(`ubuntu-24.04-arm`) from a checkout of the Flutter release, because
Flutter publishes no arm64 Linux SDK archive.

## App icon

The icon is a control tower sending signals (司令塔, _shireitou_), drawn
in [`app/assets/icon/shireitou.svg`](../app/assets/icon/shireitou.svg).
`just icons` (`scripts/render-icon`) renders it with Playwright's
Chromium into:

- `icon.png`: full bleed, for iOS, legacy Android launchers and the web.
- `icon-rounded.png`: a rounded square with margins, for macOS and
  Windows; `linux/<size>/dev.shireitou.shireitou.png` the same for Linux.
- `icon-foreground.png`: the tower alone, for Android's adaptive and
  themed (monochrome) icons on an indigo background.

and then runs `flutter_launcher_icons` (configured in `app/pubspec.yaml`)
to write every platform's icon files. Android's notification icon
(`res/drawable/ic_notification.xml`) is the same tower as a white vector,
kept by hand.
