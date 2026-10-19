# Open in VS Code (AV-015)

A session's header has an **Open in VS Code** button (the VS Code icon,
beside the "…" menu), and the "…" menu has the same item. They open the
session's folder (its working directory) in VS Code. They show for
sessions with a folder, on the desktop apps and the web; not on iOS or
Android, where there is no VS Code.

## The link

The app opens a `vscode://` link with `url_launcher`, so the operating
system (or the browser) hands it to VS Code:

- **The host runs on this machine** (its AHP URL's host is `localhost`,
  `127.0.0.1` or `::1`): `vscode://file/<folder>` opens the folder.
- **Another machine:** `vscode://vscode-remote/ssh-remote+<authority>/<folder>`
  opens it over VS Code's
  [Remote - SSH](https://code.visualstudio.com/docs/remote/ssh)
  extension, which must be installed. The authority comes from the host's
  SSH settings (the same ones as the SSH terminal, see
  [ssh-terminal.md](ssh-terminal.md)): `user@host`, or `host` alone when
  no user is set. With a port other than 22 it is the hex-encoded JSON
  `{"hostName":…,"user":…,"port":…}`, which Remote - SSH also accepts.
  Without SSH settings the host is the AHP URL's host, and the user and
  port come from `~/.ssh/config` or the defaults.

VS Code logs in with its own SSH client and `~/.ssh/config`; the
app's saved password or key is not passed to it.

When the link does not open (no VS Code, or no handler for `vscode://`),
a snack bar says so.

## Code

`app/lib/src/vscode/`:

- `vscode_link.dart` (pure): `isLocalHost`, `remoteSshAuthority` and
  `vscodeFolderUri`.
- `open_in_vscode.dart`: `openInVsCode` (reads the SSH settings, opens
  the link, shows the error), `vscodeSupported` and
  `vscodeLauncherProvider` (tests replace it).

The session folder is `sessionDirectory` from `ssh/ssh_settings.dart`,
as for the SSH terminal.

## Tests

`app/test/open_in_vscode_test.dart`: the links (local, remote with and
without settings, another port), and the header button and menu item
on a remote host, no button without a folder or on Android, and the
error.
