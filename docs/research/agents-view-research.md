# Agents View Research

Research behind [specs/agents-view.md](../../specs/agents-view.md) and
[specs/agent-host-protocol-client.md](../../specs/agent-host-protocol-client.md).
Gathered 2026-10-15. Items marked _(unverified)_ come from secondary sources.

## Agent Host Protocol (AHP)

- Repo: <https://github.com/microsoft/agent-host-protocol> (MIT). Docs:
  <https://microsoft.github.io/agent-host-protocol/>.
- Built by the VS Code team. VS Code's Agents window and `code agent host`
  are the reference host and client.
  <https://code.visualstudio.com/docs/agents/concepts/agent-host>
- JSON-RPC 2.0 over WebSocket (remote) or a message port (local). Clients
  subscribe to URI channels and get a snapshot followed by ordered actions,
  applied with pure reducers. Writes are optimistic ("write-ahead"), and
  reconnects either replay missed actions or resend a snapshot.
- Complements Zed's Agent Client Protocol (ACP): "AHP is a coordination layer.
  ACP is a communication layer." A host speaks AHP upstream to clients and
  ACP downstream to agents.
  <https://microsoft.github.io/agent-host-protocol/guide/ahp-and-acp>
- Official SDKs: Rust, TypeScript, Kotlin, Go, Swift, .NET. **No official Dart
  SDK.** The community package `ahp_sdk` 0.1.0
  (<https://pub.dev/packages/ahp_sdk>) targets protocol 0.7.0, has no reconnect
  support, and has no stars, so treat it as a reference only.
- [pi-agent-host-protocol](https://github.com/toumorokoshi/pi-agent-host-protocol)
  is an AHP host for the pi coding agent, built on
  `@microsoft/agent-host-protocol` 1.0.0 (supported versions `1.0.0` and
  `0.9.0`; VS Code currently negotiates `0.9.0`). shireitou targets its
  protocol versions.
- **Worktree grouping compared:** Cursor groups worktree and cloud agents
  under their parent "org/repo". GitHub and VS Code keep each workspace
  separate. shireitou follows the GitHub/VS Code approach.
- Key reference pages:
  - [Lifecycle](https://microsoft.github.io/agent-host-protocol/specification/lifecycle.html):
    `initialize` and `reconnect`.
  - [Session](https://microsoft.github.io/agent-host-protocol/reference/session.html):
    `SessionStatus` bitset and `createSession`.
  - [Changeset](https://microsoft.github.io/agent-host-protocol/reference/changeset.html):
    diffs, review state, and operations.
  - [Authentication](https://microsoft.github.io/agent-host-protocol/specification/authentication.html):
    RFC 9728 protected resources and `authenticate`.

## GitHub Agents view (Agent HQ / Mission Control)

Surfaces:

- An agents panel available on every page.
- github.com/copilot/agents.
- A per-repo Agents tab (Jan 2026).
- GitHub Mobile.
- The VS Code Agents window.

Features:

- **Session list:** status at a glance, a link to the PR, archive, and
  paginated history. Sessions are shared with the repo by default. Mobile
  filters by active, status, repo, type, and agent, and sorts by recent,
  oldest, active first, or needs attention first.
  <https://github.blog/changelog/2026-07-08-github-mobile-improved-filters-and-sorting-for-copilot-sessions>
- **Filter qualifiers:** `agent:`, `repository:`, `status:in_progress`,
  `timeframe:7d`, `user:`.
  <https://docs.github.com/en/copilot/reference/agent-session-filters>
- **Composer:** a repo dropdown, image attachments, base branch, an agent
  dropdown (Copilot, custom agents, Claude, Codex), a model picker with
  reasoning level, and Enter to submit.
  <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-on-github>
- **Session log:**
  - Reasoning, plus each tool call with its own icon. Similar calls are
    grouped, outputs get inline previews, and diffs expand with one click.
  - An Overview tab shows tokens and duration, and a Files changed tab shows
    the diffs.
  - <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/manage-agents>
- **Steering:** the agent applies a steering message after its current tool
  call finishes. Steering is not available for third-party agents.
- **Stop and archive:** "Stop session" keeps any commits already pushed;
  archive is a soft delete.
- **States:** in progress, waiting for input, idle, completed, failed,
  cancelled, unread, and failing CI.
- **Notifications:** pushes on completion, iOS Live Activities, Android live
  updates, and VS Code badges counting unread, waiting, and failing sessions.
- **VS Code Agents window:**
  - Groups sessions by time, workspace, or custom group, with pin and
    multi-select.
  - Each row shows +/− stats.
  - Filters: Active, Done, Archived.
  - <https://code.visualstudio.com/docs/agents/run/sessions/manage-sessions>

## Cursor Agents Window

Cursor 2.0 (Oct 2025) introduced the agent layout. Cursor 3 (Apr 2026)
replaced it with the Agents Window.
<https://cursor.com/changelog/2-0>, <https://cursor.com/blog/cursor-3>

- **Layout:** a sidebar of every local and cloud agent, grouped by workspace,
  with a "Home" group for chats with no project. The main pane holds the chat
  timeline, a file viewer, and a review/diff tab. Chats can be pinned.
- **States (API):** CREATING, RUNNING, FINISHED, ERROR, CANCELLED, EXPIRED.
  Agents are ACTIVE or ARCHIVED, and only one run can be active per agent.
  <https://cursor.com/docs/cloud-agent/api/endpoints.md>
- **Create:**
  - Inputs: prompt and images, model, repo and branch, and per-run MCP
    servers.
  - Where it runs: local, worktree, cloud, or remote machine.
  - An option to open a PR automatically.
- **Parallel:**
  - Up to 8 agents run in isolated worktrees.
  - `/best-of-n model1,model2 <task>` runs one task across several models.
  - Multi-Agent Judging recommends a winner with a comment explaining why.
  - <https://cursor.com/docs/configuration/worktrees.md>
- **Streaming events:** `assistant`, `thinking`, `tool_call` (running or
  completed), step and turn events, `result`, `error`, and `heartbeat`.
  Streams resume with `Last-Event-ID`.
- **Follow-ups:** Enter queues a message (queued messages can be reordered by
  drag); Cmd+Enter sends it now. Checkpoints can be restored.
  <https://cursor.com/docs/agent/overview.md>
- **Review:** per-file stage, unstage, and revert; commit and open a PR from
  the window; an optional `/agent-review` pass.
- **Plan mode:** the agent asks clarifying questions, writes an editable
  markdown plan, then builds it. Todo cards appear in the chat.
  <https://cursor.com/docs/agent/plan-mode.md>
- **Notifications:** an iOS push when a turn finishes, Live Activities, and
  Slack.
- **Shortcuts:** Cmd+K searches agent conversations, Shift+Tab changes mode,
  Cmd+F finds in the open conversation.
- **Mobile and web:** cursor.com/agents (installable as a web app) and an iOS
  app with an inbox, live chat, diffs, and PR actions.
  <https://cursor.com/docs/cloud-agent/mobile.md>

## Common feature set (basis for the spec)

1. An inbox of sessions with status, attention state, grouping, filtering, and
   archive.
2. A composer with agent, model, and workspace pickers and attachments.
3. A live timeline: markdown, collapsible reasoning, and tool-call cards with
   inline previews.
4. Steering: queue or send-now follow-ups, stop, approvals, and input
   requests.
5. Review: a files-changed pane, diffs, review state, and commit/PR actions.
6. Notifications and badges for sessions that need attention.
7. Parallel / best-of-N runs and plan mode (more advanced; Cursor-led).
