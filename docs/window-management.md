Window management (AeroSpace)
===

[AeroSpace](https://github.com/nikitabobko/AeroSpace) tiles macOS windows and has its own workspaces, so
switching between them is instant and needs no Mission Control animation, and System Integrity Protection
stays on. It comes from the Brewfile; `setup_window_management` (part of `setup_dotfiles`) links the config
and starts it.

Config: `config/aerospace/aerospace.toml`, linked to `~/.config/aerospace/aerospace.toml`. Saving it applies
it. The first start asks for Accessibility access (System Settings → Privacy & Security → Accessibility);
after that it starts at login.

Layout
---
A new window goes next to the focused one, in the same row (or column), and they share it equally: three
windows are three columns. There is no automatic halving as in yabai; nested layouts are made by hand
(below). When a window closes or leaves the workspace, the others grow into its space. 6 px gaps and
padding. System Settings, Archive Utility and NordVPN float.

Workspaces 1–9 are AeroSpace's, not macOS Spaces: windows on other workspaces are moved just off screen.
Leave macOS on a single Space per display. `setup_window_management` also turns on *Group windows by
application* (Mission Control shows those off-screen windows too small otherwise) and lets `ctrl+cmd` and a
drag anywhere in a window move it (after logging out and in).

Keys
---
All on `Option` (Alt). AeroSpace captures these system-wide, so they don't reach other apps: Alt+h/j/k/l in
nvim or zsh, for instance, are handled by AeroSpace.

| Key | Action |
|---|---|
| `alt+h/j/k/l` | focus the window left/down/up/right |
| `shift+alt+h/j/k/l` | swap with the window in that direction |
| `ctrl+shift+alt+h/j/k/l` | move the window through the layout in that direction |
| `alt+e` | switch the split between side by side and stacked |
| `alt+s` | accordion: the windows on top of each other, the focused one in front (again: back to tiles) |
| `alt+t` | float the window (toggle) |
| `alt+f` | fill the workspace with the window (toggle) |
| `alt+-` / `alt+=` | make the window smaller / bigger |
| `shift+alt+0` | make all windows equal size |
| `alt+1`…`9` | go to workspace 1…9 |
| `alt+0` | back to the previous workspace |
| `shift+alt+1`…`9` | move the window to workspace 1…9 and follow it |
| `shift+alt+n` / `shift+alt+p` | move the window to the next / previous display and follow it |
| `shift+alt+tab` | move the whole workspace to the next display |
| `shift+alt+;` then a key | `esc` reload the config, `r` reset the layout, `backspace` close all other windows, `h/j/k/l` put the window and its neighbour in a container of their own |

`aerospace list-windows --all` shows every window with its app id, for adding more floating apps in
`on-window-detected`.

Arranging windows
---
Three windows side by side, and you want one big window on the left with the other two stacked on the
right: focus the rightmost, `shift+alt+;` then `h`. The two right windows now share a column, one above the
other. `alt+e` inside that column switches it back to side by side.

`ctrl+shift+alt+h/j/k/l` does the same step by step: it moves the window into the neighbouring column or row,
or out of it again at the edge. `shift+alt+;` then `r` undoes all nesting: every window back in one row.

Good to know
---
- **Don't use macOS desktops** (Mission Control Spaces). AeroSpace doesn't see them: a window moved to
  another desktop still counts as being on its workspace, and its space stays empty. Use `shift+alt+<n>`
  instead, and keep a single desktop per display.
- **A window that doesn't tile** is floating: `alt+t` puts it back. New windows of the floating apps above
  always start floating.
- **A gap nothing fills**: `aerospace list-windows --workspace focused` shows what AeroSpace thinks is there.
- **Everything stacked on top of each other**: that's the accordion (`alt+s`); `alt+s` again goes back to
  tiles.
- **Minimised and hidden windows** (`cmd+m`, `cmd+h`) leave the layout until they come back.
