# Splitting, moving between and zooming panes, then a second window. Render with `make_gifs tmux-panes`.
# Prefix chords are typed as tmux receives them; the caption shows the Ghostty key that sends each one.
Output docs/img/tmux-panes.gif

Type "ls -1" Enter
Sleep 1s

# cmd+d: split right
Ctrl+a Type "|" Sleep 1.2s
Type "git log --oneline -5" Enter Sleep 1s
# cmd+shift+d: split down
Ctrl+a Type "-" Sleep 1.2s

Ctrl+h Sleep 1s
Ctrl+l Sleep 1s
Ctrl+k Sleep 1s

# cmd+shift+enter: zoom, and back
Ctrl+a Type "z" Sleep 1.5s
Ctrl+a Type "z" Sleep 1.2s

# cmd+t: new window, cmd+[: previous window
Ctrl+a Type "c" Sleep 1.2s
Ctrl+a Ctrl+h Sleep 1.5s
