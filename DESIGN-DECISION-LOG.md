# Design Decision Log

## 2026-10-16: Full reducers, session-level input and a scripted fake host

- **Reducers mirror the protocol for every action:** `reduceSession` and
  `reduceChat` now port all of `sessionReducer` and `chatReducer` from
  `@microsoft/agent-host-protocol@1.0.0`, including the edge cases
  (`session/chatsReordered` only applies a permutation, a replaced working
  directory that already exists earlier is dropped, `inputNeeded` drives
  the `InputNeeded` bit except for client tool execution, toggling a
  plugin or MCP server sets `enablement` while other customizations keep
  the legacy `enabled`, `chat/toolCallAuthRequired` only applies to
  running MCP calls, an `auth-required` call only completes with a
  failure). The switch is exhaustive over the generated unions, so a new
  protocol action is a compile error rather than a silent no-op; only the
  `…Unknown` member (a newer host) is ignored. Customization edits go
  through JSON (`toJson` + `fromJson`) where the TypeScript reducer
  spreads objects, so unknown kinds are handled the same way.
- **Changeset and canvas reducers without subscriptions:** ported now
  (`changeset_reducer.dart`) because they are small and the review pane
  (AV-100 to AV-103) needs them, but the client does not subscribe to
  those channels yet; change counts in the UI come from the catalogue's
  `SessionSummary.changes` (present in 0.9.0 too). The terminal, resource
  watch, annotations and automation reducers are not ported (no UI).
- **1.0.0 gating:** the client already ignores 1.0.0-only actions under
  0.9.0, so the reducers need no version checks. UI built on 1.0.0-only
  state checks `supportsFeature` (the background work chip);
  `authenticate` drops `expiresIn` without `tokenExpiry`.
- **Session-level input requests:** a "Waiting for you" panel above the
  timeline shows `SessionState.inputNeeded` entries the open chat does not
  already show. An entry is hidden when its tool call or input request is
  anywhere in the open chat, so a request answered inline (write-ahead
  makes the call `running` at once) does not reappear before the host
  removes the entry. Answers are dispatched to the entry's own chat even
  when the client is not subscribed to it; there is no mirror to update,
  so nothing is pending and the host's `session/inputNeededRemoved` is the
  confirmation. Client tool execution entries are not shown (this client
  provides no tools).
- **MCP sign-in without OAuth:** `auth-required` tool calls (and MCP
  servers in `authRequired` state, as header chips) offer "Sign in", which
  asks the user to paste a token and calls the new
  `AhpClient.authenticate`, and "Cancel tool call", a failed
  `chat/toolCallComplete` (the only completion the protocol allows from
  `auth-required`). A real OAuth/PKCE flow (AHP-060) needs a redirect
  handler per platform and is left for later.
- **Minimal UI for the rest:** background work is a header chip with a
  menu of labels, change counts are added to the header details. Drafts,
  canvases, working directory changes, server tools, active clients,
  customizations other than MCP alerts, chat order and `movable` are
  mirrored but have no UI yet (see GAPS.md).
- **A fake host in Dart, in the workspace:** `packages/ahp_fake_host`
  reuses `ahp_client`'s generated types and reducers to keep real state,
  so it costs little code and cannot drift from the client's model of the
  protocol. It is driven by keywords in the user's message (`tool`, `ask`,
  `side`, `auth`, `background`, `edit`) rather than a config file, so the
  same host serves automated tests and manual runs (`just fake-host`).
  Reconnect always answers `-32008`, so clients re-initialize. The risk of
  sharing reducers (a reducer bug the host and client agree on) is
  covered by the reducer unit tests against the TypeScript semantics and
  by the recorded pi traffic.
- **Where its tests run:** client-level flows run over a real loopback
  WebSocket with a token in `just test` (fast, no display). The app-level
  integration test starts the host in the app's own process (no extra
  process to manage) and drives the UI through the connect screen; it is a
  separate `just test-fake-host-app` recipe and CI step on Linux (Xvfb,
  fresh keyring) and macOS, so a failure is attributed to it rather than to
  the desktop smoke test, which `scripts/test-desktop` now runs alone.

