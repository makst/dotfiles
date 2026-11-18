#!/usr/bin/env zsh
# Shell functions for Codex CLI on this Mac: the codex wrapper, setup_codex and Codex as a tool of the agent
# layer (config/codex, docs/codex.md; the layer itself is in agent.zsh, claude.zsh has the first tool). Sourced
# by .zshrc with the rest of zsh/functions/*.zsh; each function's comment says what it does.

# codex [args…]: Codex CLI as this setup runs it. Its settings come from config/codex/config.toml, which
# Codex reads as /etc/codex/config.toml (setup_codex_system), not from -c: Codex started with -c runs without
# its shared background server. Until that link is there (check_mac reports it), the same file is passed with
# -c, one for each of _codex_settings' lines, so the sandbox and the rest hold on every Mac. In a git
# worktree (every agent's), commits write to the main checkout's .git, outside the workspace, so that
# directory is added with --add-dir. Before it starts, link_agent_skills links any skill added to
# config/agent/skills since the last start into ~/.agents/skills, where Codex reads user skills.
# In a tmux pane it runs without the shared background server (--no-daemon): that server, started once and
# shared by every Codex, runs the hooks with its own environment, so they'd miss this pane's TMUX_PANE (the
# marks, notifications) and AGENT_ASK_DIR (agent_ask's answer).
function codex() {
  link_agent_skills ~/.agents/skills
  _codex_rules
  local file=$real_script_dir/config/codex/config.toml
  local -a add
  local setting
  [[ -n $TMUX_PANE ]] && add+=(--no-daemon)
  [[ /etc/codex/config.toml -ef $file ]] ||
    for setting in ${(f)"$(_codex_settings $file)"}; do add+=(-c $setting); done
  local common=$(git rev-parse --path-format=absolute --git-common-dir 2> /dev/null)
  [[ -n $common && $common != "$(git rev-parse --path-format=absolute --git-dir 2> /dev/null)" ]] &&
    add+=(--add-dir $common)
  command codex $add "$@"
}

# _codex_settings <config.toml>: each setting of a Codex config file as `section.key=value`, one per line
# (`tui.vim_mode_default=true`), for `codex -c` and check_mac. Reads the one-line `key = value` form
# config/codex/config.toml keeps to; a section header's quoted name (`[projects."/path"]`) comes out as it is.
function _codex_settings() {
  awk '/^\[/ { section = substr($0, 2, length($0) - 2) "." }
    /^[A-Za-z_]+ = / { key = $1; sub(/^[^=]*= /, ""); print section key "=" $0 }' $1
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

# _agent_codex_ask read|edit [model]: Codex for agent_ask (zsh/bin/agent_ask), with the word {prompt} where the
# prompt goes. read: its read-only sandbox, so it can't change files; it can still ask you, in its window, for a
# command that needs more. edit: as set up (workspace-write), in the worktree agent_ask made.
function _agent_codex_ask() {
  reply=(codex)
  [[ $1 == read ]] && reply+=(-s read-only)
  [[ -n $2 ]] && reply+=(--model $2)
  reply+=('{prompt}')
}

# _agent_codex_sessions <main>: the Codex conversations of the agents of the repo at <main>, newest first, one
# per line: rollout<tab>name<tab>last active<tab>title. The name is the first directory under
# $_agent_worktrees/ in the cwd of the rollout's session_meta; the title is the first prompt that isn't
# Codex's injected context, whitespace squashed, 70 characters. A rollout whose session_meta source names a
# review (codex review, agent_review) isn't the agent's and is left out.
function _agent_codex_sessions() {
  local root=$1/$_agent_worktrees f name title
  # newest first (om), and grep -l keeps that order; plain grep, so it needs nothing beyond macOS
  local -a files=(~/.codex/sessions/**/rollout-*.jsonl(N.om))
  (( $#files )) || return 0  # grep without a file would wait for stdin
  files=(${(f)"$(grep -lF -- "\"cwd\":\"$root/" $files 2> /dev/null)"})
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

# _codex_rules: copies config/codex/rules/agent.rules to ~/.codex/rules/agent.rules when the copy is missing
# or differs, a file of its own in rules/, where Codex also keeps the approvals you save (default.rules). A
# copy, not a link: Codex skips a rules file that is a symlink (tried with 0.170.0: with the link, agent_ask
# asked for approval; with a copy it didn't). setup_codex and the codex wrapper run it, so an edit in the repo
# reaches the next start of Codex; Codex reads rules when it starts. Starts no process when nothing changed.
function _codex_rules() {
  local src=$real_script_dir/config/codex/rules/agent.rules dst=~/.codex/rules/agent.rules
  [[ -f $dst && ! -L $dst ]] && [[ "$(<$dst)" == "$(<$src)" ]] && return 0
  mkdir -p ${dst:h} && rm -f $dst && cp $src $dst
}

# setup_codex: links config/codex's hooks.json, and the shared config/agent's hooks, AGENTS.md and skills, into
# ~/.codex and ~/.agents; a real file Codex made in their place goes to the Trash first; and copies the
# command rules (_codex_rules). ~/.codex/config.toml isn't linked: Codex writes each project's trust, a path
# of this Mac, into it; the settings are linked by setup_codex_system instead. Afterwards `/hooks` in Codex
# trusts the hooks (docs/codex.md).
function setup_codex() {
  mkdir -p ~/.codex
  keep_real ~/.codex/hooks.json && ln -sfn "$real_script_dir/config/codex/hooks.json" ~/.codex/hooks.json || return
  # the hook scripts are shared by every agent tool (docs/agent.md)
  keep_real ~/.codex/hooks && ln -sfn "$real_script_dir/config/agent/hooks" ~/.codex/hooks || return
  keep_real ~/.codex/AGENTS.md && ln -sfn "$real_script_dir/config/agent/AGENTS.md" ~/.codex/AGENTS.md || return
  _codex_rules || return
  link_agent_skills ~/.agents/skills
}

# setup_codex_system: links /etc/codex/config.toml, Codex's system layer, to config/codex/config.toml, so every
# start of Codex gets this setup's settings without -c (see the codex wrapper). Uses sudo, so it isn't part of
# setup_dotfiles, like setup_touch_id_sudo. Does nothing when the link is already there; a real file in its
# place is copied to the Trash first.
function setup_codex_system() {
  local file=/etc/codex/config.toml
  [[ -L $file && $file -ef $real_script_dir/config/codex/config.toml ]] && return 0
  if [[ -e $file && ! -L $file ]]; then
    mkdir -p ~/.Trash && cp $file ~/.Trash/codex-config.toml-$(date +%s) || return
    print "=> $file wasn't a link: copied to the Trash"
  fi
  sudo mkdir -p ${file:h} && sudo ln -sfn "$real_script_dir/config/codex/config.toml" $file
}
