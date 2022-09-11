# fzf oh-my-zsh plugin tries to find [junegunn's fzf](https://github.com/junegunn/fzf) based on where
# it's been installed, and enables its fuzzy auto-completion and key bindings.
# hence, only `brew install fzf`, do not manually source auto-completion and key bindings
source ~/.oh-my-zsh/plugins/fzf/fzf.plugin.zsh

### fzf configuration
bindkey "ç" fzf-cd-widget

# inspired by: https://betterprogramming.pub/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d
export FZF_DEFAULT_OPTS="
--multi
--preview-window=:hidden
--color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
--preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
--bind 'ctrl-n:preview-down'
--bind 'ctrl-p:preview-up'
--bind 'ctrl-alt-n:preview-half-page-down'
--bind 'ctrl-alt-p:preview-half-page-up'
"

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
