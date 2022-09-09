# fzf oh-my-zsh plugin tries to find [junegunn's fzf](https://github.com/junegunn/fzf) based on where
# it's been installed, and enables its fuzzy auto-completion and key bindings.
# hence, only `brew install fzf`, do not manually source auto-completion and key bindings

###### fzf-tab configuration - https://github.com/Aloxaf/fzf-tab#configure
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
