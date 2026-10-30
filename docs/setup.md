Setup and maintenance
===

The setup runs in two stages, because the second needs zsh and Homebrew to exist first.

1. **`prepare-zsh-install.sh`** (bash) links `~/dotfiles` and `~/.zshrc` to this repo, installs Homebrew in
   `/opt/homebrew`, Homebrew's zsh and Oh My Zsh, and makes Homebrew's zsh your login shell (asks for
   your password once, for `/etc/shells` and `chsh`). An existing real `~/.zshrc` is kept as
   `~/.zshrc.backup`.
2. **`setup_dotfiles`** (a zsh function from `zsh/.functions`) does the rest. Every step is idempotent, so
   rerun it after pulling changes.

Both only ever use the native arm64 Homebrew in `/opt/homebrew`. A Homebrew in `/usr/local` on an Apple
silicon Mac is a leftover Intel install running under Rosetta and is deliberately ignored.

What `setup_dotfiles` does
---
Each step is a function you can also run on its own:

| Function | Does |
|---|---|
| `brew_setup` | `brew bundle` with the [Brewfile](../Brewfile) |
| `install_and_update_zsh_plugins` | clones or updates fzf-tab, zsh-vi-mode, zsh-autosuggestions, zsh-syntax-highlighting into Oh My Zsh |
| `fzf_setup` | links `~/.fzf.zsh` |
| `navi_data_dir_setup` | makes the cheatsheets in `data_dir/navi/cheats` visible to navi |
| `npm_setup` | installs the latest node LTS with fnm, makes it the default, installs global `typescript` |
| `install_ssh_ident` | downloads ssh-ident to `~/bin` and puts it in front of `ssh`, `scp`, `sftp` (see [git](git.md)) |
| `setup_git` | links `~/.gitconfig` |
| `setup_tmux` | links `~/.config/tmux`, installs tpm and the tmux plugins |
| `setup_nvim` | links `~/.config/nvim`, makes `vim` run nvim, installs the plugin versions pinned in `lazy-lock.json` |
| `setup_ghostty` | links the Ghostty config and themes |
| `remap_keys` | Caps Lock → Ctrl, now and at every login (a LaunchAgent) |

Not part of `setup_dotfiles`: `setup_window_management` (yabai and skhd, see
[window-management](window-management.md)), because yabai needs decisions about SIP first.

Symlinks
---
The repo is never copied: everything is linked, so editing a file in the repo takes effect immediately
(after reloading the tool).

| In `$HOME` | Points to |
|---|---|
| `~/dotfiles` | the repo |
| `~/.zshrc` | `.zshrc` |
| `~/.fzf.zsh` | `.fzf.zsh` |
| `~/.gitconfig` | `config/git/.gitconfig` |
| `~/.config/tmux/` | `config/tmux/` |
| `~/.config/nvim/` | `config/nvim/` |
| `~/.config/ghostty/config`, `themes/` | `config/ghostty/…` |
| `~/Library/Application Support/navi/cheats/makst_cheats` | `data_dir/navi/cheats/` |
| `~/.yabairc`, `~/.skhdrc` | `config/…` (only after `setup_window_management`) |
| `~/bin/vim` | `/opt/homebrew/bin/nvim` |
| `~/bin/ssh`, `scp`, `sftp` | `~/bin/ssh-ident` |

`.zshrc` finds the repo by resolving its own symlink, so the clone can live anywhere.

Data that is *not* in the repo: tmux plugins (`~/.tmux/plugins`), nvim plugins and language servers
(`~/.local/share/nvim`), Oh My Zsh (`~/.oh-my-zsh`), node versions (fnm), python versions (pyenv).

The Brewfile
---
Grouped by why a package is there: tools these dotfiles depend on (each commented with the file that uses
it), everyday CLI tools, GUI apps (casks), and a commented-out review list of things from an older Mac.
Add a package by adding a line and rerunning `brew_setup`. `brew bundle check --verbose` shows what is
missing; `brew bundle cleanup` shows what is installed but not listed.

Manual steps
---
These can't be scripted, or shouldn't be:

- **Accessibility** (System Settings → Privacy & Security → Accessibility): Ghostty, for the global
  drop-down terminal; yabai and skhd if you use them.
- **Your identity**: name and email in `config/git/.gitconfig`; SSH keys in `~/.ssh`.
- **Secrets**: shell exports in `zsh/.private`, nvim settings in `config/nvim/lua/user/hidden/init.lua`.
  Both are gitignored and loaded if they exist.
- **tmux plugins after editing the plugin list**: `C-a I` inside tmux.

Staying up to date
---
```sh
git pull && setup_dotfiles
```

That installs and upgrades brew packages, updates the zsh plugins, installs newly listed tmux plugins and
restores nvim plugins to the versions in `lazy-lock.json`. Updating tmux plugins (`C-a U`) and nvim plugins
are deliberate steps, see [tmux](tmux.md#plugins) and [neovim](neovim.md#plugins).

Other helpers
---
- `timezsh` starts an interactive zsh ten times and prints the timings: check after adding plugins.
- `sync_cheatsh` downloads the whole cheat.sh catalogue to `~/cheatsheets` for offline use (takes 15–20 min).
