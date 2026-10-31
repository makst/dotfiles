#!/bin/zsh
# Claude Code's status line: directory, git branch, worktree, model and effort, how full the context is, and
# the 5-hour / 7-day usage once it gets high. ANSI colour names like config/starship.toml, so it follows the
# Ghostty theme. Claude Code passes the session as JSON on stdin.

local -a f
f=("${(@f)$(jq -r '
  .workspace.current_dir // .cwd,
  .model.display_name // "?",
  .effort.level // "",
  (.context_window.used_percentage // 0 | floor),
  (.rate_limits.five_hour.used_percentage // 0 | floor),
  (.rate_limits.seven_day.used_percentage // 0 | floor)')}")
local dir=$f[1] model=$f[2] effort=$f[3] ctx=$f[4] five=$f[5] week=$f[6]

local reset=$'\e[0m' bold_blue=$'\e[1;34m' purple=$'\e[35m' cyan=$'\e[36m' yellow=$'\e[33m' red=$'\e[31m'
local green=$'\e[32m' dim=$'\e[90m'

# level <percent> <yellow from> <red from>: the colour for a usage figure
level() { (( $1 >= $3 )) && print -rn -- $red || { (( $1 >= $2 )) && print -rn -- $yellow || print -rn -- $green } }

# directory: from the repo root like starship (truncate_to_repo), else with ~ for home
local top=$(git -C $dir rev-parse --show-toplevel 2> /dev/null) shown
if [[ -n $top ]]; then
  shown=${top:t}${dir#$top}
else
  shown=${dir/#$HOME/\~}
fi
local out="$bold_blue$shown$reset"

if [[ -n $top ]]; then
  local branch=$(git -C $dir branch --show-current 2> /dev/null)
  [[ -z $branch ]] && branch=$(git -C $dir rev-parse --short HEAD 2> /dev/null)
  out+=" $purple $branch$reset"
  # uncommitted changes; --no-optional-locks so it never blocks git commands running at the same time
  [[ -n $(git --no-optional-locks -C $dir status --porcelain 2> /dev/null | head -1) ]] && out+="$yellow*$reset"
  # a linked worktree (agent <name>, claude -w) has its own git dir apart from the shared one
  local -a gitdirs=(${(f)"$(git -C $dir rev-parse --path-format=absolute --git-dir --git-common-dir 2> /dev/null)"})
  [[ $gitdirs[1] != $gitdirs[2] ]] && out+=" $cyan󰙅 worktree$reset"
fi

out+="  $dim$model${effort:+ $effort}$reset"
out+="  $(level $ctx 50 80)ctx $ctx%$reset"
(( five >= 50 )) && out+="  $(level $five 50 80)5h $five%$reset"
(( week >= 50 )) && out+="  $(level $week 50 80)7d $week%$reset"

print -rn -- $out
