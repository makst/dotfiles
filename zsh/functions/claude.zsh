#!/usr/bin/env zsh
# Shell functions for Claude Code on this Mac: the claude wrapper, agents in worktrees (config/claude,
# docs/claude.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh; each function's comment says
# what it does.

# claude [args…]: Claude Code with this Mac's settings on top of the shared config/claude/settings.json,
# passed with --settings so they never land in the repo:
# - this shell's SSH agent socket is allowed in the sandbox, so commits get signed there (git signs through
#   SSH_AUTH_SOCK, which zsh/.exports points at Secretive; the path differs per machine)
# - ~/.config/dotfiles/claude.json (setup_machine): plugins, marketplaces and anything else only this Mac uses
# - the project's .claude/settings.local.json enabledPlugins on top, because --settings outranks that file:
#   without this a project couldn't switch off a plugin that claude.json turns on
# Before it starts, link_claude_skills links any skill added to config/claude/skills since the last start.
# Afterwards it warns if Claude Code wrote plugins into the shared settings.json, which installing a plugin
# for the user does.
function claude() {
  link_claude_skills
  local machine=~/.config/dotfiles/claude.json settings='{}' merged
  local root=${"$(git rev-parse --show-toplevel 2> /dev/null)":-$PWD}
  local project=$root/.claude/settings.local.json
  [[ -S $SSH_AUTH_SOCK ]] &&
    settings=$(jq -nc --arg sock $SSH_AUTH_SOCK '{sandbox: {network: {allowUnixSockets: [$sock]}}}')
  if [[ -r $machine ]]; then
    merged=$(jq -c --argjson base $settings '$base * .' $machine) && settings=$merged ||
      print -u2 "$machine isn't valid JSON, starting without it"
  fi
  if [[ -r $project ]]; then
    merged=$(jq -c --argjson base $settings '$base * {enabledPlugins: (.enabledPlugins // {})}' $project) &&
      settings=$merged || print -u2 "$project isn't valid JSON, its plugins aren't applied"
  fi
  command claude --settings "$settings" "$@"
  local exit_code=$?
  claude_plugins_check
  return $exit_code
}

# claude_plugins_check: warn when the shared config/claude/settings.json has plugins or marketplaces that
# aren't committed. Installing a plugin "for you" writes it there, through the ~/.claude link, and from there
# it would reach every Mac with the next commit.
function claude_plugins_check() {
  local filter='[.enabledPlugins // {}, .extraKnownMarketplaces // {}]'
  local now=$(jq -cS $filter $real_script_dir/config/claude/settings.json 2> /dev/null)
  local committed=$(git -C $real_script_dir show HEAD:config/claude/settings.json 2> /dev/null | jq -cS $filter)
  [[ $now == $committed ]] && return 0
  print -u2 "Claude Code added plugins to the shared config/claude/settings.json (see git diff). Move them to" \
    "~/.config/dotfiles/claude.json for this Mac only, or to a project's .claude/settings.local.json;" \
    "commit only what every Mac should get."
  return 1
}

