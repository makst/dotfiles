#!/usr/bin/env zsh
# Shell functions for the shell itself and its language versions (docs/zsh.md). Sourced by .zshrc with the
# rest of zsh/functions/*.zsh; each function's comment says what it does.

# timezsh [shell]: shell start-up time (default: $SHELL), measured with hyperfine; zsh-bench
# (https://github.com/romkatv/zsh-bench) measures input lag too
timezsh() {
  hyperfine --warmup 3 --shell=none "${1-$SHELL} -i -c exit"
}

# zi [words…]: pick among the directories zoxide knows (matching the words, most used first) and change into
# the one picked. Replaces zoxide's own zi (zsh/.zshdefault loads it first), which runs a plain fzf: this one
# is the picker's (config/tmux/picker.zsh), with the same keys as every other list, and a tree preview.
function zi() {
  local dir
  source $_fzf_picker
  dir=$({ for dir in ${(f)"$(zoxide query --list -- "$@")"}; print -r -- "$dir"$'\t'"${dir/#$HOME/~}" } |
    picker directories --insert --header 'type to filter, jj for j/k · Enter goes there · Esc quits' \
      --preview 'eza --tree --level=2 --color=always --icons=always {1}' --preview-window $picker_preview) || return
  __zoxide_cd "${dir%%$'\t'*}"
}

# setup_node: installs the latest node LTS with fnm (Brewfile, zsh/.exports), makes it the default and
# installs the global npm packages into it. Through fnm exec: in a shell started before node had a default (a
# new Mac's), `npm` is Homebrew's, a dependency of the language servers, which would install into /opt/homebrew.
function setup_node() {
  fnm install --lts || return
  fnm default lts-latest || return
  fnm exec --using=default -- npm install -g \
    typescript
}

# npm_gh_token: gives npm the token gh is logged in with, for GitHub's npm registry (npm.pkg.github.com). npm
# keeps its own copy in ~/.npmrc, so a refreshed gh login doesn't reach it and npm keeps answering 401; run
# this after `gh auth refresh` (check_mac says when). gh's token needs read:packages: `gh auth refresh -s
# read:packages`.
function npm_gh_token() {
  local token
  token=$(gh auth token) || return
  npm config set //npm.pkg.github.com/:_authToken=$token
}

# setup_python: uv (Brewfile) installs python itself: `python` and `python3` in ~/.local/bin are the latest
# version. Projects pin theirs with `uv python pin` / .python-version; `uv tool install` puts CLI tools on PATH.
function setup_python() {
  uv python install --default
}
