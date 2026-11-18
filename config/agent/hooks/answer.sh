#!/bin/zsh
# Usage: answer.sh   (Stop; the hook's JSON on stdin)
# Hands an agent's answer back to the agent that asked it through agent_ask (zsh/bin/agent_ask in the dotfiles,
# docs/agent.md, "Asking another agent"). agent_ask starts the child with AGENT_ASK_DIR, its state directory;
# at the end of each turn this writes the turn's last message, the hook JSON's last_assistant_message (Claude
# Code's and Codex's name for it), to <dir>/answer.<n> and then n to <dir>/turn, which agent_ask waits for.
# Each file is written whole and moved into place, so agent_ask never reads half of one. Without AGENT_ASK_DIR,
# or with one outside agent_ask's state directory, it does nothing: every other session is left alone.

dir=${AGENT_ASK_DIR:-}
# the directory itself, not a link to elsewhere: this runs outside any sandbox
[[ -n $dir && $dir == ${XDG_STATE_HOME:-$HOME/.local/state}/agent-ask/[a-z0-9]* && $dir != *..* && -d $dir \
  && ! -L $dir && ${dir:A} == $dir && -O $dir ]] || exit 0
umask 077
n=1
[[ -r $dir/turn ]] && n=$(( $(<$dir/turn) + 1 ))
jq -r '.last_assistant_message // ""' > $dir/answer.tmp 2> /dev/null &&
  mv $dir/answer.tmp $dir/answer.$n && print $n > $dir/turn.tmp && mv $dir/turn.tmp $dir/turn
exit 0