# claude_tokens [days]: what Claude Code used in the last <days> days (default 7), read from the conversations
# in ~/.claude/projects, subagents included: per model, per project and the costliest sessions, in tokens and
# in dollars at API prices. On a plan nothing is billed, but the dollars put every model, cache read and write
# on one scale, so they show where the usage goes and whether a change cut it. Each request is logged once per
# content block with the same usage, so it is counted once per requestId. Requests Claude Code makes outside
# the conversation (titles, summaries) aren't logged and so aren't counted.
function claude_tokens() {
  local days=${1:-7}
  [[ $days == <-> ]] || { print -u2 "usage: claude_tokens [days]"; return 1 }
  local -a files=(~/.claude/projects/*/*.jsonl(N.m-$days) ~/.claude/projects/*/*/subagents/*.jsonl(N.m-$days))
  (( $#files )) || { print "No conversations in the last $days days"; return 0 }
  # $ per million tokens: input, output, cache read; a cache write is 1.25× input for 5 minutes, 2× for an hour
  # (API prices of 2026-10, claude-api skill)
  local prices='{"claude-opus-5-5": [4, 20, 0.2], "claude-sonnet-5-5": [2, 10, 0.2],
    "claude-haiku-5-5": [0.1, 0.5, 0.01], "claude-fable-5-1": [10, 50, 0.25]}'
  local since=$(( EPOCHSECONDS - days * 86400 ))
  jq -c --argjson since $since 'select(.type == "assistant" and .message.usage and .requestId
      and (.timestamp | sub("\\.[0-9]+"; "") | fromdateiso8601) >= $since)
    | .message.usage as $u
    | {r: .requestId, t: .timestamp, m: .message.model, s: .sessionId,
       p: (.cwd | sub("/\\.claude/worktrees/.*"; "")),
       in: ($u.input_tokens // 0), out: ($u.output_tokens // 0), read: ($u.cache_read_input_tokens // 0),
       w5: ($u.cache_creation.ephemeral_5m_input_tokens // 0),
       w1: ($u.cache_creation.ephemeral_1h_input_tokens // ($u.cache_creation_input_tokens // 0))}' \
    $files 2> /dev/null | jq -rs --argjson prices $prices --arg home $HOME '
    def tokens: if . < 1000 then tostring elif . < 999500 then "\(. / 1000 | round)k"
      else "\(. / 100000 | round / 10)M" end;
    # the cost of a group, with a + when some of its requests are on a model without a price, ? when all are
    def dollars: if .unpriced and .cost == 0 then "?"
      else "$\(.cost * 100 | round / 100)\(if .unpriced then "+" else "" end)" end;
    def cost: $prices[.m] as $p | if $p == null then null else
      (.in * $p[0] + .out * $p[1] + .read * $p[2] + .w5 * $p[0] * 1.25 + .w1 * $p[0] * 2) / 1e6 end;
    def total: {n: length, in: (map(.in) | add), w: (map(.w5 + .w1) | add), read: (map(.read) | add),
      out: (map(.out) | add), cost: (map(.cost // 0) | add), unpriced: any(.cost == null)};
    def row($name): [$name, (.n | tostring), (.in | tokens), (.w | tokens), (.read | tokens), (.out | tokens),
      dollars] | @tsv;
    def table($title; key; $limit):
      "\n\($title)\trequests\tinput\tcache write\tcache read\toutput\tcost",
      (group_by(key) | map({k: (.[0] | key), t: total}) | sort_by(-.t.cost) | .[:$limit][]
        | . as $g | $g.t | row($g.k // "?"));
    # a session belongs to the directory it started in, though Claude may cd elsewhere in it
    unique_by(.r) | map(. + {cost: cost}) | group_by(.s)
    | map((min_by(.t).p | sub("^" + $home; "~")) as $start | map(.p = $start)[])
    | (table("model"; .m; 20), table("project"; .p; 10), table("session"; "\(.s) \(.p)"; 5),
       "\n" + (total | row("all")))' | column -t -s $'\t'
}

# agent <name> [prompt]: Claude Code in its own git worktree (claude -w) and, inside tmux, in a new window
# named after the task. The window stays a shell once Claude exits.
#   agent fix-login
#   agent fix-login "the login form rejects valid emails"
function agent() {
  local name=${1:?usage: agent <name> [claude args...]}
  shift
  _agent_window $name $PWD claude -w $name "$@"
}

# agent_ci <number>: an agent that fixes the failing checks of pull request <number> of this repo, from the
# GitHub picker's f (cmd+g, config/github/inbox) or by hand in a clone of the repo. It makes the worktree
# ci-<number> on a branch worktree-ci-<number> at the pull request's head (not on the pull request's own
# branch, which is often checked out in the clone already, and git checks a branch out in one place only), then
# starts Claude in a window as `agent` does, told which checks failed and how to read their logs with gh, to
# commit a fix without pushing, or say the failure looks flaky. You push it with
# `git push origin HEAD:<branch>`; agent_done ci-<number> cleans up as for any agent. Pull requests from forks
# are refused: their branch isn't on origin.
#   agent_ci 15607
function agent_ci() {
  local number=${1:?usage: agent_ci <pull request number>}
  local main
  main=$(_agent_main) || return
  local name=ci-$number wt=$main/.claude/worktrees/ci-$number
  if [[ -d $wt ]]; then
    print -u2 "$name exists: agent_resume $name goes back to it, agent_done $name removes it"
    return 1
  fi
  local pr
  pr=$(cd $main && gh pr view $number --json title,url,headRefName,isCrossRepository \
    --jq '[.title, .url, .headRefName, .isCrossRepository] | @tsv') || return
  local -a fields=("${(@ps:\t:)pr}")
  local title=$fields[1] url=$fields[2] branch=$fields[3]
  [[ $fields[4] == false ]] || { print -u2 "#$number comes from a fork: its branch isn't on origin"; return 1 }
  # the failing checks, each with how to read its log: GitHub Actions' links name the run. One line: the prompt
  # is typed into the agent's window, where a newline would be Enter
  local checks
  checks=$(cd $main && gh pr checks $number --json name,bucket,link --jq '[.[] | select(.bucket == "fail")
    | ((.link | capture("/actions/runs/(?<run>[0-9]+)").run) // null) as $run
    | "\(.name) (" + (if $run then "gh run view \($run) --log-failed" else .link end) + ")"] | join("; ")' \
    2> /dev/null)
  [[ -n $checks ]] || { print -u2 "#$number has no failing checks"; return 1 }

  print "=> fetching #$number's head"
  git -C $main fetch -q origin pull/$number/head && git -C $main worktree add -q -b worktree-$name $wt FETCH_HEAD ||
    return
  local prompt="CI failed on pull request #$number ($title, $url). This worktree is at its head, on a local \
branch worktree-$name; the pull request's branch on origin is $branch. The failing checks, each with the \
command that prints its log (long: read the end first): $checks. Find the cause and fix it, and run the \
same check locally if the repo lets you. Commit the fix but don't push: I review it, and you end by telling \
me to push it with git push origin HEAD:$branch. If the failure looks flaky or has nothing to do with this \
pull request, say so instead of changing code."
  print "=> $name: when its fix is in, push it with: git -C $wt push origin HEAD:$branch"
  _agent_window $name $wt claude $prompt
}

# _agent_window [--pane] <name> <dir> <command...>: runs the command in <dir>, inside tmux in a new window named
# <name> that stays a shell once the command exits, outside tmux right here. With --pane it splits the window
# that already has a pane in <dir> instead (the agent's own, in any session) and goes there; a new window when
# none has. Shared by agent, agent_ci, agent_resume and agent_review.
function _agent_window() {
  local split=0
  [[ $1 == --pane ]] && { split=1; shift }
  local name=$1 dir=$2
  shift 2
  if [[ -z $TMUX ]]; then
    (cd $dir && "$@")
    return
  fi
  local pane window
  (( split )) && window=$(tmux list-panes -a -F $'#{window_id}\t#{pane_current_path}' |
    awk -F '\t' -v dir=$dir '$2 == dir || index($2, dir "/") == 1 { print $1; exit }')
  if [[ -n $window ]]; then
    pane=$(tmux split-window -h -P -F '#{pane_id}' -t "$window" -c "$dir") || return
    tmux switch-client -t "$pane"
  else
    pane=$(tmux new-window -P -F '#{pane_id}' -n "$name" -c "$dir") || return
  fi
  tmux send-keys -t "$pane" "${(j: :)${(q)@}}" Enter
}

# _agent_main: the repo's main checkout, where .claude/worktrees/ lives, from anywhere in the repo or a worktree
function _agent_main() {
  local main=${"$(git worktree list --porcelain 2> /dev/null | head -1)"#worktree }
  [[ -n $main ]] || { print -u2 "not in a git repo"; return 1 }
  print -r -- $main
}

# _agent_sessions <main>: the conversations of the agents of the repo at <main>, newest first, one per line:
# transcript<tab>name<tab>last active<tab>title. Claude Code keeps a transcript per directory under
# ~/.claude/projects: an agent's stays in its worktree's folder, or moves to the main checkout's when Claude
# removes the worktree itself on exit, so both are searched for conversations that ran in .claude/worktrees/.
# A reviewer's conversation (agent_review, its first prompt is /code-review) is left out: it isn't the agent's.
function _agent_sessions() {
  local root=$1/.claude/worktrees f name title
  local -a dirs=(~/.claude/projects/${1//[^A-Za-z0-9]/-}*(N/))
  (( $#dirs )) || return 0  # rg without a path would wait for stdin
  local -a files=(${(f)"$(rg -l --sortr modified -F "\"cwd\":\"$root/" -- $dirs 2> /dev/null)"})
  for f in $files; do
    # the agent's name from the first worktree path it ran in (none for a reviewer); the title Claude gave it,
    # else the last prompt
    IFS=$'\t' read -r name title < <(jq -rn --arg root $root/ '[inputs] as $e | [
      if $e | map(select(.type == "user" and (.isMeta | not)) | .message.content | strings) | first // ""
        | test("^(<command-name>)?/code-review") then "" else
      ($e | map(.cwd? // "" | select(startswith($root))) | first | ltrimstr($root) | split("/")[0]) end,
      (($e | map(select(.type == "ai-title")) | last.aiTitle)
        // ($e | map(select(.type == "last-prompt")) | last.lastPrompt) // "" | gsub("\\s+"; " ") | .[0:70])
    ] | join("\t")' $f)
    [[ -n $name ]] && print -r -- "$f"$'\t'"$name"$'\t'"$(date -r $f '+%Y-%m-%d %H:%M')"$'\t'"$title"
  done
}

# _agent_worktree <main> <name>: makes sure the agent's worktree exists, re-creating one agent_done removed: on
# its branch if that's still there, else on a new worktree-<name> from what agent_done saved in
# refs/agents/<name>, or from the default branch once that holds the saved work (it was merged).
function _agent_worktree() {
  local main=$1 name=$2 wt=$1/.claude/worktrees/$2 branch=worktree-$2 saved=refs/agents/$2
  [[ -d $wt ]] && return
  if git -C $main rev-parse -q --verify refs/heads/$branch > /dev/null; then
    git -C $main worktree add -q $wt $branch
    return
  fi
  local base=$(_agent_default $main)
  if git -C $main rev-parse -q --verify $saved > /dev/null &&
    ! git -C $main merge-base --is-ancestor $saved $base; then
    base=$saved
  fi
  git -C $main worktree add -q -b $branch $wt $base && print "re-created $name's worktree on $branch from ${base#refs/}"
}

# _agent_default <main>: the default branch: origin's, else main or master when there is one, else the one
# checked out in <main> (a repo without a remote, where any branch may be out)
function _agent_default() {
  local default=${"$(git -C $1 symbolic-ref --short refs/remotes/origin/HEAD 2> /dev/null)"#origin/} b
  if [[ -z $default ]]; then
    for b in main master; do
      git -C $1 rev-parse -q --verify refs/heads/$b > /dev/null && { default=$b; break }
    done
  fi
  print -r -- ${default:-"$(git -C $1 rev-parse --abbrev-ref HEAD)"}
}

# agent_resume [name | session id]: go back to an agent's conversation, also after agent_done removed its
# worktree. Without an argument, an fzf list of the repo's agent conversations, newest first, with the end of
# each in the preview; keys as in the cmd+shift+j agents popup (j/k, g/G, ctrl+d/u, / filters, jj, q quits).
# With a name, that agent's newest conversation; with a session id, that one. It runs claude -r <id> in the
# agent's worktree, re-created first if agent_done removed it (_agent_worktree), in a new window like `agent`.
# Piped, it prints the list instead.
function agent_resume() {
  local main
  main=$(_agent_main) || return
  local -a rows=(${(f)"$(_agent_sessions $main)"})
  (( $#rows )) || { print -u2 "no agent conversations for $main"; return 1 }
  local row
  if [[ -n $1 ]]; then
    # by name (rows are newest first), else by session id
    row=${${(M)rows:#*$'\t'${(b)1}$'\t'*}[1]}
    [[ -n $row ]] || row=${${(M)rows:#*/${(b)1}.jsonl$'\t'*}[1]}
    [[ -n $row ]] || { print -u2 "no agent conversation $1 (agent_resume lists them)"; return 1 }
  else
    local -a shown
    for row in $rows; do
      local -a cols=("${(@ps:\t:)row}")
      shown+="$cols[1]"$'\t'"${(r:16:)cols[2]} $cols[3]  $cols[4]  (${cols[1]:t:r})"
    done
    if [[ ! -t 1 ]]; then
      print -rl -- ${shown#*$'\t'}
      return
    fi
    # the preview: the conversation's prompts (bold) and Claude's replies, without tool calls, ending at the last
    local preview='select(.type == "user" or .type == "assistant") | select(.isMeta | not) | .type as $t
      | .message.content | if type == "string" then [.] else map(select(.type == "text") | .text) end
      | map(select(startswith("<") | not)) | .[]
      | if $t == "user" then "\u001b[1m❯ " + . + "\u001b[0m" else "⏺ " + . end, ""'
    # keys as in every picker (config/tmux/picker.zsh): opens in normal mode, / filters, jj back to j/k
    source $_fzf_picker
    row=$(print -rl -- $shown | picker resume \
      --header 'j/k move · Enter resumes · / filters, jj back · q quits' \
      --preview "jq -r ${(q)preview} {1}" --preview-window "$picker_preview,wrap,follow") || return 0
    row=${(M)rows:#${(b)row%%$'\t'*}$'\t'*}
  fi
  local f=${row%%$'\t'*} name=${${row#*$'\t'}%%$'\t'*}
  _agent_worktree $main $name || return
  _agent_window $name $main/.claude/worktrees/$name claude -r ${f:t:r}
}

# agent_done [--force] [name]: finish an agent started with `agent`. Without a name, lists the repo's agent
# worktrees: their branch, whether it's merged and whether there are uncommitted changes. With one, removes the
# worktree, deletes its branch and closes its tmux window, but only if nothing would be lost: no uncommitted
# changes and the branch merged into the default branch. --force deletes an unmerged branch too (uncommitted
# changes still stop it). Merged means in the local default branch or in origin's: an agent that pushed its
# work straight to origin leaves the local branch behind. A worktree with ignored files (.env, node_modules),
# which are in no commit, goes to the Trash whole instead of being removed.
function agent_done() {
  local force=0
  [[ $1 == --force ]] && { force=1; shift }
  local main
  main=$(_agent_main) || return
  local root=$main/.claude/worktrees default=$(_agent_default $main)
  local -a merged_into=($default)
  git -C $main rev-parse -q --verify refs/remotes/origin/$default > /dev/null && merged_into+=origin/$default
  _agent_merged() {
    local ref
    for ref in $merged_into; do git -C $main merge-base --is-ancestor $1 $ref && return; done
    return 1
  }

  if [[ -z $1 ]]; then
    local wt branch tip state
    for wt in $root/*(N/); do
      branch=$(git -C $wt branch --show-current) tip=$(git -C $wt rev-parse HEAD)
      if _agent_merged $tip; then state="merged"
      else
        local ahead=$(git -C $main rev-list --count $default..$tip)
        state="$ahead commit${${ahead:#1}:+s} not in $default"
      fi
      [[ -n $(git -C $wt status --porcelain) ]] && state+=", uncommitted changes"
      print "${wt:t}  (${branch:-detached}: $state)"
    done
    return
  fi

  local name=$1 wt=$root/$1
  [[ -d $wt ]] || { print -u2 "no agent worktree $wt"; return 1 }
  local branch=$(git -C $wt branch --show-current) tip=$(git -C $wt rev-parse HEAD)
  if [[ -n $(git -C $wt status --porcelain) ]]; then
    print -u2 "$name has uncommitted changes; commit or discard them first:"
    git -C $wt status --short >&2
    return 1
  fi
  if ! _agent_merged $tip && (( ! force )); then
    print -u2 "${branch:-$name} isn't merged into $default; merge it, or agent_done --force $name to drop it:"
    git -C $main log --oneline $default..$tip >&2
    return 1
  fi

  # the window `agent` opened, unless it's the one running this. It goes first: closing it ends Claude Code,
  # which locks its worktree for as long as it runs
  if [[ -n $TMUX ]]; then
    local window=$(tmux list-windows -F '#{window_id} #{window_name}' | awk -v n=$name '$2 == n { print $1; exit }')
    [[ -n $window && $window != $(tmux display-message -p '#{window_id}') ]] && tmux kill-window -t $window
  fi
  # wait up to 2 s for Claude to unlock; a lock whose Claude no longer runs (pid in the reason) is lifted
  local lock i
  for i in {1..20}; do
    lock=$(git -C $main worktree list --porcelain | awk -v wt=$wt '
      $1 == "worktree" { here = ($2 == wt) } here && $1 == "locked" { print; exit }')
    [[ -z $lock ]] && break
    sleep 0.1
  done
  if [[ -n $lock ]]; then
    local pid=${${lock#*pid }%% *}
    if [[ $pid == <-> ]] && kill -0 $pid 2> /dev/null; then
      print -u2 "$name is still locked by a running Claude Code (pid $pid); quit it first"
      return 1
    fi
    git -C $main worktree unlock $wt
  fi

  [[ $PWD == $wt(|/*) ]] && cd $main
  # git removes a worktree's ignored files (.env, node_modules) with it, and those are in no commit: a
  # worktree that has any goes to the Trash whole. Where the Trash can't be written (Claude Code's sandbox),
  # git removes it and this says what went.
  local -a ignored=(${(f)"$(git -C $wt status --porcelain --ignored)"})
  ignored=(${${(M)ignored:#'!! '*}#'!! '})
  if (( $#ignored )) && mkdir -p ~/.Trash && mv $wt ~/.Trash/agent-$name-$(date +%s) 2> /dev/null; then
    git -C $main worktree prune
    print "$name's worktree is in the Trash, with its ignored files: ${(j:, :)ignored}"
  else
    git -C $main worktree remove $wt || return
    (( $#ignored )) &&
      print -u2 "removed for good with the worktree (the Trash can't be written): ${(j:, :)ignored}"
  fi
  # the work is kept in refs/agents/<name>, which agent_resume re-creates the worktree from; the conversation
  # stays in ~/.claude/projects
  git -C $main update-ref -m "agent_done $name" refs/agents/$name $tip
  [[ -n $branch ]] && git -C $main branch -D $branch
  print "kept $name's work and conversation: agent_resume $name brings it back"
  return 0
}

# agent_land [--no-check] <name>: lands a finished agent on the default branch and finishes it, in one go
# instead of rebase, checks, merge and agent_done by hand. Stops at the first step that fails and says why:
# 1. the agent's work is committed (/ship in its window does that) and the local default branch isn't behind
#    origin's, since you push it afterwards
# 2. the agent's branch is rebased onto the default branch, in its worktree; a conflict undoes the rebase and
#    leaves it to the agent, who knows the change
# 3. the repo's checks run in the worktree on the rebased branch: the command in `git config agent.check`, set
#    once per clone so nothing lands in the project; without one it stops, --no-check lands unchecked
# 4. the default branch is fast-forwarded to the branch, then agent_done removes the worktree, branch and window
# It never pushes: that stays yours.
function agent_land() {
  local check=1
  [[ $1 == --no-check ]] && { check=0; shift }
  local name=${1:?usage: agent_land [--no-check] <name>}
  local main
  main=$(_agent_main) || return
  local wt=$main/.claude/worktrees/$name default=$(_agent_default $main) cmd
  [[ -d $wt ]] || { print -u2 "no agent worktree $wt"; return 1 }
  local branch=$(git -C $wt branch --show-current)
  [[ -n $branch ]] || { print -u2 "$name's worktree isn't on a branch (a rebase in progress?)"; return 1 }
  if [[ -n $(git -C $wt status --porcelain) ]]; then
    print -u2 "$name has uncommitted changes; /ship in its window commits them:"
    git -C $wt status --short >&2
    return 1
  fi
  if git -C $main rev-parse -q --verify refs/remotes/origin/$default > /dev/null &&
    ! git -C $main merge-base --is-ancestor origin/$default $default; then
    print -u2 "$default is behind origin/$default; pull it first"
    return 1
  fi
  if (( check )); then
    cmd=$(git -C $main config agent.check)
    [[ -n $cmd ]] || {
      print -u2 "no checks set for this repo: git config agent.check '<command>', or agent_land --no-check $name"
      return 1
    }
  fi
  if git -C $main merge-base --is-ancestor $branch $default; then
    print "$branch is already in $default"
    agent_done $name
    return
  fi

  local out
  if ! out=$(git -C $wt rebase -q $default 2>&1); then
    local conflicts=$(git -C $wt diff --name-only --diff-filter=U)
    git -C $wt rebase --abort 2> /dev/null
    [[ -n $conflicts ]] || { print -ru2 -- $out; return 1 }  # not a conflict: git's own message
    print -u2 "$branch conflicts with $default in:\n$conflicts\nask $name to rebase onto $default, then land again"
    return 1
  fi
  if (( check )); then
    print "checking $branch: $cmd"
    (cd $wt && eval $cmd) || {
      print -u2 "checks failed on $branch (rebased onto $default); fix them in $name, then land again"
      return 1
    }
  fi
  local count=$(git -C $main rev-list --count $default..$branch)
  # the main checkout has the default branch out: merge there, so its files move too; else move the branch alone
  if [[ $(git -C $main branch --show-current) == $default ]]; then
    git -C $main merge -q --ff-only $branch || return
  else
    git -C $main fetch -q . $branch:$default || return
  fi
  print "landed $count commit${${count:#1}:+s} from $branch on $default; push it when you're ready"
  agent_done $name
}

# agent_review <name> [claude args…]: a second Claude Code that reviews an agent's committed branch while the
# agent is still there to fix what it finds: /code-review of the branch in the agent's worktree, in a pane beside
# the agent's (a new window when it has none). The edit tools are taken away, so it reads and reports; you pass
# on what's worth fixing. Arguments go to claude, e.g. --model sonnet for a cheaper review.
function agent_review() {
  local name=${1:?usage: agent_review <name> [claude args...]}
  shift
  local main
  main=$(_agent_main) || return
  local wt=$main/.claude/worktrees/$name
  [[ -d $wt ]] || { print -u2 "no agent worktree $wt"; return 1 }
  local branch=$(git -C $wt branch --show-current)
  [[ -n $branch ]] || { print -u2 "$name's worktree isn't on a branch"; return 1 }
  [[ -n $(git -C $wt status --porcelain) ]] &&
    print -u2 "$name has uncommitted changes; only its commits are reviewed (/ship commits them)"
  # the prompt goes first: --disallowedTools takes every word after it
  _agent_window --pane $name $wt claude "/code-review $branch" -n "review $name" "$@" \
    --disallowedTools Edit Write NotebookEdit
}

# _agent_resume: completion; agent_resume offers the agents with a conversation (with its title), agent_done
# the worktrees
function _agent_resume() {
  local main=$(_agent_main 2> /dev/null) row name
  [[ -n $main ]] || return 1
  local -a entries
  local -A seen
  for row in ${(f)"$(_agent_sessions $main)"}; do
    local -a f=("${(@ps:\t:)row}")
    (( $+seen[$f[2]] )) && continue
    seen[$f[2]]=1
    entries+="${f[2]//:/\\:}:$f[3]  $f[4]"
  done
  _describe agent entries
}

# _agent_done: completion for agent_done, agent_land and agent_review: the agents' worktrees and each one's flag
function _agent_done() {
  local main=$(_agent_main 2> /dev/null)
  [[ -n $main ]] || return 1
  local -a flag
  case $service in
    agent_done) flag=('--force[drop an unmerged branch]') ;;
    agent_land) flag=('--no-check[land without the checks]') ;;
  esac
  _arguments $flag "1:agent:($main/.claude/worktrees/*(N/:t))"
}
(( $+functions[compdef] )) && compdef _agent_resume agent_resume && compdef _agent_done agent_done agent_land agent_review

# setup_claude: links config/claude's settings, CLAUDE.md, hooks, status line and skills into ~/.claude; a real
# file Claude Code made in their place goes to the Trash first.
function setup_claude() {
  mkdir -p ~/.claude
  local item
  for item in settings.json CLAUDE.md hooks statusline.sh; do
    # a copy Claude Code made itself goes to the Trash; the repo's version replaces it
    keep_real ~/.claude/$item && ln -sfn "$real_script_dir/config/claude/$item" ~/.claude/$item || return
  done
  link_claude_skills
}

# link_claude_skills: links each skill in config/claude/skills into ~/.claude/skills, where Claude Code looks,
# and removes the links of skills the repo no longer has. ~/.claude/skills also holds the skills claude.ai
# syncs, so it stays a real directory and the skills are linked one by one; a real copy in a skill's place
# goes to the Trash. The claude wrapper runs it on every start, so a skill added here, pulled or not yet
# committed, is there without a setup step; with nothing to do it starts no process.
function link_claude_skills() {
  local skill link
  [[ -d ~/.claude/skills ]] || mkdir -p ~/.claude/skills
  for skill in $real_script_dir/config/claude/skills/*(N/); do
    link=~/.claude/skills/${skill:t}
    [[ -L $link && $link -ef $skill ]] && continue
    keep_real $link && ln -sfn $skill ~/.claude/skills/${skill:t}
  done
  # (-@): links whose target is gone; only the ones into this repo, the rest aren't ours to remove
  for link in ~/.claude/skills/*(N-@); do
    [[ $(readlink $link) == $real_script_dir/config/claude/skills/* ]] && rm $link
  done
  return 0
}
