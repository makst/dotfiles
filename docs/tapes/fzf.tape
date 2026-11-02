# fzf in the shell: picking files into the command line and completing paths.
# Render with `make_gifs fzf`.
Output docs/img/fzf.gif

# C-t: pick a file, its path goes on the command line
Type "nvim " Sleep 300ms
Ctrl+t Sleep 1.5s
Type "tmux.md" Sleep 1.5s
Enter Sleep 1.5s
Ctrl+c Sleep 500ms

# **<Tab>: fzf completion for any command
Type "cd **" Sleep 300ms
Tab Sleep 1.5s
Type "nvim/lua" Sleep 1.5s
Enter Sleep 1s
Enter Sleep 1.5s
