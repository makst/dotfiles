# Symlinked to ~/.fzf.zsh by setup_fzf (zsh/functions/fzf.zsh), sourced after `bindkey -v` (zsh/.zshdefault).

# fzf's own key bindings and completion: CTRL-T files, ALT-C cd, **<TAB> (CTRL-R is fzf-history-widget below)
cached_eval fzf fzf --zsh

### fzf configuration
# list files with fd: fast, respects .gitignore, shows hidden files
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# The look and keys of every fzf are in config/fzf/fzfrc, which fzf reads each time it starts. tmux.conf points
# its server at the same file, so the pickers in tmux popups match. It's this checkout's file, not a link setup
# makes: fzf fails when the file is missing, so it works as soon as a pull brings it. A FZF_DEFAULT_OPTS left
# over from before would be added on top of the file, so it goes.
export FZF_DEFAULT_OPTS_FILE=${${(%):-%x}:A:h}/config/fzf/fzfrc
unset FZF_DEFAULT_OPTS

# find-in-file - usage: fif <SEARCH_TERM>
fif() {
  if [ ! "$#" -gt 0 ]; then
    print -u2 "Need a string to search for!"
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
zstyle ':fzf-tab:complete:cd:*' fzf-flags --preview-window=nohidden # fzfrc hides previews
# fzf's defaults for its look too: the border, colours and layout of every other fzf. fzf reads fzfrc whatever
# this says (fzf-tab only blanks FZF_DEFAULT_OPTS); it keeps a FZF_DEFAULT_OPTS set by hand from being dropped.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# its height is the number of candidates plus fzf-pad: the input's box and the list's border
zstyle ':fzf-tab:*' fzf-pad 5
# [ and ] switch to the previous / next group, as [x / ]x do in nvim; not , and ., which are in filenames
zstyle ':fzf-tab:*' switch-group '[' ']'
