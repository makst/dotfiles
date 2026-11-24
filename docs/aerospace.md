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
- **Every window at a glance** (`alt+w`): every window with its workspace, app icon, app and window title,
  drawn as a tree like tmux's (`cmd+j`): a workspace with more than one window has them under it, and with a
  second display each display (a laptop icon for the built-in one, a monitor for the other) has its
  workspaces under it. It opens from any app in a small Ghostty window floating over the workspace you're on,
  the cursor on the window you came from (✓): `j/k` move, `/` filters, Enter goes to that window, workspace
  or display, `1`…`9` to that workspace, `m` moves your window to the chosen one's workspace (or display),
  `t` arranges the chosen workspace in a layout, `a` lists the saved arrangements, `d` closes the chosen
  window, `q` back to where you were.
- **Layouts** (`t` in `alt+w`): a list of layouts with a drawing of each, for the workspace of the line
  you're on: side by side, stacked, one big window on the left (60%) with the others stacked on the right,
  in columns of two, or one at a time (the accordion). It goes to that workspace and arranges its tiled
  windows in the order they're in now; floating ones stay as they are.
- **Saved arrangements**: which apps go on which workspace, which workspace on which display and in what
  shape, saved per number of displays: Ghostty on the big display and Slack on the laptop's with two, both on
  one workspace one at a time with one. `a` in `alt+w` lists them: Enter applies one, `n` saves what's on
  screen. When a display comes or goes, the one used last for the new number of displays is applied by itself.
  See [Saved arrangements](#saved-arrangements).
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

### Saved arrangements
`~/.config/dotfiles/arrangements` (this Mac's own, from `config/machine/arrangements`) has a line for each
workspace of an arrangement: its name, the number of displays it's for, the display (`main` or `secondary`,
as System Settings → Displays → "Use as" says), the workspace, the shape (as `t` in `alt+w`) and the apps, in
the order the shape puts them:

```
desk    2  main       1  tiles      Ghostty
desk    2  secondary  2  accordion  Slack
laptop  1  main       1  accordion  Ghostty, Slack
```

`~/.config/aerospace/windows --apply desk` moves every window of those apps to its workspace, each workspace
to its display, arranges each in its shape and shows it, ending on the first line's workspace. Windows of apps
it doesn't name stay where they are; an app with no window is left out and named. It refuses an arrangement
made for another number of displays. `check_dotfiles` checks the file (`windows --check <file>` on its own).

`a` in `alt+w` lists them, with each one's displays, workspaces, shapes and apps in the preview; the ones made
for another number of displays are dimmed, and Enter on one says so instead of applying it.

| Key | Action |
|---|---|
| Enter | apply it (`windows --apply <name>`) |
| `n` | save what's on screen now under a name you type (`windows --save <name>`); a name in use asks before replacing |
| `r` | rename it (`windows --rename <name> <new name>`) |
| `d` | delete it, after a `y` (`windows --delete <name>`) |
| `q` | back to where you were |

**When a display comes or goes**, the arrangement used last for the new number of displays (or the first one
made for it) is applied by itself within about 7 seconds, and a notification says which. A LaunchAgent that
`setup_aerospace` loads runs `windows --watch` every 5 seconds, since AeroSpace has no event for a display
being plugged in or out; it only reads the number of displays, and its errors go to
`~/.local/state/aerospace-displays.log`. With no arrangement for that number nothing moves.

Saving writes, for each workspace with windows, its display, its shape and its apps in their order; an app on
two workspaces goes with the first. Each change keeps the file as it was in `arrangements.prev` next to it.

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
| `alt+w` | every window by display and workspace, in a picker: Enter goes there, `1`…`9` to that workspace, `m` moves your window to the chosen one's workspace or display, `t` arranges the chosen workspace in a layout, `a` the saved arrangements, `d` closes the chosen window, `q` back (see [same key, every layer](design.md#same-key-every-layer)) |
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
`config/aerospace/windows` is the window picker (`alt+w`), linked next to it; its `exec-and-forget` finds
Homebrew's `tmux` and `aerospace` through `[exec.env-vars]`, as AeroSpace starts at login with macOS's bare
`PATH`. It starts a Ghostty of its own (`open -na Ghostty` with its own size, position and title), which the
`on-window-detected` rule for the title `aerospace-windows` floats. `~/.config/aerospace/windows --list`
prints the list alone; errors from `alt+w` go to `$TMPDIR/aerospace-windows.log`.
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
- **A pick takes ~0.2 s**: the picker's Ghostty quitting hands focus back to the app you came from, up to
  ~200 ms later, so `alt+w` waits that out and then switches once (switching straight away flickered: there,
  back, there again). Should a hand-back come later, it switches again, for a second after the pick.
- **`alt+w` brought Ghostty forward instead**: the picker's own Ghostty didn't start, so it opened in a tmux
  popup of the client used last, in the Ghostty window whose title is that client's (`session · window`).
  With no tmux client it only brings Ghostty forward; with no Ghostty window it starts Ghostty.
- **The picker isn't centred**: its position is worked out from the main display's size and Ghostty's
  `font-size` (a cell 0.6 of it wide, about 1.4 high), so another font or a second display can put it off
  centre.
- **A layout came out different**: `t` flattens the workspace first and then joins and moves windows by
  their order, so a window that was minimised, or that AeroSpace lists in another order, can land
  elsewhere. `t` again, or `shift+alt+;` then `r` to put every window back in one row.
- **A saved shape isn't the one on screen**: AeroSpace only tells how a workspace's windows are split at the
  top (side by side, stacked, one at a time), so saving uses the shape `t` last gave the workspace while that
  still fits, and otherwise side by side, stacked or one at a time. Arranged by hand, a main + stack is saved
  as side by side: `t` it once, or change the line in the file.
- **An app in an arrangement isn't moved**: the name must be the one AeroSpace shows
  (`aerospace list-apps`), e.g. `Brave Browser`, not `Brave`.
- **Minimised and hidden windows** (`cmd+m`, `cmd+h`) leave the layout until they come back.

Decisions
---
- **AeroSpace, not yabai or macOS Spaces**: its own workspaces switch instantly, without Mission Control's
  animation, and System Integrity Protection stays on. It has no automatic halving as in yabai; nested
  layouts are made by hand.
- **The window list in a Ghostty of its own, not a macOS panel or a tmux popup**: it's the picker every other
  list uses (`picker`, [one tool per job](design.md#one-tool-per-job)), with its keys and filter, and it
  floats over the workspace you're on, where a tmux popup meant switching to Ghostty's workspace and back.
  A second Ghostty (`open -na`) because its options are its own: a title from the start, which an AeroSpace
  rule can float (a window from Ghostty's AppleScript has none yet when AeroSpace sees it, so it tiled
  first), and a size and position, which AeroSpace can't set for a floating window. It costs ~0.5 s to
  start and the flicker above. The tmux popup stays as the fallback.
- **`alt+w`, not `alt+j`** as `cmd+j` lists tmux's windows: `alt+j` is focus down.
