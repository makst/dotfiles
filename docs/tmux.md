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

<details>
<summary><b>Show GIF</b></summary>

Splitting, moving between and zooming panes, then a new window.

![Splitting, moving between and zooming panes, then a new window](img/tmux-panes.gif)

</details>

| Key | cmd | Action |
|---|---|---|
| `C-a c` | `cmd+t` | new window |
| `C-a \|` / `C-a -` | `cmd+d` / `cmd+shift+d` | split right / down |
| `C-a x` | `cmd+w` | close pane |
| `C-a 1`…`9` | `cmd+1`…`9` | go to window |
| `C-a C-h` / `C-a C-l` | `cmd+[` / `cmd+]` | previous / next window (repeatable) |
| `C-a l` | `cmd+0` | back to the last window |
| `C-a ;` | `ctrl+0` | back to the last pane |
| `C-a (` / `C-a )` | – | previous / next session (tmux default; no Cmd key, too close to `cmd+[` / `cmd+]`) |
| `C-a S` | `cmd+shift+0` | back to the last session (tmux's own key for it, `C-a L`, resizes panes here) |
| `C-a z` | `cmd+shift+enter` | zoom pane |
| `C-a f` | `cmd+k` | session picker |
| `C-a w` | `cmd+j` | tree of sessions and windows, with previews: the quickest way to switch to any of them |
| `C-a a` | `cmd+shift+j` | the Claude Code agents only, in a popup: most urgent first, each with its state and what it's working on, and a live preview of its screen. `j`/`k`, `g`/`G`, `ctrl+d`/`ctrl+u` move, `/` filters, `Esc` clears the filter, `q` closes |
| `C-a A` | `cmd+shift+space` | the next Claude Code agent that needs you, in any session: waiting ones first, then done ones; again for the one after, `cmd+shift+0` back |
| `C-a /` | `cmd+f` | search the scrollback upwards (`n` / `N` for more) |
| `C-a ,` / `C-a $` | `cmd+r` / `cmd+shift+r` | rename the window / session. The prompt opens in the status bar with the current name; `C-u` clears it |
| `C-a H/J/K/L` | | resize pane (repeatable) |
| `C-a d` | | detach |
| `C-a r` | | reload the config |
| `C-h/j/k/l` | | move to the pane left/down/up/right, *including nvim splits* |
| `C-Space` | | next pane, cycling: see [same key, every layer](../README.md#same-key-every-layer) |

`C-h/j/k/l` work without the prefix: vim-tmux-navigator checks whether the pane runs nvim and, if so, lets
nvim move between its own splits first. Inside nvim the same keys cross into tmux panes. The catch: those
four keys don't reach programs in the shell (`C-l` no longer clears the screen; use `clear`). `C-Space`
always goes to tmux, even in nvim: there it no longer opens completion (`Tab` does).

Session picker
---
`cmd+k` (or `tm` in a shell outside tmux) opens fzf with the running sessions first, then every directory
zoxide knows, most used first, those in your home as `~/…`. Choosing a directory creates a session there
named after it, or switches to it if it exists. Outside tmux, `tm` attaches. It opens in a popup that looks
like fzf in the shell: the terminal's background, a rounded border, the theme's colours.

<details>
<summary><b>Show GIF</b></summary>

`cmd+k` opens a project as a session, `cmd+j` shows the tree, `cmd+shift+0` goes back to the last session.

![cmd+k opens a project as a session, cmd+j shows the tree, cmd+shift+0 goes back to the last session](img/tmux-sessions.gif)

</details>

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
when they want attention. A window running Claude Code shows its agent's state instead: waiting 󰂞, done but
not seen 󰄬, working 󰔟 (see [claude-code](claude-code.md#noticing-an-agent-that-waits)). Right: how many
agents are in each state across all sessions, a `PREFIX` badge while the prefix is pressed, date, time,
battery.

The tree (`cmd+j`) and the session picker (`cmd+k`) show the same marks: on each pane, window and session,
the most urgent agent in it. Visiting a window marks its finished agents as seen.

It uses only the 16 ANSI colours, so it follows the [theme](theme.md). So do popups, menus, the tree
(`cmd+j`), search matches and the command prompt: tmux 3.8 colours them from a theme of fixed shades (a grey
popup background, `skyblue3`, …), which the config maps onto the ANSI colours.

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
