#!/usr/bin/env zsh
# Shell functions for AeroSpace and the macOS window settings (docs/aerospace.md). Sourced by .zshrc
# with the rest of zsh/functions/*.zsh; each function's comment says what it does.

# setup_aerospace: links AeroSpace's config and its window picker (AeroSpace comes from the Brewfile), sets
# the Dock and window defaults it works best with and starts it. Its first start asks for Accessibility access
# (System Settings > Privacy & Security > Accessibility); from then on it starts at login (start-at-login in
# the config). A LaunchAgent runs `windows --watch` every 5 s, which applies this Mac's arrangement for the
# number of displays when that changes (docs/aerospace.md, "Saved arrangements"); launchd starts it with a bare
# PATH, so it gets Homebrew's. A rerun reloads it only when its plist changed (load_launch_agent).
function setup_aerospace() {
  mkdir -p "$HOME/.config/aerospace"
  keep_real ~/.config/aerospace/aerospace.toml &&
    ln -sfn "$real_script_dir/config/aerospace/aerospace.toml" ~/.config/aerospace/aerospace.toml || return
  # the window picker alt+w opens (the config runs it from here)
  keep_real ~/.config/aerospace/windows &&
    ln -sfn "$real_script_dir/config/aerospace/windows" ~/.config/aerospace/windows || return
  # Mission Control shows the windows of other workspaces too small without this; the Dock restarts to take
  # it, so only when it isn't set yet
  [[ $(defaults read com.apple.dock expose-group-apps 2> /dev/null) == 1 ]] ||
    { defaults write com.apple.dock expose-group-apps -bool true && killall Dock }
  # ctrl+cmd and drag anywhere in a window moves it; applies after logging out and in
  defaults write -g NSWindowShouldDragOnGesture -bool true
  pgrep -xq AeroSpace || open -a AeroSpace
  local label="com.makst.aerospace-displays"
  local log="${XDG_STATE_HOME:-$HOME/.local/state}/aerospace-displays.log"
  mkdir -p "${log:h}"
  load_launch_agent $label "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$real_script_dir/config/aerospace/windows</string>
    <string>--watch</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$HOMEBREW_PREFIX/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartInterval</key>
  <integer>5</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
  <key>StandardErrorPath</key>
  <string>$log</string>
</dict>
</plist>"
}
