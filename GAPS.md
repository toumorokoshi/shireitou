# Gaps

Open issues and features not yet implemented.

## Implementation (nothing built yet)

- Scaffold the Flutter app (`app/`) and a pure-Dart AHP client package
  (`packages/ahp_client/`). Neither exists yet.
- Code generation from the AHP JSON Schemas, pinned to a protocol version.
- Add Flutter/Dart recipes to the `justfile` (`dart format`, `dart analyze`,
  `flutter test`) and a CI workflow. The current `justfile` only runs prettier
  over markdown.
- Record AHP traffic samples in `examples/` for reducer and conformance tests.
- Everything in [specs/agents-view.md](specs/agents-view.md) and
  [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md).

## Open questions

- **Protocol version:** both 0.7.0 and 0.8.0 appear in the wild. Confirm the
  current release and which versions VS Code's host accepts.
- **Agent/model selection:** confirm whether model and mode are set through
  `createSession.config` / `SessionConfigState` or through `AgentInfo`. This
  decides how the composer pickers (AV-041) are populated.
- **Message send/cancel:** confirm the exact chat actions or commands for
  sending a user turn, sending now vs. queuing, and cancelling (AV-080 to
  AV-082).
- **Todos/plans:** check whether AHP response parts carry structured todo or
  plan data (AV-046, AV-070).
- **PR/branch metadata:** check whether hosts expose a PR URL (AV-105). It may
  only be available through `_meta`.
- **Best-of-N (AV-045):** AHP has no notion of linked sessions, so linking and
  judging would be client-side. Decide where that state lives.
- **Mobile push (AV-123):** AHP only delivers events over a live socket, so
  background push needs a relay service. That is out of scope for now.
- **Web transport:** browsers cannot set WebSocket headers, so the token must
  go in the query string. Confirm hosts accept that, and check CORS/TLS for
  hosts on a LAN or tunnel.
- **State management library:** pick one (Riverpod is proposed) once
  scaffolding starts.
- **`ahp_sdk` evaluation:** decide whether to fork, contribute to, or ignore
  the community Dart package.
