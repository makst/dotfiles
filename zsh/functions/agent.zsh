#!/usr/bin/env zsh
# Shell functions for the agent layer (docs/agent.md): a coding agent in a git worktree and tmux window of its
# own, whichever tool runs in it. Sourced by .zshrc with the rest of zsh/functions/*.zsh; each function's
# comment says what it does. Used by: the commands below, config/github/inbox (agent_ci), nvim's review
# comments (config/nvim/lua/user/codetour/review.lua) and the tmux marks through each tool's hooks.
#
# The tool is `--tool <t>`, else `git config agent.tool`, else claude. A tool <t> is a set of functions in
# zsh/functions/<t>.zsh; the layer finds the tools as the functions _agent_*_start. All six are required (the
# consistency check "every agent tool has the whole interface"):
#   _agent_<t>_start [args…]             sets `reply` to the command line that starts the tool interactively in
#                                        the current directory; args are a prompt and/or the tool's own flags
#   _agent_<t>_resume <transcript>       sets `reply` to the command line that resumes that conversation
#   _agent_<t>_review <name> <branch> <default> [args…]
#                                        sets `reply` to a command line that reviews <branch>'s commits against
#                                        <default> without editing
#   _agent_<t>_sessions <main>           prints the tool's conversations that ran in
#                                        <main>/$_agent_worktrees/<name>, newest first, one per line:
#                                        transcript<tab>name<tab>YYYY-MM-DD HH:MM<tab>title; reviews left out
#   _agent_<t>_preview                   sets reply=(<glob of its transcripts> <jq filter>): the filter prints a
#                                        transcript's prompts (bold, "❯ ") and replies ("⏺ ") for the
#                                        resume preview
#   _agent_<t>_hooks                     prints the repo path of the file that wires the tool's hooks

# The directory every tool's worktrees live in, relative to the main checkout. Kept from `claude -w` so existing
# agents and their conversations are still found; the reason is in docs/agent.md, Decisions.
typeset -g _agent_worktrees=.claude/worktrees

