Claude Code
===

The terminal setup is built so several Claude Code agents can run side by side without getting in each
other's way, and so you notice when one of them needs you. Claude Code's own settings, instructions and
hooks are in `config/claude`, see [Config](#config).

Starting an agent
---
```sh
agent fix-login
agent fix-login "the login form rejects valid emails"
```

`agent <name> [prompt]` runs `claude -w <name>`: Claude Code in a **git worktree** of its own, so agents
never edit the same checkout as you or each other. Inside tmux it opens in a **new window named
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
Merge the agent's branch first (`git merge fix-login` or a PR); `agent_done` only removes things when nothing
would be lost: it stops if the worktree has uncommitted changes, and without `--force` if the branch has
commits that aren't in the default branch. It works from anywhere in the repo, the worktree itself included.

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
`setup_claude` links these from `config/claude` into `~/.claude`, so they're the same on every Mac:

- **`settings.json`**: model and effort, permissions, sandbox, hooks. Commits made by Claude carry only the
  `Co-Authored-By` trailer, no session link (`attribution.sessionUrl`).
- **`CLAUDE.md`**: instructions for every project: delete to the Trash, work on a branch, merge and push only
  when asked, Apple silicon only. Project-specific instructions go in that project's own `CLAUDE.md`.
- **`hooks/`**: the scripts the hooks below run.
- **`statusline.sh`**: the [status line](#status-line).

Settings you change with `/config` or by installing a plugin are written through the link into the repo, so
they show up in `git diff`. If `ls -l ~/.claude/settings.json` ever shows a plain file instead of a link, copy
the changes into `config/claude/settings.json` and run `setup_claude` again.

### Permissions
- **Allowed without asking**: read-only `git` (`status`, `diff`, `log`, `show`, `blame`, `worktree list`),
  read-only `gh pr` / `gh issue` / `gh run`, `brew list` / `info`, `eza`, `tldr`. Claude Code already lets
  plain reads like `ls`, `cat` or `rg` through by itself.
- **Never allowed**: force pushes (`--force-with-lease` still asks), reading old key files `~/.ssh/id_*` and
  any `.private` file (`zsh/.private` holds secrets).
- Everything else asks as usual, including `git commit` and `git push`.
- **Sandbox**: sandboxed commands may use Secretive's agent socket, so signed commits work without leaving
  the sandbox. Pushing still asks for Touch ID.

### Hooks
| When | Does |
|---|---|
| before a shell command | refuses `rm -r` / `rm -rf` and tells Claude to use `trash <path>` instead |
| after Claude edits or writes a file | formats it like nvim does on save (conform): prettier and stylua only where the project has their config, `goimports`/`gofmt`, `ruff`, `shfmt` when installed |
| Claude needs input, or has finished | rings the bell in its tmux pane: the window turns yellow, Ghostty bounces in the Dock |

`/hooks` lists them; `"disableAllHooks": true` in `settings.json` turns them all off.

### Status line
```
dotfiles/docs  feat/claude-config* 󰙅 worktree  Opus 5.5 medium  ctx 18%  5h 62%
```
The directory from the repo root, the branch (`*` when there are uncommitted changes), `worktree` in an
agent's own worktree, the model and effort, and how full the context window is: green, yellow from 50%, red
from 80%, when it's time to `/compact` or `/clear`. Usage of the 5-hour and 7-day limits shows up once one
passes 50%. The colours are the terminal's, like the starship prompt.
