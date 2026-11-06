# The fzf pickers' shared part, sourced by agents (cmd+shift+j), sessionizer (cmd+k), tree (cmd+j),
# agent_resume (zsh/.functions) and the history search (C-r, fzf-history-widget in .fzf.zsh): the agent marks,
# nvim's keys, and a list and preview that stay current while fzf is open.

# an agent's state as its mark, in the colours tmux uses for it (config/tmux/tmux.conf, "Claude Code agents")
typeset -gA picker_marks=(waiting $'\e[33m󰂞\e[0m' done $'\e[32m󰄬\e[0m' working $'\e[36m󰔟\e[0m')
# fzf's preview of the screen of the line's tmux target, without the empty lines below the last output: the
# preview follows the bottom, which would show only those on a screen that isn't full
typeset -g picker_screen='screen=$(tmux capture-pane -ep -t {1} 2> /dev/null) && printf "%s\n" "$screen"'
# fzf's preview label for the line's tmux target: which window the preview shows
typeset -g picker_label='focus:transform-preview-label:tmux display -p -t {1} " #S:#I #W "'
# every picker's preview: below the list, the same size, so they look alike
typeset -g picker_preview='nohidden,down,60%'

# picker <name> [--insert] [--live <command>] [fzf options…]: fzf over the lines on stdin, each
# "key<tab>what fzf shows", printing the chosen line. The keys are nvim's: in normal mode j/k move, wrapping
# round at either end, g/G go to the first/last line, ctrl+d/ctrl+u half a page, q quits, / starts typing a
# filter; while typing, jj goes back to normal mode and keeps the filter, so j/k move through what it matched.
# Esc clears the filter and goes back to the mode the picker opened in; in that mode with no filter, it quits.
# It opens in normal mode, with the input hidden until there's a filter, or with --insert ready to type. The
# prompt says which mode: "<name>> " while typing, "<name>: " in normal mode.
# --live <command> reprints the list every second, and the key is a tmux target (pane, window or session):
# while fzf is open, the list follows the command's output and the preview the target's screen.
function picker() {
  local name=$1 start=normal live=
  shift
  while [[ $1 == --insert || $1 == --live ]]; do
    case $1 in
      --insert) start=insert; shift ;;
      --live) live=$2; shift 2 ;;
    esac
  done
  local typing="$name> " normal="$name: " keys='k,g,G,ctrl-d,ctrl-u,q,/'
  local to_normal="change-prompt($normal)+rebind($keys)" to_insert="change-prompt($typing)+show-input+unbind($keys)"
  # j can't be unbound while typing, as the first j of jj has to be told apart from a j in the filter, so
  # it asks fzf which mode it's in. fzf has no timeout for the second j, unlike nvim: jj always leaves.
  local j="case \$FZF_PROMPT in
    '$normal') echo down ;;
    *) case \$FZF_QUERY in
         *j) echo 'backward-delete-char+$to_normal' ;;
         *) echo 'put(j)' ;;
       esac ;;
  esac"
  # back to the mode it opened in
  local home=$typing back=$to_insert
  [[ $start == normal ]] && home=$normal back=$to_normal
  local esc="if [ -n \"\$FZF_QUERY\" ]; then echo 'change-query()+$back'
    elif [ \"\$FZF_PROMPT\" != '$home' ]; then echo '${${start:#insert}:+hide-input+}$back'; else echo abort; fi"
  # normal mode hides the input while there's no filter. Not with the query change itself: hiding the input
  # in the same step leaves the list unfiltered, so once fzf has filtered.
  local hide="[ \"\$FZF_PROMPT\" = '$normal' ] && [ -z \"\$FZF_QUERY\" ] && echo hide-input"
  # --sync draws the picker once the list is in, not first an empty frame that fills a moment later
  local -a opts=(--sync --cycle --no-multi --no-sort --ansi --delimiter '\t' --with-nth 2 --track --id-nth 1
    --bind "j:transform:$j" --bind 'k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up,q:abort'
    --bind "/:$to_insert" --bind "esc:transform:$esc" --bind "result:transform:$hide")
  if [[ $start == normal ]]; then
    opts+=(--prompt $normal --no-input)
  else
    opts+=(--prompt $typing --bind "start:unbind($keys)")
  fi

  if [[ -z $live ]]; then
    fzf $opts "$@"
    return
  fi
  # fzf takes actions over a socket. A loop checks every second, while fzf runs, and sends only what changed:
  # redrawing an unchanged list or preview flickers. reload-sync swaps the list in at once, --track keeps the
  # cursor on the same key when the order or its line changes. The selected key comes from fzf itself, so its
  # preview refreshes only when that target's screen changed. The loop's output goes nowhere: pickers run
  # inside $(…), which waits for every holder of its pipe, so a loop still in its sleep held fzf's exit up
  # to a second.
  local sock=${TMPDIR:-/tmp}/tmux-picker-$$.sock
  {
    local list=$(eval $live) new shown= screen= target
    while sleep 1 && kill -0 $$ 2> /dev/null; do
      new=$(eval $live)
      if [[ $new != $list ]]; then
        list=$new
        curl -s --unix-socket "$sock" http://localhost -d "reload-sync($live)" > /dev/null
      fi
      target=$(curl -s --unix-socket "$sock" http://localhost | jq -r '.current.text // empty')
      target=${target%%$'\t'*}
      [[ -n $target ]] || continue
      new=$(tmux capture-pane -ep -t "$target" 2> /dev/null)
      # moving the cursor already redraws the preview: only a new screen on the same target needs it
      if [[ $target == $shown && $new != $screen ]]; then
        curl -s --unix-socket "$sock" http://localhost -d refresh-preview > /dev/null
      fi
      shown=$target screen=$new
    done
  } > /dev/null &!
  local loop=$! choice
  choice=$(fzf --listen="$sock" $opts "$@")
  local rc=$?
  kill $loop 2> /dev/null
  [[ -n $choice ]] && print -r -- $choice
  return $rc
}
