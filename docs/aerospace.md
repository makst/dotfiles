Window management (AeroSpace)
===

[AeroSpace](https://github.com/nikitabobko/AeroSpace) tiles macOS windows and has its own workspaces, so
switching between them is instant and needs no Mission Control animation, and System Integrity Protection
stays on.

What it is
---
- **Layout**: a new window goes next to the focused one, in the same row (or column), and they share it
  equally: three windows are three columns. Nested layouts are made by hand ([Arranging
  windows](#arranging-windows)). When a window closes or leaves the workspace, the others grow into its space.
  6 px gaps and padding. System Settings, Archive Utility and NordVPN float, and so does the bar Chrome, Brave
  or Firefox shows while sharing the screen (Google Meet and the like).
- **IDEs get workspaces of their own**, so nvim and the shells keep theirs: VS Code, the debugger, opens on
  workspace 7 (see [debugging](debugging.md)), Xcode on 8 with the iOS Simulator floating over it, Android
  Studio on 9 with the Android emulator floating over it (see [mobile](mobile.md)). With two displays, 7, 8
  and 9 always show on the one that isn't the main display (System Settings → Displays → *Use as*), so the
  IDE sits on one screen and nvim on the other. `alt+7` / `alt+8` / `alt+9` go there, and `,vo` / `,io` /
  `,ao` in nvim switch to it as well, since AeroSpace follows the app that comes to the front. These three
  workspaces are pinned: `shift+alt+tab` doesn't move them.
- **Workspaces 1–9 are AeroSpace's, not macOS Spaces**: windows on other workspaces are moved just off screen.
- **Keys** are all on `Option` (Alt), captured system-wide, so they don't reach other apps: Alt+h/j/k/l in
  nvim or zsh, for instance, are handled by AeroSpace.

Once per Mac
---
`setup_aerospace` (part of `setup_dotfiles`) links the config and starts AeroSpace (from the
Brewfile). It also turns on *Group windows by application* (Mission Control shows those off-screen windows
too small otherwise) and lets `ctrl+cmd` and a drag anywhere in a window move it.

1. Grant Accessibility access when the first start asks (System Settings → Privacy & Security →
   Accessibility); after that it starts at login.
2. Log out and in, for the `ctrl+cmd` drag.
3. Leave macOS on a single Space per display.

Arranging windows
---
Three windows side by side, and you want one big window on the left with the other two stacked on the
right: focus the rightmost, `shift+alt+;` then `h`. The two right windows now share a column, one above the
other. `alt+e` inside that column switches it back to side by side.

`ctrl+shift+alt+h/j/k/l` does the same step by step: it moves the window into the neighbouring column or row,
or out of it again at the edge. `shift+alt+;` then `r` undoes all nesting: every window back in one row.

Making an app float
---
1. `aerospace list-windows --all` shows every window with its app id.
2. Add the app id to `on-window-detected` in the config; saving applies it. New windows of that app start
   floating.

Keys
---
| Key | Action |
|---|---|
| `alt+h/j/k/l` | focus the window left/down/up/right |
| `alt+space` | focus the next window on this workspace, cycling: see [same key, every layer](design.md#same-key-every-layer) |
| `shift+alt+h/j/k/l` | resize the window: narrower, taller, shorter, wider, as `C-a H/J/K/L` in tmux: see [same key, every layer](design.md#same-key-every-layer) |
| `ctrl+shift+alt+h/j/k/l` | move the window through the layout in that direction |
| `alt+e` | switch the split between side by side and stacked |
| `alt+s` | accordion: the windows on top of each other, the focused one in front (again: back to tiles) |
| `alt+t` | float the window (toggle) |
| `alt+z` | fill the workspace with the window (toggle), as `C-a z` zooms a tmux pane |
| `alt+=` | make all windows equal size |
| `alt+1`…`9` | go to workspace 1…9 |
| `alt+0` | back to the previous workspace |
| `alt+[` / `alt+]` | previous / next workspace with windows on this display, cycling: see [same key, every layer](design.md#same-key-every-layer) |
| `shift+alt+1`…`9` | move the window to workspace 1…9 and follow it |
| `shift+alt+n` / `shift+alt+p` | move the window to the next / previous display and follow it |
| `shift+alt+tab` | move the whole workspace to the next display |
| `shift+alt+;` then a key | `esc` reload the config, `r` reset the layout, `backspace` close all other windows, `h/j/k/l` put the window and its neighbour in a container of their own |

Config
---
`config/aerospace/aerospace.toml`, linked to `~/.config/aerospace/aerospace.toml`. Saving it applies it.
Floating apps are in `on-window-detected`, the IDE workspaces' display in
`[workspace-to-monitor-force-assignment]`.

To look out for
---
- **Don't use macOS desktops** (Mission Control Spaces). AeroSpace doesn't see them: a window moved to
  another desktop still counts as being on its workspace, and its space stays empty. Use `shift+alt+<n>`
  instead, and keep a single desktop per display.
- **A window that doesn't tile** is floating: `alt+t` puts it back. New windows of the floating apps above
  always start floating.
- **A gap nothing fills**: `aerospace list-windows --workspace focused` shows what AeroSpace thinks is there.
- **Everything stacked on top of each other**: that's the accordion (`alt+s`); `alt+s` again goes back to
  tiles.
- **Screen sharing**: share a single window or tab rather than the whole screen; then switching workspaces
  doesn't change what others see. If a sharing bar still takes a tile (some set their title late), `alt+t`
  floats it.
- **The IDE opened on another workspace**: the rules only act on new windows. A window that was open
  before AeroSpace started stays where it was: `shift+alt+7`…`9` moves it.
- **The IDE should be on the main display**: change `'secondary'` to `'main'` under
  `[workspace-to-monitor-force-assignment]` in the config.
- **Minimised and hidden windows** (`cmd+m`, `cmd+h`) leave the layout until they come back.

Decisions
---
- **AeroSpace, not yabai or macOS Spaces**: its own workspaces switch instantly, without Mission Control's
  animation, and System Integrity Protection stays on. It has no automatic halving as in yabai; nested
  layouts are made by hand.
