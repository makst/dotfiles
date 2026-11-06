# What several groups of checks share: helpers, and the indexes check_dotfiles builds once, all at the same
# time, before the groups run (build_indexes). An index is a file in $tmp with one record per line, fields
# separated by tabs. Sourced by check_dotfiles, which provides $repo, $tmp, $text_files, $md_files and
# $shebangs.

# count <n> <thing> [<things>]: "1 file", "2 files"; the plural when adding an s doesn't make it
count() {
  if (( $1 == 1 )); then
    print -rn -- "$1 $2"
  else
    print -rn -- "$1 ${3:-$2s}"
  fi
}

# zsh_files: the zsh files, by their name or their shebang
zsh_files() {
  local f
  for f in $text_files; do
    [[ $f == (.zshrc|*.zsh|zsh/.*|config/machine/zshrc) || $shebangs[$f] == *zsh* ]] && print -r -- $f
  done
}

# ignored <path…>: the paths git ignores, with the repo's own global ignore file (what setup_git links), so
# that a path which exists only on some Macs, or in other projects (.claude/worktrees/), is known everywhere
ignored() {
  (( $# )) || return 0
  print -rl -- "$@" | git -c core.excludesFile=config/git/ignore check-ignore --stdin --no-index 2> /dev/null
}

# zsh_definitions: every function and alias the zsh config defines, one name per line
zsh_definitions() {
  awk '
    { s = $0 }
    s ~ /^[[:space:]]*function [A-Za-z_]/ { sub(/^[[:space:]]*function /, "", s); sub(/[ ({].*/, "", s); print s; next }
    s ~ /^[[:space:]]*[A-Za-z_][A-Za-z0-9_-]*[[:space:]]*\(\)/ { sub(/^[[:space:]]*/, "", s); sub(/[[:space:]]*\(.*/, "", s); print s; next }
    s ~ /^[[:space:]]*alias / {
      sub(/^[[:space:]]*alias( -[gs])? /, "", s)
      while (match(s, /^[A-Za-z0-9_.-]+=/)) {
        print substr(s, 1, RLENGTH - 1)
        s = substr(s, RLENGTH + 1)
        if (s ~ /^"/) { sub(/^"[^"]*"[[:space:]]*/, "", s) } else if (s ~ /^\047/) { sub(/^\047[^\047]*\047[[:space:]]*/, "", s) } else { sub(/^[^[:space:]]*[[:space:]]*/, "", s) }
      }
    }
  ' .zshrc .fzf.zsh zsh/.* zsh/functions/*.zsh config/tmux/sessionizer 2> /dev/null
}

# md_index: one pass over the Markdown files: "H file slug" for every heading (GitHub's anchor for it, a
# repeated one numbered), "L file line target" for every link and image, "R file line doc slug" for every
# `doc`, "Heading" mention. Code blocks, code spans and front matter are skipped.
md_index() {
  awk '
    function slug(t) {
      t = tolower(t)
      gsub(/\]\([^)]*\)/, "", t)
      gsub(/[^a-z0-9 _-]/, "", t)
      gsub(/ /, "-", t)
      return t
    }
    function heading(t,   s) {
      s = slug(t)
      print "H\t" FILENAME "\t" (seen[FILENAME, s]++ ? s "-" (seen[FILENAME, s] - 1) : s)
    }
    FNR == 1 { code = 0; front = ($0 == "---"); prev = ""; if (front) next }
    front { if ($0 == "---") front = 0; next }
    /^[ \t]*(```|~~~)/ { code = !code; prev = ""; next }
    code { next }
    {
      if ($0 ~ /^(=+|-+)[ \t]*$/ && prev != "" && prev !~ /^[|>]/) { heading(prev); prev = ""; next }
      if ($0 ~ /^#+ /) { t = $0; sub(/^#+ +/, "", t); sub(/ +#+ *$/, "", t); heading(t) }
      s = $0
      while (match(s, /`?[A-Za-z0-9_.\/-]*(\.md|README)`?,? "[^"]+"/)) {
        m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        doc = m; sub(/`?,? ".*/, "", doc); gsub(/`/, "", doc)
        h = m; sub(/^[^"]*"/, "", h); sub(/"$/, "", h)
        print "R\t" FILENAME "\t" FNR "\t" doc "\t" slug(h)
      }
      s = $0
      gsub(/`[^`]*`/, "", s)
      while (match(s, /\]\([^) ]+\)|src="[^"]+"/)) {
        m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        sub(/^(\]\(|src=")/, "", m); sub(/[)"]$/, "", m)
        print "L\t" FILENAME "\t" FNR "\t" m
      }
      prev = $0
    }
  ' $md_files
}

# slugs[file]: the anchors of each Markdown file's headings, space-separated (load_slugs fills it)
typeset -A slugs
load_slugs() {
  (( $#slugs )) && return
  local kind file slug rest
  while IFS=$'\t' read -r kind file slug rest; do
    [[ $kind == H ]] && slugs[$file]+=" $slug "
  done < $tmp/md.out
}

# path_index: every path in the repo or in ~ that a text file mentions: "P file line path" for paths from one
# of the repo's top-level directories (code's "$real_script_dir/…" included; nvim's lua/ and lsp/ count from
# config/nvim; zsh/ only for its dotfiles, zsh/datetime is a module), "T file line ~/path" for paths in ~;
# not checks/mutate, whose breaks name missing files on purpose
path_index() {
  awk '
    {
      line = $0
      gsub(/\$\{?(real_script_dir|repo|DOTFILES)\}?\//, " ", line)
      s = line
      while (match(s, /(^|[^A-Za-z0-9_.\/~$-])(\.github|\.claude|checks|config|docs|lua|lsp|zsh)\/[A-Za-z0-9_.\/-]*/)) {
        t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        if (t !~ /^(\.github|\.claude|checks|config|docs|lua|lsp|zsh)\//) t = substr(t, 2)
        if (t ~ /^zsh\/[^.]/) continue
        print "P\t" FILENAME "\t" FNR "\t" t
      }
      s = line
      gsub(/\$\{?HOME\}?\//, "~/", s)
      while (match(s, /~\/[A-Za-z0-9_.\/-]+/)) {
        print "T\t" FILENAME "\t" FNR "\t" substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      }
    }
  ' ${text_files:#checks/mutate}
}

# links_index: what the setup links, from the `ln -s` lines of zsh/functions/*.zsh and prepare-zsh-install.sh:
# "~/link source file:line". A loop's variable takes each value of its word list or glob, a local variable its
# value; a source in the repo starts with ./ (the repo itself is .), anything else is outside it.
links_index() {
  local file line loop v
  local -i n at
  local -A vars
  local -a words values
  # expand <word>: the word with the repo as ., HOME as ~, the function's locals and the loop's variable ($v)
  # filled in
  expand() {
    local w=$1 name
    w=${${${w//\$\{real_script_dir\}/.}//\$real_script_dir/.}//\$DOTFILES/.}
    w=${${w//\$\{HOME\}/\~}//\$HOME/\~}
    for name in ${(k)vars}; do w=${${w//\$\{$name\}/$vars[$name]}//\$$name/$vars[$name]}; done
    [[ -n $loop ]] && w=${${${w//\$\{${loop}:t\}/${v:t}}//\$\{$loop\}/$v}//\$$loop/$v}
    print -r -- $w
  }
  for file in zsh/functions/*.zsh prepare-zsh-install.sh; do
    n=0
    for line in "${(@f)$(<$file)}"; do
      n+=1
      words=(${(Q)${(z)line}})
      case $words[1] in
        (function) vars=() loop= ;;
        (local) for v in ${(M)words[2,-1]:#*=*}; do vars[${v%%=*}]=${v#*=}; done ;;
        (for)
          loop=$words[2]
          values=(${words[4,-1]:#(\;|do)})
          # a glob of the repo's files is expanded; any other computed list stays as it is
          if (( $#values == 1 )) && [[ $values[1] == \$real_script_dir/[^\$]#\** ]]; then
            setopt local_options null_glob
            values=(${~values[1]/\$real_script_dir/.})
          fi
          ;;
        (done) loop= ;;
      esac
      at=${words[(i)ln]}
      [[ $words[at+1] == -s* ]] || continue
      if [[ -n $loop && $words[at+2]$words[at+3] == *\$*$loop* ]]; then
        for v in $values; do
          print -r -- "$(expand $words[at+3])"$'\t'"$(expand $words[at+2])"$'\t'"$file:$n"
        done
      else
        print -r -- "$(expand $words[at+3])"$'\t'"$(expand $words[at+2])"$'\t'"$file:$n"
      fi
    done
  done
}

# link_map: fills the caller's associative array `link`, ~/link → its source in the repo, from links_index
link_map() {
  local dst src rest
  while IFS=$'\t' read -r dst src rest; do
    [[ $src == (.|./*) ]] && link[$dst]=${src#./}
  done < $tmp/links.out
}

# words_index: every name with an underscore in it (setup_python, used_percentage) in the code, the comments
# and the configs, one per line; not the Brewfiles' own, which check_names checks against these, nor
# checks/mutate's, whose breaks name missing functions on purpose
words_index() {
  awk '{ while (match($0, /[A-Za-z_][A-Za-z0-9_]*_[A-Za-z0-9_]+/)) { print substr($0, RSTART, RLENGTH); $0 = substr($0, RSTART + RLENGTH) } }' \
    ${${text_files:#*.md}:#((|*/)Brewfile|checks/mutate)} | sort -u
}

# nvim_index: checks/nvim.lua in a headless nvim without any config (Lua syntax, nvim's requires, plugins and
# lazy-lock.json, key descs, keys outside keymaps.lua), when nvim is installed
nvim_index() {
  (( $+commands[nvim] )) || return 0
  nvim --clean --headless -l checks/nvim.lua $repo ${(M)text_files:#config/nvim/*.lua} 2>&1
}

# nvim_results <check>: the problems nvim_index found for one of its checks; sets note to how many things it
# checked
nvim_results() {
  (( $+commands[nvim] )) || { print "nvim not installed"; return 2 }
  local line
  for line in "${(@f)$(<$tmp/nvim.out)}"; do
    case $line in
      ("count $1 "*) note=${line##* } ;;
      ("$1: "*) print -r -- ${line#$1: } ;;
      (count\ *|syntax:\ *|requires:\ *|plugins:\ *|descs:\ *|keymaps:\ *) ;;
      (*) print -r -- $line ;; # nvim itself failed
    esac
  done
}

# brew_ruby: Homebrew's own Ruby, else the one on PATH
brew_ruby() {
  local ruby=${HOMEBREW_PREFIX:-/opt/homebrew}/Library/Homebrew/vendor/portable-ruby/current/bin/ruby
  [[ -x $ruby ]] || ruby=${commands[ruby]}
  print -r -- $ruby
}

# brew_index: the Brewfiles' entries for each kind of Mac (checks/brewfile.rb), "file kind type name"; its
# errors in brew.err
brew_index() {
  local ruby=$(brew_ruby)
  [[ -n $ruby ]] || return 0
  $ruby checks/brewfile.rb Brewfile config/machine/Brewfile 2> $tmp/brew.err
}

# tmux_index: tmux.conf executed in a throwaway tmux server, which also catches the unknown options and values
# that parsing alone misses: "E error" for each error, then "K table key" for every key binding it ends up
# with. Its run and if-shell lines would start tpm and the plugins (tmux-continuum restores sessions), so
# they're only parsed, like the GIFs' demo.tmux.conf.
tmux_index() {
  (( $+commands[tmux] )) || return 0
  local socket=check_dotfiles_$$ line
  local -a words
  sed -E 's/^([[:space:]]*(run|run-shell|if|if-shell)[[:space:]])/# \1/' config/tmux/tmux.conf > $tmp/tmux.conf
  for line in ${(f)"$(tmux -L $socket -f /dev/null start-server \; \
    source-file -n config/tmux/tmux.conf docs/tapes/demo.tmux.conf \; source-file $tmp/tmux.conf \; \
    list-keys 2>&1)"}; do
    if [[ $line == bind-key\ * ]]; then
      # bind-key [-r] -T <table> <key> <command…>
      words=(${=line})
      print -r -- "K"$'\t'"$words[words[(i)-T]+1]"$'\t'"$words[words[(i)-T]+2]"
    else
      print -r -- "E"$'\t'"${line//$tmp\/tmux.conf/config/tmux/tmux.conf}"
    fi
  done
  tmux -L $socket kill-server 2> /dev/null
  return 0
}

# build_indexes: builds every index at the same time, each into $tmp/<name>.out
build_indexes() {
  local name
  for name in md path links words nvim brew tmux; do
    ${name}_index > $tmp/$name.out &
  done
  wait
}
