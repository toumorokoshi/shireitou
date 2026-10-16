# Agents View

Requirements for the shireitou agents view: a cross-platform Flutter app for
starting, monitoring, steering, and reviewing coding-agent sessions served by
[Agent Host Protocol](agent-host-protocol-client.md) hosts. The UX draws on the
GitHub Agents view and Cursor's Agents Window. Research and sources are in
[docs/research/agents-view-research.md](../docs/research/agents-view-research.md).

Priority: **P0** = MVP, **P1** = next, **P2** = later. Each requirement names
the AHP feature that backs it, where one exists.

## Platforms and layout

| ID     | Pri | Requirement                                                                                                                                                                                                                              |
| ------ | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AV-001 | P0  | Ship from one Flutter codebase to macOS, Windows, Linux, iOS, Android, and web.                                                                                                                                                          |
| AV-002 | P0  | The UI takes the full screen/window (see [design/ui.md](../design/ui.md)).                                                                                                                                                               |
| AV-003 | P0  | Responsive layout: **wide** (≥1200dp) = three panes (session list, session timeline, changes/review); **medium** (≥700dp) = list plus detail, with review as a tab; **compact** = stacked navigation (inbox, then session, then review). |
| AV-004 | P0  | Light and dark themes that follow the system setting.                                                                                                                                                                                    |
| AV-005 | P1  | Resizable and collapsible panes on desktop, with sizes remembered per device.                                                                                                                                                            |
| AV-006 | P2  | Tile several session timelines side by side or in a grid (Cursor agent tabs).                                                                                                                                                            |

## Hosts

| ID     | Pri | Requirement                                                                                                               |
| ------ | --- | ------------------------------------------------------------------------------------------------------------------------- |
| AV-010 | P0  | Add, edit, and remove a host (name, URL, connection token). Persist host config locally; store secrets in secure storage. |
| AV-011 | P0  | Show per-host connection status and errors (version mismatch, auth, unreachable) with a retry action.                     |
| AV-012 | P1  | Connect to several hosts at once and merge their sessions into one inbox, tagged by host.                                 |
| AV-013 | P1  | Show the agents (`AgentInfo`) each host offers, along with any sign-in they require.                                      |

## Session list (inbox)

