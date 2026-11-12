#!/usr/bin/env zsh
# Shell functions for VS Code (config/vscode, docs/debugging.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# setup_vscode: VS Code as the visual debugger next to nvim (docs/debugging.md). Links its settings into the
# repo and installs the extensions listed in config/vscode/extensions.txt that are missing. Settings changed
# in VS Code's own UI land in the repo's file, as with every other linked config.
function setup_vscode() {
  if ! command -v code > /dev/null; then
    print -u2 "VS Code's code command not found: brew bundle installs it"
    return 1
  fi
  setopt local_options extended_glob
  local user_dir=~/Library/'Application Support'/Code/User ext
  mkdir -p $user_dir
  # settings made before the link go to the Trash; the repo's version replaces them
  keep_real $user_dir/settings.json &&
    ln -sfn "$real_script_dir/config/vscode/settings.json" $user_dir/settings.json || return
  local -a installed=(${(f)"$(code --list-extensions)"})
  for ext in ${${(f)"$(<$real_script_dir/config/vscode/extensions.txt)"}%%[[:space:]]#\#*}; do
    [[ -n $ext ]] || continue
    (( ${installed[(I)(#i)$ext]} )) || code --install-extension $ext || return
  done
}
