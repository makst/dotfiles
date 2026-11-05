# Symlinked to ~/.fzf.zsh by fzf_setup (zsh/.functions), sourced after `bindkey -v` (zsh/.zshdefault).

# fzf's own key bindings and completion: CTRL-T files, ALT-C cd, **<TAB> (CTRL-R is fzf-history-widget below)
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
# --gutter=' ': fzf draws its gutter as ▌ in the text colour on every line; only the current line gets a bar.
# The input, the list and the preview each in a box of their own: one border around all of them leaves the
# input and the list a column short of the edge when the preview is below.
export FZF_DEFAULT_OPTS="
--multi
--layout=reverse
--height=60%
--input-border=rounded
--list-border=rounded
--info=inline-right
--gutter=' '
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

# fzf-history-widget (ctrl+r, and / in normal mode; bound in zsh/.zshdefault after atuin's own): atuin's history
# in fzf, so it looks and works like every other fzf. Newest first, each command once, with how long it ran
# (red when it failed) and how long ago; typing filters the commands only. Keys as in every picker
# (config/tmux/picker.zsh): it opens ready to type, jj for j/k. ctrl+r again cycles atuin's filter modes, shown
# on the list's border: global, host, session, workspace (the git repo), directory. ? shows the whole command
# with its directory and exit code. Enter puts the command on the command line to edit, as atuin's
# enter_accept = false. atuin still records every command; config/atuin/fzf-history lists them.
typeset -g _fzf_history=${${(%):-%x}:A:h}/config/atuin/fzf-history _fzf_picker=${${(%):-%x}:A:h}/config/tmux/picker.zsh
fzf-history-widget() {
  source $_fzf_picker
  local cycle="case \$FZF_LIST_LABEL in
      ' global ') m=host ;; ' host ') m=session ;; ' session ') m=workspace ;; ' workspace ') m=directory ;;
      *) m=global ;;
    esac
    echo \"change-list-label( \$m )+reload($_fzf_history \$m)\""
  # over picker's options: ranked by the match (--sort), the command the only field searched, and no --track: it
  # kept the cursor on what the first j of jj matched
  local choice
  choice=$($_fzf_history global | picker history --insert --read0 --sort --scheme history --tabstop 1 \
    --with-nth $'{1}\t{4}' --nth 2 --no-track --accept-nth 4 --list-label ' global ' --query "$BUFFER" \
    --header 'type to filter, jj for j/k · ctrl+r cycles global, host, session, workspace, directory · ? whole command' \
    --bind "ctrl-r:transform:$cycle" \
    --preview $'printf "\e[90m%s · exit %s\e[0m\n\n%s\n" {2} {3} {4}' --preview-window 'down,40%,wrap')
  [[ -n $choice ]] && BUFFER=$choice CURSOR=$#choice
  zle reset-prompt
}
zle -N fzf-history-widget

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
zstyle ':fzf-tab:complete:cd:*' fzf-flags --preview-window=nohidden # FZF_DEFAULT_OPTS hides previews
# FZF_DEFAULT_OPTS for its look too: the border, colours and layout of every other fzf
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# its height is the number of candidates plus fzf-pad: the input's box and the list's border
zstyle ':fzf-tab:*' fzf-pad 5
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