| ID     | Pri | Requirement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------ | --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AV-020 | P0  | List sessions from the root catalogue, updated live. Each row shows title, agent/provider, project/workspace, status, relative modified time, and change stats (+/−, file count) from `SessionSummary.changes`.                                                                                                                                                                                                                                                                                                       |
| AV-021 | P0  | Status badges derived from the `SessionStatus` bitset: **Working** (InProgress), **Needs input** (InputNeeded), **Idle/Done**, **Error**, and **Unread** (not IsRead).                                                                                                                                                                                                                                                                                                                                                |
| AV-022 | P0  | Filters: Active (default), Done, Archived, and Needs attention (input needed, error, or unread).                                                                                                                                                                                                                                                                                                                                                                                                                      |
| AV-023 | P0  | Mark a session read when it is opened; let the user mark it unread again.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| AV-024 | P0  | Archive and unarchive (soft delete) from the row menu and the session header.                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| AV-025 | P0  | **One folder per working directory (GitHub style).** By default, sessions are grouped into collapsible folders keyed by their exact working directory. Each git worktree is its own folder, labelled with the folder name and its full path (plus repo and branch when known). Worktrees are **never** merged under their parent repository (Cursor's "org/repo" grouping does that, and it is confusing). Sessions with no working directory go in a "No folder" group. See [Worktree grouping](#worktree-grouping). |
| AV-031 | P1  | Alternative groupings: by time (Today, Yesterday, Last 7 days, Older) or by host. The selected grouping is remembered.                                                                                                                                                                                                                                                                                                                                                                                                |
| AV-026 | P1  | Sort by most recent, oldest, or needs attention first; keep the active filter when the sort changes.                                                                                                                                                                                                                                                                                                                                                                                                                  |
| AV-027 | P1  | Free-text search over titles, and filters on agent, status, host, and workspace (GitHub-style qualifiers such as `agent:`, `status:`, `repo:`).                                                                                                                                                                                                                                                                                                                                                                       |
| AV-028 | P1  | Pin sessions to the top (stored locally).                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| AV-029 | P2  | Multi-select for bulk archive and mark-read.                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| AV-030 | P1  | Dispose (permanently delete) a session where the host allows it, with confirmation.                                                                                                                                                                                                                                                                                                                                                                                                                                   |

### Worktree grouping

The folder key is the session's first `workingDirectories` URI, normalized
(trailing slash removed, `file://` decoded). It falls back to
`SessionSummary`/`SessionMetadata.project` when no working directory is set.
Rules:

- Two worktrees of the same repo, such as `~/src/app` and
  `~/src/app-worktrees/fix-login`, appear as **two separate folders**.
- On multi-host setups, the same path on different hosts is two folders
  (the key includes the host).
- A folder header shows the session count and an attention badge. The
  header's "+" button starts a new session in that folder.
- Folders are sorted by their most recently modified session. Empty folders
  are hidden.
- Grouping is a pure function `(List<SessionSummary>) -> List<FolderGroup>`
  with unit tests covering the worktree cases.

## Starting a session (composer)

| ID     | Pri | Requirement                                                                                                                                                                       |
| ------ | --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AV-040 | P0  | "New session" composer: multi-line prompt; host picker; **agent picker** (from root `agents`); working-directory picker; submit with Enter (Shift+Enter for a newline).           |
| AV-041 | P0  | Model picker, plus mode/reasoning options when the agent exposes them through session config.                                                                                     |
| AV-042 | P1  | Attach images (paste, drag-and-drop, pick) and files to the prompt.                                                                                                               |
| AV-043 | P1  | Remote directory browser for the working directory, using host resource commands; remember recent directories per host.                                                           |
| AV-044 | P1  | `@` and `/` completions in the composer via the host `completions` command.                                                                                                       |
| AV-045 | P2  | **Parallel runs (best-of-N):** send one prompt to N agent/model combinations, creating N linked sessions, then compare them side by side and mark a winner (Cursor `/best-of-n`). |
| AV-046 | P2  | Plan mode: ask the agent for a plan first, edit the plan, then build it, where the agent supports it.                                                                             |

## Session detail (timeline)

| ID     | Pri | Requirement                                                                                                                                                                              |
| ------ | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AV-060 | P0  | Header: title, agent, model, working directory, status, current `activity` text, and actions (stop, archive, mark unread).                                                               |
| AV-061 | P0  | Timeline of turns: user messages, and assistant markdown streamed live (code blocks with syntax highlighting, copy button).                                                              |
| AV-062 | P0  | Collapsible reasoning/"thinking" blocks, visually separate from the answer and collapsed by default.                                                                                     |
| AV-063 | P0  | Tool-call cards with an icon per tool kind, a one-line summary, status (streaming, pending confirmation, running, completed, cancelled, auth-required), and expandable input and output. |
| AV-064 | P1  | Group consecutive similar tool calls (for example, "Read 6 files") into one expandable row.                                                                                              |
| AV-065 | P1  | Inline previews: shell commands with live terminal output (terminal channel) and file edits as an inline mini-diff.                                                                      |
| AV-066 | P0  | Auto-scroll while streaming, which stops when the user scrolls up, with a "jump to latest" button.                                                                                       |
| AV-067 | P0  | Turn errors are shown inline with the error message; usage (tokens) is shown per turn and per session.                                                                                   |
| AV-068 | P1  | Load older turns on demand (`fetchTurns` / windowed delivery).                                                                                                                           |
| AV-069 | P1  | Session with several chats (subagents/side chats): show a chat switcher and subagent cards that open the child chat.                                                                     |
| AV-070 | P2  | Todo/plan cards when the agent emits structured response parts for them.                                                                                                                 |
| AV-071 | P2  | Find in conversation (Cmd/Ctrl+F) and copy a turn as markdown.                                                                                                                           |

## Steering and control

| ID     | Pri | Requirement                                                                                                                                                                          |
| ------ | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AV-080 | P0  | Follow-up box under the timeline. When idle, it starts a new turn. While working, Enter **queues** the message and Cmd/Ctrl+Enter **sends now** (steers the agent at its next step). |
| AV-081 | P1  | Show queued messages above the input; edit, remove, and drag to reorder them.                                                                                                        |
| AV-082 | P0  | **Stop**: cancel the active turn; the turn is marked cancelled.                                                                                                                      |
| AV-083 | P0  | **Approvals:** tool calls pending confirmation show Approve / Deny (and any other host-provided options, plus a risk score if present). The session row shows "Needs input".         |
| AV-084 | P0  | **Input requests:** render elicitation forms (text, number, integer, boolean, select) inline and submit the answers.                                                                 |
| AV-085 | P1  | An approvals queue across sessions, so one view clears every pending approval.                                                                                                       |
| AV-086 | P2  | Hide the steering/queue controls for agents that do not support them (GitHub disables steering for third-party agents).                                                              |

## Changes and review

| ID     | Pri | Requirement                                                                                                                                     |
| ------ | --- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| AV-100 | P1  | "Files changed" pane from the session's changesets: file tree/list with created/modified/deleted/renamed markers and +/− counts.                |
| AV-101 | P1  | Diff viewer with unified view (all platforms) and side-by-side view (wide layouts), syntax highlighting, and collapsible unchanged regions.     |
| AV-102 | P1  | Per-file "reviewed" checkbox (`changeset/filesReviewChanged`) when the changeset advertises review, and a "reviewed x of y" progress indicator. |
| AV-103 | P1  | Host-advertised changeset operations (for example commit, create PR, revert, apply) as buttons, with progress and result messages.              |
| AV-104 | P2  | Comment on a diff line to send a follow-up message anchored to that file and line (GitHub "steer from Files changed").                          |
| AV-105 | P2  | Link out to the PR or branch when the host provides one in session or changeset metadata.                                                       |

## Notifications and attention

| ID     | Pri | Requirement                                                                                                                                            |
| ------ | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AV-120 | P0  | In-app attention count (needs input, error, unread) in the navigation and the window title.                                                            |
| AV-121 | P1  | Local OS notifications when a session needs input, finishes a turn, or fails, configurable per event; tapping one opens the session.                   |
| AV-122 | P1  | App-icon badge count on platforms that support it.                                                                                                     |
| AV-123 | P2  | Background or remote push notifications on mobile when the app is not running. This needs a relay, because AHP only delivers over the live connection. |
| AV-124 | P2  | iOS Live Activities and Android live updates for running sessions.                                                                                     |

## Navigation and accessibility

| ID     | Pri | Requirement                                                                                                                                                                     |
| ------ | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AV-140 | P0  | Keyboard shortcuts on desktop and web: new session (Cmd/Ctrl+N), search sessions (Cmd/Ctrl+K), next/previous session (Alt+↑/↓), stop (Cmd/Ctrl+.), focus composer (Cmd/Ctrl+L). |
| AV-141 | P0  | Screen-reader labels on all controls, with live status changes announced; meets WCAG AA contrast.                                                                               |
| AV-142 | P1  | Deep links (`shireitou://host/<host>/session/<id>`) that open a specific session.                                                                                               |
| AV-143 | P2  | Localization-ready strings (send `locale` to the host).                                                                                                                         |

## Out of scope (initially)

- Running agents locally inside the app. shireitou is a client; hosts run the
  agents.
- Managing cloud environments, secrets, network allowlists, or snapshots
  (Cursor and GitHub web-only admin features).
- Direct GitHub/GitLab API integration (PR merge, reviewers, CI status). PR
  actions come through host changeset operations instead.
- Automations/scheduled runs, remote desktop takeover, built-in browser, and
  the TCP and telemetry channels.
