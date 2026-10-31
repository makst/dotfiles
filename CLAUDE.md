# dotfiles

macOS setup for Apple silicon: Ghostty → tmux → zsh / nvim / Claude Code, one base16 colour scheme. The
README has the overview and the repository layout; `docs/<tool>.md` explains each tool.

## What this repo assumes
Apple silicon Mac, native arm64 only: Homebrew in `/opt/homebrew`, no Rosetta, Intel builds or `/usr/local`.
zsh is the shell; the tools come from the `Brewfile` (`rg`, `fd`, `eza`, `bat`, `jq`, `gh`, delta,
difftastic, …). SSH keys are in Secretive: commits are signed through `SSH_AUTH_SOCK` without a prompt,
pushing asks for Touch ID, so a push waits for the user.

## config/claude is global
`config/claude` becomes `~/.claude` on any machine, so it stays free of anything specific to this Mac, its
tools or this repo: no machine paths, no fonts, no hard dependency beyond zsh, jq, git and gh (anything else,
like a formatter or tmux, is used when present and skipped otherwise). Machine-specific Claude settings go
in the dotfiles (the `claude` wrapper in `zsh/.functions`), repo-specific ones in `.claude/settings.json`
and this file.

## This is the live setup
`~/.zshrc`, `~/.config/nvim`, `~/.config/tmux`, `~/.gitconfig`, `~/.claude/settings.json` and others are
symlinks into this repo, so an edit here changes the running setup immediately, including this Claude Code
session (`config/claude/settings.json`). Keep the config valid at every step; check JSON with `jq -e .`.

## When changing something
- **Docs move with the config.** Every change updates `docs/<tool>.md` in the same commit: what it does and
  why, keys in tables. A new tool or layer also goes in the README table. `docs/setup.md` lists every setup
  step and symlink.
- **Setup steps** are idempotent `setup_<tool>` functions in `zsh/.functions` that link from `config/` with
  `ln -sfn "$real_script_dir/config/…" ~/…`. Add each to `setup_dotfiles` and to the table in
  `docs/setup.md`. A real file that a link replaces goes to `~/.Trash`, not `rm`.
- **Brewfile**: one package per line with a comment saying what uses it (the config file, alias or setup
  function). Native arm64 only. Dropped packages stay commented out at the bottom, with the reason when it
  isn't obvious.
- **Keys**: each layer owns its modifier (README, "How the keyboard is split"). Check for clashes with tmux,
  Ghostty, AeroSpace and nvim before binding anything.
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
- Commits: `type(scope): summary` (feat, fix, docs, chore; scope = the tool, e.g. `nvim`, `git`, `claude`),
  a body with what and why.

## Testing
- `zsh -n <file>` for syntax; `hyperfine -i 'zsh -i -c exit'` for start-up time (~43 ms; keep it there).
  `zsh -i -c` prints a harmless fzf "can't change option: zle".
- Interactive zsh, tmux or nvim: a separate tmux server, `tmux -L probe`, driven with `send-keys` and read
  with `capture-pane`. Wrap it in a function (`p() { tmux -L probe "$@" }`), not a variable.
- Headless nvim: `/bin/zsh -i -c 'nvim --headless …'`. `Lazy! install` / `Lazy! clean` change the live
  plugins and `lazy-lock.json`.
- Git helpers: try them in a throwaway clone in the scratchpad, never on this repo's branches.
- `~/.Trash` can't be read from Claude Code's shell (macOS privacy), so moves there can't be checked.
