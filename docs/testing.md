# Testing

shireitou is tested in layers, from pure functions to the real app driven
in a browser against a real host. Every layer below runs in CI
(`.github/workflows/ci.yml`) except `just test-model` and
`just test-whisper` ([dictation.md](dictation.md)).

| Recipe                             | What it drives                                                              | Host                                 | CI job                 |
| ---------------------------------- | --------------------------------------------------------------------------- | ------------------------------------ | ---------------------- |
| `just test`                        | Unit and widget tests; `AhpClient` flows (`packages/ahp_fake_host/test`)    | Fake host, in process                | `lint-and-test`        |
| `just test-integration`            | `AhpClient` against pi: handshake, tokens, replies, tools, stop, reconnects | pi (no model, then the faux model)   | `integration`          |
| `just test-fake-host-app <device>` | The app (`app/integration_test/fake_host_flows_test.dart`)                  | Fake host, in process                | Linux, macOS, Windows  |
| `just test-pi-app <device>`        | The app (`app/integration_test/pi_host_flows_test.dart`)                    | pi with the faux model               | `linux-desktop`        |
| `just test-desktop <device>`       | Desktop smoke test: window, secure storage, token header                    | pi (no model)                        | Linux, macOS, Windows  |
| `just test-mobile <device>`        | Mobile smoke test: secure storage, the phone layout, approvals and input    | Fake host, in process                | `android`, `ios`       |
| `just test-web`                    | The web build in Chromium with Playwright (`app/web_test`)                  | Fake host and pi with the faux model | `web`                  |
| `just test-model`                  | One real model turn through pi                                              | pi with your `~/.pi/agent` providers | none (costs tokens)    |
| `just test-whisper`                | Dictation with the real Whisper model on a recorded sentence                | none                                 | none (161 MB download) |

The app tests run on `linux`, `macos` or `windows` (Linux needs a
display, e.g. `xvfb-run -a`), or headless with the `flutter-tester`
device, which has no window plugin but runs everything else. The mobile
smoke test runs on an Android emulator or iOS simulator (see
[mobile.md](mobile.md)).

## Screenshots against the reference UI

