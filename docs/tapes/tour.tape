# A quick tour for the README: a project as a session, delta, nvim and a shell side by side, closing a pane,
# git status in nvim, and the session tree. Render with `make_gifs tour`.
Output docs/img/tour.gif

# start outside the repo, so its branch and changes don't show in the prompt
Hide
Type "cd ~/repos/notes && clear" Enter Sleep 500ms
Show

# cmd+k: open the project api as a session
Ctrl+a Type "f" Sleep 1.2s
Type "api" Sleep 800ms
Enter Sleep 1.2s

# git diff through delta
Type "git diff" Enter Sleep 2.5s
Type "clear" Enter

# nvim, ;f: find a file
Type "nvim README.md" Enter Sleep 2s
Type ";f" Sleep 1s
Type "greet" Sleep 1s
Enter Sleep 1.5s

# cmd+d: a shell next to nvim; C-h and C-l cross between them
Ctrl+a Type "|" Sleep 1.2s
Ctrl+h Sleep 1s
Ctrl+l Sleep 1s

# cmd+w: close the nvim pane (tmux asks first), so git status gets the whole window
Ctrl+h Sleep 800ms
Ctrl+a Type "x" Sleep 1s
Type "y" Sleep 1.2s

# gs: git status in nvim (fugitive)
Type "gs" Enter Sleep 2.5s
Type ":q" Enter Sleep 1s

# cmd+j: every session and window as a tree, back to main
Ctrl+a Type "w" Sleep 2s
Type "k" Sleep 700ms
Type "k" Sleep 1s
Enter Sleep 1.5s
