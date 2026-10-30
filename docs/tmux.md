tmux
===

tmux is where everything lives. Ghostty attaches to it, every project gets a session, and sessions survive
closing Ghostty and, thanks to resurrect/continuum, rebooting the Mac.

Config: `config/tmux/tmux.conf` (linked to `~/.config/tmux/`). Reload: `C-a r`.

Model
---
- **Session** per project: created by the session picker from a directory, named after it. `main` is the
  one Ghostty opens.
- **Window** per task: an editor, a dev server, a Claude Code agent. Windows are numbered from 1, matching
  `cmd+1`…`9`, and renumbered when one closes.
- **Panes** for things you want side by side. Splits and new windows start in the current pane's directory.
- Closing the last window of a session switches to another session instead of closing the terminal.

Keys
---
The prefix is `C-a` (with Caps Lock as Ctrl, that's a left-hand roll). Press it twice to send a literal
`C-a` to the program. The `cmd` column is what Ghostty sends for you, see [ghostty](ghostty.md).

| Key | cmd | Action |
|---|---|---|
| `C-a c` | `cmd+t` | new window |
| `C-a \|` / `C-a -` | `cmd+d` / `cmd+shift+d` | split right / down |
| `C-a x` | `cmd+w` | close pane |
| `C-a 1`…`9` | `cmd+1`…`9` | go to window |
| `C-a C-h` / `C-a C-l` | `cmd+[` / `cmd+]` | previous / next window (repeatable) |
| `C-a l` | | last window |
| `C-a (` / `C-a )` | `cmd+shift+[` / `cmd+shift+]` | previous / next session |
| `C-a z` | `cmd+shift+enter` | zoom pane |
| `C-a f` | `cmd+k` | session picker |
| `C-a w` | `cmd+j` | tree of sessions and windows, with previews: the quickest way to switch to any of them |
| `C-a /` | `cmd+f` | search the scrollback upwards (`n` / `N` for more) |
| `C-a H/J/K/L` | | resize pane (repeatable) |
| `C-a d` | | detach |
| `C-a r` | | reload the config |
| `C-h/j/k/l` | | move to the pane left/down/up/right, *including nvim splits* |

`C-h/j/k/l` work without the prefix: vim-tmux-navigator checks whether the pane runs nvim and, if so, lets
nvim move between its own splits first. Inside nvim the same keys cross into tmux panes. The catch: those
four keys don't reach programs in the shell (`C-l` no longer clears the screen; use `clear`).

Session picker
---
`cmd+k` (or `tm` in a shell outside tmux) opens fzf with the running sessions first, then every directory
zoxide knows, most used first. Choosing a directory creates a session there named after it, or switches to
it if it exists. Outside tmux, `tm` attaches.

So the directories you `z` into in the shell are the projects you can jump to. See [zsh](zsh.md#navigation).

Copy and paste
---
Copy mode uses vi keys and copies to the macOS clipboard:

| Key | Action |
|---|---|
| `C-a Enter` | enter copy mode (scrolling with the mouse does too) |
| `v` / `C-v` | start selection / toggle block selection |
| `y` | copy and leave |
| `H` / `L` | start / end of line |
| `Esc` | leave |
| `C-a p` / `C-a P` / `C-a b` | paste the last buffer / choose a buffer / list buffers |

Mouse selections are copied as well. Copies also travel over ssh: tmux sends them to Ghostty as OSC 52,
so text copied in a remote tmux lands in the local clipboard.

Status bar
---
At the top. Left: the session name. Then the windows: current one in blue, a zoomed one with a fullscreen icon,
and **a window that rang the bell in yellow with a bell icon** until you visit it. Programs ring the bell
when they want attention, Claude Code for example when it waits for input (see
[claude-code](claude-code.md)). Right: a `PREFIX` badge while the prefix is pressed, date, time, battery.

It uses only the 16 ANSI colours, so it follows the [theme](theme.md).

Plugins
---
Managed by tpm, installed under `~/.tmux/plugins` (outside the repo).

| Plugin | Does |
|---|---|
| vim-tmux-navigator | `C-h/j/k/l` across tmux panes and nvim splits |
| tmux-resurrect | `C-a C-s` saves all sessions, windows, panes, their directories and contents; `C-a C-r` restores |
| tmux-continuum | saves every 15 minutes and restores automatically when the tmux server starts |

`C-a I` installs newly added plugins, `C-a U` updates them.

What resurrect brings back: the layout, directories and pane contents. Running programs are not
restarted (except a few like `vim`), so an agent or dev server shows up as a shell.

Terminal capabilities
---
Set up so nvim inside tmux looks the same as outside: true colour, undercurls and coloured underlines
(diagnostics), focus events (nvim reloads files changed on disk), no delay on `Esc`, OSC 52 clipboard and
passthrough (images, notifications). The window title in Ghostty shows `session · window`.

Remote hosts often lack the `tmux-256color` terminfo, so inside tmux the `ssh` alias connects with
`TERM=xterm-256color`.
