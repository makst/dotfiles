Claude Code
===

The terminal setup is built so several Claude Code agents can run side by side without getting in each
other's way, and so you notice when one of them needs you. Claude Code's own settings, instructions and
hooks are in `config/claude`, see [Config](#config).

<details>
<summary>Show GIF</summary>

`agent` starts Claude Code in a worktree and window, the window turns yellow when it needs an answer, `cmd+j` jumps there, then merge and `agent_done`.

![agent starts Claude Code in a worktree and window, the window turns yellow when it needs an answer, cmd+j jumps there, then merge and agent_done](img/claude-code.gif)

</details>

The GIF is recorded with the real Claude Code in a made-up project (see [gifs](gifs.md#how-theyre-made)), so
its words differ each time it's rendered.

Starting an agent
---
```sh
agent fix-login
agent fix-login "the login form rejects valid emails"
```

`agent <name> [prompt]` runs `claude -w <name>`: Claude Code in a **git worktree** of its own, on a branch
`worktree-<name>`, so agents never edit the same checkout as you or each other. Inside tmux it opens in a **new window named
`<name>`**, in the current directory; outside tmux it runs right there. Arguments after the name are passed
on to `claude`.

When Claude exits, the window stays open as a shell in the worktree. The worktrees live in
`.claude/worktrees/`, which the global gitignore hides from `git status` in every repo.

Finishing an agent
---
```sh
agent_done                    # list the repo's agents: branch, merged or not, uncommitted changes
agent_done fix-login          # remove the worktree, delete the branch, close the tmux window
agent_done --force fix-login  # the same for a branch you don't want to merge
```
Merge the agent's branch first (`git merge worktree-fix-login` or a PR); `agent_done` only removes things
when nothing would be lost: it stops if the worktree has uncommitted changes, and without `--force` if the
branch has commits that aren't in the default branch. It works from anywhere in the repo, the worktree itself
included. Claude Code locks its worktree while it runs, so `agent_done` closes the window first, which ends
Claude, and waits a moment for the lock to go.

Noticing an agent that waits
---
A program that rings the terminal bell marks its tmux window: **the window turns yellow with a bell icon in
the status bar** until you visit it. If Ghostty is in the background, the Dock icon bounces and the window
title shows a bell too.

A hook rings the bell in Claude's pane whenever it needs input or has finished its turn (see
[Config](#config)), whatever the notification setting in `/config` is.

`cmd+j` (`C-a w`) shows every session and window with a live preview, the quickest way to look over all
running agents and jump to one.

Working alongside agents
---
- **nvim reloads files changed on disk** when you return to it, so edits made by an agent (or by git) show
  up without `:e`.
- **`shift+enter`** inserts a newline in Claude Code's prompt instead of sending it.
- **Agents survive closing Ghostty**: they run in tmux, and Ghostty reattaches to it. A reboot restores the
  windows (tmux-resurrect) but not the running processes; `claude --continue` in the window picks up the
  last conversation.
- The tmux server is started from a login shell, so `claude` and everything it calls has the same `PATH` as
  your shell.

Config
---
`config/claude` is the **global** part: settings and instructions that hold on any machine and in any project,
with nothing about this Mac, its tools or this repo. `setup_claude` links it into `~/.claude`:

- **`settings.json`**: model and effort, permissions, sandbox, hooks, voice dictation (hold space). Commits
  made by Claude carry only the `Co-Authored-By` trailer, no session link (`attribution.sessionUrl`).
- **`CLAUDE.md`**: instructions for every project: delete to the trash, work on a branch, merge and push only
  when asked. What a project or machine needs goes in that project's own `CLAUDE.md` (this repo's names the
  Mac it sets up).
- **`hooks/`**: the scripts the hooks below run.
- **`statusline.sh`**: the [status line](#status-line).

Settings you change with `/config` or by installing a plugin are written through the link into the repo, so
they show up in `git diff`; for plugins that's usually not what you want, see [Plugins](#plugins). If
`ls -l ~/.claude/settings.json` ever shows a plain file instead of a link, copy the changes into
`config/claude/settings.json` and run `setup_claude` again.

### Permissions
- **Allowed without asking**: read-only `git` (`status`, `diff`, `log`, `show`, `blame`, `worktree list`),
  read-only `gh pr` / `gh issue` / `gh run`. Claude Code already lets plain reads like `ls`, `cat` or `rg`
  through by itself.
- **Never allowed**: force pushes (`--force-with-lease` still asks) and reading private key files
  `~/.ssh/id_*`. In this repo also `zsh/.private` and `config/nvim/lua/user/hidden/`, which hold secrets
  (`.claude/settings.json`, this repo's own project settings).
- Everything else asks as usual, including `git commit` and `git push`.

### This machine
The parts that depend on the Mac live in the dotfiles, not in `config/claude`. The `claude` shell function
(`zsh/.functions`) starts Claude Code with `--settings` on top of the shared settings:

- **Signing in the sandbox**: the socket in `SSH_AUTH_SOCK` (Secretive's, from `zsh/.exports`) is allowed,
  so sandboxed commands can sign commits. Pushing still asks for Touch ID.
- **This Mac's settings**: `~/.config/dotfiles/claude.json` (from `setup_machine`, `{}` at first), merged
  in. Anything a settings file can hold: plugins and marketplaces, `env`, permissions, a different `model`.

Claude Code started some other way, from the desktop app or an IDE, gets neither.

### Plugins
Where a plugin is turned on decides who gets it:

| Plugin for | Turn it on in | Reaches |
|---|---|---|
| every Mac | `config/claude/settings.json`, committed | all Macs, after `git pull` |
| this Mac only (e.g. work plugins on the work Mac) | `~/.config/dotfiles/claude.json` | only this Mac, all projects |
| one project, for you | the project's `.claude/settings.local.json` (`/plugin` → scope *local*) | only you, ignored by git everywhere |
| one project, for the whole team | the project's `.claude/settings.json` (scope *project*) | everyone working on it |

A plugin turned on in `claude.json` needs its marketplace there too:

```json
{
  "extraKnownMarketplaces": {
    "my-company": { "source": { "source": "github", "repo": "my-company/claude-plugins" } }
  },
  "enabledPlugins": { "some-plugin@my-company": true }
}
```

`/plugin install` with the default scope (*user*) writes into the shared `settings.json`. When a session ends,
the `claude` function checks for that and says so; move the entries to `claude.json`, or commit them if
every Mac should have them. Plugins shared with your claude.ai organisation sync by themselves and touch no
file.

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
| When | Does |
|---|---|
| before a shell command | refuses `rm -r` / `rm -rf` and tells Claude to move things to the trash instead |
| after Claude edits or writes a file | formats it with the language's formatter, if installed and the project uses it: prettier, stylua and ruff only where the project has their config, `shfmt` where it has an `.editorconfig`, `goimports`/`gofmt` always (Go has one style) |
| Claude needs input, or has finished | rings the bell in its tmux pane: here the window turns yellow and Ghostty bounces in the Dock; does nothing outside tmux |

The scripts need zsh and jq; a formatter or tmux that isn't there is skipped.

`/hooks` lists them; `"disableAllHooks": true` in `settings.json` turns them all off.

### Status line
```
dotfiles/docs feat/claude-config* (worktree)  Opus 5.5 medium  ctx 18%  5h 62%
```
The directory from the repo root, the branch (`*` when there are uncommitted changes), `worktree` in an
agent's own worktree, the model and effort, and how full the context window is: green, yellow from 50%, red
from 80%, when it's time to `/compact` or `/clear`. Usage of the 5-hour and 7-day limits shows up once one
passes 50%. ANSI colours and no icon font, so it follows the terminal's theme (here base16, like starship).
