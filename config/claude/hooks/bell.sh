#!/bin/zsh
# Notification and Stop: ring the bell in Claude's tmux pane when it needs you or has finished, so tmux marks
# its window (monitor-bell) and the terminal can flag it. Hooks have no terminal of their own, so the bell goes
# to the pane's tty. Outside tmux it does nothing; Claude Code's own notifications cover that.

[[ -n $TMUX_PANE ]] || exit 0
tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2> /dev/null) && [[ -w $tty ]] && printf '\a' > $tty
exit 0
