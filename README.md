# shireitou

A cross-platform (Flutter/Dart) agents view: start, monitor, steer, and review
coding-agent sessions running on
[Agent Host Protocol](https://microsoft.github.io/agent-host-protocol/) hosts,
with a UX modeled on the GitHub Agents view and Cursor's Agents Window.

> Status: requirements phase. No application code yet.

## Documentation

- [specs/agents-view.md](specs/agents-view.md): UI and feature requirements.
- [specs/agent-host-protocol-client.md](specs/agent-host-protocol-client.md):
  requirements for the Dart AHP client.
- [docs/research/agents-view-research.md](docs/research/agents-view-research.md):
  research and sources.
- [GAPS.md](GAPS.md): open questions and work not yet done.
- [DESIGN-DECISION-LOG.md](DESIGN-DECISION-LOG.md): design decisions, by date.

## Development

- `just lint`: check linting and formatting.
- `just fix`: apply formatting and lint fixes.
