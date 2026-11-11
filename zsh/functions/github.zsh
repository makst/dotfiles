#!/usr/bin/env zsh
# Shell functions for watching GitHub (docs/github.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_github: runs config/github/watch every minute with a LaunchAgent, which notifies you when your pull
# requests' checks or reviews change or a notification about you arrives, and keeps the tmux mark current.
# launchd starts programs with a bare PATH, so the agent gets Homebrew's. Reloads the agent, so a rerun
# picks up a moved repo.
function setup_github() {
  local label="com.makst.github-watch"
  local plist="$HOME/Library/LaunchAgents/$label.plist"
  local log="${XDG_STATE_HOME:-$HOME/.local/state}/github/watch.log"
  mkdir -p "$HOME/Library/LaunchAgents" "${log:h}"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$real_script_dir/config/github/watch</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$HOMEBREW_PREFIX/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
  <key>StandardErrorPath</key>
  <string>$log</string>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/$label" 2> /dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
}
