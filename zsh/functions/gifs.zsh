#!/usr/bin/env zsh
# Shell functions for the GIFs in the docs (docs/tapes, docs/gifs.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# make_gifs [tape…]: render the GIFs in docs/img from the VHS tapes in docs/tapes (all of them, or the ones
# named, e.g. `make_gifs tmux-panes`). Each tape runs in the real tmux config with the Ghostty theme and font,
# in a separate tmux server (docs/tapes/demo.tmux.conf) and a made-up HOME (docs/tapes/demo-home), and
# docs/tapes/keycast shows the keys pressed under the status bar. Rerun after changing a binding or the theme,
# and commit the GIFs.
function make_gifs() {
  local repo=$real_script_dir tmp tape name
  (( $+commands[vhs] )) || { print -u2 "make_gifs needs vhs (Brewfile)"; return 1 }
  # resolved, since mktemp's path runs through the /var symlink; programs that show paths relative to HOME
  # (Claude Code's header) would show the long resolved one instead of ~/…
  tmp=$(mktemp -d) && tmp=${tmp:A} || return

  # the Ghostty theme as a VHS theme
  local -A c
  local key value
  while IFS=' =' read -r key value; do
    [[ $key == palette ]] && key=${value%%=*} value=${value#*=}
    c[$key]=$value
  done < <(grep -v '^#' $repo/config/ghostty/themes/base16)
  local -a names=(black red green yellow blue magenta cyan white)
  local theme="{\"name\":\"base16\",\"background\":\"$c[background]\",\"foreground\":\"$c[foreground]\""
  theme+=",\"cursor\":\"$c[cursor-color]\",\"selection\":\"$c[selection-background]\""
  local i
  for i in {1..8}; do
    theme+=",\"$names[i]\":\"$c[$((i - 1))]\",\"bright${(C)names[i]}\":\"$c[$((i + 7))]\""
  done
  theme+='}'

  local -a tapes=(${@:+$repo/docs/tapes/${^@}.tape})
  (( $#tapes )) || tapes=($repo/docs/tapes/*.tape(N))
  for tape in $tapes; do
    name=${tape:t:r}
    print -P "%F{blue}=> $name%f"
    tmux -L demo kill-server 2> /dev/null
    # a fresh HOME per tape, so one tape's history or changes don't show up in the next
    $repo/docs/tapes/demo-home $tmp/$name $repo || return
    {
      print -r -- 'Set Shell zsh'
      print -r -- 'Set FontFamily "Source Code Pro, Symbols Nerd Font Mono"'
      print -r -- 'Set FontSize 18'
      print -r -- 'Set Width 1200'
      print -r -- 'Set Height 640'
      print -r -- 'Set Padding 16'
      print -r -- 'Set TypingSpeed 80ms'
      print -r -- "Set Theme $theme"
      print -r -- 'Hide'
      print -r -- "Type \"cd ${(q)repo} && HOME=$tmp/$name docs/tapes/keycast demo config/ghostty/config tmux -L demo -f docs/tapes/demo.tmux.conf new -s main -c $tmp/$name/dotfiles\" Enter"
      # the first start in a new HOME sets up the prompt and plugins' caches
      print -r -- 'Wait+Screen@30s /❯/'
      # a first command lets tmux name the window after the shell; the caption for its Enter is cleared
      print -r -- "Type \" clear; tmux set -g @keys ''\" Enter"
      print -r -- 'Sleep 1s'
      print -r -- 'Show'
      cat $tape
    } > $tmp/$name.tape
    (cd $repo && vhs $tmp/$name.tape) || { tmux -L demo kill-server 2> /dev/null; return 1 }
    tmux -L demo kill-server 2> /dev/null
  done
  trash $tmp
}
