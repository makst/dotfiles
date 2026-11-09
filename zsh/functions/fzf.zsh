#!/usr/bin/env zsh
# Shell functions for fzf and the Markdown viewer on it (config/fzf, docs/fzf.md). Sourced by .zshrc with the
# rest of zsh/functions/*.zsh; each function's comment says what it does.

# setup_fzf: links ~/.fzf.zsh, which zsh sources. fzf, eza (improved file/directory listing), bat (cat with
# syntax highlighting) and lesspipe (display more with less) come from the Brewfile.
function setup_fzf() {
  ln -sfn "$real_script_dir/.fzf.zsh" "$HOME/.fzf.zsh"
}

# mdv [dir|file]: pick a markdown file under dir (default: here) and read it rendered in glow's pager; a file
# opens straight away. The list is the picker's (config/tmux/picker.zsh), in normal mode: j/k go through the
# files while the preview below shows each one rendered, wrapped to the pane's width. The style
# (config/glow/ansi.json) uses the terminal's 16 colours, so it follows the theme; glow's own are fixed ones.
#   mdv
#   mdv docs
#   mdv README.md
function mdv() {
  local style=$real_script_dir/config/glow/ansi.json
  [[ -f $1 ]] && { glow -p -s "$style" "$1"; return }
  local file
  source $_fzf_picker
  file=$(fd --extension md . "${1:-.}" | awk '{ print $0 "\t" $0 }' |
    picker markdown --header 'j/k move · Enter reads · / filters, jj back · q quits' \
      --preview "glow -s ${(q)style} -w \$FZF_PREVIEW_COLUMNS {1}" --preview-window $picker_preview) || return
  glow -p -s "$style" "${file%%$'\t'*}"
}

# mds [dir]: browse the markdown files under dir (default: here) as a local site in the browser: a sidebar
# from the folders, search, and a reload on every save. MkDocs with the Material theme, run through uvx, so
# nothing is installed and nothing leaves the Mac (localhost only). A dir with its own mkdocs.yml uses that;
# otherwise a throwaway config points at dir, which stays untouched. C-c stops it. Material is maintained until
# May 2027 (its notice is switched off); Zensical, from the same team, reads the same config after that.
#   mds
#   mds ~/work/gcp
function mds() {
  local dir=${1:-.}
  [[ -d $dir ]] || { print -u2 "mds: $dir isn't a directory"; return 1 }
  dir=${dir:A}
  local -a run=(env NO_MKDOCS_2_WARNING=1 uvx --with mkdocs-material mkdocs serve --open --dev-addr 127.0.0.1:${MDS_PORT:-8000})
  if [[ -r $dir/mkdocs.yml ]]; then
    (cd $dir && $run)
  else
    # =(…) is a temp file zsh deletes when mkdocs exits; JSON is valid YAML and jq quotes the path
    $run -f =(jq -n --arg dir $dir '{site_name: ($dir | split("/") | last), docs_dir: $dir,
      theme: {name: "material", palette: {media: "(prefers-color-scheme)"}}}')
  fi
}
