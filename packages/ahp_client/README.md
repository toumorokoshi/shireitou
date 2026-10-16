# ahp_client

Pure-Dart client for the
[Agent Host Protocol](https://microsoft.github.io/agent-host-protocol/),
targeting protocol **1.0.0** and offering `['1.0.0', '0.9.0']` in
`initialize`. Requirements: [specs/agent-host-protocol-client.md](../../specs/agent-host-protocol-client.md).

## Usage

```dart
import 'package:ahp_client/ahp_client.dart';

final client = AhpClient(
  uri: withConnectionToken(Uri.parse('ws://127.0.0.1:63877'), token),
);
client.states.listen((state) {
  for (final session in state.sessions.values) {
    print('${session.title}: in progress = ${session.status.isInProgress}');
  }
});
await client.connect();
```

## Modules

| File                         | Contents                                                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `src/wire.dart`              | freezed/json_serializable wire types for the root channel and session catalogue                                           |
| `src/session_status.dart`    | `SessionStatus` bitset extension type                                                                                     |
| `src/protocol.dart`          | versions, error codes, `initialize`/`reconnect` params, token URL, backoff                                                |
| `src/protocol_version.dart`  | what 1.0.0 added over 0.9.0, `ProtocolFeature`, `UnsupportedActionError`                                                  |
| `src/channel_mirror.dart`    | write-ahead `ChannelMirror`, pending-action rollback, `ActionFailure`                                                     |
| `src/root_reducer.dart`      | pure `reduceRoot(RootState, RootAction)`                                                                                  |
| `src/session_reducer.dart`   | pure `reduceSession`, a port of the protocol's `sessionReducer` (every 1.0.0 session action)                              |
| `src/chat_reducer.dart`      | pure `reduceChat`, a port of the protocol's `chatReducer` (every 1.0.0 chat action)                                       |
| `src/changeset_reducer.dart` | pure `reduceChangeset` and `reduceCanvasJson` (channels not mirrored yet)                                                 |
| `src/session_catalogue.dart` | pure functions for `listSessions` and `root/session*` notifications                                                       |
| `src/subscriptions.dart`     | pure reference counting for `subscribe` / `unsubscribe`                                                                   |
| `src/host_state.dart`        | `HostState` and pure functions that apply snapshots, envelopes, reconnects (`missing` channels) and pending-action expiry |
| `src/client.dart`            | `AhpClient`: the I/O edge (WebSocket, `json_rpc_2` peer, reconnect, liveness ping and pending-action timers)              |

Everything except `client.dart` is pure and is unit-tested without a socket.
After editing `wire.dart` or `host_state.dart`, run `just codegen`.
