Setup and maintenance
===

The setup runs in two stages, because the second needs zsh and Homebrew to exist first.

1. **`prepare-zsh-install.sh`** (bash) links `~/dotfiles` (unless the clone is `~/dotfiles` itself) and
   `~/.zshrc` to this repo, installs Homebrew in
   `/opt/homebrew` and Homebrew's zsh, and makes Homebrew's zsh your login shell (asks for
   your password once, for `/etc/shells` and `chsh`). An existing real `~/.zshrc` is kept as
   `~/.zshrc.backup`.
2. **`setup_dotfiles`** (a zsh function from `zsh/functions/setup.zsh`) does the rest. The first time, it asks for
   the Mac's name and whether it's home-like or work-like, see [Several Macs](#several-macs). Every step is
   idempotent, so rerun it after pulling changes. A step that fails doesn't stop the others; the failed ones
   are listed at the end, to fix and run again on their own.

What it is
---
- **Two stages**, above; every step of the second is idempotent, so rerun it after pulling changes.
- **Links, not copies**: everything is linked, so editing a file in the repo takes effect immediately (after
  reloading the tool: `reload_dotfiles`, see [Staying up to date](#staying-up-to-date)). `.zshrc` finds the
  repo by resolving its own symlink, so the clone can live anywhere. All the links are in
  [Symlinks](#symlinks).
- **Several Macs**: the repo holds what every Mac shares, and every Mac gets all of it. What only one Mac needs
  lives in `~/.config/dotfiles`, outside the repo, so a work email, work plugins or a company's tools never
  end up in it ([Several Macs](#several-macs)).
- **Data that is *not* in the repo**: tmux plugins (`~/.tmux/plugins`), nvim plugins and language servers
  (`~/.local/share/nvim`), shell history (`~/.zsh_history`, atuin's `~/.atuin`), cached tool setup
  (`~/.cache/zsh`), node versions (fnm), python versions (uv, `~/.local/share/uv`), podman's VM
  (`~/.local/share/containers`).

A new Mac
---
In this order; the steps that aren't scripted can't be, or shouldn't be.

1. **Clone over HTTPS**: `git clone https://github.com/makst/dotfiles.git ~/repos/dotfiles`. SSH needs the
   keys from step 4 first. The first `git` on a new Mac offers to install Apple's command line tools: accept.
2. **`./prepare-zsh-install.sh`**, then `exec zsh` and **`setup_dotfiles`** (name and kind of the Mac). On a
   managed work Mac, a step MDM blocks shows up in the list of failed steps at the end. A failed `setup_brew`
   often means MDM already installed one of the apps: remove that line on this Mac, or hand the app to
   Homebrew with `brew install --cask --adopt <cask>`.
3. **Accessibility** (System Settings → Privacy & Security → Accessibility): Ghostty, for the global
   drop-down terminal; AeroSpace, which asks on its first start. If 1Password is installed, move its Quick
   Access shortcut off `cmd+shift+space` (1Password → Settings → General, e.g. to `cmd+shift+\`): Ghostty uses
   that key for the next agent that needs you ([claude-code](claude-code.md#noticing-an-agent-that-waits)).
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
   the include line, and the company's name, email domain and hosts in `forbidden`.
6. **`check_mac`** lists anything still missing, each with the step that makes it.
7. **Optional**: `setup_touch_id_sudo` (Touch ID for `sudo`, asks for your password once). Secrets in
   `zsh/.private` or `~/.config/dotfiles/zshrc`, nvim settings in `config/nvim/lua/user/hidden/init.lua`;
   none of them is in git, each is loaded if it exists.
   For iOS work, Xcode from the App Store, then `sudo xcode-select -s /Applications/Xcode.app`; for Android
   work, open Android Studio once so it installs the SDK. See [iOS](mobile.md#ios) and
   [Android](mobile.md#android).

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
are deliberate steps, see [tmux](tmux.md#updating-plugins) and [neovim](neovim.md#updating-plugins).

A pull puts the new config on disk at once, through the links, but the programs already running keep what they
started with: tmux, Ghostty and AeroSpace their config (a new tmux key does nothing yet), tmux's popups the
environment of the shell that started the server, open shells and nvim theirs. So after a pull, a rebase or a
branch switch in this checkout, git's hooks in `.githooks` (turned on by `setup_git`) run `reload_dotfiles`:

```text
dotfiles: reloaded tmux, Ghostty
dotfiles: still to do
  - zsh: `exec zsh` in the shells that are open
  - Brewfile: `setup_brew` installs what it added
```

It reloads only what changed and is running: tmux's config, Ghostty's (from Ghostty 1.2; older ones are told
to reload with `cmd+shift+,`) and AeroSpace's. What it can't do for you it lists: open shells, nvim and its
plugins (`:Lazy restore`), Android Studio's IdeaVim, new Brewfile packages, and new links (`setup_dotfiles`).
New Claude Code skills need nothing: the `claude` wrapper links them when it starts.
It prints nothing when nothing it knows about changed, and nothing in other clones or agents' worktrees, which
aren't the live setup. `reload_dotfiles` on its own reloads all three, whatever changed.

### Is this Mac up to date?
```sh
check_mac
```

`check_dotfiles` checks the repo; `check_mac` checks the Mac it runs on against the repo, after a pull or on
a Mac that hasn't been used for a while. It changes nothing and prints each problem with the step that fixes
it:

```text
check_mac: 2 problems, each with what fixes it:
  - ~/.config/ghostty/themes isn't a link to config/ghostty/themes: setup_ghostty
  - nvim plugins not at lazy-lock.json's version (flash.nvim): setup_nvim
```

| Checks | Fixed by |
|---|---|
| every link in [Symlinks](#symlinks) points into this clone | the setup step that makes it |
| the files in `~/.config/dotfiles` exist, `kind` is `home` or `work`, `claude.json` and `gitconfig` parse | `setup_machine`, or by hand |
| `brew bundle check`: every Brewfile package is installed | `setup_brew` |
| nvim's plugins are at the commits in `lazy-lock.json`, tmux's plugins are installed | `setup_nvim`, `setup_tmux` |
| fnm's default node has typescript, `~/.local/bin/python` exists, VS Code has the extensions | `setup_node`, `setup_python`, `setup_vscode` |
| where gcloud is installed, it has `gke-gcloud-auth-plugin` | `setup_gcloud` |
| where the Mac can run a VM, podman has one and no connection to one that's gone | `setup_podman` |
| `~/.npm` has no files of another user (root's, from an npm run with `sudo`), which make npm fail with EPERM | `sudo chown -R $(id -u) ~/.npm` |
| the repo's git hooks are on, `~/.ssh/config` includes the shared one, the login shell is Homebrew's zsh | `setup_git`, `setup_ssh`, `prepare-zsh-install.sh` |
| a new zsh and nvim start without printing errors | the error says |
| Secretive's agent runs, commits are signed with a key in `config/git/allowed_signers` | [A new Mac](#a-new-mac), step 4 |
| gh's login is valid; npm accepts each registry token in `~/.npmrc` (not from Claude Code's sandbox, where every login looks invalid) | `gh auth refresh`; `npm_gh_token` for GitHub's registry, the registry's own login for others |
| the GitHub watcher is loaded and its last run worked | `setup_github`; the error says ([github](github.md#to-look-out-for)) |

Adding a package
---
Add a package by adding a line and rerunning `setup_brew`. `brew bundle check --verbose` shows what is
missing; `brew bundle cleanup` shows what is installed but not listed. See [The Brewfile](#the-brewfile)
for where it goes.

Checks
---
```sh
check_dotfiles
```

Runs the checks in `checks/` before a commit, in about a second. Each check prints what it found wrong and
`check_dotfiles` returns 1 if any fails; `check_dotfiles -v` also lists every check with `ok`, `FAILED`,
`warn` or `skip` and its time. The checks that only compare the docs or a convention with the config (setup
tables, README links, GIFs and their toggles, the names the docs mention, nvim key descs, the style group)
`warn`: their problems are printed in yellow, but they don't fail the run, on a Mac or on CI. A stale doc
table is worth fixing, but it doesn't break the setup. A check whose tool isn't installed (Ghostty, AeroSpace,
starship, nvim, tmux, yq, shellcheck, Python 3.11 for TOML) is skipped and says why. Claude Code runs them
outside its sandbox (this repo's `.claude/settings.json`), since the tmux checks need a socket; a command line
with anything else on it, such as `checks/check_dotfiles | tail`, stays in the sandbox, where those two are
skipped. GitHub runs `checks/check_dotfiles -v` on every push and pull request on a macOS runner
(`.github/workflows/check.yml`), so the run's log shows each check, and a red check there means the same as a
red check here. Before the checks, CI runs `fix_completion_dirs` as `setup_brew` does on a Mac: the runner's
Homebrew leaves group-writable directories, and zsh would stop to ask about them.

| Group | File | What it checks |
|---|---|---|
| Syntax | `checks/syntax.zsh` | every zsh, bash, JSON, TOML, YAML and Lua file parses; tmux.conf, gitconfig, ssh config, Brewfile, Ghostty, starship and AeroSpace configs load in their own tool |
| Behaviour | `checks/behaviour.zsh` | zsh starts without errors, and its functions find the repo in a shell that hasn't read `.zshrc` (Claude Code's); Claude Code's hooks (deletes that can't be undone, format, bell) and status line do what they should, with only zsh, jq, git and gh on PATH |
| References | `checks/references.zsh` | Markdown links and anchors, paths, setup links, function and alias names in the docs, nvim's requires and Claude Code's hook commands all exist |
| Consistency | `checks/consistency.zsh` | setup steps and symlinks match this page; the README links every doc; plugins are pinned; every nvim key has a desc and is bound in a `keymaps.lua`; GIFs have tapes; `docs/vim-keys.md` matches nvim, VS Code and IdeaVim and has every TUI the Brewfile marks; each layer keeps to its modifier |
| Portability | `checks/portability.zsh` | nothing belongs to one Mac: no path into a user's home (`/Users/<name>/…`), nothing names this Mac (its hostname or `setup_machine` name, except in `allowed_signers`) or a word in its `~/.config/dotfiles/forbidden`; commits not yet pushed use the email of `config/git/.gitconfig` and their messages name neither |
| Safety | `checks/safety.zsh` | nothing published can hurt: no token or private key (it says which kind, never the secret), no email address but GitHub's noreply ones, `git@github.com` and made-up ones (`example.com`, `.local`, …), `zsh/.private` and nvim's `hidden/` ignored and untracked, `config/claude` names no machine path and nothing of this repo, no code reaches for `/usr/local`, x86_64 or Rosetta, and none deletes for good (`rm -r`, `find -delete`, `git clean -f`) |
| Commits | `checks/commits.zsh` | the commits a push would publish (on CI, those the push brought): a `type(scope): summary` subject, a body besides the trailers, no "Generated with" line, signed with a key in `config/git/allowed_signers` |
| Style | `checks/style.zsh` | warnings only, the conventions of `CLAUDE.md`: each Brewfile package has a comment saying what uses it, colours are ANSI names (hex only in Ghostty's theme), GIFs sit in a closed `Show GIF` toggle with a caption, each zsh function has a comment, no zsh file runs `fzf` itself instead of `picker`, each `docs/<tool>.md` has its top-level sections in the order of `docs/design.md`, "Same shape, every page", and each config or script file starts with a comment saying who uses it (nvim's `init.lua`, JSON and Markdown excepted), prose in Markdown and zsh comments stays within about 110 columns (over 115 warns; tables, code, images and URLs excepted), table rows have as many cells as their header, `$(…)` inside `${…}` is quoted, scripts are zsh (bash only for `prepare-zsh-install.sh`), and a file is executable exactly when it has a `#!` line (the sourced `.zsh` files excepted) |

`checks/lib.zsh` builds what the groups share; the groups then run at the same time. A zsh error inside a
check stops the rest of its group: that fails as "stopped in" the check, with the error, and the checks after
it in the group don't run. The recursive `rm`
cases are in `checks/rm-hook.cases`, one per line: `block` or `allow`, then the command.

### Testing the checks
```sh
checks/mutate              # every break, about 45 seconds
checks/mutate starship     # only the breaks whose description or check matches
```

A check that stays green on a broken repo is worse than none, so `checks/mutate` breaks the repo on purpose,
one thing at a time (a key set twice, a hook that allows everything, a doc page the README doesn't link), in a
throwaway git worktree, and runs `check_dotfiles` there. Each break names the check that has to fail (or warn):

| Result | Means |
|---|---|
| `caught` | that check failed or warned; any other check that failed too is shown dimmed |
| `MISSED` | that check stayed green: the check has a hole |
| `BROKEN` | the break changed nothing, because the file it edits has changed: update the break |

It exits 1 on a `MISSED` or `BROKEN`. The worktree has the repo as it is now, uncommitted changes and new
files included (`checks/snapshot`). It takes too long for every commit, so it isn't part of
`check_dotfiles` or CI, and it isn't a step of every change either: run it when a check looks like it lets
something through, or after reworking one. A new check doesn't need a break of its own; add one when a check
has let a real mistake through, so it stays caught: a line `m '<check label>' '<what breaks>' '<zsh code that
breaks it>'` in `checks/mutate`. The AeroSpace check has none, since it only validates the live config. The
breaks name files and functions that don't exist on purpose, so the path and name checks leave
`checks/mutate` out. The portability breaks use a list of forbidden words of their own (`DOTFILES_FORBIDDEN`),
not this Mac's.

### Rehearsing a new Mac
```sh
checks/fresh_mac           # a home-like and a work-like Mac, a few minutes
checks/fresh_mac work      # one kind
```

`check_dotfiles` reads the repo, and `check_mac` looks at a Mac that has been set up for a while, where an
old file or an installed tool can hide what a new Mac would miss. `checks/fresh_mac` sets up a new Mac of
each kind from nothing: in an empty HOME and a bare environment, as at a first login, it clones the repo as
it is now (uncommitted changes and new files included), runs `prepare-zsh-install.sh`,
`setup_machine fresh-<kind> <kind>` and `setup_dotfiles`, then `check_mac --scripted` (everything but the
steps done by hand: Secretive and signing). It prints the failed steps and problems and exits 1 on any,
keeping that HOME and its `setup.log` to look into; when all pass, the HOME goes to the Trash.

On a Mac in use, what would reach outside that HOME is stood in for, and each stand-in logs its call to the
HOME's `stood-in.log`: `brew bundle` only loads the Brewfile (so a work Mac's packages don't land on a home
Mac), and `defaults write`, `killall`, `open`, `hidutil`, `launchctl` and Android Studio's `studio` do
nothing, and `podman machine` only remembers an `init`, so no second VM is made. nvim, tmux and VS Code
plugins, node and python install for real into the HOME, so it needs the network. On GitHub
(`.github/workflows/fresh-mac.yml`, every Monday and by hand under Actions → fresh-mac → Run workflow)
nothing is stood in for: each kind gets a fresh macOS runner and `brew bundle` installs every package.
Its runners can't run a VM, so there `setup_podman` only makes the link. The runner's own copies of apps the
Brewfile installs (Google Chrome) are moved away first, since a new Mac doesn't have them.

Run it after changing a setup step or the order of `setup_dotfiles`.

Commands
---
### Other helpers

- `mac_keys` lists which keys belong to which Mac; `retire_mac <name>` revokes one Mac's keys (see
  [Retiring a Mac](#retiring-a-mac)).
- `timezsh` benchmarks the shell start with hyperfine: check after adding plugins.
- `check_mac` checks this Mac against the repo, see [Is this Mac up to date?](#is-this-mac-up-to-date).
- `reload_dotfiles` reloads tmux, Ghostty and AeroSpace, see [Staying up to date](#staying-up-to-date).

### What `setup_dotfiles` does

Each step is a function you can also run on its own.

| Function | Does |
|---|---|
| `setup_machine [<name> <home\|work>]` | this Mac's own settings in `~/.config/dotfiles`: asks for its name and kind once, creates the local files that are missing (see [below](#several-macs)), links `~/dotfiles` |
| `setup_brew` | `brew bundle` with the [Brewfile](../Brewfile), then `fix_completion_dirs`: makes the completion directories under `/opt/homebrew` that zsh calls insecure writable only by you, since an install can leave one group-writable |
| `setup_gcloud` | where gcloud is installed (work Macs), adds its `gke-gcloud-auth-plugin` component, which kubectl needs to log in to GKE (see [gcloud](gcloud.md#config)) |
| `setup_podman` | links `~/bin/docker` to podman, makes podman's VM if it's missing and starts it, removes connections to a VM that's gone (see [podman](podman.md)) |
| `setup_fzf` | links `~/.fzf.zsh` |
| `setup_atuin` | links `~/.atuin/config.toml`, imports the zsh history the first time, if there is one |
| `setup_btop` | links `~/.config/btop/btop.conf` |
| `setup_readline` | links `~/.inputrc` and `~/.editrc`: vi mode in REPLs (see [vim-keys](vim-keys.md#config)) |
| `setup_node` | installs the latest node LTS with fnm, makes it the default, installs global `typescript` into it |
| `setup_python` | installs the latest python with uv as `python` / `python3` in `~/.local/bin` |
| `setup_ssh` | includes `config/ssh/config` from `~/.ssh/config`, removes the old keychain login item (see [git](git.md#ssh-keys)) |
| `setup_git` | links `~/.gitconfig` and the global gitignore `~/.config/git/ignore`, turns on this repo's hooks in `.githooks` (see [Staying up to date](#staying-up-to-date)) |
| `setup_tmux` | links `~/.config/tmux`, installs tpm and the tmux plugins |
| `setup_nvim` | links `~/.config/nvim`, makes `vim` run nvim, installs the plugin versions pinned in `lazy-lock.json` and the treesitter parsers; fails when nvim reports an error on start, such as a broken config |
| `setup_ghostty` | links the Ghostty config and themes |
| `setup_claude` | links Claude Code's `settings.json`, global `CLAUDE.md`, hooks, status line and each skill into `~/.claude` (see [claude-code](claude-code.md#config)) |
| `setup_github` | a LaunchAgent that runs the GitHub watcher every minute: notifications and a tmux mark for your pull requests (see [github](github.md)) |
| `setup_caps_lock` | Caps Lock → Ctrl, now and at every login (a LaunchAgent) |
| `setup_macos_defaults` | fastest key repeat; a held key repeats in Ghostty instead of offering accents (log out and in, restart Ghostty) |
| `setup_vscode` | links VS Code's `settings.json`, installs the extensions in `config/vscode/extensions.txt` that are missing (see [debugging](debugging.md)) |
| `setup_ideavim` | links `~/.ideavimrc`, installs the IdeaVim and AceJump plugins into Android Studio when missing (see [vim-keys](vim-keys.md)) |
| `setup_window_management` | links the AeroSpace config and starts it, groups Mission Control by app, ctrl+cmd-drag moves windows (see [window-management](window-management.md)) |

Not part of `setup_dotfiles`:

- `setup_touch_id_sudo`: `sudo` accepts Touch ID, inside tmux too (pam-reattach). It writes
  `/etc/pam.d/sudo_local`, which survives macOS updates, and asks for your password to do so.

Config
---
### Several Macs

`setup_machine` creates these files from the templates in `config/machine` when they are missing and never
overwrites them:

| File | Used by | For |
|---|---|---|
| `name` | `secretive_key` | what the Mac is called, e.g. `home-m5`; its keys show up on GitHub under this name |
| `kind` | the Brewfile | `home` or `work`, whether the Mac is home-like or work-like. Packages in an `if kind == "home"` (or `"work"`) block install only on that kind: Tunnelblick only on home-like Macs |
| `gitconfig` | `~/.gitconfig`, included last | the work email in work repos, see [git](git.md#identity) |
| `zshrc` | `~/.zshrc`, sourced last | exports, aliases and tokens only this Mac needs |
| `Brewfile` | the repo's Brewfile, read at its end | packages only this Mac needs |
| `claude.json` | the `claude` wrapper, as `--settings` | Claude Code plugins and settings only this Mac uses, see [claude-code](claude-code.md#this-machine) |
| `forbidden` | `check_dotfiles` | words that must never reach the repo from this Mac, one per line: the company, the work email's domain, work hosts. The checks fail on any of them, in any case, in the repo's files and in the messages of commits not yet pushed. The words stay on this Mac, so the list itself can't leak |

Hosts only one Mac connects to go in `~/.ssh/config` itself, below the line that includes the shared
`config/ssh/config`. Rename the Mac or change its kind with `setup_machine <name> <home|work>`.

### Symlinks

| In `$HOME` | Points to |
|---|---|
| `~/dotfiles` | the repo, wherever it's cloned (`~/.ssh/config` and `~/.gitconfig` use this path) |
| `~/.zshrc` | `.zshrc` |
| `~/.fzf.zsh` | `.fzf.zsh` |
| `~/.atuin/config.toml` | `config/atuin/config.toml` |
| `~/.config/btop/btop.conf` | `config/btop/btop.conf` |
| `~/.inputrc`, `~/.editrc` | `config/readline/inputrc`, `config/readline/editrc` |
| `~/.gitconfig` | `config/git/.gitconfig` |
| `~/.config/git/ignore` | `config/git/ignore` |
| `~/.config/tmux/` | `config/tmux/` |
| `~/.config/nvim/` | `config/nvim/` |
| `~/.config/ghostty/config`, `~/.config/ghostty/themes/` | `config/ghostty/…` |
| `~/.config/aerospace/aerospace.toml` | `config/aerospace/aerospace.toml` |
| `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/hooks/`, `~/.claude/statusline.sh` | `config/claude/…` |
| `~/.claude/skills/<name>/` | each skill in `config/claude/skills/`, linked again by `claude` on every start; `~/.claude/skills` itself stays a real directory |
| `~/.ideavimrc` | `config/ideavim/ideavimrc` |
| `~/Library/Application Support/Code/User/settings.json` | `config/vscode/settings.json` |
| `~/bin/vim` | `/opt/homebrew/bin/nvim` |
| `~/bin/docker` | `/opt/homebrew/bin/podman` |

### The Brewfile

Grouped by why a package is there: tools these dotfiles depend on (each commented with the file that uses
it), everyday CLI tools, GUI apps (casks), apps for one kind of Mac only, this Mac's own list from
`~/.config/dotfiles/Brewfile`, and a commented-out review list of things from an older Mac.

To look out for
---
- After editing the tmux plugin list: `C-a I` inside tmux.
- `check_mac` doesn't check the macOS settings the setup makes once (key repeat, Caps Lock, the Dock).
- On a managed work Mac, a step MDM blocks shows up in the list of failed steps at the end of `setup_dotfiles`
  (see [A new Mac](#a-new-mac), step 2).
- For a fork, change the identity first: name and email in `config/git/.gitconfig`, the keys in
  `config/git/allowed_signers`, the repo URL in [A new Mac](#a-new-mac).

Decisions
---
- **Native arm64 only**: the setup only ever uses the Homebrew in `/opt/homebrew`. A Homebrew in `/usr/local`
  on an Apple silicon Mac is a leftover Intel install running under Rosetta and is deliberately ignored.
- **Links, not copies**, so an edit in the repo is the running setup.
- **What one Mac needs stays outside the repo**, in `~/.config/dotfiles`, and so does the list of forbidden
  words, so the list itself can't leak.
- **`checks/mutate` isn't in `check_dotfiles` or CI**: it takes too long for every commit.
