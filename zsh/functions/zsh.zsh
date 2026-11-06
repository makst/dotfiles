#!/usr/bin/env zsh
# Shell functions for the shell itself and its language versions (docs/zsh.md). Sourced by .zshrc with the
# rest of zsh/functions/*.zsh; each function's comment says what it does.

# timezsh [shell]: shell start-up time (default: $SHELL), measured with hyperfine; zsh-bench
# (https://github.com/romkatv/zsh-bench) measures input lag too
timezsh() {
  hyperfine --warmup 3 --shell=none "${1-$SHELL} -i -c exit"
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

# setup_python: uv (Brewfile) installs python itself: `python` and `python3` in ~/.local/bin are the latest
# version. Projects pin theirs with `uv python pin` / .python-version; `uv tool install` puts CLI tools on PATH.
function setup_python() {
  uv python install --default
}
