# Reference checks: whatever a doc, a comment or a config points at exists: links and their anchors, paths in
# the repo and paths in ~ that are links into it, the functions and aliases the docs name, nvim's requires, the
# scripts Claude Code's settings run. A rename that leaves one of these behind fails here. Sourced by
# check_dotfiles; lib.zsh has the helpers and indexes.

# links: Markdown links and images point at files that exist, and their #anchors at headings in them
check_links() {
  load_slugs
  local kind file line target dest anchor
  local -i n=0
  while IFS=$'\t' read -r kind file line target; do
    [[ $kind == L ]] || continue
    [[ $target == ([a-z]##:*|\#) ]] && continue
    n+=1
    dest=${target%%\#*}
    anchor=${${(M)target:#*\#*}#*\#}
    if [[ -z $dest ]]; then
      dest=$file
    elif [[ $dest == /* ]]; then
      dest=${dest#/}
    else
      [[ ${file:h} == . ]] || dest=${file:h}/$dest
      dest=${${dest:a}#$repo/}
    fi
    if [[ ! -e $dest ]]; then
      print -r -- "$file:$line: $target: no such file"
    elif [[ -n $anchor && $dest == *.md && $slugs[$dest] != *" $anchor "* ]]; then
      print -r -- "$file:$line: $target: no heading for #$anchor in $dest"
    fi
  done < $tmp/md.out
  note=$(count $n link)
}

# sections: a `doc`, "Heading" mention (CLAUDE.md's way of pointing into the docs) names a heading the doc has
check_sections() {
  load_slugs
  local kind file line doc slug
  local -i n=0
  while IFS=$'\t' read -r kind file line doc slug; do
    [[ $kind == R ]] || continue
    n+=1
    [[ $doc == README ]] && doc=README.md
    [[ $slugs[$doc] == *" $slug "* ]] || print -r -- "$file:$line: $doc has no heading \"$slug\""
  done < $tmp/md.out
  note=$(count $n mention)
}

# paths: every repo path a file mentions exists, also through a link in ~ (~/.config/tmux/sessionizer is
# config/tmux/sessionizer); paths git ignores on purpose (zsh/.private) count as existing
check_paths() {
  local -A link known
  link_map
  local kind file line p dst best
  local -a unknown where
  local -i n=0
  while IFS=$'\t' read -r kind file line p; do
    p=${p%%[.,:;]##}
    if [[ $kind == T ]]; then
      p=${p%/}
      best=
      for dst in ${(k)link}; do
        [[ $p == $dst || $p == $dst/* ]] && (( $#dst > $#best )) && best=$dst
      done
      [[ -n $best ]] || continue
      p=${link[$best]}${p#$best}
    else
      case $p in
        (lua|lua/*) p=config/nvim/$p ;;
        (lsp|lsp/*) p=config/nvim/lua/user/$p ;;
      esac
    fi
    n+=1
    [[ -e $p ]] && continue
    unknown+=($p ${p%/}/)
    where+="$file:$line: ${p%/}"
  done < $tmp/path.out
  # a path git ignores is known, as a file or as a directory (.claude/worktrees/)
  for p in ${(f)"$(ignored $unknown)"}; do known[${p%/}]=1; done
  for p in $where; do
    (( $+known[${p##*: }] )) || print -r -- "$p: no such file or directory"
  done
  note=$(count $n path)
}

# link sources: every file the setup functions link from is in the repo
check_link_sources() {
  local dst src where
  local -i n=0
  while IFS=$'\t' read -r dst src where; do
    n+=1
    # a link to something outside the repo (/opt/homebrew/bin/nvim) is that Mac's business
    [[ $src == (.|./*) && ! -e $src ]] && print -r -- "$where: links $dst to ${src#./}, which doesn't exist"
  done < $tmp/links.out
  note=$(count $n link)
}

# names: a function or setting the docs name in code (`setup_python`), or a Brewfile names in a comment,
# still exists in the code, so a rename can't leave the docs behind
check_names() {
  local -A words
  local -a list=(${(f)"$(<$tmp/words.out)"}) one=(1)
  words=(${list:^^one})
  local file line name
  local -i n=0
  awk '
    FNR == 1 { code = 0 }
    /^[ \t]*(```|~~~)/ { code = !code; next }
    code { next }
    {
      s = $0
      while (match(s, /`[^`]+`/)) {
        span = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
        # another tool'"'"'s setting (`ktlint_code_style = android_studio`) is not ours to check
        if (span ~ /=/) continue
        if (match(span, /^[a-z][a-z0-9]*_[a-z0-9_]*[a-z0-9]/)) print FILENAME "\t" FNR "\t" substr(span, RSTART, RLENGTH)
      }
    }
  ' $md_files > $tmp/names.out
  # the Brewfiles name their users in plain comments
  awk -F'#' 'NF > 1 { s = $2; while (match(s, /[a-z][a-z0-9]*_[a-z0-9_]*[a-z0-9]/)) {
    print FILENAME "\t" FNR "\t" substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } }' \
    Brewfile config/machine/Brewfile >> $tmp/names.out
  while IFS=$'\t' read -r file line name; do
    n+=1
    (( $+words[$name] )) || print -r -- "$file:$line: $name isn't in the code any more"
  done < $tmp/names.out
  note=$(count $n name)
}

# commands: what the docs' tables of aliases and functions list exists: a zsh alias or function, or for
# `git <name>`, an alias in config/git/.gitconfig
check_commands() {
  local -A defined git_aliases
  local -a list=(${(f)"$(zsh_definitions)"}) one=(1)
  defined=(${list:^^one})
  list=(${${(f)"$(git config --file config/git/.gitconfig --name-only --get-regexp '^alias\.')"}#alias.})
  git_aliases=(${list:^^one})
  local file line span
  local -a words
  local -i n=0
  awk '
    FNR == 1 { section = "" }
    /^(---|===)$/ { section = prev }
    /^#+ / { section = $0 }
    { prev = $0 }
    tolower(section) ~ /alias|function/ && /^\| `/ {
      split($0, cell, "|")
      s = cell[2]
      while (match(s, /`[^`]+`/)) {
        print FILENAME "\t" FNR "\t" substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
      }
    }
  ' $md_files > $tmp/commands.out
  while IFS=$'\t' read -r file line span; do
    words=(${=span})
    n+=1
    if [[ $words[1] == git ]]; then
      (( $+git_aliases[$words[2]] )) || print -r -- "$file:$line: git $words[2] isn't an alias in config/git/.gitconfig"
    else
      (( $+defined[$words[1]] )) || print -r -- "$file:$line: $words[1] isn't an alias or function in the zsh config"
    fi
  done < $tmp/commands.out
  note=$(count $n command)
}

# requires: every require('user.…') in the nvim config has its file, and every file is required
check_requires() {
  nvim_results requires || return
  note+=" requires"
}

# Claude Code's settings: the hooks and the status line they run are in config/claude and executable
check_claude_commands() {
  local -A link
  link_map
  local dst command script
  local -a words
  local -i n=0
  for command in ${(f)"$(jq -r '[.. | objects | select(has("command")) | .command] | .[]' config/claude/settings.json)"}; do
    words=(${(z)command})
    script=$words[1]
    n+=1
    for dst in ${(k)link}; do
      [[ $script == $dst/* || $script == $dst ]] || continue
      script=${link[$dst]}${script#$dst}
      break
    done
    [[ $script == '~/'* ]] && { print -r -- "$command: not a file the setup links into ~/.claude"; continue }
    [[ -x $script ]] || print -r -- "$command: $script isn't executable"
  done
  note=$(count $n command)
}

group "References: what the docs, comments and configs point at exists"
check "Markdown links and anchors resolve" check_links
check "doc, \"Heading\" mentions name real headings" check_sections
check "paths in the repo and in ~ exist" check_paths
check "what the setup links from exists" check_link_sources
check "functions and settings the docs name exist" check_names
check "the docs' aliases and functions are defined" check_commands
check "nvim's requires resolve and nothing is dead" check_requires
check "Claude Code's hooks and status line are executable" check_claude_commands