# _agent_tools: the known tools, one per line: those with an _agent_<t>_start function
function _agent_tools() {
  print -rl -- ${${${(k)functions[(I)_agent_*_start]}#_agent_}%_start}
}

# _agent_tool [tool]: the tool to use: the argument, else `git config agent.tool`, else claude. Fails with the
# known tools when there is no _agent_<t>_start for it.
function _agent_tool() {
  local tool=${1:-${"$(git config agent.tool 2> /dev/null)":-claude}}
  (( $+functions[_agent_${tool}_start] )) || {
    print -u2 "unknown agent tool $tool; known: ${(j:, :)${(f)"$(_agent_tools)"}}"
    return 1
  }
  print -r -- $tool
}

# agent [--tool <t>] <name> [args…]: the tool (_agent_tool) in its own git worktree, $_agent_worktrees/<name> on
# a branch worktree-<name> made from the default branch (not from the current checkout's HEAD), and, inside
# tmux, in a new window named after the task. A name that has a worktree reuses it; the window stays a shell
# once the tool exits. The worktree is made here (_agent_worktree --new), so any tool runs in it the same way;
# args are passed to the tool's start.
#   agent fix-login
#   agent fix-login "the login form rejects valid emails"
#   agent --tool codex fix-login
function agent() {
  local opt tool main
  [[ $1 == --tool ]] && { opt=${2:?usage: agent [--tool <tool>] <name> [args...]}; shift 2 }
  local name=${1:?usage: agent [--tool <tool>] <name> [args...]}
  shift
  tool=$(_agent_tool $opt) || return
  main=$(_agent_main) || return
  _agent_worktree --new $main $name || return
  local -a reply
  _agent_${tool}_start "$@"
  _agent_window $name $main/$_agent_worktrees/$name $reply
}

# agent_ci [--tool <t>] <number>: an agent that fixes the failing checks of pull request <number> of this repo,
# from the GitHub picker's f (cmd+g, config/github/inbox) or by hand in a clone of the repo. It makes the worktree
# ci-<number> on a branch worktree-ci-<number> at the pull request's head (not on the pull request's own
# branch, which is often checked out in the clone already, and git checks a branch out in one place only), then
# starts the tool in a window as `agent` does, told which checks failed and how to read their logs with gh, to
# commit a fix without pushing, or say the failure looks flaky. You push it with
# `git push origin HEAD:<branch>`; agent_done ci-<number> cleans up as for any agent. Pull requests from forks
# are refused: their branch isn't on origin.
#   agent_ci 15607
function agent_ci() {
  local opt tool
  [[ $1 == --tool ]] && { opt=${2:?usage: agent_ci [--tool <tool>] <pull request number>}; shift 2 }
  local number=${1:?usage: agent_ci [--tool <tool>] <pull request number>}
  tool=$(_agent_tool $opt) || return
  local main
  main=$(_agent_main) || return
  local name=ci-$number wt=$main/$_agent_worktrees/ci-$number
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
  local -a reply
  _agent_${tool}_start $prompt
  _agent_window $name $wt $reply
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

# _agent_main: the repo's main checkout, where $_agent_worktrees/ lives, from anywhere in the repo or a worktree
function _agent_main() {
  local main=${"$(git worktree list --porcelain 2> /dev/null | head -1)"#worktree }
  [[ -n $main ]] || { print -u2 "not in a git repo"; return 1 }
  print -r -- $main
}

# _agent_sessions <main>: the conversations of the agents of the repo at <main>, every tool's, newest first, one
# per line: transcript<tab>name<tab>last active<tab>title<tab>tool (each tool's _agent_<t>_sessions rows with
# its name added)
function _agent_sessions() {
  local tool
  for tool in ${(f)"$(_agent_tools)"}; do
    _agent_${tool}_sessions $1 | awk -v t=$tool '{ print $0 "\t" t }'
  done | sort -t $'\t' -k3,3r -s
}

# _agent_worktree [--new] <main> <name>: makes sure the agent's worktree exists. Without --new it re-creates
# one agent_done removed: on its branch if that's still there, else on a new worktree-<name> from what
# agent_done saved in refs/agents/<name>, or from the default branch once that holds the saved work (it was
# merged). With --new (`agent`: a new task) an existing worktree is reused, an existing branch worktree-<name>
# is checked out, else worktree-<name> starts from the default branch, never from refs/agents/<name>: a reused
# name starts fresh.
function _agent_worktree() {
  local fresh=0
  [[ $1 == --new ]] && { fresh=1; shift }
  local main=$1 name=$2 wt=$1/$_agent_worktrees/$2 branch=worktree-$2 saved=refs/agents/$2
  [[ -d $wt ]] && return
  if git -C $main rev-parse -q --verify refs/heads/$branch > /dev/null; then
    git -C $main worktree add -q $wt $branch
    return
  fi
  local base=$(_agent_default $main)
  if (( ! fresh )) && git -C $main rev-parse -q --verify $saved > /dev/null &&
    ! git -C $main merge-base --is-ancestor $saved $base; then
    base=$saved
  fi
  git -C $main worktree add -q -b $branch $wt $base && print "made $name's worktree on $branch from ${base#refs/}"
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
# With a name, that agent's newest conversation; with a session id, that one. It resumes it with the tool that
# had it (_agent_<t>_resume) in the agent's worktree, re-created first if agent_done removed it
# (_agent_worktree), in a new window like `agent`. Piped, it prints the list instead.
function agent_resume() {
  local main
  main=$(_agent_main) || return
  local -a rows=(${(f)"$(_agent_sessions $main)"})
  (( $#rows )) || { print -u2 "no agent conversations for $main"; return 1 }
  local row
  if [[ -n $1 ]]; then
    # by name (rows are newest first), else by session id (in the transcript's file name)
    row=${${(M)rows:#*$'\t'${(b)1}$'\t'*}[1]}
    [[ -n $row ]] || for row in $rows; do [[ ${row%%$'\t'*} == *${(b)1}* ]] && break || row=; done
    [[ -n $row ]] || { print -u2 "no agent conversation $1 (agent_resume lists them)"; return 1 }
  else
    local -a shown
    for row in $rows; do
      local -a cols=("${(@ps:\t:)row}")
      shown+="$cols[1]"$'\t'"${(r:16:)cols[2]} ${(r:6:)cols[5]} $cols[3]  $cols[4]  (${cols[1]:t:r})"
    done
    if [[ ! -t 1 ]]; then
      print -rl -- ${shown#*$'\t'}
      return
    fi
    # the preview: each tool's _agent_<t>_preview, picked by where the transcript is
    local tool preview=
    for tool in ${(f)"$(_agent_tools)"}; do
      local -a reply
      _agent_${tool}_preview
      preview+="${reply[1]}) jq -r ${(q)reply[2]} {1} ;; "
    done
    preview="case {1} in $preview esac"
    # keys as in every picker (config/tmux/picker.zsh): opens in normal mode, / filters, jj back to j/k
    source $_fzf_picker
    row=$(print -rl -- $shown | picker resume \
      --header 'j/k move · Enter resumes · / filters, jj back · q quits' \
      --preview $preview --preview-window "$picker_preview,wrap,follow") || return 0
    row=${(M)rows:#${(b)row%%$'\t'*}$'\t'*}
  fi
  local -a cols=("${(@ps:\t:)row}")
  local f=$cols[1] name=$cols[2]
  local -a reply
  _agent_worktree $main $name || return
  _agent_${cols[5]}_resume $f
  _agent_window $name $main/$_agent_worktrees/$name $reply
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
  local root=$main/$_agent_worktrees default=$(_agent_default $main)
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

  # the window `agent` opened, unless it's the one running this. It goes first: closing it ends the tool,
  # and one that locks its worktree (claude -w did) holds the lock for as long as it runs
  if [[ -n $TMUX ]]; then
    local window=$(tmux list-windows -F '#{window_id} #{window_name}' | awk -v n=$name '$2 == n { print $1; exit }')
    [[ -n $window && $window != $(tmux display-message -p '#{window_id}') ]] && tmux kill-window -t $window
  fi
  # wait up to 2 s for the tool to unlock; a lock whose tool no longer runs (pid in the reason) is lifted
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
      print -u2 "$name is still locked by a running tool (pid $pid); quit it first"
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
  # stays in the tool's own store
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
  local wt=$main/$_agent_worktrees/$name default=$(_agent_default $main) cmd
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

# agent_review [--tool <t>] <name> [args…]: a second agent that reviews an agent's committed branch while the
# agent is still there to fix what it finds, in the agent's worktree, in a pane beside the agent's own (a new
# window when it has none). How it reviews and keeps from editing is the tool's (_agent_<t>_review); args go to
# the tool, e.g. --model sonnet for a cheaper review.
function agent_review() {
  local opt tool
  [[ $1 == --tool ]] && { opt=${2:?usage: agent_review [--tool <tool>] <name> [args...]}; shift 2 }
  local name=${1:?usage: agent_review [--tool <tool>] <name> [args...]}
  shift
  tool=$(_agent_tool $opt) || return
  local main
  main=$(_agent_main) || return
  local wt=$main/$_agent_worktrees/$name
  [[ -d $wt ]] || { print -u2 "no agent worktree $wt"; return 1 }
  local branch=$(git -C $wt branch --show-current)
  [[ -n $branch ]] || { print -u2 "$name's worktree isn't on a branch"; return 1 }
  [[ -n $(git -C $wt status --porcelain) ]] &&
    print -u2 "$name has uncommitted changes; only its commits are reviewed (/ship commits them)"
  local -a reply
  _agent_${tool}_review $name $branch $(_agent_default $main) "$@"
  _agent_window --pane $name $wt $reply
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
  _arguments $flag "1:agent:($main/$_agent_worktrees/*(N/:t))"
}
(( $+functions[compdef] )) && compdef _agent_resume agent_resume && compdef _agent_done agent_done agent_land agent_review
