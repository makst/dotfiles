#!/bin/zsh
# Notification and Stop: ring the bell in Claude's tmux pane when it needs you or has finished, so its window
# turns yellow in the status bar (config/tmux/tmux.conf) and Ghostty bounces its Dock icon when in the
# background. Hooks have no terminal of their own, so the bell goes to the pane's tty.

[[ -n $TMUX_PANE ]] || exit 0
tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2> /dev/null) && [[ -w $tty ]] && printf '\a' > $tty
exit 0
