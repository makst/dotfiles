#!/usr/bin/env zsh
# Shell functions for vi keys in readline and libedit programs (config/readline, docs/vim-keys.md). Sourced by
# .zshrc with the rest of zsh/functions/*.zsh; each function's comment says what it does.

# setup_readline: vi mode in the REPLs: links ~/.inputrc for GNU readline (bash, psql) and ~/.editrc for
# libedit (sqlite3, lldb, python).
function setup_readline() {
  keep_real ~/.inputrc && ln -sfn "$real_script_dir/config/readline/inputrc" ~/.inputrc || return
  keep_real ~/.editrc && ln -sfn "$real_script_dir/config/readline/editrc" ~/.editrc || return
}
