# the repo, found through the ~/.zshrc symlink (%x is this file, :A resolves the link)
real_script_dir=${${(%):-%x}:A:h}

ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

# cached_eval <tool> <command...>: source what <command> prints (`starship init zsh`, ...) from a cache in
# ~/.cache/zsh instead of starting the tool on every shell start. The cache is rebuilt when the tool's binary
# changes (a Homebrew upgrade moves it to a new Cellar path) or the command does. Clear it with
# `rm ~/.cache/zsh/*.zsh`.
cached_eval() {
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 0
  local cache=$ZSH_CACHE_DIR/$1.zsh stamp
  [[ -r $cache ]] && read -r stamp < $cache
  if [[ $stamp != "# ${bin:A} ${@:2}" ]]; then
    { print -r -- "# ${bin:A} ${@:2}"; "${@:2}" } >| $cache
  fi
  source $cache
}

# Load the shell dotfiles; .exports first, it puts Homebrew on PATH and fpath
for file in "$real_script_dir"/zsh/.{exports,zshdefault,aliases,kubectl_aliases,functions,private}; do
  # source `file` if it's a `readable file`
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
