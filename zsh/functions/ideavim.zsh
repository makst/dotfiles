#!/usr/bin/env zsh
# Shell functions for Android Studio's vim keys (config/ideavim, docs/vim-keys.md). Sourced by .zshrc with the
# rest of zsh/functions/*.zsh; each function's comment says what it does.

# setup_ideavim: nvim's keys in Android Studio (docs/vim-keys.md). Links ~/.ideavimrc and installs the IdeaVim
# and AceJump plugins when Android Studio doesn't have them yet; that needs Android Studio closed, so a running
# one is left alone with a note.
function setup_ideavim() {
  keep_real ~/.ideavimrc && ln -sfn "$real_script_dir/config/ideavim/ideavimrc" ~/.ideavimrc || return
  command -v studio > /dev/null || return 0
  local -a plugins=(~/Library/'Application Support'/Google/AndroidStudio*/plugins/{IdeaVIM,acejump}(N/))
  (( $#plugins == 2 )) && return 0
  if pgrep -qf 'Android Studio.app'; then
    print "Android Studio is running: close it and run setup_ideavim again to install IdeaVim and AceJump"
    return 0
  fi
  studio installPlugins IdeaVIM AceJump 2>&1 | grep 'installed plugin'
}
