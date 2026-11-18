Codex CLI
===

Codex CLI is the second tool of the [agent layer](agent.md): `agent --tool codex <name>` runs it in a worktree and
tmux window of its own, with the same marks, notifications, review, resume and landing as Claude Code. This page
is Codex's own parts: how it plugs in, its hooks and its settings.

What it is
---
- **A tool of the agent layer**: `zsh/functions/codex.zsh` has its adapter (`_agent_codex_start`, `_resume`,
  `_review`, `_sessions`, `_preview`, `_hooks`, `_ask`), so `agent`, `agent_review` and `agent_resume` run and read
  Codex without the layer knowing more about it. `git config agent.tool codex` makes it the default
  ([agent](agent.md#using-another-tool)).
- **Shared with Claude Code**, from `config/agent`: the hook scripts (state marks, bell, notifications and the
  guard against `rm -r`), the skills and the global instructions (`AGENTS.md`). Only the wiring is Codex's:
  `config/codex/hooks.json` names which script runs on which event ([Config](#config)).
- **A sandbox and approvals on request**: Codex runs commands in a sandbox that can write the project
  (`workspace-write`) and asks before one that needs more. `config/codex/config.toml` sets both
  ([Config](#config)).
- **A native binary**, installed as a Homebrew cask, so tmux sees `codex` as the pane's command, which is how
  `@agent-pane` knows a pane before its first hook has fired.

### Status line

```
~/repos/dotfiles · feat/codex-status-line · No changes · GPT-6-Luna default · Context 1% used · 15.2K used · monthly 99% left
```

The line below the prompt, as close to [Claude Code's](claude.md#status-line) as Codex's built-in items get.
Codex can't run a script for its status line yet (the feature for it, `[features] tui_extensions_statusline =
true`, is "under development" in 0.170.0), so `config/codex/config.toml` picks items from the list
`/statusline` shows:

| Claude Code's status line | Codex item | Shows |
|---|---|---|
| directory from the repo root | `current-dir` | the directory, with `~` for home |
| branch | `git-branch` | the branch |
| git marks (`!+?⇡⇣`) | `branch-changes` | only what's committed against the default branch (`No changes`), not the work tree |
| model and effort | `model-with-reasoning` | the model and its reasoning level |
| ctx % and tokens | `context-used`, `used-tokens` | how full the context window is, and the session's tokens |
| 5h and 7d limits | `five-hour-limit`, `weekly-limit` | what is **left** of the plan's limits, not what's used; each appears only for the windows your plan has (on a plan with a monthly limit, `monthly 99% left`) |

What Claude Code's has and this lacks: the `(worktree)` tag and the work tree's marks (the shell prompt and the
agent window's mark have them), the cache timer and the cost (Codex shows a cost only on Enterprise
workspaces), and the green, yellow and red by level: the items take the colours of `/theme`.

Once per Mac
---
1. `setup_brew`: installs the `codex` cask.
2. `codex login`: your account, your choice; nothing of it is in the repo.
3. `setup_codex`: links the hooks, `AGENTS.md` and the skills, and copies the command rules ([Config](#config)).
4. `setup_codex_system`: links the settings as `/etc/codex/config.toml`; asks for your password, so it isn't part
   of `setup_dotfiles`. Until then the `codex` wrapper passes the same file with `-c`, so the settings hold, but
   Codex runs without its shared background server (`-c` forces that); `check_mac` reports the missing link.
5. In Codex, `/hooks`: trust the hooks. Codex runs hooks only once they're trusted; it asks again when
   `config/codex/hooks.json` changes, as it did when `answer.sh` came in (without it, an `agent_ask` of Codex
   gets no answer).
6. `exec zsh`, and in tmux `source-file ~/.config/tmux/tmux.conf`, to load the `codex` wrapper and `@agent-pane`.

Commands
---
| Command | Does |
|---|---|
| `codex [args]` | Codex with this setup's settings (`workspace-write` sandbox, approvals on request, the prompt in vim mode, the [status line](#status-line), from [Config](#config)), and in a git worktree the main checkout's `.git` writable (commits go there); passes the settings with `-c` while `/etc/codex/config.toml` isn't linked |
| `agent --tool codex <name> [prompt]` | Codex in a worktree and window of its own ([agent](agent.md#starting-an-agent)) |
| `agent_review --tool codex <name>` | `codex review --base <default branch>` in a pane beside the agent: prints the review and exits, edits nothing |
| `agent_resume` | lists Codex's conversations with Claude Code's; resumes with `codex resume <id>` |
| `setup_codex` | the links in [Config](#config) into `~/.codex` and `~/.agents` |
| `setup_codex_system` | links `/etc/codex/config.toml` to `config/codex/config.toml`, with `sudo` |
| `/hooks` | in Codex: list the hooks and trust them |
| `/vim` | in Codex: turn the prompt's vim mode on or off |
| `agent_ask --tool codex <prompt>` | from Claude Code or your shell: Codex answers in a tmux window, read-only for the project's files (`-s read-only`) ([agent](agent.md#asking-another-agent)) |
| `$ship`, `$handoff`, `$ask` | in Codex: the shared skills, which Claude Code calls `/ship`, `/handoff` and `/ask` ([claude](claude.md#skills)); `$ask` runs `agent_ask` |

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
  | Stop | `answer.sh` (first), `bell.sh`, `tmux-state.sh done` |
  | SessionEnd | `tmux-state.sh off` |

- **`config/codex/rules/agent.rules`** → `~/.codex/rules/agent.rules`, a **copy**, not a link: Codex's command
  rules for the agent layer. Codex skips a rules file that is a symlink (Codex 0.170.0: with the link, `agent_ask`
  asked for approval; with a copy it didn't). `setup_codex` and the `codex` wrapper copy it when it is missing or
  differs (`_codex_rules`), so an edit in the repo reaches the next start of Codex, which reads rules when it
  starts. Codex reads every `*.rules` file there and keeps the approvals you save in `default.rules`; the
  strictest matching rule wins. `agent_ask` is allowed without a prompt, and `agent_ask_edit` prompts. They
  start another tool in a tmux window, which has to reach the tmux server from outside Codex's sandbox, so
  without a rule every ask would stop for approval. An allowed rule only skips the approval: to run outside
  its sandbox Codex must also call `agent_ask` with the escalation option (sandbox_permissions
  "require_escalated") and a justification (the `ask` skill says so); without it `agent_ask` fails with
  "can't reach the tmux server".
- **`config/agent/hooks/`** → `~/.codex/hooks`, and **`config/agent/AGENTS.md`** → `~/.codex/AGENTS.md`: the
  scripts the table runs, and the instructions every tool shares.
- **`config/agent/skills/<name>/`** → `~/.agents/skills/<name>/`, where Codex reads user skills; the `codex`
  wrapper links a new one when it starts. `~/.agents/skills` itself stays a real directory.
- **`config/codex/config.toml`** → `/etc/codex/config.toml`, linked by `setup_codex_system`: the settings.
  `sandbox_mode = "workspace-write"` and `approval_policy = "on-request"`; under `[tui]`, `vim_mode_default =
  true` and `status_line` ([Status line](#status-line)). Codex reads `/etc/codex/config.toml` first and
  `~/.codex/config.toml` on top of it, so a setting in your own file (one `/statusline` saves, say) wins;
  `/debug-config` in Codex lists the layers.
- **Not linked: `~/.codex/config.toml`**, Codex's own: it writes each project's trust there.

The `codex` login, its conversations (`~/.codex/sessions/`, one `rollout-*.jsonl` per conversation) and the
trusted projects Codex adds to `config.toml` stay in `~/.codex` and out of the repo.

To look out for
---
- **Asking Codex works (read-only, tried live)**: it needs `/hooks` to have trusted the changed
  `config/codex/hooks.json` first (the Stop hook `answer.sh` returns the answer). `agent_ask` starts it with
  `-s read-only`, and a command that needs more asks you in its window `ask-<id>`.
- **A Codex child of `agent_ask_edit` isn't verified live**: in its worktree the `codex` wrapper adds the main
  checkout's `.git` with `--add-dir`, so commits should work; nobody has tried it end to end.
- **Codex asking Claude Code works too (read-only, tried live)**, with the escalated call above.
- **In a tmux pane `codex` runs with `--no-daemon`**: Codex's shared background server, started once and shared
  by every Codex, runs the hooks with its own environment, so they missed the pane's `TMUX_PANE` and
  `AGENT_ASK_DIR`: the marks and notifications didn't work, and `agent_ask` never got Codex's answer. The cost:
  each Codex in tmux starts its own server. The `/etc/codex/config.toml` link still holds the settings.
- **`~/.codex/rules/default.rules` is Codex's own**: approvals you save go there; `agent.rules` is the repo's and
  is copied beside it, so `~/.codex/rules` stays a real directory.
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
- **The prompt starts in vim mode** (`vim_mode_default` in `config/codex/config.toml`): if a Codex release renames
  the setting, the prompt starts in normal typing mode and `/vim` turns vim mode on.
- **A status line item Codex doesn't know is left out**, with "Ignored invalid status line item" under
  `⚠ warnings · f2 to view`. `check_dotfiles` warns when an item's name isn't in the installed Codex binary
  (a release renamed or dropped it), but a name the binary has can still be refused: `monthly-limit` is in the
  `/statusline` list and is refused, while `five-hour-limit` and `weekly-limit` show the monthly window. After a
  change to the list, start `codex` and look at `f2`.
- **`codex -c …` or `codex -p …`** runs without the shared background server ("Running without the shared
  background server" under `f2`): Codex runs its server inside the process then. It works, but a setting meant
  for every start belongs in `config/codex/config.toml`. In tmux the wrapper does the same on purpose
  (`--no-daemon`, above).
- **`/statusline` and other settings saved in Codex** go into `~/.codex/config.toml`, which outranks this
  setup's file: to change the setup for every Mac, edit `config/codex/config.toml` and remove the key from
  `~/.codex/config.toml`. `/statusline` saves `status_line = […]` and `status_line_use_colors = true` under
  `[tui]`. `check_mac` lists each setting of the repo's file that `~/.codex/config.toml` overrides.

Decisions
---
- **The settings are linked as `/etc/codex/config.toml`, not `~/.codex/config.toml` or `-c`**: Codex writes
  each project's trust, a path of this Mac, into `~/.codex/config.toml`, so a linked file there would collect
  machine paths in the repo; and Codex started with `-c` or `-p` runs without its shared background server
  (a Codex in tmux does anyway, for its hooks' environment).
  The system layer is the one file left, at the cost of a `sudo` step. This is the "Exceptions say why" entry
  for a tool whose config isn't linked from its home.
- **Codex's built-in status line items, not a second bar in tmux**: a tmux line fed by the rollout file
  could copy Claude Code's whole line, but it would be a second status line for one job ("One tool per job")
  and would read a format Codex doesn't promise. When `tui_extensions_statusline = true` is released, the line
  can come from a script as Claude Code's does.
- **The Homebrew cask, not npm**: a native binary with nothing else to install, and tmux sees `codex` as the
  pane's command.
- **The hook scripts are shared, not copied**: Codex's hook input has the same fields the scripts read
  (`tool_input.command`, `last_assistant_message`, `tool_name`), so one script serves both tools ("One tool per
  job"); only the wiring differs.
- **`agent_review` runs `codex review`, which doesn't edit**: it prints the review and exits, so the reviewer
  needs no tool taken away, as Claude Code's does.
- **Command rules in a file of their own, `rules/agent.rules`**: Codex writes the approvals you save into
  `rules/default.rules`, so the repo's rules go beside it and a saved approval never ends up in the repo.
- **The rules file is copied, not linked** (the "Exceptions say why" entry for a file Codex reads): Codex skips
  a rules file that is a symlink, so `_codex_rules` keeps a copy current instead.
- **`answer.sh` shared with Claude Code**: Codex's Stop hook input has `last_assistant_message` too, so
  `agent_ask` reads a Codex child's answer the same way as a Claude Code one ([agent](agent.md#decisions)).