## 2026-10-16: Wire type generation

- **Generated from the JSON Schemas, output committed:** a new pure-Dart
  workspace package, `packages/ahp_wire_gen`, reads the AHP 1.0.0 schemas
  (`actions`, `commands`, `errors`, `notifications`, `state`) and writes
  `packages/ahp_client/lib/src/generated/` (one library, one part per
  schema file). The output is committed rather than built on the fly, so
  the package stays a plain Dart dependency, reviews show type changes, and
  IDEs need no build step. `just codegen` regenerates it (then
  `dart format` and freezed for `host_state.dart`); CI runs
  `just fetch-schema` and `just codegen` and fails on any working-tree
  change, which also catches hand edits and stale vendored schemas.
- **Vendored schemas:** the five files from tag `v1.0.0` of
  `microsoft/agent-host-protocol` live in
  `packages/ahp_wire_gen/schema/1.0.0/` (about 2 MB; each file repeats the
  shared defs). Generation needs no network; `just fetch-schema` re-downloads
  them. A def found in several files is generated once, into the part of
  the first file (state, actions, commands, notifications, errors).
- **Own emitter, not freezed:** the generator emits plain Dart (immutable
  `final class`es with `fromJson`/`toJson`/typed `copyWith`/deep equality,
  `sealed class` unions, enums) instead of freezed sources. The schemas
  need things freezed unions cannot express: a member in two unions
  (`ChatTurnStartedAction` is a `ChatAction` and a `StateAction`;
  `ToolCallPendingConfirmationState` is a `ToolCallState` and a
  `ToolCallConfirmationState`), nested unions (`chat/toolCallConfirmed` is
  itself a union on `approved`), discriminators with several values
  (`number`/`integer` questions), and untagged string-or-object unions.
  Sealed classes that members `implement` handle all of them, and the
  build goes from ~17 k lines of freezed output for a subset of the
  protocol to ~37 k lines for all of it, generated in under a second.
  freezed stays for `host_state.dart`; `json_serializable` and
  `json_annotation` are gone.
- **Whole schema, faithful shapes:** every `$def` is generated (canvases,
  changesets, terminals, customizations, MCP servers, automations,
  background work), so extending the reducers needs no new types. The
  flattened hand-written `ToolCall`, `ChatInputQuestion` and raw-JSON
  fields are replaced by the protocol's unions (`ToolCallState`,
  `ChatInputQuestion`, `ToolResultContent`, `ChatInputAnswer`, ...), and
  the chat reducer now builds the next tool call state per status, like
  the TypeScript reducer.
- **Forward compatibility:** each tagged union decodes unknown
  discriminators to `<Union>Unknown` (keeping the JSON and decoding the
  fields all members share), each enum has `$unknown`, and missing required
  lists/maps decode as empty. Unknown action types stay no-ops, as before.
  An unknown `reconnect` result kind makes the client run `initialize`
  again.
- **Shared fields on unions:** fields every member has (same type, or
  member types of one union) are abstract getters on the sealed class
  (`ToolCallState.toolCallId`, `.contributor`, `.invocationMessage`), and
  `ToolCallStateFields` in `wire.dart` adds the few that only some states
  have (`toolInput`, `content`, `confirmed`, `selectedOption`).
- **Explicit departures, all in `config.dart`:** `Snapshot.state` and
  `ActionEnvelope.action` stay JSON (no discriminator for the former;
  write-ahead and the reducers already work on JSON); the partial
  `changes` of `session/chatUpdated` and `root/sessionSummaryChanged` stay
  JSON because pi clears fields with an explicit `null`; `RootAction`,
  `SessionAction` and the other per-channel action unions are synthesized
  from `StateAction` by type prefix (the schemas only export `ChatAction`);
  `Icon`/`TextPosition`/`TextRange`/`TextSelection` get an `Ahp` prefix to
  avoid clashing with Flutter and `dart:ui`; `number` is `int` except for a
  short list of fractional fields; `SessionStatus` maps to the existing
  bitset extension type. Two upstream schema defects (an empty `$ref` in
  `StateAction`, and `approved` without its `true`/`false` literal types)
  are patched, and each patch throws once upstream fixes it.
