# shireitou

A cross-platform (Flutter/Dart) agents view: start, monitor, steer, and review
coding-agent sessions running on
[Agent Host Protocol](https://microsoft.github.io/agent-host-protocol/) hosts,
with a UX modeled on the GitHub Agents view and Cursor's Agents Window.

> Status: bootstrapping. The app connects to a host and lists its sessions,
> grouped by working directory. Session detail, chat, and steering are not
> built yet; see [GAPS.md](GAPS.md).

## Layout

- [`packages/ahp_client/`](packages/ahp_client/): pure-Dart AHP client (no
  Flutter dependency). Wire types, pure reducers, and the WebSocket JSON-RPC
  connection.
- [`app/`](app/): the Flutter app (macOS, Windows, Linux, iOS, Android, web).
- [`examples/`](examples/): recorded AHP traffic used by tests.

The root `pubspec.yaml` is a [pub workspace](https://dart.dev/tools/pub/workspaces),
so one `flutter pub get` at the root resolves both packages.

## Documentation

- [docs/architecture.md](docs/architecture.md): how the code is organized.
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
just test                # ahp_client unit tests and app widget tests
just test-integration    # ahp_client against a real pi-agent-host-protocol
just codegen             # regenerate freezed/json_serializable code
just run                 # flutter run -d chrome
just run macos           # needs a full Xcode install
just run chrome 'ws://127.0.0.1:63877?tkn=...'   # prefill the host URL
```

To try it against a real host, start
[pi-agent-host-protocol](https://github.com/toumorokoshi/pi-agent-host-protocol)
(`npm start` in its checkout), then paste the `ws://…?tkn=…` URL it prints
into the connect screen.

`just test-integration` launches pi-agent-host-protocol from
`PI_AHP_HOST_DIR` (default: `../pi-agent-host-protocol`, a sibling of this
repo) in an isolated temp directory, and is skipped when no checkout exists.
