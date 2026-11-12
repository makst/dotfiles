#!/usr/bin/env zsh
# Shell functions for atuin, the shell history (config/atuin, docs/zsh.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# setup_atuin: links atuin's config into ~/.atuin, where it keeps its data and config, and imports the zsh
# history once, if there is one (a new Mac has none, and atuin import fails without it).
function setup_atuin() {
  mkdir -p ~/.atuin
  keep_real ~/.atuin/config.toml &&
    ln -sfn "$real_script_dir/config/atuin/config.toml" ~/.atuin/config.toml || return
  # once: copy the zsh history in, so C-r finds what was typed before atuin
  [[ -f ~/.atuin/data/history.db || ! -s ~/.zsh_history ]] || atuin import zsh
}
