#!/usr/bin/env zsh
# Shell functions for btop (config/btop, docs/zsh.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_btop: links btop's config, which sets vim keys and the terminal's colours.
function setup_btop() {
  mkdir -p ~/.config/btop
  ln -sfn "$real_script_dir/config/btop/btop.conf" ~/.config/btop/btop.conf
}
