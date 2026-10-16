# Design Decision Log

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
