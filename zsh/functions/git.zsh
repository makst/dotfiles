#!/usr/bin/env zsh
# Shell functions for git (config/git, docs/git.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_git: links ~/.gitconfig and the global gitignore, and turns on this repo's hooks (.githooks), which
# run reload_dotfiles after a pull, rebase or branch switch.
function setup_git() {
  ln -sfn "$real_script_dir/config/git/.gitconfig" "$HOME/.gitconfig"
  mkdir -p "$HOME/.config/git"
  ln -sfn "$real_script_dir/config/git/ignore" "$HOME/.config/git/ignore"
  git -C "$real_script_dir" config core.hooksPath .githooks
}
