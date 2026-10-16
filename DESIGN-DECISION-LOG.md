# Design Decision Log

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
