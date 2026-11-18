#!/bin/zsh
# Notification and Stop: ring the bell in the agent's tmux pane when it needs you or has finished, so tmux marks
# its window (monitor-bell) and the terminal can flag it. Hooks have no terminal of their own, so the bell goes
# to the pane's tty. Outside tmux it does nothing; the tool's own notifications cover that.

[[ -n $TMUX_PANE ]] || exit 0
# an agent that agent_ask started (AGENT_ASK_DIR) hands its answer back at Stop (answer.sh): nobody to call
[[ -n ${AGENT_ASK_DIR:-} && $(jq -r '.hook_event_name // empty' 2> /dev/null) == Stop ]] && exit 0
tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2> /dev/null) && [[ -w $tty ]] && printf '\a' > $tty
exit 0
