# Colour themes

The app ships the popular colour themes of VS Code, Neovim and Emacs
(AV-097). Pick them from the sidebar's "…" menu under **Appearance**:
**System**, **Light** or **Dark**, then a **Dark theme** and a **Light
theme**. The app uses the dark theme while it is dark and the light one
while it is light, so with **System** it follows the OS and still uses
your picks. Picking a theme of the other brightness switches the mode to
it, so the change shows at once. The choices are kept per device.

| Editor      | Dark                                                                                                                                                                         | Light                                                                                      |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| shireitou   | Graphite (the default)                                                                                                                                                       | Graphite (the default)                                                                     |
| VS Code     | One Dark, GitHub Dark, GitHub Dark Dimmed, Dracula, Ayu Dark, Ayu Mirage, Monokai, Material Palenight, Nord                                                                  | One Light, GitHub Light, Ayu Light, Material Lighter                                       |
| Neovim      | Catppuccin Mocha, Macchiato and Frappé, Tokyo Night, Storm and Moon, Kanagawa, Kanagawa Dragon, Rosé Pine, Rosé Pine Moon, Nightfox, Everforest, Gruvbox Material, Oxocarbon | Catppuccin Latte, Tokyo Night Day, Rosé Pine Dawn, Everforest, Gruvbox Material, Oxocarbon |
| Emacs / Vim | Doom One, Modus Vivendi, Zenburn, Solarized Dark, Gruvbox Dark, Tomorrow Night, Tomorrow Night Eighties, Spacemacs                                                           | Modus Operandi, Solarized Light, Gruvbox Light, Tomorrow                                   |

The list was picked from the 2026 rankings: VS Code Marketplace installs,
[Dotfyle](https://dotfyle.com/neovim/colorscheme/top)'s Neovim
configurations and [MELPA](https://emacsthemes.com/popular) downloads.

## Where the colours come from

Every theme is a [Base24](https://github.com/tinted-theming/base24) palette:
eight background-to-foreground shades (`base00` to `base07`), eight
accents (`base08` to `base0F`: red, orange, yellow, green, cyan, blue,
purple, brown) and, in Base24, darker backgrounds and the bright ANSI
colours (`base10` to `base17`). A Base16 scheme is padded to Base24 with
its normal colours.

- `app/themes/manifest.yaml` lists the themes, in menu groups. Most are
  [tinted-theming/schemes](https://github.com/tinted-theming/schemes)
  ports, vendored in `app/themes/vendor/` at a pinned commit (MIT, see
  `vendor/LICENSE`); Base24 is used where a port exists.
- `app/themes/local/` holds the themes with no port, written in the same
  format from their upstream palettes: Graphite (the app's own), Doom
  One (`doom-one-theme.el`), Modus Vivendi and Operandi
  (`modus-themes.el`) and Nightfox (`palette/nightfox.lua`). Each file
  says which upstream names fill which slot.
- `app/tool/gen_themes.dart` turns the manifest into
  `app/lib/src/theme/generated/themes.g.dart`, a `const` list of
  `ThemeSpec`s. `test/gen_themes_test.dart` fails when the file is stale.

```sh
just themes          # regenerate themes.g.dart from the manifest
just fetch-themes    # re-download the vendored schemes, then regenerate
```

To add a theme, add a line to the manifest (a `scheme:` from
tinted-theming, or a `file:` in `local/`), run `just fetch-themes` (or
`just themes` for a local file) and `just test`.

## How a palette becomes the app's colours

`themeColors` in `app/lib/src/theme/themes.dart` is pure:

| App colour                       | From                                                              |
| -------------------------------- | ----------------------------------------------------------------- |
| Main pane                        | `base00`                                                          |
| Sidebar, title bar, terminals    | `base01` when darker than `base00`, else `base00` darkened        |
| Selected row                     | `base02`, moved towards `base00` until `base05` text is 4.5:1     |
| Hover, bubble, hairline, raised  | `base00` mixed with the selection (raised: with white when light) |
| Text, muted text                 | `base05`, `base04`                                                |
| Accent (links, buttons, running) | `base0D`                                                          |
| Attention, done, error, idle     | `base0A`, `base0B`, `base08`, `base03`                            |
| Diff added, removed lines        | `base0B`, `base08` at 20%                                         |
| Terminal ANSI                    | Base24's mapping (`base01` black … `base17` bright magenta)       |

Code is highlighted with the
[Base16 styling guide](https://github.com/tinted-theming/home/blob/main/styling.md)'s
roles: keywords `base0E`, strings `base0B`, numbers and attributes
`base09`, comments `base03`, functions `base0D`, types `base0A`,
variables and tags `base08`, regular expressions `base0C`, and
preprocessor and meta `base0F`.

Many themes' own colours are under WCAG AA, comments above all. Each text
colour is moved, along its hue's lightness, only as far as it needs
(`readable` in `contrast.dart`): text, muted text, links, error text and
code 4.5:1, and status dots, the diff gutter and code on diff lines 3:1.
`test/contrast_test.dart` checks every theme.
