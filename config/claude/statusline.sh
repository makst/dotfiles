#!/bin/zsh
# Claude Code's status line: directory, git branch, worktree, model and effort, how full the context is, and
# the 5-hour / 7-day usage of the plan's limits and the time until each resets. ANSI colour names and no icon font, so it fits any terminal and
# theme. Claude Code passes the session as JSON on stdin; needs zsh, jq and git.

local -a f
f=("${(@f)$(jq -r '
  # seconds until a limit resets; resets_at is epoch seconds or an ISO 8601 time
  def left: if . == null then "" else
    (if type == "string" then sub("\\.[0-9]+"; "") | fromdateiso8601 else . end) - now | floor
    | if . < 0 then 0 else . end end;
  .workspace.current_dir // .cwd,
  .model.display_name // "?",
  .effort.level // "",
  (.context_window.used_percentage // 0 | floor),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
  (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor end),
  (.rate_limits.five_hour.resets_at | left),
  (.rate_limits.seven_day.resets_at | left)')}")
local dir=$f[1] model=$f[2] effort=$f[3] ctx=$f[4] five=$f[5] week=$f[6] five_left=$f[7] week_left=$f[8]

local reset=$'\e[0m' bold_blue=$'\e[1;34m' purple=$'\e[35m' cyan=$'\e[36m' yellow=$'\e[33m' red=$'\e[31m'
local green=$'\e[32m' dim=$'\e[90m'

# level <percent> <yellow from> <red from>: the colour for a usage figure
level() { (( $1 >= $3 )) && print -rn -- $red || { (( $1 >= $2 )) && print -rn -- $yellow || print -rn -- $green } }

# left <seconds> <unit> <name> <small unit> <small name>: a time to the nearest unit, or to the nearest small
# unit when it's one unit or less, e.g. "3h" or "42m"
left() {
  (( $1 > $2 )) && print -rn -- "$(( ($1 + $2 / 2) / $2 ))$3" || print -rn -- "$(( ($1 + $4 / 2) / $4 ))$5"
}

# directory: from the repo root, else with ~ for home
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
  out+=" $purple$branch$reset"
  # uncommitted changes; --no-optional-locks so it never blocks git commands running at the same time
  [[ -n $(git --no-optional-locks -C $dir status --porcelain 2> /dev/null | head -1) ]] && out+="$yellow*$reset"
  # a linked worktree (claude -w) has its own git dir apart from the shared one
  local -a gitdirs=(${(f)"$(git -C $dir rev-parse --path-format=absolute --git-dir --git-common-dir 2> /dev/null)"})
  [[ $gitdirs[1] != $gitdirs[2] ]] && out+=" $cyan(worktree)$reset"
fi

out+="  $dim$model${effort:+ $effort}$reset"
out+="  $(level $ctx 50 80)ctx $ctx%$reset"
# the plan's limits; missing before the first reply in a session and when signed in with an API key
# and the time until each resets: hours or, within the last hour, minutes; days or, within the last day, hours
[[ -n $five ]] && out+="  $(level $five 50 80)5h $five%$reset${five_left:+ $dim$(left $five_left 3600 h 60 m)$reset}"
[[ -n $week ]] && out+="  $(level $week 50 80)7d $week%$reset${week_left:+ $dim$(left $week_left 86400 d 3600 h)$reset}"

print -rn -- $out
