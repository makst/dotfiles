zsh
===

Homebrew's zsh is the login shell, without a framework: four plugins from Homebrew, vi keys on the command
line, a starship prompt, atuin for history and zoxide for jumping between directories. A new shell is
ready in about 70 ms (220 ms with Oh My Zsh), a third of which is zsh-vi-mode.

How it loads
---
`~/.zshrc` is a link into the repo. It finds the repo through that link and sources, in order:

| File | Contains |
|---|---|
| `zsh/.exports` | `PATH` (Homebrew, `~/bin`, `~/.local/bin`), fnm, pager and colour settings |
| `zsh/.zshdefault` | options, history, completion, plugins, prompt, zoxide |
| `zsh/.aliases` | aliases |
| `zsh/.kubectl_aliases` | generated kubectl aliases |
| `zsh/.functions` | shell functions, including the whole install (`setup_dotfiles`) |
| `zsh/.private` | gitignored: tokens and machine-specific settings, if the file exists |

Put new things in the file that matches; put anything secret in `.private`.

Plugins
---
Four Homebrew formulae (so `brew upgrade` updates them), sourced from `$HOMEBREW_PREFIX/share` in an order
that matters:

| Plugin | Gives you |
|---|---|
| fzf-tab | `Tab` completion through fzf, see [fzf](fzf.md#completion-fzf-tab) |
| zsh-vi-mode | vi modes on the command line |
| zsh-autosuggestions | grey suggestion from history as you type; `→` or `End` accepts it |
| fast-syntax-highlighting | commands coloured as you type, red when they don't exist; loads last |

Completion matches case-insensitively and inside words, and `cd -<Tab>` picks from the directories
visited in this shell. Typing a directory name alone `cd`s into it.

Start-up speed
---
- **No framework.** Oh My Zsh cost more than everything else together (its update check alone ~30 ms).
- **Tool setup is cached.** `starship init`, `zoxide init`, `fzf --zsh`, `atuin init`, `navi widget`,
  vivid's colours and lesspipe print shell code; `cached_eval` (in `.zshrc`) keeps that output in
  `~/.cache/zsh` and only reruns the tool when it was upgraded. fnm is the exception: it makes a link per
  shell. Homebrew's environment is written out instead of running `brew shellenv`.
- **Completion** is initialised from a dump in `~/.cache/zsh`, rebuilt and security-checked once a day.
  If zsh ever says *insecure directories*, run `compaudit` and `chmod g-w` what it lists.

atuin would also take over the grey suggestions, starting itself on every key press; they stay on zsh's
own history instead.

`timezsh` measures the start with hyperfine; check it after adding anything.

Vi mode
---
The command line starts in insert mode. `jj` switches to normal mode, where the usual vim motions,
operators and text objects work, `v` selects, and `vv` opens the command line in nvim to edit it there. The
cursor is a bar in insert mode and a block in normal mode.

| Key | Mode | Action |
|---|---|---|
| `↑` / `↓` | both | previous / next history entry *starting with what you've typed* |
| `C-k` / `C-j` | normal | the same, on the home row (outside tmux; inside tmux these keys move between panes) |
| `C-r` | insert | history search (atuin) |

zsh-vi-mode resets key bindings when it starts, so it's started while it loads (`ZVM_INIT_MODE=sourcing`)
and fzf's, navi's and atuin's widgets are loaded after it. Add other key bindings after it too, or they'll
silently disappear.

History
---
`~/.zsh_history` keeps 100 000 commands with timestamps, shared between all open shells, with duplicates
removed (only the latest copy of a repeated command is kept). A command typed with a leading space isn't
saved.

[atuin](https://atuin.sh) keeps a second copy in SQLite with the directory, exit code and duration of each
command, and owns `C-r` (`/` in normal mode):

- Type to search; `C-r` again cycles the filter: everywhere, this Mac, this session, this git repo, this
  directory.
- `Enter` or `Tab` puts the command on the command line, ready to edit or run.
- `atuin stats` shows your most used commands; `atuin search --exit 0 --cwd . <text>` searches from scripts.

Config: `config/atuin/config.toml` (linked to `~/.atuin/config.toml`). History stays on this Mac: sync
needs an account (`atuin register`) and is off, and atuin's AI key (`?`) isn't bound.

Prompt (starship)
---
Config: `config/starship.toml`, found through `STARSHIP_CONFIG`.

Two lines: context on the first, your input on the second after a `❯` that turns red when the last
command failed and flips to `❮` in vi normal mode. The first line shows the directory (shortened to the
repo root), git branch, state and status, and only where relevant: kubernetes context and namespace, AWS
profile, node / python / go version in projects of that language, terraform workspace, how long the last
command took (over 2 s) and background jobs.

All colours are ANSI names, so the prompt follows the [theme](theme.md).

Navigation
---
zoxide learns the directories you visit:

- `z foo` jumps to the most frecent directory matching `foo` (`z foo bar` for both words).
- `zi foo` picks among matches with fzf.
- `Alt+C` (fzf) changes into any subdirectory.

The same zoxide list feeds the tmux session picker (`cmd+k`), so projects you `z` into become sessions
you can open with two keystrokes.

Language versions
---
- **node**: fnm. Entering a directory with `.nvmrc`, `.node-version` or a `package.json` `engines` field
  switches to that version (in subdirectories too); otherwise the default version is used. The default
  is on `PATH` everywhere, including for nvim's language servers. `fnm install <v>`, `fnm default <v>`.
- **python**: [uv](https://docs.astral.sh/uv/). `python` / `python3` are the latest version (from
  `setup_python`); in a project, `uv init`, `uv add <pkg>`, `uv run <script>` manage the virtualenv and
  `uv python pin <v>` its version. `uv tool install <pkg>` installs a CLI tool, `uvx <pkg>` runs one once.
- **go**: from Homebrew.

Aliases and functions worth knowing
---
| Command | Does |
|---|---|
| `ll`, `la` (`l`), `lt` | eza: long listing with git status and icons; with hidden files; tree two levels deep |
| `lg` | lazygit |
| `tm` | tmux session picker |
| `agent <name> [prompt]` | Claude Code in a worktree and its own tmux window, see [claude-code](claude-code.md) |
| `fif <text>` | files containing the text, with a preview of the matches |
| `change_theme` | pick a base16 scheme for nvim and Ghostty, see [theme](theme.md) |
| `docker` | podman (Docker Desktop isn't installed) |
| `k`, `kgpo`, `kdp`, … | kubectl aliases from [kubectl-aliases](https://github.com/ahmetb/kubectl-aliases): `k` + verb + resource + flags |
| `copy_last_cmd` | copy the previous command to the clipboard |
| `sn` / `sp` | Spotify next / previous track |
| `timezsh` | benchmark shell start-up (hyperfine) |

`vim` runs nvim everywhere (it's a link in `~/bin`), including as git's editor.

Pager and colours
---
`less` keeps colours and, through lesspipe, shows the contents of archives and other binary formats.
`bat` and the file colours for eza, fzf-tab and completion (`LS_COLORS`, generated by vivid) use the
terminal palette, so they follow the [theme](theme.md).