`just screenshots` runs `app/test/screenshots/reference_layout_test.dart`
(tagged `screenshots`, so `just test` leaves it out). It pumps the real
`SessionsScreen` with fixture data like
[the reference screenshot](../design/reference/agents-window.md) (pinned
sessions, Chats, two workspaces, an open session with a 25-step turn, a
markdown table and the composer's chips) and writes PNGs to
`app/build/screenshots/`:

| File                  | What                                                         |
| --------------------- | ------------------------------------------------------------ |
| `dark.png`            | Desktop, dark, at the reference's scale                      |
| `light.png`           | Desktop, light                                               |
| `compact.png`         | A phone (390×844), the open session                          |
| `compact-list.png`    | A phone, the session list                                    |
| `dark-hover.png`      | Desktop, a row hovered: its buttons and hover card           |
| `dark-scrolled.png`   | Desktop, scrolled up: the jump-to-latest button and the rail |
| `theme-<id>.png`      | Desktop, in a sample of the colour themes (AV-097)           |
| `appearance-menu.png` | Desktop, the Appearance menu's dark themes                   |

The desktop shots are 1781×1112 pixels at a 1.2 pixel ratio (1484×927
logical pixels), because the reference was taken at 120% zoom; they are
half the reference's size, pixel for pixel, so the two can be compared
directly or cropped at the same coordinates. Widget tests draw text with
a box font, so the test loads the macOS system fonts (`SFNS.ttf`,
`SFNSMono.ttf`), the Flutter SDK's Material icons and the codicons from
the app's assets; on other systems it
is skipped. The PNGs depend on the fonts installed, so they are not
golden files and do not run in CI; the layout they show (row heights,
the shared column, the hover card's position) is asserted in the widget
tests.

## Screenshots in the docs

`just docs-screenshots` runs
`app/test/screenshots/docs_screenshots_test.dart` the same way, but with
made-up sessions (a `weather-app` and a `dotfiles` folder) and writes to
`docs/images/`, which is committed and shown in the README and docs:
`desktop-dark.png`, `desktop-light.png`, `tool-approval.png`,
`theme-tokyo-night.png`, `phone-session.png` and `phone-list.png`. Both
tests share `screenshot_harness.dart` (fonts, screen sizes, pumping the
app, writing PNGs). Re-run it after a visible UI change and commit the
images; it is not run in CI.

## pi with the faux model

pi ships a scripted "faux" model provider for its own tests.
`scripts/pi-faux-host.ts` (`just pi-faux-host`) runs
pi-agent-host-protocol with it, embedded (pi's SDK in the same `node`
process), so tests stream real pi turns without an API key or network
access. It imports the host from a pi-agent-host-protocol checkout
(`--pi-dir`, else `PI_AHP_HOST_DIR`, else a sibling of this repo) that has
had `npm ci`. Options: `--port` (0 for a free one), `--token T` (default
`faux-token`) or `--no-token`, `--state-dir` (sessions, settings and the
archive; a temp directory removed on exit by default) and
`--tokens-per-second` (default 500).

The model replies by keyword in the newest user message:

| Message contains | Reply                                                                                                       |
| ---------------- | ----------------------------------------------------------------------------------------------------------- |
| `tool`           | "Running a command." and a `bash` call of `echo hello from pi`, then "The bash tool printed: hello from pi" |
| `slow`           | "Counting slowly: word1 … word3000 done.", about 12 s of streaming (to stop, queue behind or reconnect)     |
| `history`        | "pi faux history: <each user message in context, joined by `\|`>" (to check what a truncation dropped)      |
| `think`          | Reasoning, then "Thought about: <message>"                                                                  |
| anything else    | "pi faux reply: <message>"                                                                                  |

Dart tests start it with `PiFauxHost.start()` (`packages/ahp_fake_host`),
which finds the script from the current directory, the running executable
or `SHIREITOU_REPO`, and is skipped (`PiFauxHost.unavailable`) without a
checkout. `restart()` stops pi and starts it again on the same port and
state directory, as a host restart: pi forgets its clients (a `reconnect`
gets `-32008`) but keeps the sessions it saved.

## Breaking the connection

`TcpRelay` (`packages/ahp_fake_host`, and `Relay` in
`app/web_test/tests/support.ts`) sits between a client and a host:

- `drop()` closes every relayed connection, as a network drop would;
- `refusing = true` turns new connections away, so the client stays in
  "Reconnecting…" until the test lets it back in;
- `hold()` black-holes what the client sends until the next `drop()`, so a
  dispatched action is lost with the connection and rolled back.

The fake host can do the same without a relay: `dropConnections()`,
`refuseConnections`, `loseActions`, and `removeSession()` for a channel
that is gone when the client comes back (see
[fake-host.md](fake-host.md)).

What is covered:

| Case                                   | Fake host (client, app, web) | pi (client, app, web) |
| -------------------------------------- | ---------------------------- | --------------------- |
| Replay of actions missed while away    | yes, yes, —                  | yes, yes, yes         |
| Snapshots when the replay is too short | yes, —, —                    | —                     |
| `missing` channels                     | yes, yes, —                  | yes, —, —             |
| Pending action rolled back             | yes, yes, —                  | yes, yes, yes         |
| Host restart (`-32008`, `initialize`)  | —                            | yes, yes, yes         |
| Reconnect after a drop                 | yes, yes, yes                | yes, yes, yes         |

## The web app in a browser

`app/web_test` is a Playwright suite (`@playwright/test`, Chromium). `just
test-web` builds the web app with `--dart-define=SHIREITOU_SEMANTICS=true`,
which turns Flutter's semantics tree on at start, so the DOM has an element
with an accessible name for every button, field and text, and Playwright
finds them by role and name (`getByRole("button", { name: "Connect" })`).
The build is served by `python3 -m http.server` on port 8765
(`SHIREITOU_WEB_PORT`). Each test starts its own hosts: the fake host with
`dart run ahp_fake_host` and pi with `scripts/pi-faux-host.ts`, behind a
relay.

- `fake_host.spec.ts`: a session and a reply; Ctrl+K, Alt+↓, Ctrl+L and
  Ctrl+. as the browser delivers them; MCP sign-in through a real new tab,
  the fake authorization server and `oauth_callback.html` (the code comes
  back over `BroadcastChannel`); a reconnect.
- `pi.spec.ts`: the new-session draft in the session pane starts a pi
  session; a drop in the middle of a
  reply is replayed; a message lost with the connection is rolled back; pi
  restarts and the session continues. Skipped without a pi checkout.

Keys reach the app only while the Flutter view has the focus. After the
focused element goes away (the Connect button, when the connect page
closes) the browser's focus is on the page body, so the tests click into
the app first, as a user would. Playwright sends keys through the Chrome
DevTools Protocol, so shortcuts the browser itself reserves (Ctrl+N, Ctrl+T)
are not exercised as they would be from a real keyboard.

Failed tests keep a Playwright trace in `app/web_test/test-results/`
(uploaded by CI as `playwright-traces`); open one with `npx playwright
show-trace <trace.zip>`.
