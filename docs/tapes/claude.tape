# An agent from start to finish: Claude Code in its own worktree and window, its window turning yellow when it
# rings the bell (done, or needs an answer), cmd+j to get there, then agent_done. This is the real Claude Code
# (docs/gifs.md), so its words differ on every render; the wait for it is hidden.
# Render with `make_gifs claude`.
Output docs/img/claude.gif

Type "z api" Enter Sleep 800ms
Type `agent greet-test "add a test for greet in greet.test.ts (don't run it), then commit it"` Enter
Sleep 7s

# cmd+1: back to your own window while it works; its window turns yellow when Claude rings the bell
Ctrl+a Type "1" Sleep 1s
Hide
Wait+Screen@240s /󰂞|󰄬/
Show
Sleep 2s

# cmd+j: every window with a live preview; pick the agent's to read what it did
Ctrl+a Type "w" Sleep 2.5s
Type "j" Sleep 2s
Enter Sleep 4s

# cmd+1: back; agent_done lists the agents, and won't remove one whose branch isn't merged (or use --force)
Ctrl+a Type "1" Sleep 800ms
Type "agent_done" Enter Sleep 2s
Type "agent_done greet-test" Enter Sleep 3s
Type "clear" Enter
Type "git merge worktree-greet-test" Enter Sleep 2s
Type "agent_done greet-test" Enter Sleep 5s
