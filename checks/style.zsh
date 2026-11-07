# Style checks: the conventions CLAUDE.md, "When changing something", sets for every change, which nothing
# else would notice breaking: each Brewfile package says what uses it, colours are ANSI names, GIFs sit in a
# closed "Show GIF" toggle, each zsh function has a comment, lists go through the picker, docs pages keep
# the section order of docs/design.md, and each file says at the top who uses it. They only warn (check -w):
# a missed convention doesn't break the setup.
# Sourced by check_dotfiles; lib.zsh has the helpers and indexes.

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
# normal mode as every other; no zsh file runs fzf itself, except the picker, .fzf.zsh, which sets fzf up, and
# checks/ (checks/mutate's break does it on purpose)
check_picker() {
  local -a zsh=(${${${${(f)"$(zsh_files)"}:#config/tmux/picker.zsh}:#.fzf.zsh}:#checks/*})
  grep -nE '(^|[|;&({]|\$\(|then|do|else)[[:space:]]*(command[[:space:]]+)?fzf([[:space:]]|$)' -- $zsh |
    awk -F: '$3 !~ /^[[:space:]]*#/ { print $1 ":" $2 ": runs fzf; a list goes through picker (config/tmux/picker.zsh)" }'
  note=$(count $#zsh file)
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

group "Style: the conventions every change keeps to"
check -w "each Brewfile package says what uses it" check_brew_comments
check -w "colours are ANSI names, not hex" check_hex_colours
check -w "GIFs sit in a closed Show GIF toggle" check_gif_toggles
check -w "each zsh function has a comment" check_function_comments
check -w "lists go through the picker, not a bare fzf" check_picker
check -w "docs pages keep the section order of docs/design.md" check_docs_shape
check -w "each file says at the top who uses it" check_top_comments
