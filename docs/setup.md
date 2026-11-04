Setup and maintenance
===

The setup runs in two stages, because the second needs zsh and Homebrew to exist first.

1. **`prepare-zsh-install.sh`** (bash) links `~/dotfiles` (unless the clone is `~/dotfiles` itself) and
   `~/.zshrc` to this repo, installs Homebrew in
   `/opt/homebrew` and Homebrew's zsh, and makes Homebrew's zsh your login shell (asks for
   your password once, for `/etc/shells` and `chsh`). An existing real `~/.zshrc` is kept as
   `~/.zshrc.backup`.
2. **`setup_dotfiles`** (a zsh function from `zsh/.functions`) does the rest. The first time, it asks for
   the Mac's name and whether it's home-like or work-like, see [Several Macs](#several-macs). Every step is
   idempotent, so rerun it after pulling changes. A step that fails doesn't stop the others; the failed ones
   are listed at the end, to fix and run again on their own.

On a new Mac, follow [A new Mac](#a-new-mac): a few steps around these two can't be scripted.

Both only ever use the native arm64 Homebrew in `/opt/homebrew`. A Homebrew in `/usr/local` on an Apple
silicon Mac is a leftover Intel install running under Rosetta and is deliberately ignored.

What `setup_dotfiles` does
---
Each step is a function you can also run on its own:

| Function | Does |
|---|---|
| `setup_machine [<name> <home\|work>]` | this Mac's own settings in `~/.config/dotfiles`: asks for its name and kind once, creates the local files that are missing (see [below](#several-macs)), links `~/dotfiles` |
| `brew_setup` | `brew bundle` with the [Brewfile](../Brewfile), then `fix_completion_dirs`: makes the completion directories under `/opt/homebrew` that zsh calls insecure writable only by you, since an install can leave one group-writable |
| `fzf_setup` | links `~/.fzf.zsh` |
| `setup_atuin` | links `~/.atuin/config.toml`, imports the zsh history the first time |
| `npm_setup` | installs the latest node LTS with fnm, makes it the default, installs global `typescript` |
| `setup_python` | installs the latest python with uv as `python` / `python3` in `~/.local/bin` |
| `setup_ssh` | includes `config/ssh/config` from `~/.ssh/config`, removes the old keychain login item (see [git](git.md#ssh-keys)) |
| `setup_git` | links `~/.gitconfig` and the global gitignore `~/.config/git/ignore` |
| `setup_tmux` | links `~/.config/tmux`, installs tpm and the tmux plugins |
| `setup_nvim` | links `~/.config/nvim`, makes `vim` run nvim, installs the plugin versions pinned in `lazy-lock.json`; fails when nvim reports an error on start, such as a broken config |
| `setup_ghostty` | links the Ghostty config and themes |
| `setup_claude` | links Claude Code's `settings.json`, global `CLAUDE.md`, hooks, status line and each skill into `~/.claude` (see [claude-code](claude-code.md#config)) |
| `remap_keys` | Caps Lock → Ctrl, now and at every login (a LaunchAgent) |
| `setup_macos_defaults` | fastest key repeat; a held key repeats in Ghostty instead of offering accents (log out and in, restart Ghostty) |
| `setup_vscode` | links VS Code's `settings.json`, installs the extensions in `config/vscode/extensions.txt` that are missing (see [debugging](debugging.md)) |
| `setup_ideavim` | links `~/.ideavimrc`, installs the IdeaVim and AceJump plugins into Android Studio when missing (see [vim-keys](vim-keys.md)) |
| `setup_window_management` | links the AeroSpace config and starts it, groups Mission Control by app, ctrl+cmd-drag moves windows (see [window-management](window-management.md)) |

Not part of `setup_dotfiles`:

- `setup_touch_id_sudo`: `sudo` accepts Touch ID, inside tmux too (pam-reattach). It writes
  `/etc/pam.d/sudo_local`, which survives macOS updates, and asks for your password to do so.

Several Macs
---
The repo holds what every Mac shares, and every Mac gets all of it. What only one Mac needs lives in `~/.config/dotfiles`, outside the
repo, so a work email, work plugins or a company's tools never end up in it. `setup_machine` creates these
files from the templates in `config/machine` when they are missing and never overwrites them:

| File | Used by | For |
|---|---|---|
| `name` | `secretive_key` | what the Mac is called, e.g. `home-m5`; its keys show up on GitHub under this name |
| `kind` | the Brewfile | `home` or `work`, whether the Mac is home-like or work-like. Packages in an `if kind == "home"` (or `"work"`) block install only on that kind: Tunnelblick only on home-like Macs |
| `gitconfig` | `~/.gitconfig`, included last | the work email in work repos, see [git](git.md#identity) |
| `zshrc` | `~/.zshrc`, sourced last | exports, aliases and tokens only this Mac needs |
| `Brewfile` | the repo's Brewfile, read at its end | packages only this Mac needs |
| `claude.json` | the `claude` wrapper, as `--settings` | Claude Code plugins and settings only this Mac uses, see [claude-code](claude-code.md#this-machine) |

Hosts only one Mac connects to go in `~/.ssh/config` itself, below the line that includes the shared
`config/ssh/config`. Rename the Mac or change its kind with `setup_machine <name> <home|work>`.

Symlinks
---
The repo is never copied: everything is linked, so editing a file in the repo takes effect immediately
(after reloading the tool).

| In `$HOME` | Points to |
|---|---|
| `~/dotfiles` | the repo, wherever it's cloned (`~/.ssh/config` and `~/.gitconfig` use this path) |
| `~/.zshrc` | `.zshrc` |
| `~/.fzf.zsh` | `.fzf.zsh` |
| `~/.atuin/config.toml` | `config/atuin/config.toml` |
| `~/.gitconfig` | `config/git/.gitconfig` |
| `~/.config/git/ignore` | `config/git/ignore` |
| `~/.config/tmux/` | `config/tmux/` |
| `~/.config/nvim/` | `config/nvim/` |
| `~/.config/ghostty/config`, `~/.config/ghostty/themes/` | `config/ghostty/…` |
| `~/.config/aerospace/aerospace.toml` | `config/aerospace/aerospace.toml` |
| `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/hooks/`, `~/.claude/statusline.sh` | `config/claude/…` |
| `~/.claude/skills/<name>/` | each skill in `config/claude/skills/`; `~/.claude/skills` itself stays a real directory |
| `~/.ideavimrc` | `config/ideavim/ideavimrc` |
| `~/Library/Application Support/Code/User/settings.json` | `config/vscode/settings.json` |
| `~/bin/vim` | `/opt/homebrew/bin/nvim` |

`.zshrc` finds the repo by resolving its own symlink, so the clone can live anywhere.

Data that is *not* in the repo: tmux plugins (`~/.tmux/plugins`), nvim plugins and language servers
(`~/.local/share/nvim`), shell history (`~/.zsh_history`, atuin's `~/.atuin`), cached tool setup
(`~/.cache/zsh`), node versions (fnm), python versions (uv, `~/.local/share/uv`).

The Brewfile
---
Grouped by why a package is there: tools these dotfiles depend on (each commented with the file that uses
it), everyday CLI tools, GUI apps (casks), apps for one kind of Mac only, this Mac's own list from
`~/.config/dotfiles/Brewfile`, and a commented-out review list of things from an older Mac.
Add a package by adding a line and rerunning `brew_setup`. `brew bundle check --verbose` shows what is
missing; `brew bundle cleanup` shows what is installed but not listed.

A new Mac
---
In this order; the steps that aren't scripted can't be, or shouldn't be.

1. **Clone over HTTPS**: `git clone https://github.com/makst/dotfiles.git ~/repos/dotfiles`. SSH needs the
   keys from step 4 first. The first `git` on a new Mac offers to install Apple's command line tools: accept.
2. **`./prepare-zsh-install.sh`**, then `exec zsh` and **`setup_dotfiles`** (name and kind of the Mac). On a
   managed work Mac, a step MDM blocks shows up in the list of failed steps at the end. A failed `brew_setup`
   often means MDM already installed one of the apps: remove that line on this Mac, or hand the app to
   Homebrew with `brew install --cask --adopt <cask>`.
3. **Accessibility** (System Settings → Privacy & Security → Accessibility): Ghostty, for the global
   drop-down terminal; AeroSpace, which asks on its first start.
4. **SSH keys**, on every Mac, since Secure Enclave keys can't leave the Mac they were made on. Until then
   commits aren't signed and ssh to GitHub doesn't work. Open Secretive and let it start its agent at login,
   create the keys `push` (Require Authentication on) and `signing` (off), open a new shell (so
   `SSH_AUTH_SOCK` points at Secretive), `gh auth login`, then `secretive_key push` and
   `secretive_key signing`, see [git](git.md#ssh-keys). The signing key turns on signing for this Mac and is
   added to `config/git/allowed_signers`: commit that. Then switch the clone to SSH:
   `git remote set-url origin git@github.com:makst/dotfiles.git`. So every Mac has its own pair of keys, listed
   on GitHub under the Mac's name (see [One set of keys per Mac](git.md#one-set-of-keys-per-mac)).
5. **What only this Mac needs**, in `~/.config/dotfiles` (see [Several Macs](#several-macs)): on a work Mac
   the work email in `gitconfig` (and add it to your GitHub account under Settings → Emails, so work commits
   count as yours and show as Verified), work plugins in `claude.json`, work hosts in `~/.ssh/config` below
   the include line.
6. **Optional**: `setup_touch_id_sudo` (Touch ID for `sudo`, asks for your password once). Secrets in
   `zsh/.private` or `~/.config/dotfiles/zshrc`, nvim settings in `config/nvim/lua/user/hidden/init.lua`;
   none of them is in git, each is loaded if it exists.
   For iOS work, Xcode from the App Store, then `sudo xcode-select -s /Applications/Xcode.app`; for Android
   work, open Android Studio once so it installs the SDK. See [iOS](mobile.md#ios) and
   [Android](mobile.md#android).

For a fork, change the identity first: name and email in `config/git/.gitconfig`, the keys in
`config/git/allowed_signers`, the repo URL above.

After editing the tmux plugin list: `C-a I` inside tmux.

Retiring a Mac
---
When a Mac is sold, wiped, handed back or lost, stop trusting its keys. On another Mac:

1. **`mac_keys`** lists every Mac's keys on GitHub and in `config/git/allowed_signers`; find its name.
2. **`retire_mac <name>`** shows what it will do and asks first. It deletes the Mac's push and signing keys
   on GitHub and marks its signing key in `allowed_signers` as valid only until now, so the commits it signed
   still show as verified. Commit `allowed_signers`.
3. **By hand**, as `retire_mac` lists them: its key on GitLab, its key in any server's
   `~/.ssh/authorized_keys`, and tokens made only for that Mac (revoke them where they were made).
4. **If you still have the Mac**: sign out of GitHub (`gh auth logout`) and delete its keys in Secretive
   before wiping it.

Staying up to date
---
```sh
git pull && setup_dotfiles
```

That installs and upgrades brew packages (the zsh plugins are among them), installs newly listed tmux plugins and
restores nvim plugins to the versions in `lazy-lock.json`. Updating tmux plugins (`C-a U`) and nvim plugins
are deliberate steps, see [tmux](tmux.md#plugins) and [neovim](neovim.md#plugins).

Checks
---
```sh
check_dotfiles
```

Runs the checks in `checks/` before a commit, in about half a second. Each check prints what it found wrong
and `check_dotfiles` returns 1 if any fails; `check_dotfiles -v` also lists every check with `ok`, `FAILED` or
`skip` and its time. A check whose tool isn't installed (Ghostty, AeroSpace, starship, nvim, tmux, yq,
shellcheck, Python 3.11 for TOML) is skipped and says why. GitHub runs `checks/check_dotfiles -v` on every
push and pull request on a macOS runner (`.github/workflows/check.yml`), so the run's log shows each check,
and a red check there means the same as a red check here. Before the checks, CI runs `fix_completion_dirs`
as `brew_setup` does on a Mac: the runner's Homebrew leaves group-writable directories, and zsh would stop to
ask about them.

| Group | File | What it checks |
|---|---|---|
| Syntax | `checks/syntax.zsh` | every zsh, bash, JSON, TOML, YAML and Lua file parses; tmux.conf, gitconfig, ssh config, Brewfile, Ghostty, starship and AeroSpace configs load in their own tool |
| Behaviour | `checks/behaviour.zsh` | zsh starts without errors; Claude Code's hooks (recursive `rm`, format, bell) and status line do what they should, with only zsh, jq, git and gh on PATH |
| References | `checks/references.zsh` | Markdown links and anchors, paths, setup links, function and alias names in the docs, nvim's requires and Claude Code's hook commands all exist |
| Consistency | `checks/consistency.zsh` | setup steps and symlinks match this page; the README links every doc; plugins are pinned; GIFs have tapes; `docs/vim-keys.md` matches nvim, VS Code and IdeaVim; each layer keeps to its modifier |

`checks/lib.zsh` builds what the groups share; the groups then run at the same time. The recursive `rm`
cases are in `checks/rm-hook.cases`, one per line: `block` or `allow`, then the command.

Other helpers
---
- `mac_keys` lists which keys belong to which Mac; `retire_mac <name>` revokes one Mac's keys (see
  [Retiring a Mac](#retiring-a-mac)).
- `timezsh` benchmarks the shell start with hyperfine: check after adding plugins.
