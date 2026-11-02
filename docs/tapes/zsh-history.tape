# Finding old commands: prefix search with the up arrow, grey suggestions, atuin's search.
# Render with `make_gifs zsh-history`.
Output docs/img/zsh-history.gif

# the up arrow only goes through commands starting with what's typed
Type "git" Sleep 500ms
Up Sleep 1s
Up Sleep 1s
Up Sleep 1s
Ctrl+c Sleep 500ms

# grey suggestion from history; the right arrow takes it
Type "docker c" Sleep 1s
Right Sleep 1.5s
Ctrl+c Sleep 500ms

# C-r: atuin, fuzzy over the whole history; Enter puts the command on the line to edit
Ctrl+r Sleep 1.5s
Type "pr ch" Sleep 1.5s
Enter Sleep 2s
