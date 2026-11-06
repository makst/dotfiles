#!/bin/zsh
# Claude Code's status line: directory, git branch, worktree, model and effort, how full the context is
# (percent and tokens), how long the prompt cache stays warm, what the session would cost at API prices, and
# the 5-hour / 7-day usage of the plan's limits and the time until each resets. ANSI colour names and no icon
# font, so it fits any terminal and theme. Claude Code passes the session as JSON on stdin; needs zsh, jq and git.

local -a f
f=("${(@f)$(jq -r '
  # seconds until a limit resets; resets_at is epoch seconds or an ISO 8601 time
  def left: if . == null then "" else
    (if type == "string" then sub("\\.[0-9]+"; "") | fromdateiso8601 else . end) - now | floor
    | if . < 0 then 0 else . end end;
  # a token count, short: 950, 180k, 1M
  def tokens: if . < 1000 then floor | tostring elif . < 999500 then "\(. / 1000 | round)k"
    else "\(. / 100000 | round / 10)M" end;
  .workspace.current_dir // .cwd,
  .model.display_name // "?",
  .effort.level // "",
  (.context_window.used_percentage // 0 | floor),
  # tokens in the context: the input of the last request, else worked out from the percentage and the window size
  (.context_window as $c
    | ($c.current_usage | if . then (.input_tokens // 0) + (.cache_creation_input_tokens // 0)
        + (.cache_read_input_tokens // 0) else null end)
      // (if $c.context_window_size and $c.used_percentage then $c.context_window_size * $c.used_percentage / 100
          else null end)
    | if . == null then "" else tokens end),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
  (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor end),
  (.rate_limits.five_hour.resets_at | left),
  (.rate_limits.seven_day.resets_at | left),
  # seconds until the prompt cache expires, 0 when it is cold
  (.prompt_cache | if . == null then "" elif .warm == false then 0 else .expires_at | left end),
  # what the session would cost at API prices, in dollars
  (.cost.total_cost_usd // "")')}")
local dir=$f[1] model=$f[2] effort=$f[3] ctx=$f[4] tokens=$f[5] five=$f[6] week=$f[7] five_left=$f[8]
local week_left=$f[9] cache_left=$f[10] cost=$f[11]

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
  # the state of the work tree with the prompt's marks (starship's git_status): = conflicted, $ stashed,
  # ✘ deleted, » renamed, ! modified, + staged, ? untracked, then ⇡ ahead / ⇣ behind the upstream.
  # --no-optional-locks so it never blocks git commands running at the same time
  local line x y ahead=0 behind=0
  local -A has
  for line in ${(f)"$(git --no-optional-locks -C $dir status --porcelain=v2 --branch 2> /dev/null)"}; do
    case $line in
      '# branch.ab '*) ahead=${${line#*+}%% *} behind=${line##*-} ;;
      [12]' '*)
        x=${line[3]} y=${line[4]}
        [[ $line == 2* ]] && has[»]=1
        [[ $x == D || $y == D ]] && has[✘]=1
        [[ $y == M ]] && has[!]=1
        [[ $x == [MAT] ]] && has[+]=1 ;;
      u' '*) has[=]=1 ;;
      '? '*) has[?]=1 ;;
    esac
  done
  git -C $dir rev-parse -q --verify refs/stash > /dev/null 2>&1 && has[\$]=1
  local marks= mark
  for mark in = \$ ✘ » ! + \?; do (( ${+has[$mark]} )) && marks+=$mark; done
  if (( ahead && behind )); then
    marks+="⇕⇡$ahead⇣$behind"
  elif (( ahead )); then
    marks+="⇡$ahead"
  elif (( behind )); then
    marks+="⇣$behind"
  fi
  [[ -n $marks ]] && out+=" $yellow$marks$reset"
  # a linked worktree (claude -w) has its own git dir apart from the shared one
  local -a gitdirs=(${(f)"$(git -C $dir rev-parse --path-format=absolute --git-dir --git-common-dir 2> /dev/null)"})
  [[ $gitdirs[1] != $gitdirs[2] ]] && out+=" $cyan(worktree)$reset"
fi

out+="  $dim$model${effort:+ $effort}$reset"
out+="  $(level $ctx 50 80)ctx $ctx%$reset${tokens:+ $dim$tokens$reset}"
# the prompt cache: the time until it expires, green, yellow in its last 10 minutes, red once cold, when the next
# message reads the whole context again, slower and dearer
if [[ -n $cache_left ]]; then
  if (( cache_left == 0 )); then
    out+="  ${red}cache cold$reset"
  else
    out+="  $( (( cache_left <= 600 )) && print -rn -- $yellow || print -rn -- $green)cache $(left $cache_left 3600 h 60 m)$reset"
  fi
fi
# the session's cost at API prices: on a plan nothing is billed, but it grows with the usage of the limits
if [[ -n $cost ]]; then
  local dollars
  (( cost < 10 )) && printf -v dollars '$%.2f' $cost || printf -v dollars '$%.0f' $cost
  out+="  $dim$dollars$reset"
fi
# the plan's limits; missing before the first reply in a session and when signed in with an API key
# and the time until each resets: hours or, within the last hour, minutes; days or, within the last day, hours
[[ -n $five ]] && out+="  $(level $five 50 80)5h $five%$reset${five_left:+ $dim$(left $five_left 3600 h 60 m)$reset}"
[[ -n $week ]] && out+="  $(level $week 50 80)7d $week%$reset${week_left:+ $dim$(left $week_left 86400 d 3600 h)$reset}"

print -rn -- $out
