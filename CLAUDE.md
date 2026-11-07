# dotfiles

macOS setup for Apple silicon: Ghostty → tmux → zsh / nvim / Claude Code, one base16 colour scheme. The
README has the overview and the repository layout; `docs/<tool>.md` explains each tool.

## What this repo assumes
Apple silicon Mac, native arm64 only: Homebrew in `/opt/homebrew`, no Rosetta, Intel builds or `/usr/local`.
zsh is the shell; the tools come from the `Brewfile` (`rg`, `fd`, `eza`, `bat`, `jq`, `yq`, `gh`, delta,
difftastic, `shellcheck`, `shfmt`, `ast-grep`, …). SSH keys are in Secretive: commits are signed through
`SSH_AUTH_SOCK` without a prompt, pushing asks for Touch ID, so a push waits for the user.

## config/claude is global
`config/claude` becomes `~/.claude` on any machine, so it stays free of anything specific to this Mac, its
tools or this repo: no machine paths, no fonts, no hard dependency beyond zsh, jq, git and gh (anything else,
like a formatter or tmux, is used when present and skipped otherwise). Machine-specific Claude settings go
in the dotfiles (the `claude` wrapper in `zsh/functions/claude.zsh`), repo-specific ones in `.claude/settings.json`
and this file. It also runs next to work projects' own Claude setups: never write into a project, and
format only with what the project configures.

## Several Macs
The repo serves any number of Macs, each with a name and a kind (home-like or work-like). Shared config goes
in the repo and every Mac gets it; what one Mac needs goes in `~/.config/dotfiles` (name, kind, gitconfig,
zshrc, Brewfile, claude.json, forbidden), created from `config/machine` by `setup_machine` and loaded when present.
Nothing in the repo may name a company, work email or work host, nor any one Mac: the portability checks
fail on a path into a home, this Mac's name, a word in `~/.config/dotfiles/forbidden` and an unpushed commit
with another email.

## This is the live setup
`~/.zshrc`, `~/.config/nvim`, `~/.config/tmux`, `~/.gitconfig`, `~/.claude/settings.json` and others are
symlinks into this repo, so an edit here changes the running setup immediately, including this Claude Code
session (`config/claude/settings.json`). Keep the config valid at every step; check JSON with `jq -e .`.

## When changing something
- **Docs move with the config.** Every change updates `docs/<tool>.md` in the same commit: what it does and
  why, keys in tables, in the section `docs/design.md`, "Same shape, every page", gives it (a new page follows
  that order). A new tool or layer also goes in the README table. `docs/setup.md` lists every setup step and
  symlink.
- **Setup steps** are idempotent `setup_<tool>` functions in `zsh/functions/<tool>.zsh` (the Mac-wide ones and
  `setup_dotfiles` in `zsh/functions/setup.zsh`) that link from `config/` with
  `ln -sfn "$real_script_dir/config/…" ~/…`.
- **Brewfile**: one package per line with a comment saying what uses it (the config file, alias or setup
  function). Native arm64 only. Dropped packages stay commented out at the bottom, with the reason when it
  isn't obvious.
- **Learn it once**: every key follows the design principle in `docs/design.md`, "Learn it once": vim is the
  grammar, the key names the action and the modifier the layer, nvim is the reference, one picker. A new tool
  or TUI gets vim keys (by config if its own don't follow) or an entry saying why it can't; a new list to
  choose from goes through `picker` in `config/tmux/picker.zsh`, not a bare `fzf`.
- **One search away**: every file and list follows `docs/design.md`, "One search away": a thing of one kind
  goes in the file named for that kind (nvim: `lua/user/<plugin>/keymaps.lua` for keys, `config.lua` for
  setup), each tool's parts are named for the tool (`config/<tool>/`, `docs/<tool>.md`, `setup_<tool>`), each
  thing is defined once and referred to by file and section, a file's top comment names who uses it, and state
  worth checking opens in the picker with a preview. Say where a change breaks this and why.
- **Key families**: before adding any key or command (navigation, editing, windows, anything), look for the
  family it belongs to, in `docs/design.md`, "Same key, every layer", and in the existing bindings of every
  layer, and reuse it: the same key with the layer's modifier, the same verb for the same action (next,
  previous, last, by number, by direction). Say which family it joins or why none fits, and add it to that
  table. When a layer is missing a family member it could have, point it out.
