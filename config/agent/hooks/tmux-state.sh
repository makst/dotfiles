#!/bin/zsh
# Usage: tmux-state.sh working|waiting|done|idle|off [tool]
# Records what the agent in its tmux pane is doing, as the pane option @agent: the one place that says what it
# holds. Claude Code's hooks call it; any other tool that runs in a pane can call it or set @agent the same
# way. Outside tmux it does nothing.
#   working  a prompt was sent (UserPromptSubmit) or a tool finished (PostToolUse); also set by watch_prompt
#            below when you approve a permission prompt
#   waiting  for a permission (PermissionRequest) or an answer (Notification, elicitation_dialog)
#   done     finished (Stop), not seen yet; in a window you're looking at it is written as idle instead, and
#            tmux turns done into idle itself when you switch to the window or session (@agent-seen,
#            config/tmux/tmux.conf)
#   idle     the session started (SessionStart), or you declined a prompt (watch_prompt); shows nothing
#   off      (SessionEnd) unsets the option; shows nothing
# The hook events are in config/claude/settings.json, "hooks". The urgency order is waiting, done, working
# (idle and unset show nothing); each reader spells it out itself, as tmux formats can't share a variable:
# @agent-*-state in tmux.conf, `rank` in agents, next-agent.
# Readers, all in config/tmux unless named:
#   tmux.conf, "agents (Claude Code or another tool)"  the most urgent state of each window (@agent-window-state,
#                                    the window mark) and session (@agent-session-state), the counts in the status
#                                    line (@agent-all-*, @agent-summary), @agent-seen, and @agent-pane (a pane
#                                    that runs an agent, whatever its state)
#   agents                           the cmd+shift+j overview: the panes ordered by state
#   next-agent                       cmd+shift+space: the next waiting agent, then the done ones
#   tree                             the mark of each session, window and pane
#   sessionizer                      the mark of each session (@agent-session-state)
#   nvim/lua/user/codetour/review.lua  finds the agent's pane through @agent-pane

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
    [[ $(tmux display -p -t "$TMUX_PANE" '#{@agent}' 2> /dev/null) == waiting ]] || return
    screen=$(tmux capture-pane -p -t "$TMUX_PANE" -S -15 2> /dev/null)
    if [[ ${(L)screen} == *'esc to cancel'* || ${(L)screen} == *'do you want to '* ]]; then
      seen=1
    elif (( seen )); then
      for i in {1..6}; do
        if tmux capture-pane -p -t "$TMUX_PANE" -S -15 | grep -qE '^ *[*·✢✳✶✻✽] .*… \([0-9]+[smh]'; then
          tmux set -p -t "$TMUX_PANE" @agent working
          return
        fi
        sleep 0.5
      done
      tmux set -p -t "$TMUX_PANE" @agent idle
      return
    elif (( polls >= 20 )); then
      return
    fi
  done
}

state=$1
if [[ $state == off ]]; then
  tmux set -pu -t "$TMUX_PANE" @agent 2> /dev/null
  exit 0
fi
if [[ $state == done ]] \
  && [[ $(tmux display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}' 2> /dev/null) == 1 ]]; then
  state=idle
fi
tmux set -p -t "$TMUX_PANE" @agent "$state" 2> /dev/null
# watch_prompt's screen patterns are Claude Code's, so only Claude's hooks get it: they pass no [tool], the
# other tools' hooks name theirs (config/codex/hooks.json) and their state stays waiting until the next hook.
# Not pane_current_command: Claude Code's process shows as its version (2.1.325), not as claude. In the
# background, with its output closed, so the tool doesn't wait for it.
if [[ $state == waiting && -z $2 ]]; then
  watch_prompt < /dev/null > /dev/null 2>&1 &!
fi
exit 0
