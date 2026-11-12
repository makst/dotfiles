#!/usr/bin/env zsh
# Shell functions for Ghostty (config/ghostty, docs/ghostty.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# setup_ghostty: links Ghostty's config and the base16 theme change_theme writes.
function setup_ghostty() {
  mkdir -p "$HOME/.config/ghostty"
  keep_real "$HOME/.config/ghostty/config" &&
    ln -sfn "$real_script_dir/config/ghostty/config" "$HOME/.config/ghostty/config" || return
  keep_real "$HOME/.config/ghostty/themes" &&
    ln -sfn "$real_script_dir/config/ghostty/themes" "$HOME/.config/ghostty/themes" || return
}
