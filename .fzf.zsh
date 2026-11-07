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

typeset -g _fzf_picker=${${(%):-%x}:A:h}/config/tmux/picker.zsh

# find_file [command…]: pick a file from what the command lists (default: fd, every file but ignored ones),
# with a preview, and print its path. The pickers of ;f, ;a and ;g below.
find_file() {
  source $_fzf_picker
  (( $# )) || set -- fd --type f --type l --hidden --exclude .git --color never
  local file
  file=$("$@" | awk '{ print $0 "\t" $0 }' |
    picker files --insert --header 'type to filter, jj for j/k · Enter opens · Esc quits' \
      --preview 'bat --color=always --style=numbers {1}' --preview-window $picker_preview) || return
  print -r -- ${file%%$'\t'*}
}

# fif [text]: grep the project with rg as you type (starting from the text), with the match in its file as
# the preview, and open the one picked in nvim at its line. The picker of ;r below.
fif() {
  source $_fzf_picker
  local rg="rg --line-number --no-heading --color=never --smart-case --field-match-separator='\t' -- {q} || true"
  local -a match
  # fields: file, line, text; fzf doesn't filter (--disabled), rg does on every change of the query. The empty
  # stdin keeps fzf from listing FZF_DEFAULT_COMMAND's files first.
  match=("${(@ps:\t:)$(: | picker grep --insert --disabled --query "$1" --no-track \
    --bind "start:reload:$rg" --bind "change:reload:$rg" --with-nth '{1}:{2}: {3..}' \
    --header 'type to grep, jj for j/k · Enter opens at the line · Esc quits' \
    --preview 'bat --color=always --style=numbers --highlight-line {2} --line-range $(( {2} > 10 ? {2} - 10 : 1 )): {1}' \
    --preview-window $picker_preview)}")
  (( $#match >= 2 )) || return 1
  nvim +$match[2] -- $match[1]
}

# The find keys in normal mode (bound in zsh/.zshdefault), nvim's in the shell: ;f files, ;a all files
# (ignored ones too), ;g files in git, ;r grep, ;p projects, and ,lg lazygit, ,e yazi, ,tt / ,tm the shells. Each
# but the shells puts the command it runs on the command line and runs it, so it lands in the history; what was
# typed comes back afterwards.
_find_run() {
  zle push-line
  BUFFER=$1
  zle accept-line
}
_find_open() {
  local file
  file=$(find_file "$@")
  zle reset-prompt
  [[ -n $file ]] && _find_run "nvim -- ${(q)file}"
}
find-files-widget() { _find_open }
find-all-files-widget() { _find_open fd --type f --type l --hidden --no-ignore --exclude .git --color never }
find-git-files-widget() { _find_open git ls-files --cached --others --exclude-standard }
find-grep-widget() { _find_run fif }
find-projects-widget() { _find_run tm }
lazygit-widget() { _find_run lazygit }
yazi-widget() { _find_run yazi }
# ,tt / ,tm: nvim's two shells in a tmux pane below (config/tmux/scratch) for this directory; inside one, they
# hide it.
# Not put on the command line: they show and hide, they don't run a command.
scratch-tt-widget() { ~/.config/tmux/scratch tt; zle reset-prompt }
scratch-tm-widget() { ~/.config/tmux/scratch tm; zle reset-prompt }
zle -N find-files-widget
zle -N find-all-files-widget
zle -N find-git-files-widget
zle -N find-grep-widget
zle -N find-projects-widget
zle -N lazygit-widget
zle -N yazi-widget
zle -N scratch-tt-widget
zle -N scratch-tm-widget

# fzf-history-widget (ctrl+r, and / in normal mode; bound in zsh/.zshdefault after atuin's own): atuin's history
# in fzf, so it looks and works like every other fzf. Newest first, each command once, with how long it ran
# (red when it failed) and how long ago; typing filters the commands only. Keys as in every picker
# (config/tmux/picker.zsh): it opens ready to type, jj for j/k. ctrl+r again cycles atuin's filter modes, shown
# on the list's border: global, host, session, workspace (the git repo), directory. ? shows the whole command
# with its directory and exit code. Enter puts the command on the command line to edit, as atuin's
# enter_accept = false. atuin still records every command; config/atuin/fzf-history lists them.
typeset -g _fzf_history=${${(%):-%x}:A:h}/config/atuin/fzf-history
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
