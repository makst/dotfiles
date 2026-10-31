#!/bin/zsh
# PostToolUse on Edit|Write: format the file Claude just changed, with the formatters nvim's conform uses
# (config/nvim/lua/user/conform.lua) and under the same conditions: prettier and stylua only in projects that
# configure them. A formatter that isn't installed is skipped; failures never block Claude.

file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[[ -f $file ]] || exit 0
dir=${file:h}
path+=(~/.local/share/nvim/mason/bin)

# up_find <names...>: the nearest of these files in the file's directory or above it
up_find() {
  local d=$dir name
  while [[ $d != / ]]; do
    for name in "$@"; do [[ -e $d/$name ]] && { print -r -- $d/$name; return } done
    d=${d:h}
  done
  return 1
}

prettier_file() {
  up_find .prettierrc .prettierrc.json .prettierrc.yaml .prettierrc.yml .prettierrc.json5 .prettierrc.js \
    .prettierrc.cjs .prettierrc.mjs .prettierrc.toml prettier.config.js prettier.config.cjs prettier.config.mjs \
    > /dev/null || return 0
  local bin=$(up_find node_modules/.bin/prettier) || bin=$(command -v prettier) || return 0
  $bin --write --log-level warn $file
}

case ${file:e} in
  js|jsx|mjs|cjs|ts|tsx|json|jsonc|yaml|yml|md|css|scss|html) prettier_file ;;
  go)
    if (( $+commands[goimports] )); then goimports -w $file
    elif (( $+commands[gofmt] )); then gofmt -w $file
    fi
    ;;
  py)
    if (( $+commands[ruff] )); then
      ruff check --select I --fix --quiet $file
      ruff format --quiet $file
    fi
    ;;
  lua) up_find stylua.toml .stylua.toml > /dev/null && (( $+commands[stylua] )) && stylua $file ;;
  sh|bash) (( $+commands[shfmt] )) && shfmt -w $file ;;
esac
exit 0
