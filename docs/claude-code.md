Claude Code
===

The terminal setup is built so several Claude Code agents can run side by side without getting in each
other's way, and so you notice when one of them needs you. Claude Code's own settings, instructions and
hooks are in `config/claude`, see [Config](#config).

<details>
<summary><b>Show GIF</b></summary>

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
branch has commits that aren't in the default branch. A commit counts as merged when it's in the local
default branch or in origin's, so an agent that pushed its work straight to `origin/main` can be finished
without pulling first. It works from anywhere in the repo, the worktree itself included. Claude Code locks
its worktree while it runs, so `agent_done` closes the window first, which ends Claude, and waits a moment
for the lock to go.

Noticing an agent that waits
---
Hooks tell tmux what each agent is doing (see [Config](#config)), and tmux marks it wherever it lists windows
or sessions:

| Mark | State | Set when |
|---|---|---|
| yellow bell 󰂞 | **waiting** for you | Claude asks for a permission or asks you a question |
| green tick 󰄬 | **done**, not seen yet | Claude finishes its turn in a window you're not looking at |
| cyan hourglass 󰔟 | **working** | you send a prompt or approve a permission, and after each tool it runs |
| none | idle | Claude has just started, you've looked at the finished agent, or it was on screen when it finished |

A window shows the mark of its most urgent agent, in that order; a session the most urgent of its windows.
The marks appear on the windows in the status bar, in the tree (`cmd+j`) next to every session, window and
pane, and next to the running sessions in the session picker (`cmd+k`). The right of the status bar counts
the agents in each state across all sessions, e.g. `󰂞 1 󰄬 2 󰔟 3`, so you see them from any session.

The hook also rings the bell when Claude needs input or has finished its turn, whatever the notification
setting in `/config` is: if Ghostty is in the background, the Dock icon bounces and the window title shows a
bell. Any other program that rings the bell turns its window yellow with a bell icon until you visit it.

When you aren't looking at the agent, a macOS notification tells you too: when Claude asks for a permission
(`wants to use Bash: <what the command does>`), asks you a question, or finishes its turn (the first 200
characters of its last message). The title is the conversation's title and the agent's `session:window`.
You're looking at it when its window is the active one of a session that a tmux client shows and that client's
terminal (Ghostty) is the frontmost app; then nothing is sent. Clicking the notification switches the tmux
client you used last to the agent's pane and brings Ghostty to the front. A newer notification from the same
agent replaces the older one.

This needs `terminal-notifier` (Brewfile). Without it, or with its notifications turned off, `osascript`
shows a plain notification that clicking doesn't jump from. The first notification asks whether
terminal-notifier may send notifications; if it was declined, turn it on in System Settings → Notifications
→ terminal-notifier, or run `tccutil reset UserNotification fr.julienxx.oss.terminal-notifier` to be asked
again. `terminal-notifier -diagnose` says what's wrong when none appear. Outside tmux or off macOS no
notification is sent.

No hook fires when you answer a permission prompt, only once the tool has finished, so while an agent waits
the hook watches its pane twice a second: when the prompt goes away and Claude's spinner line
(`✻ Thinking… (3s`) shows, you approved and it's *working*; without the spinner you declined and it's idle.
This reads Claude Code's screen, like [herdr](https://github.com/herdrdev/herdr) does: if a release changes
the prompt's `Esc to cancel` or the spinner line, the watcher gives up after 10 s and the window shows
*working* only once the tool is done.

Inside tmux, Claude Code keeps its terminal title still (`✳`, no spinner) and sends no progress bar, so
neither can show the state; that's why the hooks are needed.

`cmd+shift+j` (`C-a a`) is the overview of all agents: a popup listing every pane that runs Claude Code (also
those started before the hooks, which have no state yet), most urgent first: waiting, done, working, then the
rest. Each line has the agent's mark, its window and what it's working on (the title Claude gives the
conversation); below is a preview of the selected agent's screen. List and preview update within a second, so
an agent that starts waiting moves up while you look, and the cursor stays on the agent it was on; only what
changed is redrawn, so nothing flickers. It moves like nvim: `j` / `k` down / up, `g` / `G` the first / last
agent, `ctrl+d` / `ctrl+u` half a page, `Enter` jumps there, `q` or `Esc` closes it. `/` filters by typing,
like nvim's search; `Esc` clears the filter and goes back to moving. For every window, agents or not, use
`cmd+j` (`C-a w`). The script is `config/tmux/agents`.

`cmd+shift+space` (`C-a A`) jumps straight to the next agent that needs you, in any session: the waiting ones
first, then the done ones (which turn idle as you see them). Press it again for the one after; when none is
left it says so. `cmd+shift+0` takes you back to the session you came from, `cmd+0` to the window. The script
is `config/tmux/next-agent`.

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

- **`settings.json`**: model (Opus, 1M-token context) and effort, permissions, sandbox, hooks, voice dictation
  (hold space), vim keys in the prompt (`editorMode`: `Esc` or `jj` for normal mode, then motions like `w`, `b`, `f`,
  `dd`, `ciw`; `i` back to typing; see [vim-keys](vim-keys.md)).
  Commits made by Claude carry only the `Co-Authored-By` trailer, no session link (`attribution.sessionUrl`).
- **`CLAUDE.md`**: instructions for every project: delete to the trash, work on a branch, merge and push only
  when asked. What a project or machine needs goes in that project's own `CLAUDE.md` (this repo's names the
  Mac it sets up).
- **`hooks/`**: the scripts the hooks below run.
- **`skills/`**: the [skills](#skills) every project gets.
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
- **Google Cloud is read-only**: `gcloud`, `bq` and `gsutil` commands that create, change or delete
  resources or access, and `gcloud config set`, are denied (see [gcloud](gcloud.md#what-claude-code-can-do)).
- Everything else asks as usual, including `git commit` and `git push`.

### This machine
The parts that depend on the Mac live in the dotfiles, not in `config/claude`. The `claude` shell function
(`zsh/.functions`) starts Claude Code with `--settings` on top of the shared settings:

- **Signing in the sandbox**: the socket in `SSH_AUTH_SOCK` (Secretive's, from `zsh/.exports`) is allowed,
  so sandboxed commands can sign commits. Pushing still asks for Touch ID.
- **This Mac's settings**: `~/.config/dotfiles/claude.json` (from `setup_machine`, `{}` at first), merged
  in. Anything a settings file can hold: plugins and marketplaces, `env`, permissions, a different `model`,
  and auto mode's description of the environment (`autoMode.environment`), which names this Mac's repos.
- **The project's plugin choices**: `enabledPlugins` from the project's `.claude/settings.local.json`, put on
  top. Settings passed with `--settings` outrank that file, so without this a project couldn't switch off a
  plugin that `claude.json` turns on.

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

To keep a plugin from `claude.json` out of one project, set it to `false` in that project's
`.claude/settings.local.json` (`"enabledPlugins": { "some-plugin@my-company": false }`) and restart
Claude Code. Plugins your organisation turns on through managed settings can't be switched off this way;
managed settings outrank everything.

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
| Claude asks for permission or a question, or has finished | sends a macOS notification unless you're looking at the agent's tmux window; clicking it jumps there ([Noticing an agent that waits](#noticing-an-agent-that-waits)); does nothing outside tmux or off macOS |
| the session starts, a prompt is sent, a tool has run, Claude asks for permission or a question or has finished, the session ends | records the agent's state (working, waiting, done) in its tmux pane, for the marks in [Noticing an agent that waits](#noticing-an-agent-that-waits); does nothing outside tmux |

The scripts need zsh and jq; a formatter, tmux or terminal-notifier that isn't there is skipped.

`/hooks` lists them; `"disableAllHooks": true` in `settings.json` turns them all off.

### Skills
A skill is a set of instructions Claude follows when you type its name as a slash command. They live in
`config/claude/skills/<name>/SKILL.md`; `setup_claude` links each one into `~/.claude/skills`, which stays a
real directory because the skills claude.ai syncs live there too.

| Command | Does |
|---|---|
| `/ship [pr] [about]` | finishes the work in this checkout: moves to a branch if on the default one, checks the diff against the project's `CLAUDE.md` (docs, lock files, tests that should come with it), runs the project's checks, commits in the project's style. With `pr` it also pushes and opens a pull request. Only you can start it; Claude doesn't run it by itself |

In an agent's window, `/ship` then `agent_done <name>` after merging is the whole finish.

### Status line
```
dotfiles/docs feat/claude-config* (worktree)  Opus 5.5 medium  ctx 18% 184k  cache 42m  5h 12% 3h  7d 34% 4d
```
The directory from the repo root, the branch (`*` when there are uncommitted changes), `worktree` in an
agent's own worktree, the model and effort, and how full the context window is, in percent and tokens: green,
yellow from 50%, red from 80%, when it's time to `/compact` or `/clear`. Then how much of the plan's 5-hour
session and 7-day weekly limits is used, in the same colours, each followed by the time until it resets:
hours, or minutes in the last hour, for the session; days, or hours in the last day, for the week. They appear
after the first reply in a session, and not at all when signed in with an API key.

Between the context and the limits, how long the prompt cache stays warm: `cache 42m` in green, yellow in its
last 10 minutes, and `cache cold` in red once it has expired: the next message then reads the whole context
again, which is slower and uses more of the limits, so it's a good moment to `/clear` or `/compact` instead of
carrying on. The cache lasts a set time after the last request (`prompt_cache.ttl` in the input, an hour on
this setup). The status line redraws every 60 seconds (`refreshInterval` in `settings.json`), so this shows
while the session sits idle too.

ANSI colours and no icon font, so it follows the terminal's theme (here base16, like starship).
