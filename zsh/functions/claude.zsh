#!/usr/bin/env zsh
# Shell functions for Claude Code on this Mac: the claude wrapper and Claude Code as a tool of the agent layer
# (config/claude, docs/claude.md; the layer itself is in agent.zsh). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# claude [args…]: Claude Code with this Mac's settings on top of the shared config/claude/settings.json,
# passed with --settings so they never land in the repo:
# - this shell's SSH agent socket is allowed in the sandbox, so commits get signed there (git signs through
#   SSH_AUTH_SOCK, which zsh/.exports points at Secretive; the path differs per machine)
# - ~/.config/dotfiles/claude.json (setup_machine): plugins, marketplaces and anything else only this Mac uses
# - the project's .claude/settings.local.json enabledPlugins on top, because --settings outranks that file:
#   without this a project couldn't switch off a plugin that claude.json turns on
# Before it starts, link_agent_skills links any skill added to config/agent/skills since the last start.
# Afterwards it warns if Claude Code wrote plugins into the shared settings.json, which installing a plugin
# for the user does.
function claude() {
  link_agent_skills ~/.claude/skills
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


# The agent layer's interface for Claude Code (zsh/functions/agent.zsh lists it), the first tool of the layer.

# _agent_claude_start [args…]: starts Claude Code, with a prompt and/or its own flags. It goes through the
# claude wrapper above: send-keys types the command into an interactive zsh, which has it.
function _agent_claude_start() { reply=(claude "$@") }

# _agent_claude_resume <transcript>: resumes the conversation whose transcript file is <transcript>
function _agent_claude_resume() { reply=(claude -r ${1:t:r}) }

# _agent_claude_review <name> <branch> <default> [args…]: /code-review of <branch> in a conversation named
# "review <name>", with the edit tools taken away. The prompt goes first: --disallowedTools takes every word
# after it. <default> isn't needed: /code-review finds the base itself.
function _agent_claude_review() {
  local name=$1 branch=$2
  shift 3
  reply=(claude "/code-review $branch" -n "review $name" "$@" --disallowedTools Edit Write NotebookEdit)
}

# _agent_claude_sessions <main>: the Claude Code conversations of the agents of the repo at <main>, newest
# first, one per line: transcript<tab>name<tab>last active<tab>title. Claude Code keeps a transcript per
# directory under ~/.claude/projects: a new agent's stays in its worktree's folder; it moves to the main
# checkout's only for agents started with `claude -w`, which removes the worktree itself on exit. Both are
# searched for conversations that ran in $_agent_worktrees/.
# A reviewer's conversation (agent_review, its first prompt is /code-review) is left out: it isn't the agent's.
function _agent_claude_sessions() {
  local root=$1/$_agent_worktrees f name title
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


# _agent_claude_preview: the glob of Claude Code's transcripts and the jq filter that prints a conversation's
# prompts (bold) and Claude's replies, without tool calls, for agent_resume's preview
function _agent_claude_preview() {
  reply=('*/.claude/projects/*' 'select(.type == "user" or .type == "assistant") | select(.isMeta | not) | .type as $t
      | .message.content | if type == "string" then [.] else map(select(.type == "text") | .text) end
      | map(select(startswith("<") | not)) | .[]
      | if $t == "user" then "\u001b[1m❯ " + . + "\u001b[0m" else "⏺ " + . end, ""')
}

# _agent_claude_hooks: the file that wires Claude Code's hooks, for the checks
function _agent_claude_hooks() { print config/claude/settings.json }

# setup_claude: links config/claude's settings, CLAUDE.md and status line, and the shared config/agent's hooks,
# AGENTS.md and skills, into ~/.claude; a real file Claude Code made in their place goes to the Trash first.
# It refuses to run inside Claude Code (CLAUDECODE is set): a running session removes a ~/.claude/hooks that
# wasn't there when it started, so the hooks would be gone again after the next command.
function setup_claude() {
  if [[ -n $CLAUDECODE ]]; then
    print -u2 "setup_claude: run it in a plain terminal with Claude Code closed; a running session removes ~/.claude/hooks"
    return 1
  fi
  mkdir -p ~/.claude
  local item
  for item in settings.json CLAUDE.md statusline.sh; do
    # a copy Claude Code made itself goes to the Trash; the repo's version replaces it
    keep_real ~/.claude/$item && ln -sfn "$real_script_dir/config/claude/$item" ~/.claude/$item || return
  done
  # the hook scripts are shared by every agent tool (docs/agent.md)
  keep_real ~/.claude/hooks && ln -sfn "$real_script_dir/config/agent/hooks" ~/.claude/hooks || return
  # the instructions every tool shares; CLAUDE.md imports them (@~/.claude/AGENTS.md)
  keep_real ~/.claude/AGENTS.md && ln -sfn "$real_script_dir/config/agent/AGENTS.md" ~/.claude/AGENTS.md || return
  link_agent_skills ~/.claude/skills
}