- **0.9.0:** the v0.9.0 schemas were fetched once to confirm that their
  `StateAction` differs from 1.0.0 by exactly the ten actions in
  `protocol_version.dart`. They are not vendored: the client only offers
  0.9.0 as a fallback and generates 1.0.0 types, so a test checks the list
  against the generated `StateAction.discriminatorValues` instead.

## 2026-10-16: Reconnect details, write-ahead rollback, and 0.9.0 degradation

- **0.9.0 vs 1.0.0, from the releases:** the list of 1.0.0 additions comes
  from diffing the `src/types` TypeScript of
  `@microsoft/agent-host-protocol@0.9.0` and `@1.0.0` (interfaces, enums
  and action types, with the TypeScript compiler API), not from the
  protocol's `ACTION_INTRODUCED_IN` registry. The registry dates
  `chat/isReadChanged`, `chat/backgroundWork*`, `session/chatsReordered`
  and others `0.9.0`, and the canvas actions `0.10.0` (never released),
  but none of them is in the 0.9.0 package; the 1.0.0 changelog agrees
  with the diff. The result is ten actions, one command (`moveChat`) and a
  set of optional fields, listed in the spec.
- **Degradation is a version check, not per-feature capability probing:**
  0.9.0 and 1.0.0 are the only versions offered, so one pure module
  (`protocol_version.dart`) holds the added actions and a
  `ProtocolFeature` enum; `isActionKnownToVersion` and `supportsFeature`
  compare versions. Under 0.9.0, incoming 1.0.0-only actions are ignored
  (a safety net; hosts should not send them) and dispatching one throws
  `UnsupportedActionError` (a `StateError`, which the UI already catches)
  rather than sending something the host would reject. Fields need no
  handling, since all of them are optional and nothing reads them yet. The
  app shows an "AHP 0.9.0" chip whose tooltip lists the missing features,
  instead of a dismissable banner, because nothing the user can do today
  is affected.
- **`AhpClient.protocolVersions`:** the offered list is a constructor
  option (default `['1.0.0', '0.9.0']`) so the integration test can make
  pi negotiate 0.9.0.
- **Pending actions are rolled back, and the user is told:** the
  write-ahead guide says a client clears `pendingActions` after a
  reconnect. The client does that after applying a replay (which echoes
  whatever the host accepted) and before applying snapshots (which carry
  no echoes). It also rolls back an action not echoed within 30 s (the
  TypeScript client's default request timeout), with a one-shot timer per
  action calling a pure function. Each rollback, and each host rejection,
  is an `ActionFailure` on `AhpClient.failures`; the app shows a snackbar
  per failure. After a snapshot the action may in fact have been applied,
  so that message says it "may not have gone through" instead of claiming
  it was lost. A late echo is still applied (the host's state wins).
  `dispatch` is refused while reconnecting, so an action cannot be sent on
  the new socket and then cleared by the reconnect.
- **Missing channels:** the replay's `missing` channels are released
  (subscription counts dropped, so later `unsubscribe` calls are no-ops),
  unmirrored, and listed in `HostState.missingChannels` instead of a
  separate event stream, so widgets observe them like any other state.
  Subscribing again clears the entry. A snapshot result or the
  `initialize` fallback has no `missing` list; since a host may only omit
  snapshots of field-less channels, a session or chat mirror without a
  snapshot is treated as missing too.
- **Liveness pings:** `ping` every 15 s with a 10 s timeout, so a dead
  socket is found within about 25 s. Only a timeout or a closed peer
  counts as dead; any JSON-RPC answer, including `MethodNotFound` from a
  host without `ping`, counts as alive. A failed ping starts the normal
  reconnect loop. Protocol-level pings were chosen over WebSocket ping
  frames because browsers cannot send those.

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
