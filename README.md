- [About](#about)
- [Install from scratch](#install-from-scratch)
- [Working with the full installation](#working-with-the-full-installation)

About
---
MacOS development setup.

Install from scratch
---
**Warning:**
Make sure you fork this repo and adjust it to your own preferences before even starting the setup.

1. Install git.
2. Clone this repo.
3. From inside this repo, run
   ```
   $ ./prepare-zsh-install.sh
   $ exec zsh
   $ setup_dotfiles # idempotent, can be executed after every `git pull`
   ```

   `prepare-zsh-install.sh` links the dotfiles into `$HOME`, installs Homebrew (native `/opt/homebrew` on Apple
   silicon), zsh and Oh My Zsh, and makes Homebrew's zsh your login shell. `setup_dotfiles` then installs the
   packages from the [Brewfile](./Brewfile) (including nvim, starship and fnm), the zsh and tmux plugins, node (fnm), ssh-ident, links the git, tmux, nvim and Ghostty config and remaps Caps Lock to Ctrl at every login. `change_theme` switches the base16 colour scheme of nvim and Ghostty together.

   yabai and skhd are installed by the Brewfile, but `setup_window_management` is not part of `setup_dotfiles`:
   run it yourself after reading the SIP notes in that function.

Terminal: Ghostty + tmux + nvim
---
Ghostty's first window attaches to the tmux session `main`, so sessions, Claude Code agents and layouts survive
quitting Ghostty (and, with tmux-resurrect/continuum, a reboot). Its Cmd shortcuts drive tmux (prefix is `C-a`):

| Ghostty | tmux | |
|---|---|---|
| cmd+t | prefix c | new window |
| cmd+d / cmd+shift+d | prefix \| / prefix - | split right / down |
| cmd+w | prefix x | close pane (asks first) |
| cmd+1..9, cmd+[ / cmd+] | prefix 1..9, prefix C-h / C-l | go to window |
| cmd+shift+enter | prefix z | zoom pane |
| cmd+k | prefix f | session picker: running sessions and zoxide directories (`tm` outside tmux) |
| cmd+j | prefix w | tree of all sessions and windows |
| cmd+f | prefix / | search the scrollback |

C-h/j/k/l move between tmux panes and nvim splits. Further Ghostty windows (cmd+n) and the quick terminal
(ctrl+\`) are plain zsh.

`agent <name> [prompt]` starts Claude Code in its own git worktree (`claude -w`) in a new tmux window named
`<name>`. A window whose program rings the bell, e.g. an agent waiting for input, turns yellow in the status line
until you visit it. nvim reloads files changed on disk when you come back to it.

Working with the full installation
---
Discover [functions](./zsh/.functions) that you can run/rerun/modify to set up your dev environment.
