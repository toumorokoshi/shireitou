# Open in VS Code (AV-015)

Agents often run on a remote machine (the AHP host). The app opens a
session's folder in a code editor, so you can look around, run tests or
fix something by hand. On a remote host the editor connects over SSH
with its Remote - SSH extension. The app has no SSH client of its own.

## Opening a folder

- **From a session:** the editor button in the session header (left of
  the "…" menu), or **Open in VS Code** in the "…" menu, opens the
  session's working directory.
- **From the sidebar:** hover a folder's header and click the editor
  button, or right-click the header and choose **Open in VS Code**.

The labels name the chosen editor ("Open in Cursor"). Sessions and
folders that have no path (no working directory, or a URI that is not
`file:`) have no button. The host menu has no "open" item, because
there is no folder to open. It has **Editor settings…** instead.

## Editor settings

A host's submenu in the sidebar's "…" menu has **Editor settings…**:

- **Editor:** VS Code, VS Code Insiders or Cursor. This choice applies
  to every host.
- **Folders are on:** **This computer**, or **An SSH host** with the
  host (an address or a `~/.ssh/config` alias), port and an optional
  user. If no user is given, the SSH config's user or the current user
  is used.

The first time a folder is opened on a host with no settings:

- a host on a loopback address (`127.0.0.1`, `localhost`, `::1`) opens
  on this computer without asking;
- for any other host the settings dialog opens, with the SSH host set
  to the host part of the AHP URL on port 22.

A host reached through a forwarded port on `127.0.0.1` (for example
`ssh -L`) is taken to be this computer. Choose **An SSH host** in its
editor settings to change that.

The settings are not secret and live in the prefs store:
`code_editor` for the editor and `editor_target:<host key>` for each host.
Logging in is left to the editor, which uses your SSH config, keys and
agent. The app stores no passwords or keys.

## The URLs

The app hands the editor a URL with `url_launcher`. The system opens it
in the app registered for the scheme (`vscode`, `vscode-insiders` or
`cursor`):

- This computer: `vscode://file/<folder>`.
- SSH: `vscode://vscode-remote/ssh-remote+<authority>/<folder>`. The
  authority is `user@host`, or just `host` when no user is set. The
  editor lowercases URL authorities, so when that would change the
  authority (a capital letter, an IPv6 address or a port other than 22),
  it is hex-encoded JSON `{"hostName", "user", "port"}`. Remote - SSH
  reads that form too.

If nothing opens the URL, a message asks whether the editor (and, for
SSH, Remote - SSH) is installed.

## Platforms

- **Desktop:** works on macOS (including the sandbox), Linux and
  Windows.
- **Web:** the browser hands the URL over, or asks first, without
  leaving the page.
- **iOS and Android:** there is no desktop editor, so the buttons and
  the settings are not shown.

## Moving from the SSH terminal

Before 2026-10-19 the app had its own SSH terminal, with settings in
secure storage (`ssh:<host key>`) that included passwords and keys.
The first time a host's target is loaded, its host, port and user are
copied to the prefs store. The old entry and the known host keys
(`ssh_known_hosts`) are then deleted from secure storage.

## Code

`app/lib/src/editor/`:

- `editor_target.dart` (pure): `CodeEditor`, `EditorTarget` and its
  JSON, `defaultEditorTarget`, `editorTargetProblem`, `isLoopbackHost`,
  `sshRemoteAuthority`, `openInEditorUri`, `editorFolder` and
  `sessionDirectory`.
- `editor_store.dart`: `codeEditorProvider` (the chosen editor),
  `EditorTargetStore` (per-host targets, and the move from secure
  storage), `editorLauncherProvider` (tests replace it) and
  `editorSupported`.
- `open_in_editor.dart`: `openInEditor`, `editEditorSettings` and the
  settings dialog.

## Tests

`app/test/open_in_editor_test.dart` covers:

- the pure logic: defaults, problems, authorities and URLs;
- the store and the move out of secure storage;
- the app flow on Linux: the session button on a loopback host, the
  settings from the host menu, the session menu and the folder menu
  over SSH, and an editor that is not installed;
- no button on Android.
