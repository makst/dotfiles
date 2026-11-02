# git in a small demo project: delta for diffs, difftastic for structural ones, lazygit.
# Render with `make_gifs git`.
Output docs/img/git.gif

Type "z api" Enter Sleep 1s

# git diff goes through delta: syntax highlighting, changes within a line
Type "git diff" Enter Sleep 3s
Type "clear" Enter

# git dft: difftastic compares syntax, so moved code and reformatting don't show as changes
Type "git dft" Enter Sleep 3s
Type "clear" Enter

# lg: lazygit; stage the file with Space, c to commit
Type "lg" Enter Sleep 2.5s
Space Sleep 1.5s
Type "c" Sleep 1s
Type "Trim names, add farewell" Sleep 500ms
Enter Sleep 2s
Type "q" Sleep 1s
