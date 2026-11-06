#!/usr/bin/env zsh
# Shell functions for AeroSpace and the macOS window settings (docs/window-management.md). Sourced by .zshrc
# with the rest of zsh/functions/*.zsh; each function's comment says what it does.

# setup_window_management: links AeroSpace's config (AeroSpace comes from the Brewfile), sets the Dock and
# window defaults it works best with and starts it. Its first start asks for Accessibility access (System
# Settings > Privacy & Security > Accessibility); from then on it starts at login (start-at-login in the config).
function setup_window_management() {
  mkdir -p "$HOME/.config/aerospace"
  ln -sfn "$real_script_dir/config/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  # Mission Control shows the windows of other workspaces too small without this
  defaults write com.apple.dock expose-group-apps -bool true && killall Dock
  # ctrl+cmd and drag anywhere in a window moves it; applies after logging out and in
  defaults write -g NSWindowShouldDragOnGesture -bool true
  open -a AeroSpace
}
