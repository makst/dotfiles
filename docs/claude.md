Claude Code
===

Claude Code is the default tool of the [agent layer](agent.md), which runs it in a worktree and tmux window of
its own. This page is Claude Code's own parts: its settings, instructions, hooks, status line and skills, in
`config/claude`, see [Config](#config), and how it plugs into the layer.

What it is
---
- **The default tool of the [agent layer](agent.md)**: `zsh/functions/claude.zsh` has its adapter
  (`_agent_claude_start`, `_resume`, `_review`, `_sessions`, `_preview`, `_hooks`), so `agent`, `agent_review`
  and `agent_resume` run and read Claude Code without the layer knowing more about it.
- **The global config**, `config/claude`, holds on any machine and in any project, with nothing about this
  Mac, its tools or this repo; what depends on the Mac comes from the `claude` wrapper ([This
  machine](#this-machine)).

### Status line

```
dotfiles/docs feat/claude-config !+ (worktree)  Opus 5.5 medium  ctx 18% 184k  cache 42m  $3.20  5h 12% 3h  7d 34% 4d
```

The directory from the repo root, the branch and its state with the prompt's marks (`!` modified, `+` staged,
`?` untracked, `✘` deleted, `»` renamed, `=` conflicted, `$` stashed, `⇡`/`⇣` ahead / behind), `worktree` in
an agent's own worktree, the model and effort, and how full the context window is, in percent and tokens:
green, yellow from 50%, red from 80%, when it's time to `/compact` or `/clear`. Then how much of the plan's
5-hour session and 7-day weekly limits is used, in the same colours, each followed by the time until it
resets: hours, or minutes in the last hour, for the session; days, or hours in the last day, for the week.
They appear after the first reply in a session, and not at all when signed in with an API key.

Between the context and the limits, how long the prompt cache stays warm: `cache 42m` in green, yellow in its
last 10 minutes, and `cache cold` in red once it has expired: the next message then reads the whole context
again, which is slower and uses more of the limits, so it's a good moment to `/clear` or `/compact` instead of
carrying on. The cache lasts a set time after the last request (`prompt_cache.ttl` in the input, an hour on
this setup). The status line redraws every 60 seconds (`refreshInterval` in `settings.json`), so this shows
while the session sits idle too.

After the cache, what the session would cost at API prices (`cost.total_cost_usd` in the input), in grey:
dollars and cents, whole dollars from $10. On a plan nothing is billed, but the figure grows with the usage
of the limits, so a session that gets expensive shows while it runs, not a day later in `/usage`.

ANSI colours and no icon font, so it follows the terminal's theme (here base16, like starship).

Turning on a plugin
---
Where a plugin is turned on decides who gets it:

| Plugin for | Turn it on in | Reaches |
|---|---|---|
| every Mac | `config/claude/settings.json`, committed | all Macs, after `git pull` |
| this Mac only (e.g. work plugins on the work Mac) | `~/.config/dotfiles/claude.json` | only this Mac, all projects |
| one project, for you | the project's `.claude/settings.local.json` (`/plugin` → scope *local*) | only you, ignored by git everywhere |
| one project, for the whole team | the project's `.claude/settings.json` (scope *project*) | everyone working on it |

On every Mac: `frontend-design` from the official marketplace, design guidance when building a UI.

A plugin turned on in `claude.json` needs its marketplace there too:

```json
{
  "extraKnownMarketplaces": {
    "my-company": { "source": { "source": "github", "repo": "my-company/claude-plugins" } }
  },
  "enabledPlugins": { "some-plugin@my-company": true }
}
```

To keep a plugin from `claude.json` out of one project, set it to `false` in that project's
`.claude/settings.local.json` (`"enabledPlugins": { "some-plugin@my-company": false }`) and restart
Claude Code. Plugins shared with your claude.ai organisation sync by themselves and touch no file.

Checking token usage
---
`claude_tokens [days]` shows what Claude Code used in the last few days (default 7), from the conversations in
`~/.claude/projects`, subagents included: per model, per project (the directory the session started in) and
the five costliest sessions, each with its requests, fresh input, cache writes, cache reads, output and the
cost at API prices. The dollars put every model and cache read on one scale, so they answer where the usage
goes and whether a change (Haiku subagents) cut it, which `/usage` only shows as
shares. A `+` after a cost means some requests were on a model the function has no price for (an older one);
`?`, that all were. A session id goes straight into `claude -r <id>`. It reads a week (~3,000 requests) in
under a second.

Keys
---
| Key | Action |
|---|---|
| `shift+enter` | newline in Claude Code's prompt instead of sending it |
| `jj` / `Esc` | normal mode in the prompt, then motions like `w`, `b`, `f`, `dd`, `ciw`; `i` back to typing ([vim-keys](vim-keys.md)) |
| `shift+tab` | auto mode, see [Permissions](#permissions) |

Commands
---
| Command | Does |
|---|---|
| `claude [--read-only] [args]` | Claude Code with this setup's settings ([This machine](#this-machine)); `--read-only` (first) starts it unable to change the project's files: the Edit, Write and NotebookEdit tools denied, the checkout and its `.git` denied for writes in the sandbox, no command allowed to run outside the sandbox (`allowUnsandboxedCommands` off), `git * --output*` denied (an allowed `git diff --output=<file>` would write anywhere), the default permission mode instead of auto. MCP tools and the network aren't covered. It is how `agent_ask` starts a read-only child ([agent](agent.md#asking-another-agent)); plan mode isn't used because it stalls on a task-like prompt |
| `claude_tokens [days]` | token usage and cost ([Checking token usage](#checking-token-usage)) |
| `/hooks` | list the hooks |
| `/sandbox` | the sandbox settings in effect |
| `/resume` | bring back a cleared conversation, which is still on disk |

### Skills

Slash commands from `config/agent/skills`, shared with the other agent tools ([Config](#config)); a new one
is added as in [agent](agent.md#adding-a-skill):

| Command | Does |
|---|---|
| `/ship [pr] [about]` | finishes the work in this checkout: moves to a branch if on the default one, checks the diff against the project's `CLAUDE.md` (docs, lock files, tests that should come with it), runs the project's checks, commits in the project's style. With `pr` it also pushes and opens a pull request. Only you can start it; Claude doesn't run it by itself |
| `/handoff [focus]` | gets a conversation ready for `/clear`: saves what only it knows (open items, the next step, ideas not taken, options you declined, gotchas, the state of the branch) into Claude's memory, updating the file that already covers a topic, lists each item with the file it went into so you can check it, and ends with one line to paste after `/clear` to carry on. It writes memory only, never commits. Only you can start it |
| `/ask` | hands a question or task to another agent tool (Codex, or any tool of the layer) through `agent_ask` and brings back its answer ([agent](agent.md#asking-another-agent)); also `$ask` in Codex |

Config
---
`config/claude` is the **global** part. `setup_claude` links it into `~/.claude`:

- **`settings.json`**: model (Opus) and effort, permissions, sandbox, hooks, voice dictation (hold space),
  vim keys in the prompt (`editorMode`, `vimInsertModeRemaps`). Commits made by Claude carry only the
  `Co-Authored-By` trailer, no session link (`attribution.sessionUrl`). Conversations are kept for a year
  (`cleanupPeriodDays`). Subagents run on Haiku (`CLAUDE_CODE_SUBAGENT_MODEL`) unless Claude gives one a model
  when it starts it; `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is left off. The status line redraws every 60 seconds
  (`refreshInterval`).
- **`CLAUDE.md`**: imports `~/.claude/AGENTS.md` (the instructions every agent tool shares, see
  [agent](agent.md#config)) and adds what only Claude Code has: pick a model per subagent (Haiku for
  searching and reading, Sonnet or Opus for judgment) and suggest another model for the conversation when one
  fits better. What a project or machine needs goes in that project's own `CLAUDE.md` (this repo's names the
  Mac it sets up).
- **Shared with the other tools**, in `config/agent` and linked by `setup_claude`: `hooks/` (the scripts the
  [hooks](#hooks) run), `skills/` (the [skills](#skills)) and `AGENTS.md`; each is described in
  [agent](agent.md#config).
- **`statusline.sh`**: the [status line](#status-line).

Settings you change with `/config` or by installing a plugin are written through the link into the repo, so
they show up in `git diff`.

### Permissions

- **Allowed without asking**: read-only `git` (`status`, `diff`, `log`, `show`, `blame`, `worktree list`),
  read-only `gh pr` / `gh issue` / `gh run`. Claude Code already lets plain reads like `ls`, `cat` or `rg`
  through by itself.
- **Asking another agent**: `agent_ask` is allowed without asking, and `agent_ask_edit` (a child that changes
  files, in a worktree of its own; a follow-up to it too) asks first ([agent](agent.md#asking-another-agent)).
  `/ask` is the skill that calls it. A read-only child is read-only for the project's files: MCP tools and
  the network are outside that.
- **Never allowed**: force pushes (`--force-with-lease` still asks) and reading private key files
  `~/.ssh/id_*`. In this repo also `zsh/.private` and `config/nvim/lua/user/hidden/`, which hold secrets
  (`.claude/settings.json`, this repo's own project settings, which also denies sandboxed writes to `./zsh`:
  `agent_ask` runs outside the sandbox and sources `zsh/functions`, so a sandboxed Claude must not plant code
  there; it edits those files with its Edit tool).
- **Google Cloud is read-only**: `gcloud`, `bq` and `gsutil` commands that create, change or delete
  resources or access, and `gcloud config set`, are denied (see [gcloud](gcloud.md#what-claude-code-can-do)).
- **AWS is read-only**: `aws` commands that create, change or delete resources or access, `aws configure
  set`, and `cdk deploy` / `destroy` / … are denied, and so is reading `~/.aws/credentials` and the SSO and
  CLI caches (see [aws](aws.md#what-claude-code-can-do)).
- Everything else asks as usual, including `git commit` and `git push`, outside auto mode.
- **In auto mode** (`shift+tab`) Claude doesn't ask before a command its classifier judges safe for the task,
  and that includes `git commit`. The global `CLAUDE.md` still says to commit only when asked; push, force
  push and the deny list above hold in auto mode too.

### Sandbox

Every command Claude runs in Bash runs in Claude Code's sandbox (macOS Seatbelt), set in `settings.json`
under `sandbox`. Inside it, commands run without asking (`autoAllowBashIfSandboxed`), because they can only:

- **write** in the project, the temp directory, `~/.cache` and `~/.local/state` (shell and nvim state). Not
  even there: Claude Code's own settings, hooks (`config/agent/hooks`, which `~/.claude/hooks` links to) and
  `CLAUDE.md`, so Claude edits those with its Edit tool, which asks. Also not `~/.local/state/agent-ask`,
  the state of `agent_ask` children, so a child can't tamper with it. In this repo (`.claude/settings.json`)
  also not `./zsh`, which `agent_ask` sources outside the sandbox.
- **read** everywhere except the files the permissions deny (`~/.ssh/id_*`, AWS credentials and caches, this
  repo's secrets).
- **reach** GitHub, Homebrew's API, npm and PyPI without asking, any port on localhost (dev servers), and
  Secretive's socket (see [This machine](#this-machine)); a host not listed asks.

| Runs outside the sandbox | Why |
|---|---|
| `trash`, `gio trash` | moves to the Trash, outside the project: the way `CLAUDE.md` says to delete |
| `git push / pull / fetch` | SSH to GitHub can't go through the sandbox's proxy |
| `gh`, `gcloud`, `bq`, `gsutil`, `kubectl` | Go programs whose TLS checks fail under Seatbelt |
| `aws` | needs the SSO token in `~/.aws/sso/cache`, which the sandbox can't read ([aws](aws.md#to-look-out-for)) |
| `brew` | writes to `/opt/homebrew` |
| `tmux` | needs its socket: `tmux -L probe` and the hooks' window state |
| `agent_ask`, `agent_ask_edit` | start another agent in a tmux window through the tmux server's socket; the child runs under its own sandbox ([agent](agent.md#asking-another-agent)) |
| `check_dotfiles`, `check_mac`, `checks/*` | in this repo only (`.claude/settings.json`): the tmux checks need a socket |

These still go through the permission rules. A command the sandbox stops fails with "Operation not
permitted"; Claude may then run it again outside, which asks first (in auto mode the classifier decides).

### This machine

The parts that depend on the Mac live in the dotfiles, not in `config/claude`. The `claude` shell function
(`zsh/functions/claude.zsh`) starts Claude Code with `--settings` on top of the shared settings:

- **Signing in the sandbox**: the socket in `SSH_AUTH_SOCK` (Secretive's, from `zsh/.exports`) is allowed,
  so sandboxed commands can sign commits. Pushing still asks for Touch ID.
- **This Mac's settings**: `~/.config/dotfiles/claude.json` (from `setup_machine`, `{}` at first), merged
  in. Anything a settings file can hold: plugins and marketplaces, `env`, permissions, a different `model`,
  and auto mode's description of the environment (`autoMode.environment`), which names this Mac's repos.
- **The project's plugin choices**: `enabledPlugins` from the project's `.claude/settings.local.json`, put on
  top. Settings passed with `--settings` outrank that file, so without this a project couldn't switch off a
  plugin that `claude.json` turns on.
- **New skills**: before it starts, it links any skill added to `config/agent/skills` and drops the links of
  deleted ones (see [Skills](#skills)).

### Work projects

The global config is meant to sit unnoticed next to a team's own Claude Code setup:

- A project's `.claude/settings.json` and `CLAUDE.md` add to these settings or override them; nothing here
  writes into a project. Personal project settings go in `.claude/settings.local.json`, which the global
  gitignore keeps out of every repo, as it does agent worktrees.
- The format hook formats only with what the project itself configures (see [Hooks](#hooks)), so files
  aren't restyled in someone else's style.
- **Settings managed by the company**: if IT installs Claude Code settings through MDM
  (`/Library/Application Support/ClaudeCode/managed-settings.json`), they take precedence over everything
  here, including the `claude` function's. Plugins they turn on simply join the others. If they allow only
  managed hooks or permission rules, the hooks and permissions here stop applying; nothing else changes.

### Hooks

`settings.json`, "hooks", runs the scripts of `config/agent/hooks` (what each does: [agent](agent.md#config)):

| Claude Code event | Script |
|---|---|
| PreToolUse on Bash | `no-recursive-rm.sh` |
| PostToolUse on Edit, Write | `format.sh` |
| SessionStart, UserPromptSubmit, PostToolUse, PermissionRequest, Notification, Stop, SessionEnd | `tmux-state.sh working`, `waiting`, `done`, `idle` or `off`, as the event says |
| Stop (listed first; Claude Code runs an event's hooks in parallel, so the order doesn't matter) | `answer.sh`: hands the answer back to the agent that asked, when `agent_ask` started this session; nothing otherwise |
| PermissionRequest, Notification (a question), Stop | `bell.sh` (Notification and Stop), `notify.sh` (PermissionRequest and the question) |

The scripts need zsh and jq; a formatter, tmux or terminal-notifier that isn't there is skipped.
`"disableAllHooks": true` in `settings.json` turns them all off. The agents overview is `config/tmux/agents`,
the jump to the next agent `config/tmux/next-agent`.

To look out for
---
- If `ls -l ~/.claude/settings.json` ever shows a plain file instead of a link, copy the changes into
  `config/claude/settings.json` and run `setup_claude` again.
- Run `setup_claude` in a plain terminal with every Claude Code session closed, then start Claude. A running
  session deletes a `~/.claude/hooks` that wasn't there when it started, so every hook fails (the `rm` guard
  too) and the sandbox stops protecting `config/agent/hooks`. `setup_claude` refuses to run inside Claude Code;
  `check_mac` reports the missing link.
- `/plugin install` with the default scope (*user*) writes into the shared `settings.json`. When a session
  ends, the `claude` function checks for that and says so; move the entries to `claude.json`, or commit them
  if every Mac should have them.
- Plugins your organisation turns on through managed settings can't be switched off per project; managed
  settings outrank everything.
- Claude Code started some other way, from the desktop app or an IDE, gets none of the wrapper's settings
  ([This machine](#this-machine)).
- **Notifications** need `terminal-notifier` (Brewfile). Without it, or with its notifications turned off,
  `osascript` shows a plain notification that clicking doesn't jump from. The first notification asks whether
  terminal-notifier may send notifications; if it was declined, turn it on in System Settings → Notifications
  → terminal-notifier, or run `tccutil reset UserNotification fr.julienxx.oss.terminal-notifier` to be asked
  again. `terminal-notifier -diagnose` says what's wrong when none appear.
- **The approval watcher reads Claude Code's screen**: if a release changes the prompt's `Esc to cancel` or
  the spinner line, it gives up after 10 s and the window shows *working* only once the tool is done.
- **Sandbox**: only a whole command line is excluded: `tmux …; checks/check_dotfiles` or
  `checks/check_dotfiles | tail` runs sandboxed, so run excluded commands on their own. Run that way, the two
  tmux checks are skipped and say why, instead of failing.
- **Sandbox**: Claude's shell is a snapshot of an interactive zsh, which keeps the functions but only exported
  variables; so `.zshrc` exports `real_script_dir` (the repo), which the functions use.
- **Sandbox**: no unix socket can be made inside: zsh skips lowering background jobs' priority when
  `$CLAUDECODE` is set (`bg_nice`, `zsh/.zshdefault`), git's fsmonitor is off for Claude's commands (`env` in
  `settings.json`), and nvim's fzf-lua falls back to a localhost port (`user/fzf-lua/server.lua`).
- **Sandbox**: `open`, `osascript` and `pbcopy` don't work inside; Claude gives you the command, or `/copy`
  for text.
- **Sandbox**: a change to the sandbox settings applies to the next command, a new exclusion in a project's
  `.claude/settings.json` only after a restart.
- `claude_tokens`' prices are in the function (from the `claude-api` skill, 2026-10); they matched Claude
  Code's own cost for a session to the cent. Requests Claude Code makes outside the conversation, like titles,
  aren't in the files and aren't counted.

Decisions
---
- **Opus without `[1m]`**: it has a 1M-token context of its own.
- **Subagents on Haiku**: in `/usage`, subagents on the main model were 40% of the usage.
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` stays off, so Claude can still choose a bigger one.
- **Conversations kept a year, not 30 days**, so `agent_resume` and `claude -r` can still find old ones.
- **`git commit` isn't blocked in auto mode**: a commit on a branch is easy to undo (`git reset HEAD~`).
- **Hooks for the agents' state**: inside tmux, Claude Code keeps its terminal title still (`✳`, no spinner)
  and sends no progress bar, so neither can show the state.
- **Reading the screen for approvals**, like [herdr](https://github.com/herdrdev/herdr) does: no hook fires
  when you answer a permission prompt.
