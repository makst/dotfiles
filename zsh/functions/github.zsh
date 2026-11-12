#!/usr/bin/env zsh
# Shell functions for watching GitHub (docs/github.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_github: links ~/.config/github, where tmux finds the picker (cmd+g), and runs config/github/watch
# every minute with a LaunchAgent, which notifies you when your pull requests' checks or reviews change or a
# notification about you arrives, and keeps the tmux mark current.
# launchd starts programs with a bare PATH, so the agent gets Homebrew's. A rerun reloads the agent only when
# its plist changed (a moved repo), so it doesn't stop a run of the watcher (load_launch_agent).
function setup_github() {
  local label="com.makst.github-watch"
  local log="${XDG_STATE_HOME:-$HOME/.local/state}/github/watch.log"
  mkdir -p "${log:h}"
  # the picker, for tmux's binding (cmd+g)
  mkdir -p "$HOME/.config"
  keep_real ~/.config/github && ln -sfn "$real_script_dir/config/github" ~/.config/github || return
  load_launch_agent $label "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
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
</plist>"
}
