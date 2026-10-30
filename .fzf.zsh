# Symlinked to ~/.fzf.zsh by fzf_setup (zsh/.functions), sourced after `bindkey -v` (zsh/.zshdefault).

# fzf's own key bindings and completion: CTRL-T files, ALT-C cd, **<TAB> (CTRL-R is atuin's, loaded after this)
cached_eval fzf fzf --zsh

### fzf configuration
# ALT-C as typed with Option on a Mac keyboard when Option is not Alt
bindkey "ç" fzf-cd-widget

# list files with fd: fast, respects .gitignore, shows hidden files
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# https://betterprogramming.pub/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d
# Colours are the terminal's 16 ANSI ones, so they follow the Ghostty theme.
export FZF_DEFAULT_OPTS="
--multi
--layout=reverse
--height=60%
--border=rounded
--info=inline-right
--preview-window=:hidden
--color='fg:-1,bg:-1,hl:green,fg+:bright-white,bg+:bright-black,hl+:bright-green'
--color='info:yellow,prompt:blue,pointer:magenta,marker:green,spinner:cyan,header:cyan,border:bright-black,gutter:-1'
--preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && eza --tree --level=2 --color=always --icons=always {}) || echo {} 2> /dev/null | head -200'
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
--bind 'ctrl-n:preview-down'
--bind 'ctrl-p:preview-up'
--bind 'ctrl-alt-n:preview-half-page-down'
--bind 'ctrl-alt-p:preview-half-page-up'
"

# find-in-file - usage: fif <SEARCH_TERM>
fif() {
  if [ ! "$#" -gt 0 ]; then
    echo "Need a string to search for!";
    return 1;
  fi

  rg --files-with-matches --no-messages "$1" | fzf --preview "rg --ignore-case --pretty --context 10 '$1' {}" --preview-window=right:60%
}

###### fzf-tab configuration - https://github.com/Aloxaf/fzf-tab#configure
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# don't show the plain completion menu, fzf-tab replaces it
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
