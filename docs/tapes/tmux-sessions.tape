# The session picker opening a project as a session, the tree of sessions, and switching back.
# Render with `make_gifs tmux-sessions`.
Output docs/img/tmux-sessions.gif

# cmd+k: session picker, running sessions first, then the directories zoxide knows
Ctrl+a Type "f" Sleep 1.5s
Type "web" Sleep 1s
Enter Sleep 1.5s
Type "ls" Enter Sleep 1s

# cmd+j: every session and window as a tree, with previews
Ctrl+a Type "w" Sleep 2s
Up Sleep 700ms
Up Sleep 1s
Enter Sleep 1.5s

# cmd+shift+0: back to the last session, and again to return
Ctrl+a Type "S" Sleep 1.5s
Ctrl+a Type "S" Sleep 1.5s
