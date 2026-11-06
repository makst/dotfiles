# Consistency checks: the files that describe the same thing agree. The setup's steps and links and their
# tables in docs/setup.md, the docs and the README, nvim's plugins and lazy-lock.json, the GIFs and their tapes,
# each key in nvim, VS Code, Android Studio and docs/vim-keys.md, and the keyboard split between Ghostty, tmux,
# AeroSpace and nvim. Sourced by check_dotfiles; lib.zsh has the helpers and indexes.

# table_column <file> <section> [column]: the first word of each code span in a column (default 1) of the
# tables under a heading of the file (setext or #)
table_column() {
  awk -v want="$2" -v column=${3:-1} '
    /^(---|===)$/ { section = prev }
    /^#+ / { section = $0; sub(/^#+ +/, "", section) }
    { prev = $0 }
    !/^\|/ { row = 0 }
    section == want && /^\|/ && !/^\|[-|: ]+$/ && row++ {
      line = $0
      gsub(/\\\|/, "\001", line)
      split(line, cell, "|")
      s = cell[column + 1]
      while (match(s, /`[^`]+`/)) {
        span = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
        gsub(/\001/, "|", span)
        print span
      }
    }
  ' $1
}

# setup steps: what setup_dotfiles runs is defined, docs/setup.md's table of steps lists exactly those (and
# setup_machine, which runs first), and every other setup_* function is under "Not part of setup_dotfiles"
check_setup_steps() {
  local text=$(awk '/for step in/ { on = 1 } on { print } on && /; do/ { exit }' zsh/.functions)
  text=${${${text//\\/ }#*for step in}%%; do*}
  local -a steps=(${=text}) defined=(${(f)"$(zsh_definitions)"})
  local -a table=(${${(f)"$(table_column docs/setup.md 'What `setup_dotfiles` does')"}%% *})
  local -a apart=(${${(f)"$(awk '/^Not part of `setup_dotfiles`/ { on = 1; next } on && /^[A-Za-z]/ { exit }
    on && /^- `/ { s = $0; sub(/^- `/, "", s); sub(/`.*/, "", s); print s }' docs/setup.md)"}%% *})
  local f
  for f in $steps; do
    (( $defined[(Ie)$f] )) || print -r -- "zsh/.functions: setup_dotfiles runs $f, which isn't defined"
  done
  for f in $steps setup_machine; do
    (( $table[(Ie)$f] )) || print -r -- "docs/setup.md: $f isn't in the table of what setup_dotfiles does"
  done
  for f in $table; do
    (( $steps[(Ie)$f] )) || [[ $f == setup_machine ]] ||
      print -r -- "docs/setup.md: the table of steps lists $f, which setup_dotfiles doesn't run"
  done
  for f in ${(M)defined:#(setup_*|*_setup)}; do
    (( $steps[(Ie)$f] || $apart[(Ie)$f] )) || [[ $f == (setup_machine|setup_dotfiles) ]] ||
      print -r -- "zsh/.functions: $f is neither a step of setup_dotfiles nor under \"Not part of\" in docs/setup.md"
  done
  note="$(count $#steps step)"
}

# symlinks: every link the setup makes is in docs/setup.md's table of symlinks, and every row there is made
# by the setup; <name> in a row stands for any name
check_symlinks() {
  local -a rows=(${${(f)"$(table_column docs/setup.md Symlinks)"}%/})
  local dst src where row
  local -A listed
  while IFS=$'\t' read -r dst src where; do
    for row in $rows; do
      # as patterns, with ~ out of the way (zsh would expand it) and <name> as *
      [[ ${dst/#\~/HOME} == ${~${${row/#\~/HOME}//<[^>]##>/*}} ]] && { listed[$row]=1; continue 2 }
    done
    print -r -- "$where: links $dst, which isn't in docs/setup.md's table of symlinks"
  done < $tmp/links.out
  for row in $rows; do
    (( $+listed[$row] )) || print -r -- "docs/setup.md: the table of symlinks has $row, which the setup doesn't link"
  done
  note=$(count $#rows link)
}

# README: every page in docs/ is linked from the README
check_readme() {
  local kind file line target
  local -A linked
  while IFS=$'\t' read -r kind file line target; do
    [[ $kind == L && $file == README.md ]] && linked[${target%%\#*}]=1
  done < $tmp/md.out
  for file in ${(M)md_files:#docs/*.md}; do
    (( $+linked[$file] )) || print -r -- "README.md doesn't link to $file"
  done
  note=$(count ${#${(M)md_files:#docs/*.md}} page)
}

# this Mac's files: each template in config/machine is in docs/setup.md's table of them and is read by the
# config (as ~/.config/dotfiles/<name>)
check_machine_files() {
  local -a rows=(${(f)"$(table_column docs/setup.md 'Several Macs')"})
  local -A used
  local kind file line p
  while IFS=$'\t' read -r kind file line p; do
    [[ $kind == T && $file != *.md && $p == '~/.config/dotfiles/'* ]] && used[${${p#\~/.config/dotfiles/}%%/*}]=1
  done < $tmp/path.out
  local -a templates=(${${(M)files:#config/machine/*}#config/machine/})
  for file in $templates; do
    (( $rows[(Ie)$file] )) || print -r -- "docs/setup.md: config/machine/$file isn't in the table of this Mac's files"
    (( $+used[$file] )) || print -r -- "config/machine/$file: nothing reads ~/.config/dotfiles/$file"
  done
  note=$(count $#templates template)
}

# nvim's plugins: lua/user/plugins.lua and lazy-lock.json list the same ones, with keys lazy.nvim knows
check_plugins() {
  nvim_results plugins || return
  note+=" plugins"
}

# GIFs: each tape renders a GIF that's in docs/img, each GIF there comes from a tape and is shown in a doc
check_gifs() {
  local tape out gif kind file line target
  local -A made shown
  local -a tapes=(${(M)text_files:#docs/tapes/*.tape}) gifs=(${(M)files:#docs/img/*.gif})
  for tape in $tapes; do
    out=${${(M)${(f)"$(<$tape)"}:#Output *}#Output }
    if [[ -z $out ]]; then
      print -r -- "$tape: no Output line"
    elif [[ ! -e $out ]]; then
      print -r -- "$tape: renders $out, which isn't in the repo (make_gifs ${tape:t:r})"
    fi
    made[$out]=1
  done
  while IFS=$'\t' read -r kind file line target; do
    [[ $kind == L && $target == *.gif ]] && shown[${target:t}]=1
  done < $tmp/md.out
  for gif in $gifs; do
    (( $+made[$gif] )) || print -r -- "$gif: no tape in docs/tapes renders it"
    (( $+shown[${gif:t}] )) || print -r -- "$gif: no doc shows it"
  done
  note="$(count $#tapes tape), $(count $#gifs GIF)"
}

# keys_index: the keys each editor maps, "<editor> <key>", with , for the leader, <C-x> for control keys,
# <Space> and <BS> for the space bar and Backspace:
# nvim's keymap.set and map() calls (Lua), VS Code's vim.*KeyBindings (JSON), IdeaVim's map commands, plus what
# their plugins and settings map on their own (vim-tmux-navigator, surround, commentary)
keys_index() {
  awk '
    {
      s = $0
      while (match(s, /keymap\.set\([ ]*(\{[^}]*\}|\047[^\047]*\047|"[^"]*")[ ]*,[ ]*\047[^\047]+\047/) || match(s, /(^|[^.A-Za-z_])map\([ ]*\047[^\047]+\047/)) {
        m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        sub(/\047$/, "", m); sub(/.*\047/, "", m)
        print "nvim\t" m
      }
    }
  ' ${(M)text_files:#config/nvim/*.lua}
  jq -r 'to_entries[] | select(.key | test("^vim\\..*KeyBindings")) | .value[] | "vscode\t" + (.before | join(""))' \
    config/vscode/settings.json
  awk '/^[ \t]*[nvxio]?(nore)?map[ \t]/ { k = $2; if (k ~ /^<(silent|expr|buffer)>$/) k = $3; print "ideavim\t" k }' \
    config/ideavim/ideavimrc
  # what plugins and settings map without a line in the config
  grep -q "'christoomey/vim-tmux-navigator'" config/nvim/lua/user/plugins.lua && print -l "nvim\t<C-"{h,j,k,l}">"
  grep -q "'kylechui/nvim-surround'" config/nvim/lua/user/plugins.lua && print -l "nvim\t"{ys,ds,cs,S}
  print -l "nvim\t"{gc,gcc,"]b","[b"} # built into nvim
  [[ $(jq -r '.["vim.surround"]' config/vscode/settings.json) == true ]] && print -l "vscode\t"{ys,ds,cs,S}
  grep -q '^set surround' config/ideavim/ideavimrc && print -l "ideavim\t"{ys,ds,cs,S}
  grep -q '^set commentary' config/ideavim/ideavimrc && print -l "ideavim\t"{gc,gcc}
  return 0
}

# key_spans <text>: sets reply to the keys in the text's code spans, the way the configs write them: C-h as
# <C-h>, C-h/j/k/l as each of the four, Space as <Space>, Backspace as <BS> (in reply rather than printed, so
# no subshell per call)
key_spans() {
  reply=()
  local span k
  local -i i
  # split at the backticks (\x60: a literal one would start a command substitution); the spans are every
  # second part
  local -a parts=("${(@ps:\x60:)1}")
  for (( i = 2; i <= $#parts; i += 2 )); do
    span=$parts[i]
    [[ -n $span && $span != *[[:space:]]* ]] || continue
    case $span in
      (C-?/*) for k in ${(s:/:)${span#C-}}; do reply+="<C-$k>"; done ;;
      (C-?) reply+="<$span>" ;;
      (Space) reply+='<Space>' ;;
      (Backspace) reply+='<BS>' ;;
      (*) reply+=$span ;;
    esac
  done
}

# keys: docs/vim-keys.md's tables match the configs. A ✓ (or a plugin's name) means the editor maps the key,
# – means it doesn't, · that it's the editor's own. Each key VS Code or Android Studio maps is in the doc, so a
# key added to one of them gets documented. The leader is , in all three.
check_keys() {
  local -A mapped documented
  local editor key
  keys_index | sed -E 's/<[Ll]eader>/,/g; s/<[Ss]pace>/<Space>/g; s/<[Bb][Ss]>/<BS>/g' > $tmp/keys.out
  # keys go into subscripts through a variable: written out, [d or ]d would end the subscript
  local k
  while IFS=$'\t' read -r editor key; do k="$editor $key"; mapped[$k]=1; done < $tmp/keys.out
  local -A column_editor=(nvim nvim 'VS Code' vscode 'Android Studio' ideavim)
  local line value span
  local -a cells heads groups values keys reply
  local -i n=0 i g in_table=0
  for line in "${(@f)$(<docs/vim-keys.md)}"; do
    # every key the doc names anywhere
    key_spans $line
    for k in $reply; do documented[$k]=1; done
    if [[ $line != \|* ]]; then
      in_table=0
      continue
    fi
    # the cells, without the empty ones before the first | and after the last
    cells=("${(@s:|:)line}")
    cells=("${(@)${(@)${(@)cells[2,-2]}/#[[:space:]]##/}/%[[:space:]]##/}")
    if (( !in_table )); then
      heads=("${(@)cells}") in_table=1
      continue
    fi
    [[ $line == \|[-:\|\ ]## ]] && continue
    # the key column holds groups of keys separated by " / "; a column has one value, or one per group
    groups=("${(@s: / :)cells[1]}")
    for i in {1..$#heads}; do
      editor=$column_editor[$heads[i]]
      [[ -n $editor ]] || continue
      values=("${(@s: / :)cells[i]}")
      for g in {1..$#groups}; do
        value=$values[g]
        (( $#values == 1 )) && value=$values[1]
        key_spans $groups[g]
        keys=($reply)
        for key in $keys; do
          [[ $key == , ]] && continue # the leader, checked below
          n+=1
          k="$editor $key"
          case $value in
            (·*) ;;
            (–*) (( $+mapped[$k] )) &&
              print -r -- "docs/vim-keys.md: $heads[i] maps $key, but the table says it doesn't" ;;
            (*) (( $+mapped[$k] )) ||
              print -r -- "docs/vim-keys.md: $heads[i] should map $key ($value), but its config doesn't" ;;
          esac
        done
      done
    done
  done
  # IDE keys the doc doesn't mention
  while IFS=$'\t' read -r editor key; do
    [[ $editor == nvim ]] && continue
    k=$key
    (( $+documented[$k] )) || print -r -- "docs/vim-keys.md doesn't mention $key, which $editor maps"
  done < $tmp/keys.out
  # the leader
  grep -q "mapleader = ','" config/nvim/lua/user/keymaps.lua || print "nvim's leader isn't ,"
  [[ $(jq -r '.["vim.leader"]' config/vscode/settings.json) == , ]] || print "VS Code's vim.leader isn't ,"
  grep -q "^let mapleader = ','" config/ideavim/ideavimrc || print "IdeaVim's mapleader isn't ,"
  note=$(count $n key)
}

# keyboard: each layer keeps to its modifier (README, "How the keyboard is split"): AeroSpace's own keys use
# Option, Ghostty binds no Option and not tmux's C-a or C-h/j/k/l, tmux's prefix-free keys use no Option, and
# nvim maps no Option or Cmd keys, which never reach it
check_keyboard() {
  local line
  local -i n=0
  awk '/^\[/ { main = ($0 == "[mode.main.binding]"); next } main && /^[a-z0-9-]+ *=/ { n++; k = $1; if (k !~ /(^|-)alt-/) print "config/aerospace/aerospace.toml:" NR ": " k " uses no Option (alt)" } END { print "count " n }' \
    config/aerospace/aerospace.toml > $tmp/keyboard.out
  awk '/^keybind *=/ { n++; t = $0; sub(/^keybind *= */, "", t); sub(/=.*/, "", t); gsub(/(global|all|unconsumed|performable):/, "", t)
    if (t ~ /(^|\+)(alt|opt|option)\+/) print "config/ghostty/config:" NR ": " t " uses Option, which AeroSpace owns"
    if (t ~ /^ctrl\+[ahjkl]$/) print "config/ghostty/config:" NR ": " t " is tmux'"'"'s (prefix, panes)" } END { print "count " n }' \
    config/ghostty/config >> $tmp/keyboard.out
  awk '/^[ \t]*bind(-key)?[ \t].*-n[ \t]+M-/ { print "config/tmux/tmux.conf:" NR ": a prefix-free Option key, which AeroSpace takes first" }' \
    config/tmux/tmux.conf >> $tmp/keyboard.out
  grep -nE "keymap\.set\(.*'<[MAD]-" ${(M)text_files:#config/nvim/*.lua} |
    sed -E 's/^([^:]*:[0-9]+):.*/\1: an Option or Cmd key, which nvim never gets/' >> $tmp/keyboard.out
  for line in "${(@f)$(<$tmp/keyboard.out)}"; do
    [[ $line == count\ * ]] && { n+=${line#count }; continue }
    [[ -n $line ]] && print -r -- $line
  done
  note=$(count $n binding)
}

# Ghostty → tmux: each Cmd key Ghostty turns into tmux's prefix and a key (text:\x01…) reaches a binding tmux
# has, its own or one from tmux.conf
check_ghostty_tmux() {
  (( $+commands[tmux] )) || { print "tmux not installed"; return 2 }
  local -A prefix
  local kind table key line text code
  local -i n=0
  while IFS=$'\t' read -r kind table key; do
    [[ $kind == K && $table == prefix ]] && prefix[${key#\\}]=1
  done < $tmp/tmux.out
  for line in ${(M)${(f)"$(<config/ghostty/config)"}:#keybind*=text:\\x01*}; do
    text=${line#*=text:\\x01}
    # one character, or \xNN, where 01 to 1a are C-a to C-z
    if [[ $text == \\x(#b)([0-9a-fA-F](#c2)) ]]; then
      code=$(( 16#$match[1] ))
      (( code >= 1 && code <= 26 )) && key="C-${(L)${(#)$(( code + 64 ))}}" || key=${(#)code}
    else
      key=$text
    fi
    n+=1
    (( $+prefix[$key] )) || print -r -- "config/ghostty/config: ${line%%=text*} sends prefix $key, which tmux doesn't bind"
  done
  note=$(count $n key)
}

group "Consistency: the files that describe the same thing agree"
check "setup_dotfiles' steps match docs/setup.md" check_setup_steps
check "every symlink is in docs/setup.md, and only those" check_symlinks
check "the README links every page in docs/" check_readme
check "this Mac's files are documented and read" check_machine_files
check "nvim's plugins are pinned in lazy-lock.json" check_plugins
check "every GIF has its tape and its doc" check_gifs
check "docs/vim-keys.md matches nvim, VS Code and IdeaVim" check_keys
check "each layer keeps to its modifier" check_keyboard
check "Ghostty's Cmd keys reach tmux bindings" check_ghostty_tmux
