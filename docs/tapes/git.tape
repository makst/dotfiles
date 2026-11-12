# git in a small demo project: delta for diffs, difftastic for structural ones, fugitive's status in nvim.
# Render with `make_gifs git`.
Output docs/img/git.gif

Type "z api" Enter Sleep 1s

# git diff goes through delta: syntax highlighting, changes within a line
Type "git diff" Enter Sleep 3s
Type "clear" Enter

# git dft: difftastic compares syntax, so moved code and reformatting don't show as changes
Type "git dft" Enter Sleep 3s
Type "clear" Enter

# gs: fugitive's status in nvim; gu goes to the first unstaged file, = shows its diff inline, s stages it,
# cc writes the commit message
Type "gs" Enter Sleep 2.5s
Type "gu" Sleep 1s
Type "=" Sleep 2s
Type "s" Sleep 1.5s
Type "cc" Sleep 1.5s
Type "iTrim names, add farewell" Sleep 500ms
Escape Type ":wq" Enter Sleep 2s
Type ":q" Enter Sleep 1s
