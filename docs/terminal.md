# Terminal panel (AV-016)

A session's pane has a terminal panel at the bottom, like VS Code's. Each
terminal runs the system `ssh` to the session's AHP host and starts in
the session's folder. The app has no SSH client of its own, so the user,
keys, port, jump hosts and host key checks all come from your
`~/.ssh/config`, `~/.ssh/known_hosts` and SSH agent.

## Opening it

- **The terminal button** in the session header (left of the "…" menu)
  opens or closes the panel. Opening it on a host with no terminal
  starts one.
- **Alt+T** (⌥T on macOS) does the same on every platform, also from
  inside the terminal, so the shell never gets Alt+T (readline's
  "transpose words" is Esc then T there). **Ctrl+\`** works too, as in
  VS Code. On macOS Alt+T is in the Session menu, and Ctrl+\` is
  handled by the app's own shortcuts, since a menu item takes one key.
- **New terminal** in the session's "…" menu, or the panel's **+**,
  opens another terminal.

## The panel

- A tab per terminal, named after the folder and the host
  (`app · 10.0.0.5`). The tab's **×** ends that `ssh`.
- When `ssh` exits, the terminal shows `[Process exited with code N]`
  and the tab says "(exited)". **Restart** runs it again.
- **Maximize panel** fills the session pane (the conversation stays
  open underneath), **Restore panel size** gives it its height back, and
  **Hide panel** closes it without ending the terminals.
- Drag the panel's top edge to resize it, or double-click the edge to go
  back to the default height (260 px). The height and whether the panel
  is open are kept on this device (`terminal_panel_height` and
  `terminal_panel_open` in the prefs store).
- Terminals belong to their AHP host. They keep running when you switch
  sessions or hide the panel, and the panel shows the current session's
  host's terminals.
- Copy and paste: Cmd+C and Cmd+V on macOS, Ctrl+Shift+C and Ctrl+V
  elsewhere, or a right-click (copy the selection, or paste when nothing
  is selected). The terminal uses the colour theme's terminal colours
  and keeps 10,000 lines of scrollback.
- Links: Cmd+click (Ctrl+click on Linux and Windows) on an `http` or
  `https` URL opens it in the browser, as in VS Code. While the key is
  held, the link under the pointer is highlighted and the pointer turns
  into a hand. A URL the terminal wrapped onto the next line is one
  link, and trailing punctuation (`.`, `,`, `)` without its `(`) is left
  out. A plain click still goes to the terminal (selection, or the
  program when it reads the mouse).

## The command

The SSH host is the host part of the AHP URL: for
`ws://10.0.0.5:63877?tkn=…` it is `10.0.0.5`. The app passes no user,
key or port. Set those up in `~/.ssh/config`:

```sshconfig
Host 10.0.0.5
  User me
  IdentityFile ~/.ssh/id_ed25519
```

A terminal for a session in `/src/app` runs:

```sh
ssh -t -- 10.0.0.5 'cd '\''/src/app'\'' 2>/dev/null; exec "$SHELL" -l'
```

Without a folder it runs `ssh -- 10.0.0.5`. A host that starts with
`-` or has whitespace or control characters is refused, so it can never
be read as an `ssh` option. The process gets the app's environment
(including `SSH_AUTH_SOCK`) with `TERM=xterm-256color`.

## The file viewer

The file viewer (AV-106) reads files over the same `ssh`, so a file a
reply names opens from a remote host with the terminal's access. It runs

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 -- 10.0.0.5 "cat -- '/src/app/lib/main.dart'"
```

without a pty. Batch mode makes `ssh` fail instead of asking for a
password or to accept a host key, since the viewer cannot answer; use a
key (or the SSH agent) and connect once in the terminal to accept the
host key. Reads stop at 16 MiB. When `ssh` fails, the viewer asks the
AHP host with `resourceRead`, and shows `ssh`'s error if that fails too.
The web and mobile apps always use `resourceRead`.

## Platforms

- **macOS, Linux and Windows:** the panel, with `ssh` in a pseudo-terminal
  (pty). The macOS app is not sandboxed, since a sandboxed `ssh` could
  not read `~/.ssh` or reach the SSH agent (see
  [desktop.md](desktop.md)). Windows uses its OpenSSH client
  (`ssh.exe` on the `PATH`).
- **Web, iOS and Android:** there is no pty and no system `ssh`. The
  button is **Connect with SSH** and opens `ssh://<host>` in an installed
  SSH app; if nothing opens it, a message says so.

## The pty

[`packages/flutter_pty/`](../packages/flutter_pty/) is flutter_pty
0.4.2 (MIT) copied into the repo. Its C code (`forkpty` on macOS and
Linux, ConPTY on Windows) is compiled by a Dart build hook
(`hook/build.dart`, `native_toolchain_c`) on the desktops only, and the
Dart side calls it through `@Native` bindings. That needs a C compiler
(Xcode, clang or gcc, or Visual Studio) but no CocoaPods or Swift
Package Manager. Its README lists the changes.

## Code

`app/lib/src/terminal/`:

- `ssh_command.dart` (pure): `sshHostOf`, `validSshHost`, `shellQuote`,
  `sshArguments`, `sshReadFileArguments` (the file viewer's `cat`),
  `sshEnvironment`, `sshUri` and `terminalLabel`.
- `../files/ssh_file_read.dart`: `fileTextProvider`, the file viewer's
  read over `ssh` with the `resourceRead` fallback.
- `pty_process.dart`: the `PtyProcess` interface, `ptySpawnerProvider`
  and `processEnvironmentProvider` (tests replace them) and
  `ptySupported`. `pty_process_io.dart` starts processes with
  `flutter_pty`; `pty_process_web.dart` is the conditional import for
  the web.
- `terminal_session.dart`: `TerminalSession` (an xterm `Terminal` wired to
  `ssh` in a pty: start, restart, resize, close) and `terminalsProvider`
  (the open terminals and the one shown per host).
- `terminal_links.dart` (pure): `linkAt` (the URL in a string at an
  index) and `terminalLinkAt` (the URL in the xterm buffer at a cell,
  across wrapped lines).
- `terminal_panel.dart`: `toggleTerminalPanel`, `openNewTerminal`, the
  panel's open, height and maximized providers, `TerminalDock` (the
  conversation with the panel under it), `TerminalPanel` and
  `TerminalTabView`.

## Tests

- `app/test/terminal_test.dart`: the pure logic, `TerminalSession` and
  `terminalsProvider` against a fake pty, the app flow on Linux (the
  button, a second terminal from the menu, exit and restart, closing a
  tab, maximize, Alt+T and Ctrl+\` from inside and outside the terminal, hide,
  Ctrl+click on a link) and the `ssh://` link on Android.
- `app/test/terminal_links_test.dart`: finding links in text and in the
  buffer (trailing punctuation, wrapped lines, wide characters).
- `packages/flutter_pty/test/`: the Windows quoting, and a real pty
  (argv, `TERM`, typed input, the size and the environment).
- `app/integration_test/fake_host_flows_test.dart`: the built app runs
  `ssh -V` in a pty (Linux, macOS and Windows in CI).
