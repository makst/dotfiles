#!/bin/zsh
# Usage: notify.sh (PermissionRequest, Notification on elicitation_dialog, Stop; the hook's JSON on stdin)
# Sends a macOS notification when Claude waits for you or has finished, unless you're looking at it: its tmux
# window is the active one of an attached session and that client's terminal app is the frontmost app.
# With terminal-notifier, clicking it switches the client you used last to the agent's pane and brings its
# terminal to the front; without it, or with its notifications turned off, osascript shows one that clicking
# doesn't jump from. Outside tmux or off macOS it does nothing.

[[ $OSTYPE == darwin* && -n $TMUX_PANE ]] && (( $+commands[tmux] && $+commands[lsappinfo] )) || exit 0

input=$(jq -r '[.hook_event_name, .tool_name // "", .tool_input.description // .tool_input.command // "",
  .last_assistant_message // ""] | map(gsub("\\s+"; " ")) | join("\t")' 2> /dev/null) && [[ -n $input ]] || exit 0
event=${input%%$'\t'*} rest=${input#*$'\t'}
tool=${rest%%$'\t'*} rest=${rest#*$'\t'}
detail=${rest%%$'\t'*} last=${rest#*$'\t'}

# app_of <pid>: the pid and path of the .app that <pid> runs in, e.g. Ghostty for a tmux client
app_of() {
  local pid=$1 comm
  while (( pid > 1 )); do
    comm=$(ps -o comm= -p $pid) || return 1
    [[ $comm == */*.app/Contents/MacOS/* ]] && { print -r -- "$pid ${comm%%.app/*}.app"; return }
    pid=${"$(ps -o ppid= -p $pid)"// } || return 1
  done
  return 1
}

# notify: sends the notification, unless the agent's window is on screen in the frontmost app
notify() {
  local front pane_info client app line newest=0
  front=$(lsappinfo info -only pid "$(lsappinfo front)") && front=${front##*=}
  pane_info=$(tmux display -p -t "$TMUX_PANE" '#{window_active}'$'\t''#S:#W'$'\t''#{s/^✳ //:pane_title}') || return
  local active=${pane_info%%$'\t'*} where=${${pane_info#*$'\t'}%%$'\t'*} title=${pane_info##*$'\t'}
  # on screen: the window is active in a session that a client in the frontmost app shows
  if (( active )); then
    for line in ${(f)"$(tmux list-clients -t "$TMUX_PANE" -F '#{client_pid}' 2> /dev/null)"}; do
      [[ $(app_of $line) == "$front "* ]] && return
    done
  fi

  local message
  case $event in
    PermissionRequest) message="wants to use $tool${detail:+: $detail}" ;;
    Notification) message='has a question for you' ;;
    *) message=${last:-finished its turn} ;;
  esac
  (( $#message > 200 )) && message="${message[1,199]}…"
  [[ -z $title || $title == ('Claude Code'|$HOST) ]] && title=$where || title="$title — $where"

  if (( $+commands[terminal-notifier] )); then
    # the client you used last, and its terminal app, are where a click takes you
    for line in ${(f)"$(tmux list-clients -F '#{client_activity} #{client_name} #{client_pid}')"}; do
      (( ${line%% *} > newest )) && newest=${line%% *} client=${${line#* }% *} app=$(app_of ${line##* })
    done
    local click=()
    [[ -n $client ]] && click=(-execute "${(q)commands[tmux]} -S ${(q)$(tmux display -p '#{socket_path}')} \
switch-client -c ${(q)client} -t ${(q)TMUX_PANE}${app:+; open -a ${(q)${app#* }}}")
    # it can't read a message that starts with one of these unless it's escaped
    [[ $message == [-\[\(\{\"\']* ]] && message="\\$message"
    terminal-notifier -title 'Claude Code' -subtitle "$title" -message "$message" \
      -group "claude-${TMUX%%,*}-$TMUX_PANE" $click && return
    message=${message#\\}
  fi
  # terminal-notifier is missing, or its notifications are turned off
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Claude Code" subtitle (item 2 of argv)' \
    -e 'end run' "$message" "$title"
}

# in the background, with its output closed, so Claude Code doesn't wait for it
notify < /dev/null > /dev/null 2>&1 &!
exit 0
