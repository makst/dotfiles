#!/usr/bin/env zsh
# Shell functions for nvim (config/nvim, docs/nvim.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# setup_nvim: links ~/.config/nvim, makes `vim` run nvim, installs the plugin versions in lazy-lock.json and
# the treesitter parsers; fails when nvim's start prints an error.
function setup_nvim() {
  keep_real "$HOME/.config/nvim" && ln -sfn "$real_script_dir/config/nvim" "$HOME/.config/nvim" || return
  mkdir -p "$HOME/bin"
  # `vim` runs nvim, also where aliases don't (git's core.editor = vim)
  keep_real "$HOME/bin/vim" && ln -sfn /opt/homebrew/bin/nvim "$HOME/bin/vim" || return

  # plugins: lazy.nvim bootstraps itself on first start; install the versions pinned in
  # config/nvim/lazy-lock.json (needs network)
  command -v nvim > /dev/null || return 1
  # config/nvim/lua/user/treesitter.lua starts downloading the parsers on every start until they're there;
  # this run waits for them, so that the next one starts with everything installed
  nvim --headless "+Lazy! restore" "+lua require('user.treesitter').wait()" +qa
  # nvim exits 0 even when the config throws; a start with everything installed writes nothing to stderr, so
  # anything there (a Lua error) fails the step and setup_dotfiles lists it
  local errors
  { errors=$(nvim --headless +qa 2>&1 1>&3) } 3>&1
  [[ -z $errors ]] || { print -u2 -r -- $errors; return 1 }
}
