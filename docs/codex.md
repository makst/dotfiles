Codex CLI
===

Codex CLI is the second tool of the [agent layer](agent.md): `agent --tool codex <name>` runs it in a worktree and
tmux window of its own, with the same marks, notifications, review, resume and landing as Claude Code. This page
is Codex's own parts: how it plugs in, its hooks and its settings.

What it is
---
- **A tool of the agent layer**: `zsh/functions/codex.zsh` has its adapter (`_agent_codex_start`, `_resume`,
  `_review`, `_sessions`, `_preview`, `_hooks`), so `agent`, `agent_review` and `agent_resume` run and read
  Codex without the layer knowing more about it. `git config agent.tool codex` makes it the default
  ([agent](agent.md#using-another-tool)).
- **Shared with Claude Code**, from `config/agent`: the hook scripts (state marks, bell, notifications and the
  guard against `rm -r`), the skills and the global instructions (`AGENTS.md`). Only the wiring is Codex's:
  `config/codex/hooks.json` names which script runs on which event ([Config](#config)).
- **A sandbox and approvals on request**: Codex runs commands in a sandbox that can write the project
  (`workspace-write`) and asks before one that needs more. The wrapper sets both ([Commands](#commands)).
- **A native binary**, installed as a Homebrew cask, so tmux sees `codex` as the pane's command, which is how
  `@agent-pane` knows a pane before its first hook has fired.

Once per Mac
---
1. `setup_brew`: installs the `codex` cask.
2. `codex login`: your account, your choice; nothing of it is in the repo.
3. `setup_codex`: links the hooks, `AGENTS.md` and the skills ([Config](#config)).
4. In Codex, `/hooks`: trust the hooks. Codex runs hooks only once they're trusted; it asks again when
   `config/codex/hooks.json` changes.
5. `exec zsh`, and in tmux `source-file ~/.config/tmux/tmux.conf`, to load the `codex` wrapper and `@agent-pane`.

Commands
---
| Command | Does |
|---|---|
| `codex [args]` | Codex with this setup's settings: `workspace-write` sandbox, approvals on request, the prompt in vim mode, and in a git worktree the main checkout's `.git` writable (commits go there) |
| `agent --tool codex <name> [prompt]` | Codex in a worktree and window of its own ([agent](agent.md#starting-an-agent)) |
| `agent_review --tool codex <name>` | `codex review --base <default branch>` in a pane beside the agent: prints the review and exits, edits nothing |
| `agent_resume` | lists Codex's conversations with Claude Code's; resumes with `codex resume <id>` |
| `setup_codex` | the links in [Config](#config) |
| `/hooks` | in Codex: list the hooks and trust them |
| `/vim` | in Codex: turn the prompt's vim mode on or off |
| `$ship`, `$handoff` | in Codex: the shared skills, which Claude Code calls `/ship` and `/handoff` ([claude](claude.md#skills)) |

Config
---
`setup_codex` links, into `~/.codex` and `~/.agents`:

- **`config/codex/hooks.json`** → `~/.codex/hooks.json`: which script of `config/agent/hooks` runs on which event
  (what each does: [agent](agent.md#config)):

  | Codex event | Script |
  |---|---|
  | PreToolUse on Bash | `no-recursive-rm.sh` |
  | SessionStart, Interrupt | `tmux-state.sh idle` |
  | UserPromptSubmit, PostToolUse | `tmux-state.sh working` |
  | PermissionRequest | `tmux-state.sh waiting codex` (no approval watcher), `notify.sh Codex` |
  | Stop | `bell.sh`, `tmux-state.sh done`, `notify.sh Codex` |
  | SessionEnd | `tmux-state.sh off` |

- **`config/agent/hooks/`** → `~/.codex/hooks`, and **`config/agent/AGENTS.md`** → `~/.codex/AGENTS.md`: the
  scripts the table runs, and the instructions every tool shares.
- **`config/agent/skills/<name>/`** → `~/.agents/skills/<name>/`, where Codex reads user skills; the `codex`
  wrapper links a new one when it starts. `~/.agents/skills` itself stays a real directory.
- **Not linked: `~/.codex/config.toml`.** Settings go through `-c` in the `codex` wrapper:
  `sandbox_mode="workspace-write"`, `approval_policy="on-request"` and `tui.vim_mode_default=true`.

The `codex` login, its conversations (`~/.codex/sessions/`, one `rollout-*.jsonl` per conversation) and the
trusted projects Codex adds to `config.toml` stay in `~/.codex` and out of the repo.

To look out for
---
- **No prompt watcher**: Claude Code's hook watches its screen to see whether you approved a permission, Codex's
  doesn't, so the mark stays *waiting* until the tool finishes or your next prompt.
- **No format hook**: `format.sh` reads Claude Code's Edit and Write events, so Codex's edits aren't formatted.
- **Skills are `$ship` and `$handoff`**, not `/ship`: in Codex `/` starts its own commands.
- **Hooks need trust**: after `setup_codex` or a change to `config/codex/hooks.json`, Codex runs no hook until
  `/hooks` has trusted it; the marks and the `rm` guard are off until then.
- **The conversation list reads Codex's rollout files**, in the format of Codex 0.170.0; a release that
  changes it empties the list: read `~/.codex/sessions/**/rollout-*.jsonl` with `jq -c .` and fix
  `_agent_codex_sessions` in `zsh/functions/codex.zsh`. Whether a `codex review` leaves a rollout that the list
  should skip isn't checked yet.
- **The Interrupt hook isn't checked yet**: `config/codex/hooks.json` wires it to `tmux-state.sh idle`, but no
  interrupted turn has been seen to fire it; if the window stays *working* after Esc, look at that event first.
- **The prompt starts in vim mode** (`tui.vim_mode_default`, set by the wrapper): if a Codex release renames
  the setting, the prompt starts in normal typing mode and `/vim` turns vim mode on.

Decisions
---
- **`config.toml` isn't linked, settings go through `-c`**: Codex writes each project's trust, a path of this Mac,
  into `~/.codex/config.toml`, so a linked file would collect machine paths in the repo. This is the "Exceptions
  say why" entry for a tool whose config isn't in `config/<tool>/` whole.
- **The Homebrew cask, not npm**: a native binary with nothing else to install, and tmux sees `codex` as the
  pane's command.
- **The hook scripts are shared, not copied**: Codex's hook input has the same fields the scripts read
  (`tool_input.command`, `last_assistant_message`, `tool_name`), so one script serves both tools ("One tool per
  job"); only the wiring differs.
- **`agent_review` runs `codex review`, which doesn't edit**: it prints the review and exits, so the reviewer
  needs no tool taken away, as Claude Code's does.
