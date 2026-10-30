zsh
===

Homebrew's zsh is the login shell, without a framework: three plugins from Homebrew, vi keys on the command
line, a starship prompt, atuin for history and zoxide for jumping between directories. A new shell is
ready in about 45 ms (220 ms with Oh My Zsh and zsh-vi-mode).

How it loads
---
`~/.zshrc` is a link into the repo. It finds the repo through that link and sources, in order:

| File | Contains |
|---|---|
| `zsh/.exports` | `PATH` (Homebrew, `~/bin`, `~/.local/bin`), fnm, pager and colour settings |
| `zsh/.zshdefault` | options, history, completion, plugins, prompt, zoxide |
| `zsh/.aliases` | aliases |
| `zsh/.functions` | shell functions, including the whole install (`setup_dotfiles`) |
| `zsh/.private` | gitignored: tokens and machine-specific settings, if the file exists |

Put new things in the file that matches; put anything secret in `.private`.

Plugins
---
Three Homebrew formulae (so `brew upgrade` updates them), sourced from `$HOMEBREW_PREFIX/share` in an order
that matters:

| Plugin | Gives you |
|---|---|
| fzf-tab | `Tab` completion through fzf, see [fzf](fzf.md#completion-fzf-tab) |
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
zsh's own vi mode (`bindkey -v`) with a few additions in `zsh/.zshdefault`. The command line starts in insert
mode. `jj` switches to normal mode, where the usual vim motions and operators work (`dw`, `cb`, `yy`, `p`,
`u` / `C-r` undo / redo, `.` repeats, `~` / `gu` / `gU` change case), `v` / `V`
select, and `vv` opens the command line in nvim to edit it there. The cursor is a bar in insert mode and a
block in normal mode.

- **Text objects**: `iw` / `aw` and, for quotes and brackets, `ci"`, `da(`, `yi]`, `ci{`, … (`b` = `()`,
  `B` = `{}`).
- **Surround**, like vim-surround: `cs"'` changes `"…"` to `'…'`, `ds(` removes the parentheses around the
  cursor, `ysiw"` quotes a word, `S"` quotes the visual selection.
- `jj` must be typed within 0.2 s (`KEYTIMEOUT`); a single `j` appears once the next key arrives.

| Key | Mode | Action |
|---|---|---|
| `↑` / `↓` | both | previous / next history entry *starting with what you've typed* |
| `C-k` / `C-j` | normal | the same, on the home row (outside tmux; inside tmux these keys move between panes) |
| `C-r` | insert | history search (atuin) |

`bindkey -v` resets the main keymap, so fzf's, navi's and atuin's widgets are loaded after it. Put new key
bindings after it too.

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
| `k`, `kg`, `kd`, `kgpo`, `klo`, `kex`, … | kubectl: `k` + verb (+ resource), the full list is at the end of `zsh/.aliases` |
| `copy_last_cmd` | copy the previous command to the clipboard |
| `sn` / `sp` | Spotify next / previous track |
| `timezsh` | benchmark shell start-up (hyperfine) |

`vim` runs nvim everywhere (it's a link in `~/bin`), including as git's editor.

Other command-line tools
---
From the Brewfile, worth knowing about:

| Command | Does |
|---|---|
| `gh` | GitHub from the terminal: `gh pr create`, `gh pr checks`, `gh run watch`, `gh pr checkout <n>` |
| `xh` | HTTP requests with httpie's syntax: `xh POST api.example.com name=x`, `xh -d <url>` downloads |
| `btop` | processes, CPU, memory, disks and network |
| `yazi` | file manager with previews; `q` quits, `?` lists keys |
| `tldr <cmd>` | short, practical examples instead of the man page |
| `dust` | what takes the space in a directory tree |
| `hyperfine '<cmd>'` | benchmarks a command, compares several |
| `uv`, `uvx` | python projects and tools, see [above](#language-versions) |

Pager and colours
---
`less` keeps colours and, through lesspipe, shows the contents of archives and other binary formats.
`bat` and the file colours for eza, fzf-tab and completion (`LS_COLORS`, generated by vivid) use the
terminal palette, so they follow the [theme](theme.md).
