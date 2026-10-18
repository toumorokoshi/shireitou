# shireitou

A cross-platform (Flutter/Dart) agents view: start, monitor, steer, and review
coding-agent sessions running on
[Agent Host Protocol](https://microsoft.github.io/agent-host-protocol/) hosts,
with a UX modeled on the GitHub Agents view and Cursor's Agents Window.

> Status: usable for chat and review, on the web and as macOS and Linux
> desktop apps. The app connects to several hosts at once (remembering
> recent hosts), lists their sessions in one inbox of Pinned, Chats and
> one section per working directory (with the repository when the host
> reports it, and the host's name on rows when several are open), opens a session's
> history (paging older turns in when the host windows it, with a rail
> of turn markers to jump between turns), streams
> replies with highlighted code, folds each turn's tool calls into one
> "Completed N steps" line (grouping similar ones), shows live
> terminal output and inline diffs, switches between a session's chats
> (subagents, side chats), sends, queues, edits and reorders follow-ups,
> syncs drafts, stops turns, answers tool approvals (with the host's
> options, risk assessments, edited input and result confirmation), input
> requests (also from other chats, with synced drafts) and sign-in
> prompts (OAuth in the browser with PKCE, or a pasted token; expired
> tokens are refreshed), reviews changesets (files,
> diffs, "reviewed" marks, host operations), shows background work,
> canvases and session details, and starts new sessions from a draft
> in the session pane (host, agent,
> model and its options such as the thinking level, a folder browsed on
> the host, and the agent's settings such as the mode). The inbox has
> filters, search and sort in its header, a "Pinned" section at the top,
> two-line rows with a status dot, pin and "mark as done" on hover and a
> hover card, rename, archive
> and mark read from a row's menu, a
> swipe or multi-select, folders reordered by drag and drop (the order
> and collapsed folders remembered), and the attention count in the window title; keyboard
> shortcuts start sessions, search, step through sessions, stop turns and
> focus the composer (in the macOS menu bar too), and the hosts open at
> the last run reconnect on start. Agents' todo lists show as checklists,
> plan reviews take a choice plus feedback, the session header (a
> title and a "…" menu with the details and actions) links to
> the branch's pull request, the composer is one rounded box with mode,
> model and effort chips and a send arrow that turns into stop, `/` in the composer and follow-up box
> completes the agent's skills and commands (from the host's
> `completions`), one prompt can start several runs to
> compare and pick from, and the desktop apps (and the web app, where
> the browser allows) notify when a session needs input, finishes or
> fails. A host's menu and a session's menu open an SSH terminal on the
> host (desktop and mobile apps). Push notifications for a closed app
> are not built; see [GAPS.md](GAPS.md).

## Layout

- [`packages/ahp_client/`](packages/ahp_client/): pure-Dart AHP client (no
  Flutter dependency). Wire types, pure reducers, and the WebSocket JSON-RPC
  connection.
- [`packages/ahp_fake_host/`](packages/ahp_fake_host/): a scripted AHP
  host for tests that asks for tool approvals, input and MCP sign-in
  (with an in-process OAuth authorization server),
  streams terminals, edits files into changesets, spawns subagent chats
  and serves a windowed long session (see
  [docs/fake-host.md](docs/fake-host.md)).
- [`packages/ahp_wire_gen/`](packages/ahp_wire_gen/): generates the client's
  wire types from the vendored AHP 1.0.0 JSON Schemas (see
  [docs/wire-types.md](docs/wire-types.md)).
- [`app/`](app/): the Flutter app (macOS, Windows, Linux, iOS, Android, web).
- [`examples/`](examples/): recorded AHP traffic used by tests.

The root `pubspec.yaml` is a [pub workspace](https://dart.dev/tools/pub/workspaces),
so one `flutter pub get` at the root resolves every package.

## Documentation

- [docs/architecture.md](docs/architecture.md): how the code is organized.
- [docs/wire-types.md](docs/wire-types.md): how the AHP wire types are
  generated from the JSON Schemas, and how to upgrade the protocol version.
- [docs/fake-host.md](docs/fake-host.md): the scripted fake host and the
  tests that use it.
- [docs/testing.md](docs/testing.md): the test layers, pi with its faux
  model, breaking connections, and the browser tests.
- [docs/desktop.md](docs/desktop.md): macOS, Linux and Windows builds,
  dependencies, window behavior and the desktop smoke test.
- [docs/mobile.md](docs/mobile.md): iOS and Android builds, permissions,
  secure storage, sign-in and the mobile smoke test.
- [docs/ssh-terminal.md](docs/ssh-terminal.md): SSH terminals to a host
  (settings, host keys, the terminals screen).
- [docs/packaging.md](docs/packaging.md): packages, the app icon, the
  release workflow and the signing secrets it uses.
- [specs/agents-view.md](specs/agents-view.md): UI and feature requirements.
- [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md):
  requirements for the Dart AHP client.
- [specs/push-relay.md](specs/push-relay.md): design of the push relay
  for notifications while the app is closed (not built).
- [docs/research/agents-view-research.md](docs/research/agents-view-research.md):
  research and sources.
- [GAPS.md](GAPS.md): open questions and work not yet done.
- [DESIGN-DECISION-LOG.md](DESIGN-DECISION-LOG.md): design decisions, by date.

## Development

Requires Flutter 3.47.7 (Dart 3.13), Node.js (for prettier), and
[just](https://github.com/casey/just).

```sh
flutter pub get          # resolves the whole workspace
just lint                # prettier, dart format, dart/flutter analyze
just fix                 # dart fix, then format
just test                # unit and widget tests, client flows on the fake host
just fake-host           # run the scripted fake host (prints its URL)
just test-fake-host-app linux   # drive the app against the fake host
just test-fake-host-app flutter-tester   # the same, headless
just test-integration    # ahp_client against pi (no API key: pi's faux model)
just pi-faux-host        # run pi with its scripted faux model (prints its URL)
just test-pi-app linux   # drive the app against pi with the faux model
just test-web            # the web build in Chromium with Playwright
just test-model          # a real model turn through pi (costs tokens)
just test-desktop linux  # desktop smoke test against pi (see docs/desktop.md)
just test-mobile <id>    # mobile smoke test on an emulator/simulator (docs/mobile.md)
just icons               # re-render the app icons (see docs/packaging.md)
just codegen             # regenerate the wire types (and freezed code)
just fetch-schema        # re-download the vendored AHP 1.0.0 JSON Schemas
just run                 # flutter run -d chrome
just run macos           # needs a full Xcode install
just run linux           # needs GTK 3, CMake, Ninja, clang, libsecret
just run windows         # needs Visual Studio 2022 with C++ desktop tools
just run chrome 'ws://127.0.0.1:63877?tkn=...'   # prefill the host URL
```

## Trying it

1. Start a host. From a
   [pi-agent-host-protocol](https://github.com/toumorokoshi/pi-agent-host-protocol)
   checkout (needs a model provider configured for pi in `~/.pi/agent`):

   ```sh
   node src/bin/pi-agent-host-protocol.ts --pi-mode embedded
   ```

   It prints `pi-agent-host-protocol listening on ws://127.0.0.1:<port>?tkn=…`.
   To keep test sessions out of your real pi history, add
   `--session-dir /tmp/pi-sessions`.

2. Run the desktop app (`just run linux` or `just run macos`; see
   [docs/desktop.md](docs/desktop.md)), the app in Chrome (`just run`), or
   build and serve the web app:

   ```sh
   cd app && flutter build web
   python3 -m http.server 8080 --directory build/web   # open http://127.0.0.1:8080
   ```

3. Paste the whole `ws://…?tkn=…` URL into the connect screen, optionally
   with a name. Hosts you connect to are remembered (in secure storage)
   under **Recent hosts**, most recent first, where you can reconnect, edit
   or forget them.

4. Pick a session, or press **+** to start one: a draft opens in the
   session pane, laid out like a session; choose the agent and folder
   above its box and the model with the chips along its bottom, write
   the prompt and press Enter, and the
   pane switches to the new session. In a session, Enter sends a
   follow-up (or queues it while the agent works), Cmd/Ctrl+Enter steers the
   running turn, Shift+Enter adds a newline, and the stop square (the
   send arrow while the agent works and the box is empty) cancels the
   turn. ↑ in the empty box edits the newest queued message (Enter
   re-queues it), or else recalls your earlier messages to edit and send
   again; ↓ steps back.

   Shortcuts (Cmd on macOS, Ctrl elsewhere): Cmd/Ctrl+N new session,
   Cmd/Ctrl+K show and focus the search field (with `agent:`, `status:`, `repo:` and
   `host:` qualifiers), Alt+↓/↑ next and previous session, Cmd/Ctrl+.
   stop, Cmd/Ctrl+L focus the follow-up box, Cmd/Ctrl+Alt+B open or close
   the review pane (wide windows; it starts closed), Cmd/Ctrl+Alt+↑/↓
   previous and next turn in the open chat. Right-click or
   long-press a session to rename it, archive it, mark it read or unread,
   or select several; swipe it left to archive it, or hover it and click
   the check to mark it done. The filter icon above the list picks the
   filter and sort; the "…" menu holds Select, Add host…, Disconnect and
   each host's status, Retry and SSH terminal. Click a session's
   title in its header to rename it.

`just test-integration` launches pi-agent-host-protocol from
`PI_AHP_HOST_DIR` (default: `../pi-agent-host-protocol`, a sibling of this
repo, with `npm ci` run in it) in an isolated temp directory, and is skipped
when no checkout exists. Its client flows, `just test-pi-app` and
`just test-web` use pi's scripted faux model, so they need no API key; see
[docs/testing.md](docs/testing.md).
`just test-model` does the same but with your `~/.pi/agent` providers, and
sends one tiny real turn; CI does not run it.
