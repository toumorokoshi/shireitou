# Design Decision Log

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
