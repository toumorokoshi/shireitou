# shireitou

A cross-platform (Flutter/Dart) agents view: start, monitor, steer, and review
coding-agent sessions running on
[Agent Host Protocol](https://microsoft.github.io/agent-host-protocol/) hosts,
with a UX modeled on the GitHub Agents view and Cursor's Agents Window.

> Status: usable for chat and review, on the web and as macOS and Linux
> desktop apps. The app connects to several hosts at once (remembering
> recent hosts), lists their sessions in one inbox grouped by host and
> working directory (with repository and branch when the host reports
> them), opens a session's
> history (paging older turns in when the host windows it), streams
> replies with highlighted code, groups similar tool calls, shows live
> terminal output and inline diffs, switches between a session's chats
> (subagents, side chats), sends, queues, edits and reorders follow-ups,
> syncs drafts, stops turns, answers tool approvals, input requests (also
> from other chats) and MCP sign-in prompts, reviews changesets (files,
> diffs, "reviewed" marks, host operations), shows background work,
> canvases and session details, and starts new sessions (host, agent,
> model and its options such as the thinking level, a folder browsed on
> the host, and the agent's settings such as the mode). Notifications are
> not built yet; see [GAPS.md](GAPS.md).

## Layout

- [`packages/ahp_client/`](packages/ahp_client/): pure-Dart AHP client (no
  Flutter dependency). Wire types, pure reducers, and the WebSocket JSON-RPC
  connection.
- [`packages/ahp_fake_host/`](packages/ahp_fake_host/): a scripted AHP
  host for tests that asks for tool approvals, input and MCP sign-in,
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
- [docs/desktop.md](docs/desktop.md): macOS and Linux builds, dependencies,
  window behavior, packaging and the desktop smoke test.
- [specs/agents-view.md](specs/agents-view.md): UI and feature requirements.
- [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md):
  requirements for the Dart AHP client.
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
just test-integration    # ahp_client against a real pi-agent-host-protocol
just test-model          # a real model turn through pi (costs tokens)
just test-desktop linux  # desktop smoke test against pi (see docs/desktop.md)
just codegen             # regenerate the wire types (and freezed code)
just fetch-schema        # re-download the vendored AHP 1.0.0 JSON Schemas
just run                 # flutter run -d chrome
just run macos           # needs a full Xcode install
just run linux           # needs GTK 3, CMake, Ninja, clang, libsecret
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

4. Pick a session, or press **+** to start one: choose the agent, model and
   folder, write a prompt and press Enter. In a session, Enter sends a
   follow-up (or queues it while the agent works), Cmd/Ctrl+Enter steers the
   running turn, Shift+Enter adds a newline, and **Stop** cancels the turn.

`just test-integration` launches pi-agent-host-protocol from
`PI_AHP_HOST_DIR` (default: `../pi-agent-host-protocol`, a sibling of this
repo) in an isolated temp directory, and is skipped when no checkout exists.
`just test-model` does the same but with your `~/.pi/agent` providers, and
sends one tiny real turn; CI does not run it.
