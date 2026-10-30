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
New windows split the focused area: side by side on a wide screen, stacked on a tall one, each nested split
the other way. 10 px gaps and padding. System Settings and Archive Utility float.

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
