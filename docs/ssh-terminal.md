# SSH terminal (AV-014)

Agents often run on a remote machine (the AHP host). The app opens an
interactive SSH shell there, so you can look around, run tests or fix
something by hand without leaving the app.

## Opening a terminal

- **From the sidebar:** the "…" menu in the sidebar header has a
  submenu per host with **Open SSH terminal** and **SSH settings…**.
- **From a session:** the session header's menu has **Open SSH
  terminal**. The shell changes to the session's working directory
  (`cd '<folder>' && clear`) once it opens.

The first time, the SSH settings dialog opens. The SSH host defaults to
the host part of the AHP host's URL (for `ws://10.0.0.5:63877?tkn=…`,
`10.0.0.5`) on port 22. Enter the user and choose how to log in:

- **Password.**
- **Private key**, pasted or loaded with **Load from file…** (OpenSSH,
  PKCS#1 RSA or SEC1 EC; Ed25519, ECDSA and RSA), with an optional
  passphrase.
- **SSH agent**: the keys of the agent at `SSH_AUTH_SOCK`. This works on
  Linux. It does not work in the sandboxed macOS app (the sandbox cannot
  reach the agent's socket), on Windows (OpenSSH's agent is a named
  pipe) or on mobile.

The settings, the password, the key and its passphrase are kept per AHP
host in platform secure storage (`ssh:<host key>`), like host tokens.

## Host keys

The app trusts a server's host key on first use: it shows the key's
type and SHA256 fingerprint in the terminal and remembers them
(`ssh_known_hosts` in secure storage, by `host:port`). Later connections
must present the same key. If the key has changed, the connection is
refused with both fingerprints shown. If the change is expected (the
machine was reinstalled), choose **Forget host key** in the SSH settings
and connect again.

## The terminals screen

Each terminal is a tab on the **SSH terminals** screen. Opening another
terminal adds a tab, and the chip's × closes it (and its connection).
Terminals keep running when you go back to the sessions. Opening another
terminal shows them all again.

- The status bar shows connecting, connected or the error, with
  **Reconnect** once disconnected. A reconnect opens a new shell in the
  same folder.
- The pty follows the view's size (SSH window change).
- Copy and paste: the platform's shortcuts (Cmd+C and Cmd+V on macOS,
  Ctrl+Shift+C and Ctrl+Shift+V elsewhere), the Copy and Paste buttons,
  or a right-click (it copies the selection, or pastes when nothing is
  selected).
- Scrollback holds 10,000 lines.
- On phones, the system keyboard types into the terminal. A row of keys
  under it adds Esc, Tab, a sticky Ctrl (the next key is sent with
  Ctrl, for example Ctrl then `c`), arrows and a few symbols.

## Web

Browsers cannot open the TCP connections SSH needs. On the web, **Open
SSH terminal** explains this instead of opening a terminal, and **SSH
settings…** is not shown. `ssh_connect.dart` picks the connector with a
conditional import: `ssh_connect_io.dart` where `dart:io` exists,
`ssh_connect_web.dart` otherwise.

## Code

`app/lib/src/ssh/`:

- `ssh_settings.dart` (pure): `SshSettings` and its JSON,
  `defaultSshSettings`, `sshSettingsProblem`, `decideHostKey` (trust on
  first use), the known-hosts JSON, `shellQuote`,
  `changeDirectoryCommand` and `sessionDirectory`.
- `ssh_agent_codec.dart` (pure): the SSH agent protocol messages that
  list keys and sign.
- `ssh_shell.dart`: the `SshShell` interface, `sshConnectorProvider`
  (tests replace it with a fake) and `describeSshError`.
- `ssh_connect_io.dart`: `connectSsh` on [dartssh2](https://pub.dev/packages/dartssh2)
  (and the agent client over the Unix socket).
- `ssh_store.dart`: settings and known host keys in secure storage.
- `ssh_terminal.dart`: `SshTerminal` (an [xterm](https://pub.dev/packages/xterm)
  `Terminal` wired to a shell: connect, reconnect, host key check,
  sticky Ctrl) and `sshTerminalsProvider` (the open tabs).
- `ssh_terminal_screen.dart` and `ssh_settings_dialog.dart`: the UI,
  `openSshTerminal` and `editSshSettings`.

## Tests

- `app/test/ssh_settings_test.dart`: the pure logic and the agent
  messages.
- `app/test/ssh_terminal_test.dart`: `SshTerminal` against a fake shell
  (trust on first use, a changed key, disconnect and reconnect, `cd`,
  resize, Ctrl), and the app flow from the host menu and the session
  menu.
- `app/test/ssh_sshd_test.dart`: `connectSsh` against a real OpenSSH
  `sshd` started on a free port as the current user with generated keys
  (a pty, a command, resize, a refused host key, a wrong passphrase).
  It runs on Linux (CI installs `openssh-server`) and macOS, and is
  skipped where `/usr/sbin/sshd` is missing.
