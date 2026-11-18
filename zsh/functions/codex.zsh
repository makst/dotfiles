#!/usr/bin/env zsh
# Shell functions for Codex CLI on this Mac: the codex wrapper, setup_codex and Codex as a tool of the agent
# layer (config/codex, docs/codex.md; the layer itself is in agent.zsh, claude.zsh has the first tool). Sourced
# by .zshrc with the rest of zsh/functions/*.zsh; each function's comment says what it does.

# codex [args…]: Codex CLI with this setup's settings, passed with -c (before the arguments, so a subcommand
# like `codex resume` gets them too) and not from a linked config.toml, because Codex writes each project's
# trust (a path of this Mac) into ~/.codex/config.toml:
# - sandbox_mode workspace-write and approval_policy on-request: commands run in a sandbox that can write the
#   project, and Codex asks before one that needs more
# - tui.vim_mode_default: the prompt starts in vim mode (docs/vim-keys.md); `/vim` toggles it
# In a git worktree (every agent's), commits write to the main checkout's .git, outside the workspace, so that
# directory is added with --add-dir. Before it starts, link_agent_skills links any skill added to
# config/agent/skills since the last start into ~/.agents/skills, where Codex reads user skills.
function codex() {
  link_agent_skills ~/.agents/skills
  local common=$(git rev-parse --path-format=absolute --git-common-dir 2> /dev/null)
  local -a add
  [[ -n $common && $common != "$(git rev-parse --path-format=absolute --git-dir 2> /dev/null)" ]] &&
    add=(--add-dir $common)
  command codex -c 'sandbox_mode="workspace-write"' -c 'approval_policy="on-request"' \
    -c 'tui.vim_mode_default=true' $add "$@"
}


# The agent layer's interface for Codex CLI (zsh/functions/agent.zsh lists it), the second tool of the layer.
# A rollout (Codex's conversation file, ~/.codex/sessions/YYYY/MM/DD/rollout-<time>-<id>.jsonl) is JSON lines:
# the first is {"type":"session_meta","payload":{"id":…,"cwd":…,"source":…}}, then
# {"type":"response_item","payload":{"type":"message","role":"user"|"assistant","content":[{"type":
# "input_text"|"output_text","text":…}]}}; Codex's own context (AGENTS.md, <environment_context>) comes as
# user messages that start with "# AGENTS" or "<". Checked against a Codex 0.170.0
# rollout; the "# AGENTS" prefix and telling a review's rollout apart aren't yet (docs/codex.md).

# _agent_codex_start [args…]: starts Codex, with a prompt and/or its own flags. It goes through the codex
# wrapper above: send-keys types the command into an interactive zsh, which has it.
function _agent_codex_start() { reply=(codex "$@") }

# _agent_codex_resume <transcript>: resumes the conversation whose rollout file is <transcript>, by the id in
# its first line
function _agent_codex_resume() { reply=(codex resume "$(head -1 $1 | jq -r '.payload.id // empty')") }

# _agent_codex_review <name> <branch> <default> [args…]: `codex review` of the branch's changes against
# <default>. It runs non-interactively: prints the review in the pane and exits, and doesn't edit. <name> and
# <branch> aren't needed: it runs in the agent's worktree, on its branch.
function _agent_codex_review() {
  local default=$3
  shift 3
  reply=(codex review --base $default "$@")
}

# _agent_codex_sessions <main>: the Codex conversations of the agents of the repo at <main>, newest first, one
# per line: rollout<tab>name<tab>last active<tab>title. The name is the first directory under
# $_agent_worktrees/ in the cwd of the rollout's session_meta; the title is the first prompt that isn't
# Codex's injected context, whitespace squashed, 70 characters. A rollout whose session_meta source names a
# review (codex review, agent_review) isn't the agent's and is left out.
function _agent_codex_sessions() {
  local root=$1/$_agent_worktrees f name title
  [[ -d ~/.codex/sessions ]] || return 0  # rg without a path would wait for stdin
  local -a files=(${(f)"$(rg -l --sortr modified -F "\"cwd\":\"$root/" -- ~/.codex/sessions 2> /dev/null)"})
  for f in $files; do
    # the unit separator, not a tab: a tab is whitespace to read, which would drop an empty name
    IFS=$'\x1f' read -r name title < <(jq -rn --arg root $root/ '[limit(300; inputs)] as $e
      | ($e | map(select(.type == "session_meta") | .payload) | first // {}) as $m
      | [if ($m.source | tostring | test("review"; "i")) then ""
         elif ($m.cwd // "" | startswith($root)) then ($m.cwd | ltrimstr($root) | split("/")[0]) else "" end,
         ($e | map(select(.type == "response_item" and .payload.type == "message" and .payload.role == "user")
            | .payload.content[]? | select(.type == "input_text") | .text
            | select((startswith("<") or startswith("# AGENTS")) | not)) | first // ""
          | gsub("\\s+"; " ") | .[0:70])] | join("\u001f")' $f)
    [[ -n $name ]] && print -r -- "$f"$'\t'"$name"$'\t'"$(date -r $f '+%Y-%m-%d %H:%M')"$'\t'"$title"
  done
}

# _agent_codex_preview: the glob of Codex's rollouts and the jq filter that prints a conversation's prompts
# (bold) and Codex's replies, without its injected context, for agent_resume's preview
function _agent_codex_preview() {
  reply=('*/.codex/sessions/*' 'select(.type == "response_item" and .payload.type == "message"
      and (.payload.role == "user" or .payload.role == "assistant")) | .payload.role as $r | .payload.content
      | map(select(.type == "input_text" or .type == "output_text") | .text)
      | map(select((startswith("<") or startswith("# AGENTS")) | not)) | .[]
      | if $r == "user" then "\u001b[1m❯ " + . + "\u001b[0m" else "⏺ " + . end, ""')
}

# _agent_codex_hooks: the file that wires Codex's hooks, for the checks
function _agent_codex_hooks() { print config/codex/hooks.json }

# setup_codex: links config/codex's hooks.json, and the shared config/agent's hooks, AGENTS.md and skills, into
# ~/.codex and ~/.agents; a real file Codex made in their place goes to the Trash first. config.toml isn't
# linked (see the codex wrapper). Afterwards `/hooks` in Codex trusts the hooks (docs/codex.md).
function setup_codex() {
  mkdir -p ~/.codex
  keep_real ~/.codex/hooks.json && ln -sfn "$real_script_dir/config/codex/hooks.json" ~/.codex/hooks.json || return
  # the hook scripts are shared by every agent tool (docs/agent.md)
  keep_real ~/.codex/hooks && ln -sfn "$real_script_dir/config/agent/hooks" ~/.codex/hooks || return
  keep_real ~/.codex/AGENTS.md && ln -sfn "$real_script_dir/config/agent/AGENTS.md" ~/.codex/AGENTS.md || return
  link_agent_skills ~/.agents/skills
}
