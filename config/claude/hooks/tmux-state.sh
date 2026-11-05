#!/bin/zsh
# Usage: tmux-state.sh working|waiting|done|idle|off
# Records what Claude Code is doing in its tmux pane, as the pane option @claude, so tmux can show it on the
# window, in the session tree and the picker (config/tmux/tmux.conf, "Claude Code agents"). A finished agent in a
# window you're looking at is already seen, so it's idle rather than done. Outside tmux it does nothing.

[[ -n $TMUX_PANE ]] && (( $+commands[tmux] )) || exit 0

# watch_prompt
# While the agent waits, watches its pane for the permission prompt to go away: no hook fires when you answer
# one, only when the tool has finished. Then the spinner line (`✻ Thinking… (3s`) means you approved and it
# works, no spinner that you declined and it's idle. Stops when the state changes otherwise or the pane closes,
# and after 10 s if no prompt shows up (a dialog it doesn't know); the hooks take over from there.
watch_prompt() {
  local seen=0 polls=0 i screen
  while sleep 0.5; do
    (( ++polls ))
    [[ $(tmux display -p -t "$TMUX_PANE" '#{@claude}' 2> /dev/null) == waiting ]] || return
    screen=$(tmux capture-pane -p -t "$TMUX_PANE" -S -15 2> /dev/null)
    if [[ ${(L)screen} == *'esc to cancel'* || ${(L)screen} == *'do you want to '* ]]; then
      seen=1
    elif (( seen )); then
      for i in {1..6}; do
        if tmux capture-pane -p -t "$TMUX_PANE" -S -15 | grep -qE '^ *[*·✢✳✶✻✽] .*… \([0-9]+[smh]'; then
          tmux set -p -t "$TMUX_PANE" @claude working
          return
        fi
        sleep 0.5
      done
      tmux set -p -t "$TMUX_PANE" @claude idle
      return
    elif (( polls >= 20 )); then
      return
    fi
  done
}

state=$1
if [[ $state == off ]]; then
  tmux set -pu -t "$TMUX_PANE" @claude 2> /dev/null
  exit 0
fi
if [[ $state == done ]] \
  && [[ $(tmux display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}' 2> /dev/null) == 1 ]]; then
  state=idle
fi
tmux set -p -t "$TMUX_PANE" @claude "$state" 2> /dev/null
# in the background, with its output closed, so Claude Code doesn't wait for it
[[ $state == waiting ]] && watch_prompt < /dev/null > /dev/null 2>&1 &!
exit 0
