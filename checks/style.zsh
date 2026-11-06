# Style checks: the conventions CLAUDE.md, "When changing something", sets for every change, which nothing else
# would notice breaking: each Brewfile package says what uses it, colours are ANSI names, GIFs sit in a closed
# "Show GIF" toggle, each zsh function has a comment, and lists go through the picker. Sourced by
# check_dotfiles; lib.zsh has the helpers and indexes.

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

group "Style: the conventions every change keeps to"
check "each Brewfile package says what uses it" check_brew_comments
check "colours are ANSI names, not hex" check_hex_colours
check "GIFs sit in a closed Show GIF toggle" check_gif_toggles
check "each zsh function has a comment" check_function_comments
check "lists go through the picker, not a bare fzf" check_picker
