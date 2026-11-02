# An agent in its own worktree and tmux window, its window turning yellow when it needs an answer, jumping
# there with the session tree, then merging and cleaning up. `claude` here is docs/tapes/claude-stand-in.
# Render with `make_gifs claude-code`.
Output docs/img/claude-code.gif

Type "z api" Enter Sleep 800ms
Type `agent greet-test "add a test for greet"` Enter Sleep 2s

# cmd+1: back to work while the agent runs; its window turns yellow when it rings the bell
Ctrl+a Type "1" Sleep 5s

# cmd+j: every window with a preview; pick the agent's
Ctrl+a Type "w" Sleep 1.5s
Down Sleep 1.5s
Enter Sleep 1.2s
Type "y" Sleep 2s

# cmd+1: merge the agent's branch, then remove its worktree, branch and window
Ctrl+a Type "1" Sleep 800ms
Type "git merge greet-test" Enter Sleep 1.5s
Type "agent_done greet-test" Enter Sleep 3s
