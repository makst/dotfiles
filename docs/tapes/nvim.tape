# nvim: finding a file, the file tree, and moving between nvim and a tmux pane with the same keys.
# Render with `make_gifs nvim`.
Output docs/img/nvim.gif

Type "nvim README.md" Enter Sleep 2.5s

# ;f: find files
Type ";f" Sleep 1.2s
Type "tmux.conf" Sleep 1.5s
Enter Sleep 2s

# ,e: file tree on the right; C-h back to the file
Type ",e" Sleep 2s
Ctrl+h Sleep 1.2s

# cmd+d: a shell next to nvim; C-h and C-l cross between them
Ctrl+a Type "|" Sleep 1.5s
Ctrl+h Sleep 1.2s
Ctrl+l Sleep 1.2s
Ctrl+h Sleep 1.5s
