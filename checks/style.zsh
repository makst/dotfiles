# Style checks: the conventions CLAUDE.md, "When changing something", sets for every change, which nothing
# else would notice breaking: each Brewfile package says what uses it, colours are ANSI names, GIFs sit in a
# closed "Show GIF" toggle, each zsh function has a comment, lists go through the picker and are in its list,
# headings stand apart from the text above, docs pages keep the
# section order of docs/design.md, each file says at the top who uses it, prose wraps at about 110 columns,
# table rows have the header's cells, $(…) inside ${…} is quoted, scripts are zsh and executable.
# They only warn (check -w): a missed convention doesn't break the setup. Sourced by check_dotfiles;
# lib.zsh has the helpers and indexes.

# Brewfile: each package line says, in a comment, what uses it (the config file, alias or setup function), in
# the shared Brewfile and the machine template
check_brew_comments() {
  awk '/^[[:space:]]*(brew|cask|mas|tap|vscode)[[:space:]]/ && !/#[[:space:]]*[^[:space:]]/ {
    print FILENAME ":" FNR ": no comment saying what uses it"
  }' Brewfile config/machine/Brewfile
}

# colours: ANSI names, never hex, so every tool follows the base16 theme (docs/theme.md). The theme itself,
# config/ghostty/themes, is where the hex values live. Markdown is left out: a doc may quote one.
check_hex_colours() {
  local -a configs=(${${${text_files:#*.md}:#config/ghostty/themes/*}:#checks/mutate})
  grep -nE '#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?([^0-9a-zA-Z_]|$)' -- $configs |
    awk -F: '{ print $1 ":" $2 ": a hex colour; an ANSI colour name follows the theme" }'
  note=$(count $#configs file)
}

# GIFs: each one in a Markdown file sits in a toggle that's closed by default, titled <b>Show GIF</b>, with one
# line saying what it shows above the image (docs/gifs.md, "Adding one"). Code blocks are skipped.
check_gif_toggles() {
  awk '
    FNR == 1 { n = 0; code = 0; want_close = 0 }
    /^[ \t]*(```|~~~)/ { code = !code; next }
    code || /^[ \t]*$/ { next }
    want_close {
      if ($0 != "</details>") print FILENAME ":" want_close ": the GIF'"'"'s toggle isn'"'"'t closed right after it"
      want_close = 0
    }
    /^(!\[|<img).*\.gif/ {
      # back over the caption (wrapped, it takes more than one line) to the summary
      for (j = n; j > 0 && line[j] !~ /^</; j--);
      if (j == n || j < 2 || line[j] != "<summary><b>Show GIF</b></summary>" || line[j - 1] != "<details>")
        print FILENAME ":" FNR ": not in <details>, <summary><b>Show GIF</b></summary>, a line saying what it shows"
      want_close = FNR
    }
    { line[++n] = $0 }
  ' $md_files
}

# zsh functions: each one in the config has a comment above it saying what it does and why; a group of
# definitions written together, with no blank line between them, may share one. checks/ is left out: its
# helpers and stubs are tests.
check_function_comments() {
  local -a zsh=(${${(f)"$(zsh_files)"}:#checks/*})
  awk '
    FNR == 1 { top = "" }
    /^[[:space:]]*$/ { top = ""; next }
    top == "" { top = $0 }
    /^(function +[A-Za-z_][A-Za-z0-9_:-]*|[A-Za-z_][A-Za-z0-9_:-]* *\(\)) *(\(\))? *\{/ && top !~ /^#/ {
      name = $0; sub(/^function +/, "", name); sub(/[ ({].*/, "", name)
      print FILENAME ":" FNR ": " name " has no comment above it"
    }
  ' $zsh
  note=$(count $#zsh file)
}

# one picker: a list to choose from goes through `picker` (config/tmux/picker.zsh), so it has the same keys and
# normal mode as every other; no zsh file runs fzf or fzf-tmux itself (after a pipe, a variable set for it,
# `command` or xargs too), except the picker, .fzf.zsh, which sets fzf up, and checks/ (checks/mutate's break
# does it on purpose). nvim's lists are fzf-lua's and aren't looked at.
check_picker() {
  local -a zsh=(${${${${(f)"$(zsh_files)"}:#config/tmux/picker.zsh}:#.fzf.zsh}:#checks/*})
  local before='(^|[|;&({]|\$\(|then|do|else|xargs)[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
  grep -nE "$before(command[[:space:]]+)?fzf(-tmux)?([[:space:]]|\$)" -- $zsh |
    awk -F: '$3 !~ /^[[:space:]]*#/ { print $1 ":" $2 ": runs fzf; a list goes through picker (config/tmux/picker.zsh)" }'
  note=$(count $#zsh file)
}

# picker list: config/tmux/picker.zsh's top comment is the one list of the pickers (docs/design.md, "One
# search away"; docs/tmux.md, "Pickers", is the docs' copy): each script and each function that calls
# `picker` is named there. A helper (a name that starts with _) stands for the functions that call it.
check_picker_list() {
  local -a files=(${(f)"$(grep -lE '(^|[|(;&[:space:]])picker [a-z$]' -- ${${(f)"$(zsh_files)"}:#checks/*})"})
  local head=$(awk 'NR > 1 && !/^#/ { exit } { print }' config/tmux/picker.zsh)
  awk '
    FNR == 1 { script = (FILENAME !~ /\.zsh$/); f = ""; if (script) { f = FILENAME; sub(/.*\//, "", f) } }
    !script && /^(function )?[A-Za-z_][A-Za-z0-9_-]*[ ]?\(\)/ { f = $0; sub(/^function /, "", f); sub(/[ ]?\(.*/, "", f) }
    /(^|[|(;&[:space:]])picker [a-z$]/ && !/^[[:space:]]*#/ && f != "" && f !~ /^_/ { print f "\t" FILENAME ":" FNR }
  ' ${files:#config/tmux/picker.zsh} | while IFS=$'\t' read -r name where; do
    [[ $head == *$name* ]] || print -r -- "$where: $name calls picker but isn't in config/tmux/picker.zsh's top comment"
  done
  note=$(count $(( $#files - 1 )) file)
}

# headings: a setext heading (a line with --- or === under it) has an empty line above it; without one,
# Markdown takes the paragraph above as part of the heading
check_headings() {
  awk '
    FNR == 1 { code = 0; prev = ""; before = ""; front = /^---$/ }
    front { if (FNR > 1 && /^---$/) front = 0; next }  # front matter, as in a skill
    /^[ \t]*(```|~~~)/ { code = !code }
    !code && /^(---+|===+)$/ && FNR > 2 && prev != "" && prev !~ /^[|<]/ && before != "" {
      print FILENAME ":" FNR - 1 ": the heading \"" prev "\" has text right above it; leave an empty line"
    }
    { before = prev; prev = $0 }
  ' $md_files
  note=$(count $#md_files file)
}

# docs pages: the top-level sections (setext, `---`) of each docs/<tool>.md come in the order of
# docs/design.md, "Same shape, every page": What it is, Once per Mac / per project, a heading per task, Keys,
# Commands, Config, To look out for, Decisions. Any other name is a task; a page may skip sections, and only
# the "once per" and task ones may repeat. A big page's areas (mobile.md's iOS, Android) are tasks here, their
# own shape in `###` below them.
check_docs_shape() {
  local -a docs=(${(M)md_files:#docs/*.md})
  awk '
    function rank(name) {
      if (name == "What it is") return 1
      if (name ~ /^Once per (Mac|project)$/) return 2
      if (name == "Keys") return 4
      if (name == "Commands") return 5
      if (name == "Config") return 6
      if (name == "To look out for") return 7
      if (name == "Decisions") return 8
      return 3
    }
    FNR == 1 { last = 0; lastname = ""; code = 0; prev = "" }
    /^[ \t]*(```|~~~)/ { code = !code }
    !code && /^---$/ && FNR > 3 && prev != "" && prev !~ /^\|/ {
      r = rank(prev)
      if (r < last || (r == last && r != 2 && r != 3))
        print FILENAME ":" FNR - 1 ": \"" prev "\" after \"" lastname "\"; the order is What it is, Once per, " \
          "tasks, Keys, Commands, Config, To look out for, Decisions (docs/design.md, \"Same shape, every page\")"
      last = r; lastname = prev
    }
    { prev = $0 }
  ' $docs
  note=$(count $#docs page)
}

# top comments: the first line of a config or script file (after a #! line) is a comment saying who loads or
# calls it (docs/design.md, "One search away"). Left out: nvim's init.lua (only require lines), files that
# can't hold a comment (JSON, Markdown, allowed_signers) or whose tool writes them (base16-vim.lua, themes).
check_top_comments() {
  local f first
  local -a files=(${(M)text_files:#(config|zsh|checks|.githooks|.github)/*})
  files+=(${(M)text_files:#(.zshrc|.fzf.zsh|prepare-zsh-install.sh)})
  files=(${files:#*.(json|md|tape|cases)})
  files=(${files:#(*/init.lua|*/themes/*|*/base16-vim.lua|*/allowed_signers|*/skills/*|*/lazy-lock*)})
  for f in $files; do
    first=$(grep -vE '^(#!|[[:space:]]*$)' $f | head -n1)
    [[ $first == (\#|--|\"|\;|//)* ]] || print -r -- "$f: no comment at the top saying who uses it"
  done
  note=$(count $#files file)
}

# prose width: lines of prose in Markdown and comment lines in zsh files wrap at about 110 columns (CLAUDE.md,
# "Style"; over 115 is flagged), so a page reads the same in a terminal, in nvim and in a diff. Left out:
# tables, code blocks, HTML (the GIF toggles), images and lines with a URL, which can't be broken, and
# links (the git hooks are one script). zsh, not awk: macOS's awk counts bytes, so – or é would count twice.
check_prose_width() {
  setopt local_options extended_glob
  local f line md code front
  local -i n
  local -a zsh=(${(M)text_files:#(*.zsh|zsh/*|.zshrc|config/tmux/*|.githooks/*|checks/(check_dotfiles|mutate|fresh_mac))})
  zsh=(${zsh:#*.md})
  for f in $md_files $zsh; do
    [[ -L $f ]] && continue
    [[ $f == *.md ]] && md=1 || md=
    code= front= n=0
    while IFS= read -r line; do
      (( ++n ))
      # a skill's front matter: its description has to be one line
      [[ $md && $n == 1 && $line == --- ]] && front=1 && continue
      [[ $front ]] && { [[ $line == --- ]] && front=; continue }
      [[ $md && $line == [[:space:]]#('```'|'~~~')* ]] && { [[ $code ]] && code= || code=1; continue }
      [[ $code || ${#line} -le 115 || $line == *://* ]] && continue
      if [[ $md ]]; then
        [[ $line == [[:space:]]#([\|\<]|'![')* ]] || print -r -- "$f:$n: ${#line} columns"
      else
        [[ $line == [[:space:]]#\#* ]] && print -r -- "$f:$n: ${#line} columns"
      fi
    done < $f
  done
  note=$(count $(( $#md_files + $#zsh )) file)
}

# Markdown tables: every row has as many cells as the header, so no row is cut short or spills a column. A |
# inside a code span or written \| is part of a cell; code blocks are skipped.
check_md_tables() {
  awk '
    function cells(s) {
      gsub(/\\\|/, "", s)
      gsub(/`[^`]*`/, "", s)
      sub(/^[ \t]*\|/, "", s); sub(/\|[ \t]*$/, "", s)
      return gsub(/\|/, "|", s) + 1
    }
    FNR == 1 { code = 0; want = 0; prev = "" }
    /^[ \t]*(```|~~~)/ { code = !code; want = 0; next }
    code { next }
    /^[ \t]*\|/ {
      if (!want && $0 ~ /^[ \t]*\|[ \t:|-]+$/ && prev ~ /^[ \t]*\|/) { want = cells(prev); header = FNR - 1 }
      else if (want && cells($0) != want)
        print FILENAME ":" FNR ": " cells($0) " cells, the header (line " header ") has " want
      prev = $0
      next
    }
    { want = 0; prev = $0 }
  ' $md_files
  note=$(count $#md_files file)
}

# command substitutions: one inside ${…} is quoted, "${(f)"$(cmd)"}" or "${(@f)$(cmd)}", since unquoted zsh
# splits its output into words before the flags see it (CLAUDE.md, "Style"). Comments are skipped; a " opened
# earlier on the line counts, one on an earlier line doesn't.
check_quoted_substitutions() {
  local -a zsh=(${(f)"$(zsh_files)"})
  awk '
    /^[ \t]*#/ { next }
    {
      s = $0; at = 0
      while (match(s, /\$\{(\([^)]*\))?[#^=~]*\$\(/)) {
        before = substr($0, 1, at + RSTART - 1)
        # the quotes before it, without escaped ones and single-quoted text
        gsub(/\\"/, "", before); gsub(/\047[^\047"]*\047/, "", before)
        if (gsub(/"/, "", before) % 2 == 0)
          print FILENAME ":" FNR ": $(…) inside ${…} without quotes; write \"$(…)\""
        at += RSTART + RLENGTH - 1; s = substr(s, RSTART + RLENGTH)
      }
    }
  ' $zsh
  note=$(count $#zsh file)
}

# bash: the repo is zsh; only prepare-zsh-install.sh, which runs before zsh is set up, is bash (CLAUDE.md,
# "Style"). Scripts in other languages (docs/tapes/keycast, Python) are fine.
check_bash() {
  local f
  for f in ${(k)shebangs}; do
    [[ $f != prepare-zsh-install.sh && $shebangs[$f] == (*/(ba|)sh|*env\ (ba|)sh)(|\ *) ]] &&
      print -r -- "$f: $shebangs[$f]; the repo's scripts are zsh"
  done
  note=$(count $#shebangs script)
}

# exec bits: a script with a #! line is executable, and an executable file has one, so it runs the same from
# any shell. It fails: a picker or the watcher that lost its bit doesn't run. The .zsh files are sourced, not
# run: their #! line only tells editors the language.
check_exec_bits() {
  local f
  for f in ${(k)shebangs}; do
    [[ $f == *.zsh || -x $f ]] || print -r -- "$f: has a #! line but isn't executable"
  done
  for f in $text_files; do
    [[ -x $f && ! -L $f && -z $shebangs[$f] ]] && print -r -- "$f: executable without a #! line"
  done
  note=$(count $#text_files file)
}

group "Style: the conventions every change keeps to"
check -w "each Brewfile package says what uses it" check_brew_comments
check -w "colours are ANSI names, not hex" check_hex_colours
check -w "GIFs sit in a closed Show GIF toggle" check_gif_toggles
check -w "each zsh function has a comment" check_function_comments
check -w "lists go through the picker, not a bare fzf" check_picker
check -w "every picker is in picker.zsh's list" check_picker_list
check -w "headings have an empty line above them" check_headings
check -w "docs pages keep the section order of docs/design.md" check_docs_shape
check -w "each file says at the top who uses it" check_top_comments
check -w "prose and comments wrap at about 110 columns" check_prose_width
check -w "Markdown table rows have the header's cells" check_md_tables
check -w "\$(…) inside \${…} is quoted" check_quoted_substitutions
check -w "scripts are zsh, bash only for prepare-zsh-install.sh" check_bash
check "scripts are executable, executables are scripts" check_exec_bits
