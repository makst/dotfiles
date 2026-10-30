dotfiles
===

A keyboard-driven macOS development setup for Apple silicon. Ghostty opens straight into tmux, tmux holds
the shells, nvim sessions and Claude Code agents, and one base16 colour scheme is shared by all of them.

| Layer | Tool | Docs |
|---|---|---|
| Install and update | Homebrew (`Brewfile`), `setup_dotfiles` | [setup](docs/setup.md) |
| Terminal | Ghostty | [ghostty](docs/ghostty.md) |
| Sessions, windows, panes | tmux + session picker | [tmux](docs/tmux.md) |
| Shell | zsh (no framework), zsh-vi-mode, starship, atuin, zoxide, fnm, uv | [zsh](docs/zsh.md) |
| Fuzzy finding | fzf, fzf-tab, fd, bat, eza, navi | [fzf](docs/fzf.md) |
| Editor | Neovim (lazy.nvim, LSP, treesitter, telescope) | [neovim](docs/neovim.md) |
| Version control | git, diff-so-fancy, lazygit, ssh-ident | [git](docs/git.md) |
| AI agents | Claude Code in tmux windows and git worktrees | [claude-code](docs/claude-code.md) |
| Colours | base16 scheme for nvim, Ghostty and everything else | [theme](docs/theme.md) |
| Window manager | yabai + skhd (optional) | [window-management](docs/window-management.md) |

Install from scratch
---
**Fork this repo first** and change at least the git identity in `config/git/.gitconfig`: it is set up for
one person.

```sh
git clone <your fork> ~/repos/dotfiles && cd ~/repos/dotfiles
./prepare-zsh-install.sh   # Homebrew, zsh, links ~/.zshrc, makes zsh the login shell
exec zsh
setup_dotfiles             # everything else; idempotent, rerun after every `git pull`
```

Then grant Accessibility access to Ghostty (for the drop-down terminal). [docs/setup.md](docs/setup.md) lists
what each step does, every symlink it creates and the manual steps that remain.

How the keyboard is split
---
Every tool owns its own modifier, so the layers don't fight over keys:

| Keys | Owner | Examples |
|---|---|---|
| `Cmd` | Ghostty, translated into tmux commands | `cmd+t` new window, `cmd+d` split, `cmd+k` session picker |
| `C-a` | tmux prefix | `C-a f` session picker, `C-a w` session tree, `C-a z` zoom |
| `C-h/j/k/l` | tmux panes *and* nvim splits, seamlessly | |
| `Option` (Alt) | yabai/skhd, globally, when running | `alt+h` focus window left |
| `Caps Lock` | remapped to Ctrl | |
| `,` | nvim leader | `,e` file tree, `,lg` lazygit |
| `;` | nvim pickers (telescope, harpoon) | `;f` files, `;r` grep |
| `jj` | leave insert mode, in nvim and in zsh | |
| `C-r` / `C-t` / `C-g` | atuin history, fzf files, navi cheatsheets, in zsh | |

Switching sessions and windows
---
| Key | Action |
|---|---|
| `cmd+j` | every session and window as a tree with live previews; move with arrows or `j`/`k`, `Enter` switches |
| `cmd+k` | fuzzy-find a running session or a project directory, which becomes a session (`tm` outside tmux) |
| `cmd+shift+[` / `cmd+shift+]` | previous / next session |
| `cmd+[` / `cmd+]`, `cmd+1`…`9` | previous / next window, window by number |
| `C-a l` | back to the last window |
| `cmd+r` / `cmd+shift+r` | rename the window / session |

More in [tmux](docs/tmux.md#keys).

A typical day
---
1. Open Ghostty: you land in the tmux session `main`, exactly as you left it, even after a reboot.
2. `cmd+k`, type part of a project name: a tmux session for that directory opens (or is reused).
3. `vim .` in one window, `cmd+d` for a shell next to it, `C-h`/`C-l` to move between them.
4. `agent fix-login "the login form rejects valid emails"` starts Claude Code in its own worktree and
   window; when it needs you, its window turns yellow in the status bar.

Repository layout
---
```
Brewfile                  every package and app, commented by purpose
prepare-zsh-install.sh    first-run bootstrap (bash, before zsh exists)
.zshrc                    sources zsh/*; everything else is linked from config/
zsh/                      shell config, aliases, functions (setup_dotfiles lives in .functions)
config/atuin/             shell history search
.fzf.zsh                  fzf and fzf-tab configuration
config/ghostty/           Ghostty config and the generated base16 theme
config/tmux/              tmux.conf and the session picker
config/nvim/              Neovim: one directory per plugin under lua/user/
config/starship.toml      prompt
config/git/.gitconfig     git
config/.yabairc .skhdrc   window manager
data_dir/navi/cheats/     own navi cheatsheets
docs/                     this documentation
```

Private, machine-specific settings go in files that are gitignored and loaded when present:
`zsh/.private` (shell, e.g. tokens) and `config/nvim/lua/user/hidden/init.lua` (nvim).
