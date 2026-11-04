# Syntax checks: every config file parses in the tool that reads it, so a typo shows up here and not on some
# Mac later. Sourced by check_dotfiles; lib.zsh has the helpers and indexes.

err=$tmp/err.$group_name

# zsh: parsed by zcompile, zsh's own parser (what zsh -n uses), without starting a zsh per file
check_zsh() {
  local f
  local -a list=(${(f)"$(zsh_files)"})
  note=$(count $#list file)
  for f in $list; do
    zcompile -U $tmp/syntax.zwc $f 2> $err && continue
    # zcompile's message starts with the calling function's name, not the file's
    [[ ${${(f)"$(<$err)"}[1]} == (#b)*:([0-9]##):\ (*) ]] && print -r -- "$f:$match[1]: $match[2]" ||
      print -r -- "$f: $(<$err)"
  done
}

# bash: only the scripts that have to run before zsh is set up; shellcheck finds their bugs
check_bash() {
  local f
  local -a list
  for f in ${(k)shebangs}; do
    [[ $shebangs[$f] == '#!'(*/|*env\ )(bash|sh)(|\ *) ]] && list+=$f
  done
  note=${(j:, :)list}
  (( $+commands[shellcheck] )) || { print "shellcheck not installed"; return 2 }
  shellcheck $list
}

# JSON: all files in one jq, and one by one only to find the broken one
check_json() {
  local f
  local -a list=(${(M)text_files:#*.json})
  note=$(count $#list file)
  jq -e . $list > /dev/null 2>&1 && return 0
  for f in $list; do
    jq -e . $f > /dev/null 2> $err || print -r -- "$f: $(<$err)"
  done
}

# TOML: Python's tomllib, strict like starship's and AeroSpace's own parsers (a key set twice is an error there,
# while yq keeps the last one)
check_toml() {
  local -a list=(${(M)text_files:#*.toml})
  note=$(count $#list file)
  (( $+commands[python3] )) || { print "python3 not installed"; return 2 }
  python3 -I -c '
import sys
try:
    import tomllib
except ImportError:
    print("needs Python 3.11 or newer, for tomllib")
    sys.exit(2)
for path in sys.argv[1:]:
    try:
        with open(path, "rb") as f:
            tomllib.load(f)
    except Exception as e:
        print(f"{path}: {e}")
' $list
}

# YAML: the CI workflow, and each Claude Code skill's front matter, which needs a name and a description or
# Claude Code never offers the skill
check_yaml() {
  local f
  local -a list=(${(M)text_files:#*.y(a|)ml}) skills=(${(M)text_files:#config/claude/skills/*/SKILL.md})
  note="$(count $#list file), $(count $#skills skill)"
  (( $+commands[yq] )) || { print "yq not installed"; return 2 }
  for f in $list; do
    yq . $f > /dev/null 2> $err || print -r -- "$f: $(<$err)"
  done
  for f in $skills; do
    yq --front-matter=extract -e '.name and .description' $f > /dev/null 2>&1 ||
      print -r -- "$f: the front matter needs a name and a description"
  done
}

# Lua: every file of the nvim config compiles
check_lua() {
  nvim_results syntax || return
  note+=" files"
}

# tmux: tmux.conf, executed in a throwaway server (tmux_index), so unknown options and values fail too
check_tmux() {
  note="tmux.conf, demo.tmux.conf"
  (( $+commands[tmux] )) || { print "tmux not installed"; return 2 }
  grep '^E' $tmp/tmux.out | cut -f2-
  return 0
}

# git: the shared and the machine template gitconfig parse, and the shell aliases (!…) in them, which git runs
# with sh
check_git_config() {
  local f entry
  local -i aliases=0
  for f in config/git/.gitconfig config/machine/gitconfig; do
    git config --file $f --list > $tmp/gitconfig.out 2> $err || { print -r -- "$f: $(<$err)"; continue }
    for entry in ${(M)${(f)"$(<$tmp/gitconfig.out)"}:#alias.*=!*}; do
      aliases+=1
      sh -n -c "${entry#*=!}" 2> $err || print -r -- "$f: ${entry%%=*}: $(<$err)"
    done
  done
  note="2 files, $(count $aliases 'shell alias' 'shell aliases')"
}

# ssh: ssh -G reads the shared config the way ssh does and rejects unknown options (-T: no terminal to ask for)
check_ssh() {
  note="config/ssh/config"
  ssh -T -G -F config/ssh/config github.com < /dev/null > /dev/null
}

# Brewfile: loads for a Mac of no kind, a home-like and a work-like Mac, so the kind blocks are read too
check_brewfile() {
  [[ -n $(brew_ruby) ]] || { print "Ruby not found"; return 2 }
  [[ -s $tmp/brew.err ]] && { print -r -- "$(<$tmp/brew.err)"; return 1 }
  note="$(grep -c '^[^ ]* none ' $tmp/brew.out) entries, more for home and work"
}

# Brewfile: every package exists in Homebrew (formula, cask or alias), by Homebrew's own lists of names, and none
# is listed twice for the same kind of Mac. A tap's package is checked when the tap is installed here.
check_brew_names() {
  [[ -n $(brew_ruby) && ! -s $tmp/brew.err ]] || { print "the Brewfile doesn't load"; return 2 }
  local api=${HOMEBREW_CACHE:-$HOME/Library/Caches/Homebrew}/api
  [[ -r $api/formula_names.txt && -r $api/cask_names.txt ]] ||
    { print "Homebrew's lists of names aren't in $api (brew update fetches them)"; return 2 }
  local -a one=(1) names
  local -A formula cask seen reported
  names=(${(f)"$(<$api/formula_names.txt)"} ${${(f)"$(<$api/formula_aliases.txt)"}%%\|*})
  formula=(${names:^^one})
  names=(${(f)"$(<$api/cask_names.txt)"})
  cask=(${names:^^one})
  local file kind type name tap key taps=${HOMEBREW_REPOSITORY:-/opt/homebrew}/Library/Taps
  local -i checked=0
  while read -r file kind type name; do
    key="$file $kind $type $name"
    if (( $+seen[$key] )) && ! (( $+reported[$file $type $name] )); then
      print -r -- "$file: $type \"$name\" is listed twice for a $kind Mac"
      reported[$file $type $name]=1
    fi
    seen[$key]=1
    [[ $type == (brew|cask) ]] || continue
    # each package once: the shared ones from the run for no kind, a kind block's own from its run
    key="$file none $type $name"
    [[ $kind != none ]] && (( $+seen[$key] )) && continue
    if [[ $name == */*/* ]]; then
      # a tap's package: its formula or cask file, when the tap is installed
      tap=$taps/${name%%/*}/homebrew-${${name#*/}%%/*}
      [[ -d $tap ]] || continue
      local -a found=($tap/**/${name##*/}.rb(N))
      (( $#found )) || print -r -- "$file: $type \"$name\" isn't in its tap"
    elif [[ $type == brew ]]; then
      (( $+formula[$name] )) || print -r -- "$file: brew \"$name\" isn't a Homebrew formula"
    else
      (( $+cask[$name] )) || print -r -- "$file: cask \"$name\" isn't a Homebrew cask"
    fi
    checked+=1
  done < $tmp/brew.out
  note=$(count $checked package)
}

# Ghostty: its own validator, when Ghostty is installed
check_ghostty() {
  note="config/ghostty/config"
  local ghostty=${commands[ghostty]:-/Applications/Ghostty.app/Contents/MacOS/ghostty}
  [[ -x $ghostty ]] || { print "Ghostty not installed"; return 2 }
  $ghostty +validate-config --config-file=config/ghostty/config
}

# starship: it warns about keys it doesn't know (a misspelt option is otherwise ignored), when installed
check_starship() {
  note="config/starship.toml"
  (( $+commands[starship] )) || { print "starship not installed"; return 2 }
  STARSHIP_CONFIG=$repo/config/starship.toml STARSHIP_LOG=warn starship print-config > /dev/null 2> $err
  print -r -- ${"$(<$err)"//$'\e'\[[0-9;]#m/}
}

# AeroSpace: the running AeroSpace validates its config, when it's running and its config is this checkout's
check_aerospace() {
  note="config/aerospace/aerospace.toml"
  (( $+commands[aerospace] )) && pgrep -qx AeroSpace || { print "AeroSpace isn't running"; return 2 }
  [[ ~/.config/aerospace/aerospace.toml -ef config/aerospace/aerospace.toml ]] ||
    { print "the live config isn't this checkout's"; return 2 }
  aerospace reload-config --dry-run --warnings-as-errors 2>&1
}

group "Syntax: each file parses in the tool that reads it"
check "zsh files parse" check_zsh
check "bash scripts pass shellcheck" check_bash
check "JSON files parse" check_json
check "TOML files parse" check_toml
check "YAML files and skills' front matter parse" check_yaml
check "nvim's Lua files compile" check_lua
check "tmux.conf runs in a throwaway server" check_tmux
check "gitconfig and its shell aliases parse" check_git_config
check "ssh config is valid" check_ssh
check "Brewfile loads for every kind of Mac" check_brewfile
check "every Brewfile package exists in Homebrew" check_brew_names
check "Ghostty config is valid" check_ghostty
check "starship config has only known keys" check_starship
check "AeroSpace config is valid" check_aerospace
