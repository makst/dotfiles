Setup and maintenance
===

The setup runs in two stages, because the second needs zsh and Homebrew to exist first.

1. **`prepare-zsh-install.sh`** (bash) links `~/dotfiles` and `~/.zshrc` to this repo, installs Homebrew in
   `/opt/homebrew` and Homebrew's zsh, and makes Homebrew's zsh your login shell (asks for
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
| `fzf_setup` | links `~/.fzf.zsh` |
| `setup_atuin` | links `~/.atuin/config.toml`, imports the zsh history the first time |
| `navi_data_dir_setup` | makes the cheatsheets in `data_dir/navi/cheats` visible to navi |
| `npm_setup` | installs the latest node LTS with fnm, makes it the default, installs global `typescript` |
| `setup_python` | installs the latest python with uv as `python` / `python3` in `~/.local/bin` |
| `setup_ssh` | includes `config/ssh/config` from `~/.ssh/config`, loads keychain keys into the agent at every login (see [git](git.md#ssh-keys)) |
| `setup_git` | links `~/.gitconfig` |
| `setup_tmux` | links `~/.config/tmux`, installs tpm and the tmux plugins |
| `setup_nvim` | links `~/.config/nvim`, makes `vim` run nvim, installs the plugin versions pinned in `lazy-lock.json` |
| `setup_ghostty` | links the Ghostty config and themes |
| `remap_keys` | Caps Lock → Ctrl, now and at every login (a LaunchAgent) |
| `setup_macos_defaults` | fastest key repeat; a held key repeats in Ghostty instead of offering accents (log out and in, restart Ghostty) |
| `setup_window_management` | links the AeroSpace config and starts it, groups Mission Control by app, ctrl+cmd-drag moves windows (see [window-management](window-management.md)) |

Not part of `setup_dotfiles`:

- `setup_touch_id_sudo`: `sudo` accepts Touch ID, inside tmux too (pam-reattach). It writes
  `/etc/pam.d/sudo_local`, which survives macOS updates, and asks for your password to do so.

Symlinks
---
The repo is never copied: everything is linked, so editing a file in the repo takes effect immediately
(after reloading the tool).

| In `$HOME` | Points to |
|---|---|
| `~/dotfiles` | the repo |
| `~/.zshrc` | `.zshrc` |
| `~/.fzf.zsh` | `.fzf.zsh` |
| `~/.atuin/config.toml` | `config/atuin/config.toml` |
| `~/.gitconfig` | `config/git/.gitconfig` |
| `~/.config/tmux/` | `config/tmux/` |
| `~/.config/nvim/` | `config/nvim/` |
| `~/.config/ghostty/config`, `themes/` | `config/ghostty/…` |
| `~/Library/Application Support/navi/cheats/makst_cheats` | `data_dir/navi/cheats/` |
| `~/.config/aerospace/aerospace.toml` | `config/aerospace/aerospace.toml` |
| `~/bin/vim` | `/opt/homebrew/bin/nvim` |

`.zshrc` finds the repo by resolving its own symlink, so the clone can live anywhere.

Data that is *not* in the repo: tmux plugins (`~/.tmux/plugins`), nvim plugins and language servers
(`~/.local/share/nvim`), shell history (`~/.zsh_history`, atuin's `~/.atuin`), cached tool setup
(`~/.cache/zsh`), node versions (fnm), python versions (uv, `~/.local/share/uv`).

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
  drop-down terminal; AeroSpace, which asks on its first start.
- **Your identity**: name, email and signing key in `config/git/.gitconfig` and `config/git/allowed_signers`;
  SSH keys in `~/.ssh` (`new_ssh_key` makes one, see [git](git.md#ssh-keys)), which key goes to which host in `config/ssh/config`.
- **SSH passphrases into the keychain**, once per key: `ssh-add --apple-use-keychain <key>`. Then add the
  public key to GitHub as a signing key for *Verified* commits, see [git](git.md#signing).
- **Secrets**: shell exports in `zsh/.private`, nvim settings in `config/nvim/lua/user/hidden/init.lua`.
  Both are gitignored and loaded if they exist.
- **tmux plugins after editing the plugin list**: `C-a I` inside tmux.

Staying up to date
---
```sh
git pull && setup_dotfiles
```

That installs and upgrades brew packages (the zsh plugins are among them), installs newly listed tmux plugins and
restores nvim plugins to the versions in `lazy-lock.json`. Updating tmux plugins (`C-a U`) and nvim plugins
are deliberate steps, see [tmux](tmux.md#plugins) and [neovim](neovim.md#plugins).

Other helpers
---
- `timezsh` benchmarks the shell start with hyperfine: check after adding plugins.
- `sync_cheatsh` downloads the whole cheat.sh catalogue to `~/cheatsheets` for offline use (takes 15–20 min).
