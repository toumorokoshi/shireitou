# Design Decision Log

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
