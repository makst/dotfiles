#!/usr/bin/env zsh
# Shell functions for tmux (config/tmux, docs/tmux.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# setup_tmux: links ~/.config/tmux and installs tpm and the plugins tmux.conf lists.
function setup_tmux() {
  mkdir -p "$HOME/.config"
  keep_real "$HOME/.config/tmux" && ln -sfn "$real_script_dir/config/tmux" "$HOME/.config/tmux" || return
  # the config used to live in ~/.tmux.conf, which tmux would still prefer
  [[ -L ~/.tmux.conf ]] && rm ~/.tmux.conf

  # plugin manager; the plugins themselves are listed in config/tmux/tmux.conf
  [[ ! -d ~/.tmux/plugins/tpm ]] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ~/.tmux/plugins/tpm/bin/install_plugins
}
