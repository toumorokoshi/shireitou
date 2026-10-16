# Agent Host Protocol Client

Requirements for the Dart client that connects shireitou to one or more
[Agent Host Protocol (AHP)](https://microsoft.github.io/agent-host-protocol/)
hosts. See [docs/research/agents-view-research.md](../docs/research/agents-view-research.md)
for background.

## Background

AHP is a host-authoritative, multi-client state synchronization protocol for
agent sessions, authored by Microsoft (VS Code team, MIT licensed). Key traits:

- JSON-RPC 2.0 over any reliable, ordered, bidirectional stream. WebSocket is
  the primary remote transport (one JSON-RPC message per text frame).
- State lives in URI-addressed **channels** (`ahp-root://`,
  `ahp-session:/<uuid>`, `ahp-chat:/<id>`, terminal, changeset, ...).
  Subscribing returns a snapshot (`resource`, `state`, `fromSeq`), followed by
  ordered `action` notifications.
- State is immutable and advanced by **pure reducers**. Clients may dispatch
  actions optimistically ("write-ahead") and reconcile against the host's
  ordered echo.
- Hosts translate concrete agents (Copilot, Claude, Codex, ...) into an
  agent-agnostic presentation model, so the UI does not need per-agent code.
- The spec is a working draft; breaking changes are expected. The protocol
  version is negotiated in `initialize`.

## Target protocol version

shireitou supports the same protocol versions as the reference host it is
developed against, [pi-agent-host-protocol](https://github.com/toumorokoshi/pi-agent-host-protocol).
That host negotiates with `@microsoft/agent-host-protocol` **1.0.0**, whose
`SUPPORTED_PROTOCOL_VERSIONS` is `['1.0.0', '0.9.0']`.

- Wire types are generated from the **1.0.0** schemas, the same release as
  the npm package `@microsoft/agent-host-protocol@1.0.0`.
- `initialize` offers `protocolVersions: ['1.0.0', '0.9.0']`.
- When `0.9.0` is negotiated (the version VS Code currently resolves to on
  that host), the client ignores actions and fields that 1.0.0 added and
  degrades features that depend on them. See
  [0.9.0 compatibility](#090-compatibility).
- Upgrading the target version is a deliberate change: bump it here,
  regenerate the types, and re-test against pi-agent-host-protocol.

### 0.9.0 compatibility

Found by diffing the TypeScript sources (`src/types`) of
`@microsoft/agent-host-protocol@0.9.0` and `@1.0.0` from npm, and checked
against the 1.0.0 entry of the protocol's `CHANGELOG.md`. The `StateAction`
unions of the v0.9.0 and v1.0.0 JSON Schemas differ by exactly the ten
actions below, and `protocol_version_test.dart` checks that each of them is
a member of the generated `StateAction`. The protocol's
`ACTION_INTRODUCED_IN` registry dates some of these actions `0.9.0` or
`0.10.0` (an unreleased version), but none of them is in the 0.9.0
release. Notifications (`root/*`, `auth/required`, `otlp/*`) are the same
in both.

Actions in 1.0.0 that 0.9.0 does not have:

| Action                                 | Dispatched by | What it does                                      |
| -------------------------------------- | ------------- | ------------------------------------------------- |
| `chat/isReadChanged`                   | client        | Read state of one chat.                           |
| `chat/isArchivedChanged`               | client        | Archives one chat without its session.            |
| `chat/backgroundWorkSet`               | host          | Adds or updates a background shell or subagent.   |
| `chat/backgroundWorkRemoved`           | host          | Removes background work.                          |
| `chat/changesetsChanged`               | host          | Replaces the chat's changeset catalogue.          |
| `chat/movableChanged`                  | host          | Whether `moveChat` may move the chat.             |
| `chat/canvasesChanged`                 | host          | Replaces the chat's canvas references.            |
| `canvas/stateChanged`                  | host          | Canvas channel state (experimental channel).      |
| `session/chatsReordered`               | client        | Reorders the session's chats.                     |
| `session/mcpServerBackgroundRequested` | client        | Asks the host to background a blocking MCP start. |

Commands in 1.0.0 that 0.9.0 does not have: `moveChat` (`MoveChatParams`,
`MoveChatResult`, `ChatMoveDestination`).

Fields and enum values in 1.0.0 that 0.9.0 does not have (all optional):

| Type                          | Added                                                               |
| ----------------------------- | ------------------------------------------------------------------- |
| `SessionSummary`              | `chats` (`SessionChatSummary[]`), `defaultChat`                     |
| `SessionChatSummary` (new)    | `resource`, `title`, `origin`, `interactivity`, `status`, `changes` |
| `ChatState`                   | `changes`, `movable`, `changesets`, `backgroundWork`, `canvases`    |
| `ChatSummary`                 | `changes`, `movable`                                                |
| `AuthenticateParams`          | `expiresIn`                                                         |
| `ConfigPropertySchema`        | `minItems`, `maxItems`                                              |
| `McpServerStartingState`      | `blocking`                                                          |
| `AutomationDefinition`, patch | `disableConditions`                                                 |
| `AutomationEntry`             | `runCount`, `customizations`                                        |
| `AutomationSessionTemplate`   | `customizations`                                                    |
| `AutomationCapabilities`      | `customizations`                                                    |
| `ChangesetStatus`             | `recomputing`                                                       |
| `Snapshot.state`              | `CanvasState` (canvas channel)                                      |

`FileEdit.before`/`after`/`diff` and the tool-call `edits` became named
types (`FileEditSide`, `FileEditDiffStats`, `FileEditCollection`) with the
same JSON shape, so they need no handling.

How the client degrades (`protocol_version.dart`):

- `applyEnvelope` ignores (only advances `serverSeq` for) the ten actions
  above when `0.9.0` is negotiated, as a safety net: the versioning spec
  says the host only sends actions known to the negotiated version.
- `AhpClient.dispatch` throws `UnsupportedActionError` for them instead of
  sending an action the host would reject.
- Every added field is optional in the wire types, and the client treats
  its absence as "unknown". Nothing the client or app does today depends
  on one: the app reads `SessionSummary.changes` (present in 0.9.0), and
  `openSession` takes the default chat from the session channel's
  `SessionState.defaultChat` (0.4.0), not from `SessionSummary`.
- `ProtocolFeature` names each 1.0.0 feature, and `supportsFeature` /
  `unavailableFeatures` answer which ones the negotiated version lacks.
  UI for those features (per-chat read/archive, background work, per-chat
  changes, moving or reordering chats, canvases, MCP backgrounding, token
  expiry, config array bounds) must check `supportsFeature` before it is
  shown. None of it is built yet.
- The app shows an "AHP 0.9.0" chip in the session list's app bar whose
  tooltip lists the unavailable features (`compatibilityNotice`).

## Requirements

Priority: **P0** = MVP, **P1** = next, **P2** = later.

### Connection and lifecycle

| ID      | Pri | Requirement                                                                                                                                                                                                                                                       |
| ------- | --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AHP-001 | P0  | Connect to a host over WebSocket (`ws://` / `wss://`) with a JSON-RPC 2.0 peer supporting requests, responses, and notifications in both directions.                                                                                                              |
| AHP-002 | P0  | Support connection gating with a connection token, passed as a query parameter (required on web, where browsers cannot set upgrade headers) or as a header on native platforms.                                                                                   |
| AHP-003 | P0  | Send `initialize` with `protocolVersions` (most preferred first), a stable `clientId`, `clientInfo`, `locale`, and `initialSubscriptions` (`ahp-root://` plus open sessions). Handle `-32005 UnsupportedProtocolVersion` and show the host's `supportedVersions`. |
| AHP-004 | P0  | Track `serverSeq`. On disconnect, reconnect with backoff using `reconnect` (`clientId`, `lastSeenServerSeq`, `subscriptions`), and handle both `replay` (apply `actions`, drop `missing`) and `snapshot` results.                                                 |
| AHP-005 | P0  | Respond to `ping` and surface connection state (connecting, connected, reconnecting, failed) to the UI.                                                                                                                                                           |
| AHP-006 | P1  | Support multiple concurrent host connections (a multi-host client, similar to the official Rust/Swift/Go/.NET `MultiHostClient`), with sessions namespaced by host.                                                                                               |
| AHP-007 | P1  | Reassemble large payloads split into `channel/frame` notifications.                                                                                                                                                                                               |
| AHP-008 | P2  | Pluggable transport abstraction, so a local IPC or stdio stream can be added later without changing higher layers.                                                                                                                                                |

### Channels and state

| ID      | Pri | Requirement                                                                                                                                                                                                       |
| ------- | --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AHP-020 | P0  | Reference-counted `subscribe` / `unsubscribe` per channel URI, so several widgets can observe one channel.                                                                                                        |
| AHP-021 | P0  | Pure reducers for the root, session, and chat channels: `(State, Action) -> State`, with no I/O. Reducers must be unit-tested against the protocol's example data.                                                |
| AHP-022 | P0  | Write-ahead dispatch: apply client actions (`dispatchAction`) optimistically, then rebase on the host's ordered echo; roll back on rejection.                                                                     |
| AHP-023 | P0  | Root channel: expose `agents` (`AgentInfo[]`), `activeSessions`, and `config`. Keep the session catalogue from `listSessions` plus `root/sessionAdded`, `root/sessionRemoved`, `root/sessionSummaryChanged`.      |
| AHP-024 | P0  | Session channel: expose `SessionState` (`lifecycle`, `title`, `status`, `activity`, `provider`, `project`, `workingDirectories`, `chats`, `defaultChat`, `changesets`, `inputNeeded`, `config`, `activeClients`). |
| AHP-025 | P0  | Chat channel: turns, streaming markdown (`chat/delta`), reasoning, response parts, tool calls, usage, pending/queued messages, input requests, and errors. Use `fetchTurns` to page older turns.                  |
| AHP-026 | P0  | Decode `SessionStatus` as a **bitset** (`Idle=1`, `Error=2`, `InProgress=8`, `InputNeeded=24`, `IsRead=32`, `IsArchived=64`) using bitwise checks, never equality.                                                |
| AHP-027 | P1  | Changeset channel: `ChangesetState` (`status`, `files[]` with `FileEdit` and `reviewed`, `operations[]`); dispatch `changeset/filesReviewChanged`; call `invokeChangesetOperation`.                               |
| AHP-028 | P1  | Terminal channel: stream terminal output for tool calls and session terminals.                                                                                                                                    |
| AHP-029 | P1  | Windowed delivery for long chats, so mobile clients do not hold the entire history in memory.                                                                                                                     |
| AHP-030 | P2  | Resource commands (`resourceList`, `resourceRead`, ...) for remote working-directory browsing, starting from `InitializeResult.defaultDirectory`.                                                                 |
| AHP-031 | P2  | Annotations, canvases, automation catalogue/run, and MCP channels.                                                                                                                                                |

### Commands

| ID      | Pri | Requirement                                                                                                                                                                        |
| ------- | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AHP-040 | P0  | `createSession` with a client-chosen `ahp-session:/<uuid>` URI, `provider`, `workingDirectories`, and `config`; handle `-32003 SessionAlreadyExists` and `session/creationFailed`. |
| AHP-041 | P0  | Send user messages, cancel the active turn, and approve or deny tool calls (`pending-confirmation` and `pending-result-confirmation`) via the chat actions.                        |
| AHP-042 | P0  | Answer input requests (elicitations: text, number, integer, boolean, select).                                                                                                      |
| AHP-043 | P0  | Dispatch `session/isReadChanged` and `session/isArchivedChanged`.                                                                                                                  |
| AHP-044 | P1  | `disposeSession`, `completions` (for `@`/`/` completions in the composer), and queued-message reordering.                                                                          |

### Authentication

| ID      | Pri | Requirement                                                                                                                                                              |
| ------- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AHP-060 | P1  | Read `AgentInfo.protectedResources` (RFC 9728), get tokens via OAuth (system browser, PKCE), and push them with `authenticate { resource, token, expiresIn?, scopes? }`. |
| AHP-061 | P1  | Handle `auth/required` (`required` / `expired`) and `-32007 AuthRequired` by prompting re-auth, then retrying.                                                           |
| AHP-062 | P1  | Surface tool calls in the `auth-required` state (MCP auth challenges) with a call to action.                                                                             |
| AHP-063 | P0  | Store host tokens in platform secure storage (Keychain, Keystore, DPAPI, libsecret); never log them.                                                                     |

### Implementation constraints

- Wire types are **generated** from the JSON Schemas in the protocol
  repo's `schema/` directory, pinned to protocol 1.0.0 (see
  [Target protocol version](#target-protocol-version)). The schemas are
  vendored in `packages/ahp_wire_gen/schema/1.0.0/`; `just codegen` writes
  the whole schema (every `$def`, including canvases, changesets,
  terminals, customizations, MCP servers, automations and background work)
  into `packages/ahp_client/lib/src/generated/`, and CI fails when the
  vendored schemas or the committed output are stale. Departures from the
  schemas (fields kept as JSON, schema fixes, renames) are listed in
  [docs/wire-types.md](../docs/wire-types.md).
- Unknown values must not break decoding: a union member whose
  discriminator this version does not know decodes to `<Union>Unknown`
  (keeping its JSON), and an unknown enum value to `$unknown`. Reducers
  treat both as no-ops.
- pi-agent-host-protocol 0.3.0 sends a `modifiedAt` in `SessionSummary.chats`
  entries (`SessionChatSummary`), which the 1.0.0 schema does not have; the
  generated types drop it.
- pi-agent-host-protocol is the integration-test host. It prints a
  `ws://127.0.0.1:<port>?tkn=…` URL and reads only the `tkn` query
  parameter, so native clients send the token both as `tkn` and as an
  `Authorization: Bearer` header (AHP-002).
- The client is a pure-Dart package (no Flutter dependency) so it can be
  tested headlessly and reused by a CLI.
- I/O (sockets, timers) is kept at the edges; protocol logic is pure functions
  over immutable data, per the project's code design tenets.
- Conformance tests replay recorded host traffic (snapshots plus action
  streams) from `examples/`.
- Session URIs are opaque. pi publishes a session created as
  `ahp-session:/<id>` under `pi:/<id>` in the catalogue, so the client keys
  sessions by the host's `resource` and must not assume it equals the URI it
  sent to `createSession`.
- `unsubscribe` is sent as a JSON-RPC notification (pi handles it as one).

## Implementation status

As of 2026-10-16, iteration 5 (`packages/ahp_client`). Iteration 5
replaced the hand-written wire types with ones generated from the 1.0.0
JSON Schemas; no requirement changed status.

| ID      | Status  | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AHP-001 | Done    | `web_socket_channel` + `json_rpc_2` `Peer`.                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| AHP-002 | Done    | Token in the `tkn` query parameter on web; on native platforms also as `Authorization: Bearer <token>` (the spec names no header; this matches the protocol repo's Swift client). `webSocketConnector` selects query, header or both.                                                                                                                                                                                                                                         |
| AHP-003 | Done    | Offers `['1.0.0', '0.9.0']` (overridable with `protocolVersions`); `-32005` shows the host's `supportedVersions`. 0.9.0 degrades as in [0.9.0 compatibility](#090-compatibility); tested against pi offering only `0.9.0`.                                                                                                                                                                                                                                                    |
| AHP-004 | Done    | Tracks `serverSeq`, reconnects with backoff, handles `replay`/`snapshot`, falls back to `initialize` on `-32008`. `missing` channels (and, for a `snapshot` result or the `initialize` fallback, which have no `missing` list, mirrored session and chat channels left without a snapshot) are unsubscribed, unmirrored and listed in `HostState.missingChannels`; the session view says the session is gone. A liveness ping that times out drops the socket and reconnects. |
| AHP-005 | Done    | Answers `ping`; exposes `ConnectionStatus`. Sends a liveness `ping` every 15 s while connected; no answer within 10 s means the socket is dead. Any JSON-RPC answer, even an error, counts as alive.                                                                                                                                                                                                                                                                          |
| AHP-020 | Done    | Pure reference counting in `subscriptions.dart`.                                                                                                                                                                                                                                                                                                                                                                                                                              |
| AHP-021 | Done    | Root, session and chat reducers; chat and session are tested against recorded pi traffic (`examples/ahp/pi-host-chat-turns.json`). Actions not modeled are no-ops.                                                                                                                                                                                                                                                                                                            |
| AHP-022 | Done    | `ChannelMirror`: optimistic apply, rebase on the host's echo, rollback on `rejectionReason`. An action not echoed within 30 s is rolled back. After a reconnect every action still pending is rolled back (a replay already echoed the accepted ones). Each rollback is reported on `AhpClient.failures`. Dispatch is refused while reconnecting.                                                                                                                             |
| AHP-023 | Done    | Root state plus session catalogue (`listSessions` paging and `root/session*` notifications).                                                                                                                                                                                                                                                                                                                                                                                  |
| AHP-024 | Done    | `SessionState` mirror; customizations, MCP, changesets, server tools and working-directory actions are not reduced.                                                                                                                                                                                                                                                                                                                                                           |
| AHP-025 | Partial | Turns, deltas, reasoning, tool calls, usage, errors, pending messages and input requests. `fetchTurns` is sent; turns arrive as `chat/turnsLoaded` (pi always sends full history). Background work, canvases, changesets and MCP auth actions are not reduced.                                                                                                                                                                                                                |
| AHP-026 | Done    | `SessionStatus` extension type with bitwise checks.                                                                                                                                                                                                                                                                                                                                                                                                                           |
| AHP-040 | Partial | Client-chosen URI, `-32003` retry, and returns the URI the host lists. A `session/creationFailed` session never reaches pi's catalogue, so the call times out.                                                                                                                                                                                                                                                                                                                |
| AHP-041 | Done    | `chat/turnStarted`, `chat/pendingMessageSet` (queued/steering), `chat/turnCancelled`, `chat/toolCallConfirmed`, `chat/toolCallResultConfirmed`. pi rejects confirmations (it never asks).                                                                                                                                                                                                                                                                                     |
| AHP-042 | Done    | `chat/inputCompleted` with typed answers. Not verified against a host; pi sends no input requests.                                                                                                                                                                                                                                                                                                                                                                            |
| AHP-043 | Done    | `session/isReadChanged`, `session/isArchivedChanged`.                                                                                                                                                                                                                                                                                                                                                                                                                         |
| AHP-063 | Done    | Saved hosts (URLs and tokens) in `flutter_secure_storage`: verified on web (encrypted local storage) and Linux (libsecret, desktop smoke test). macOS uses the login keychain; covered by the CI smoke test. shireitou never logs tokens or shows them in host labels.                                                                                                                                                                                                        |