- **Keys**: each layer owns its modifier (`docs/design.md`, "How the keyboard is split"). Check for clashes
  with tmux, Ghostty, AeroSpace and nvim before binding anything. nvim's keys are the reference for every
  editor: a key added or changed in nvim also goes into VS Code (`config/vscode/settings.json`) and Android
  Studio (`config/ideavim/ideavimrc`) where they have a matching action, and into the table in
  `docs/vim-keys.md`.
- **GIFs** in any Markdown file sit in a `<details>` toggle, closed by default, where they belong on the page.
  The `<summary>` is always `<b>Show GIF</b>`; inside, one short line says what the GIF shows, then the image.
  Format in `docs/gifs.md`, "Adding one".
- **Colours**: ANSI colour names, never hex, so starship, the Claude status line, tmux etc. follow the base16
  theme (`docs/theme.md`).
- **Secrets** never go in the repo: `zsh/.private` and `config/nvim/lua/user/hidden/` are gitignored and
  loaded when present.
- **nvim**: one file or directory per plugin under `config/nvim/lua/user/`; plugin versions are pinned in
  `lazy-lock.json`, commit it with the change.

## Style
- zsh, not bash (except `prepare-zsh-install.sh`): zsh parameter expansion, `(N)` globs, `print -r`. Quote
  `$(…)` inside `${…}`; unquoted, zsh splits it into words.
- A comment above each function: usage line, then what it does and why. Comments and prose in docs wrap at
  about 110 columns; tables may run longer.
- Docs: plain, direct English; say what a thing does for the user, not how clever it is.
- Commits: `type(scope): summary` (feat, fix, refactor, docs, chore; scope = the tool, e.g. `nvim`, `git`,
  `claude`), a body with what and why.

## Testing
- `check_dotfiles` before every commit: the same checks CI runs (`docs/setup.md`, "Checks"). A `warn` doesn't
  block the commit; fix it when it's in what you touched.
- `checks/mutate` is for when a check looks like it lets something through, not a step of every change; a new
  check needs no break of its own (`docs/setup.md`, "Testing the checks").
- After changing a setup step, `checks/fresh_mac` (a few minutes) sets up a new Mac of each kind in a
  throwaway HOME; `check_mac` checks the live one (`docs/setup.md`, "Rehearsing a new Mac").
- `zsh -n <file>` for syntax; `hyperfine -i 'zsh -i -c exit'` for start-up time (~43 ms on an M5,
  ~75 ms on an M1 Max): compare before and after a change on the same Mac; it shouldn't grow.
  `zsh -i -c` prints a harmless fzf "can't change option: zle".
- Interactive zsh, tmux or nvim: a separate tmux server, `tmux -L probe`, driven with `send-keys` and read
  with `capture-pane`. Wrap it in a function (`p() { tmux -L probe "$@" }`), not a variable.
- Headless nvim: `/bin/zsh -i -c 'nvim --headless …'`. `Lazy! install` / `Lazy! clean` change the live
  plugins and `lazy-lock.json`.
- Git helpers: try them in a throwaway clone in the scratchpad, never on this repo's branches.
- Claude Code's sandbox is on (`docs/claude-code.md`, "Sandbox"): Bash can't write `config/claude/settings.json`,
  `config/claude/hooks/`, `config/claude/CLAUDE.md` or `.claude/settings.json` (use Edit), and run
  `check_dotfiles` or `checks/…` on its own line, not after `cd …;` or piped, so it runs outside the sandbox
  (inside, the tmux checks are skipped).
- `~/.Trash` can't be read from Claude Code's shell (macOS privacy), so moves there can't be checked.
