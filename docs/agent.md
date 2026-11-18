Agents
===

The terminal setup is built so several coding agents can run side by side without getting in each other's way,
and so you notice when one of them needs you. The job, worktrees, windows, marks, review, resume and landing,
belongs to this layer; the tool that does the coding is a plug-in, [Claude Code](claude.md) by default or
[Codex CLI](codex.md).

What it is
---
- **One worktree per agent**: `agent` starts the tool in a git worktree of its own, in a tmux window of its
  own, so agents never edit the same checkout as you or each other.
- **nvim reloads files changed on disk** when you return to it, so edits made by an agent (or by git) show
  up without `:e`.
- **Agents survive closing Ghostty**: they run in tmux, and Ghostty reattaches to it. A reboot restores the
  windows (tmux-resurrect) but not the running processes.
- The tmux server is started from a login shell, so the tool and everything it calls has the same `PATH` as
  your shell.
- **Conversations stay**: each tool keeps its conversations as files of its own (Claude Code: one per session
  in `~/.claude/projects/`, a folder per directory, here for a year). An agent's stays in its worktree's
  folder (an agent started with the old `claude -w` moved to the main checkout's when Claude removed the
  worktree itself on exit; both are found). `agent_resume` lists every tool's.

### One layer, any tool

`zsh/functions/agent.zsh` owns the agent job and runs whichever tool `git config agent.tool` names (`--tool
<name>` on one command), `claude` when none is set. A tool is a set of functions in `zsh/functions/<tool>.zsh`;
the layer finds the tools as the functions `_agent_<tool>_start`. Each defines all seven:

| Function | Does |
|---|---|
| `_agent_<t>_start [args…]` | sets `reply` to the command line that starts the tool interactively in the current directory; args are a prompt and/or the tool's own flags |
| `_agent_<t>_resume <transcript>` | sets `reply` to the command line that resumes that conversation |
| `_agent_<t>_review <name> <branch> <default> [args…]` | sets `reply` to a command line that reviews the branch's commits against the default branch without editing |
| `_agent_<t>_sessions <main>` | prints the tool's conversations that ran in the repo's agent worktrees, newest first: `transcript<TAB>name<TAB>YYYY-MM-DD HH:MM<TAB>title`; reviews left out |
| `_agent_<t>_preview` | sets `reply=(<glob of its transcripts> <jq filter>)`: the filter prints a transcript's prompts and replies for the `agent_resume` preview |
| `_agent_<t>_hooks` | prints the repo path of the file that wires the tool's hooks |
| `_agent_<t>_ask read\|edit [model]` | sets `reply` to the command line that starts the tool for `agent_ask` ([Asking another agent](#asking-another-agent)), with the word `{prompt}` where the prompt goes; `read` must start it unable to change the project's files. Every word is quoted and `{prompt}` must be a whole word |

A tool's hooks file runs the `rm` guard, `tmux-state.sh` and `answer.sh` (on Stop, so the answer goes back to
whoever asked); a tool without hooks writes the answer itself ([Adding a tool](#adding-a-tool)). A check fails
when a tool has only part of the interface, or its hooks file lacks the guard or `answer.sh`. The tools:

| Tool | Adapter | Its page |
|---|---|---|
| `claude` (default) | `zsh/functions/claude.zsh` | [claude](claude.md) |
| `codex` | `zsh/functions/codex.zsh` | [codex](codex.md) |

### Noticing an agent that waits

Hooks tell tmux what each agent is doing (the scripts are in [Config](#config); Claude Code's wiring in
[claude](claude.md#hooks)), and tmux marks it
wherever it lists windows or sessions:

| Mark | State | Set when |
|---|---|---|
| yellow bell 󰂞 | **waiting** for you | the agent asks for a permission or asks you a question |
| green tick 󰄬 | **done**, not seen yet | the agent finishes its turn in a window you're not looking at |
| cyan hourglass 󰔟 | **working** | you send a prompt or approve a permission, and after each tool it runs |
| none | idle | the agent has just started, you've looked at the finished agent, or it was on screen when it finished |

A window shows the mark of its most urgent agent, in that order; a session the most urgent of its windows. The
marks appear on the windows in the status bar, in the tree (`cmd+j`) next to every session, window and pane
with more than one in its window, and next to the running sessions in the session picker (`cmd+k`). The right
of the status bar counts the agents in each state across all sessions, e.g. `󰂞 1 󰄬 2 󰔟 3`, so you see them
from any session.

The hook also rings the bell when the agent needs input or has finished its turn, whatever the notification
setting in `/config` is: if Ghostty is in the background, the Dock icon bounces and the window title shows a
bell. Any other program that rings the bell turns its window yellow with a bell icon until you visit it.

When you aren't looking at the agent, a macOS notification tells you too: when the agent asks for a permission
(`wants to use Bash: <what the command does>`) or asks you a question. Finishing a turn sends no notification,
only the bell and the green mark. The title is the conversation's title and the agent's `session:window`.
You're looking at it when its window is the active one of a session that a tmux client shows and that client's
terminal (Ghostty) is the frontmost app; then nothing is sent. Clicking the notification switches the tmux
client you used last to the agent's pane and brings Ghostty to the front. A newer notification from the same
agent replaces the older one. Outside tmux or off macOS no notification is sent.

No hook fires when you answer a permission prompt, only once the tool has finished, so while a Claude Code
agent waits the hook watches its pane twice a second: when the prompt goes away and the spinner line
(`✻ Thinking… (3s`) shows, you approved and it's *working*; without the spinner you declined and it's idle.

The overview of all agents (`cmd+shift+j`) lists every pane that runs an agent tool (also those started before
the hooks, which have no state yet), most urgent first: waiting, done, working, then the rest. Each line has
the agent's mark, its window and what it's working on (the title the tool gives the conversation); below is a
preview of the selected agent's screen. List and preview update within a second, so an agent that starts
waiting moves up while you look, and the cursor stays on the agent it was on; only what changed is redrawn,
so nothing flickers. For every window, agents or not, use `cmd+j` (`C-a w`).

Once per project
---
Tell `agent_land` which checks to run before it merges an agent, in the project's main checkout:

```sh
git config agent.check 'checks/check_dotfiles'   # this repo
git config agent.check 'npm test'                # e.g. a Node project
```

It goes in the clone's `.git/config`, not into the project, so set it again in a new clone and on each Mac.
Pick what's fast and local, the checks you'd run before a commit.

Using another tool
---
```sh
agent --tool codex fix-login "the login form rejects valid emails"   # this one agent
git config --global agent.tool codex                                   # every agent from now on
git config --global --unset agent.tool                                 # back to Claude Code
```

The tool is `claude` unless `git config agent.tool <name>` says another: `--global` for every project, no flag
for this clone, or per Mac in `~/.config/dotfiles/gitconfig`. `--tool <name>` on `agent`, `agent_ci` and
`agent_review` names it for one command. `agent_resume` needs no flag: it lists every tool's conversations and
resumes one with the tool that had it. `agent_ask --tool <name>` takes the same names. The tools are in
[One layer, any tool](#one-layer-any-tool); each has its once-per-Mac steps on its page.

Starting an agent
---
```sh
agent fix-login
agent fix-login "the login form rejects valid emails"
```

`agent [--tool <name>] <name> [prompt]` makes a **git worktree** `.claude/worktrees/<name>` on a branch
`worktree-<name>`, from the repo's default branch (not from the checkout you're in), and starts the tool in
it. Inside tmux it opens in a **new window named `<name>`**; outside tmux it runs right there. A name that
already has a worktree reuses it, and one whose branch is still there checks that branch out; any other name
starts fresh from the default branch. Arguments after the name are passed on to the tool. The worktree is made
by `agent` itself, not by `claude -w`, so every tool runs in it the same way; agents started with `claude -w`
earlier still work.

When the tool exits, the window stays open as a shell in the worktree. The worktrees live in
`.claude/worktrees/` for every tool (see [Decisions](#decisions)), which the global gitignore hides from
`git status` in every repo.


Reviewing an agent
---
```sh
agent_review fix-login                  # a reviewer beside fix-login, running /code-review on its branch
agent_review fix-login --model sonnet   # the same on a cheaper model; arguments go to the tool
```

`agent_review [--tool <name>] <name>` starts a second agent in the agent's worktree, in a pane beside the
agent's own (in a new window when the agent has none open), and goes there. It reviews the agent's branch
(Claude Code: `/code-review`), so it reviews what's committed: `/ship` first, it says so when there are
uncommitted changes. It can't edit (Claude Code: the Edit and Write tools are taken away), so it reports and
doesn't change code; tell the agent what's worth fixing, while it still has the change in its context. Its
conversation isn't one of the agent's: `agent_resume` doesn't list it. It runs on the tool's default model and
effort; pass the tool's own flags after the name (Claude Code: `--model` or `--effort`).


Fixing a pull request's CI
---
```sh
agent_ci 15607
```

`agent_ci [--tool <name>] <number>`, in a clone of the repo, or `f` on a failing pull request in the GitHub
picker (`cmd+g`, [github](github.md#keys)): an agent named `ci-<number>` that fixes the pull request's failing
checks.

1. It fetches the pull request's head and makes the worktree `ci-<number>` there, on a branch
   `worktree-ci-<number>`, then starts the tool in a window as `agent` does.
2. The agent's first prompt names the failing checks, each with the `gh run view <run> --log-failed` that
   prints its log, and asks it to fix the cause and commit, not push, or to say when the failure looks flaky.
3. When it's done (green mark), look at its commit and push it to the pull request:
   `git push origin HEAD:<branch>`, which the agent repeats at the end.
4. `agent_done --force ci-<number>`: squash-merged pull requests leave the commit out of the default branch,
   so it doesn't count as merged. Not `agent_land`: the fix goes to the pull request, not into the default
   branch.

It refuses a pull request without failing checks, one from a fork (its branch isn't on origin) and a second
`ci-<number>` while the first is still there (`agent_resume ci-<number>` goes back to it).

To review it yourself, committed or not, comment on the code in nvim and send the comments to the agent as one
message:
1. Open nvim in the agent's worktree and `;g` (or `greview`): the files its branch changes, committed or not;
   `Enter` opens one beside its old side ([nvim](nvim.md#reviewing-a-branch)).
2. `,n` on a line opens a window below it to write the comment in, several lines if you like: `:w` saves it
   and it shows above the line, like a code tour's note; `q` closes without saving. `,n` on a line that has
   one opens it to change; saving it empty deletes it.
3. `;n` lists the comments not sent yet, each previewed at its line: `Enter` goes there, `M-r` opens one in
   the same window, `M-d` removes one. `M-g` switches to `;g`'s files, and `M-n` there comes back.
4. `M-p` (`p` in normal mode) pastes them all into the agent's prompt, in file and line order, each with its
   `path:line` and the line as it read, and goes to the agent's pane. Read it, add to it, press `Enter`.

The agent's pane is the pane of the tool working in the same git root; with a reviewer beside it, `M-p` asks
which. The comments are sent once: after `M-p` they're gone from the code, and tmux keeps the message in its
paste buffer `review` (`C-a P`) in case the prompt was cleared. Outside tmux, or with no agent here, the
message goes to the clipboard.


Asking another agent
---
```sh
agent_ask --tool codex "why does the login test fail on CI but not here?"
agent_ask --tool claude --model haiku "list the places that read FOO_URL"
agent_ask --to codex-101530 "and where is it set?"      # a follow-up to the same child
agent_ask_edit --tool codex --name fix-x "make the retry in client.ts exponential, commit it"
agent_ask --list                                          # the open children
agent_ask --close codex-101530
```

`agent_ask` hands a task to another agent tool and prints its answer, the way a subagent works but across
tools: Claude Code asks Codex, Codex asks Claude Code, either asks any tool of the layer. Agents call it from
their shell (`/ask` in Claude Code, `$ask` in Codex: the shared skill `config/agent/skills/ask/`); you can run
it too. It needs tmux.

1. It opens a **window `ask-<id>`** in the caller's tmux session, in the background, and starts the tool there,
   interactive, with the prompt. You can switch to the window to watch it, or answer a permission prompt; its
   marks and notifications are those of any agent ([Noticing an agent that waits](#noticing-an-agent-that-waits)).
2. When the child finishes its turn, the Stop hook `answer.sh` writes its last message to the child's state
   directory, and `agent_ask` prints it with how to go on. Exit code 0 is an answer, 1 an error (the tool
   exited without one: the end of its window is printed), 75 still working at `--timeout` (540 s by default):
   `agent_ask --wait <id>` picks it up later.
3. `--to <id> "…"` sends a follow-up to the same child, which still has what it read. `--close <id>` closes the
   window when you're done; an answered child stays open until then.

| | `agent_ask` (read-only) | `agent_ask_edit` |
|---|---|---|
| Works in | the caller's directory | its own worktree `ask-<id>` on a branch `worktree-ask-<id>`, as `agent` makes them |
| Can change files | not the project's (see below) | yes, commits there, doesn't push |
| Claude Code | `claude --read-only` ([claude](claude.md#commands)) | as set up |
| Codex | `-s read-only` | its usual sandbox, in the worktree; the `codex` wrapper adds the main checkout's `.git` with `--add-dir` so commits work (not verified live yet) |
| Asks you first | no | yes: both tools' permission rules ask for `agent_ask_edit` |
| Follow-up | `agent_ask --to <id>` | `agent_ask_edit --to <id>` (`agent_ask --to` refuses an edit child) |
| Afterwards | `agent_ask --close` | `agent_review ask-<id>`, `agent_land ask-<id>`, as for any agent |

The rules it keeps:
- **Two names, not a flag.** `agent_ask_edit` is the same script, linked under a second name by `setup_agent`.
  Permission rules match a command's name reliably; a quoted `'--edit'` could slip past a rule on the
  arguments. `--edit` is refused. A follow-up to an edit child is `agent_ask_edit --to <id>`, so it asks too.
- **Read-only means the project's files.** The child can't change them, but MCP tools and the network aren't
  cut off: it is not a sandbox against everything.
- **No flags of the tool pass through.** `--tool` must be a tool of the layer, `--model` a plain model name,
  and how the tool starts read-only is the adapter's `_agent_<t>_ask`: the caller can't ask for a looser
  sandbox or approvals.
- **Follow-ups are plain text.** They are pasted with the control characters removed (newline and tab stay),
  after the lead line "Follow-up from the agent that asked you:". The text can't send keys (an escape would end
  the bracketed paste early) or start a command of the tool's own (`/…`, `!…`).
- **No nesting, 4 children**: a child can't ask further, and at most 4 children are open per tmux session.
  Both limits are soft: the depth is an environment variable (`AGENT_ASK_DEPTH`), and the 4 are counted by window
  name, so two callers at once can go one over.
- **The child's sandbox is its own.** It is the tool, started by the tmux server, never run with its sandbox or
  approvals off.

State is one directory per child, `~/.local/state/agent-ask/<id>/` (mode 700): `prompt`, `task` (the
caller's words, for `--list`), `meta`, `expect` (the turn the caller waits for: one more than `turn` when a prompt
is sent), `turn` and `answer.<n>`, `exited`, and `lock/` while a follow-up is sent; the top comment of
`zsh/bin/agent_ask` lists them. The child's pane is tagged `@agent-ask=<id>`, so a reused pane id isn't taken
for it. The directories stay after `--close`, like a conversation. Every Claude Code session's sandbox denies
writing `~/.local/state/agent-ask` ([claude](claude.md#sandbox)), so a child can't tamper with its state, and
`answer.sh` refuses a symlinked state directory.

Finishing an agent
---
```sh
agent_land fix-login             # rebase, run the checks, merge into the default branch, then agent_done
agent_land --no-check fix-login  # the same without the checks
agent_done                       # list the repo's agents: branch, merged or not, uncommitted changes
agent_done fix-login             # remove the worktree, delete the branch, close the tmux window
agent_done --force fix-login     # the same for a branch you don't want to merge
```

1. `/ship` in the agent's window (Claude Code; see [claude](claude.md#skills)) commits its work in the
   project's style.
2. `agent_land fix-login` merges it and finishes the agent; for a PR instead, `/ship pr`, then `agent_done
   fix-login` once it's merged.
3. `git push` when you're ready: `agent_land` never pushes.

`agent_land` does in one go what you'd do by hand, and stops at the first step that fails, saying why, with
the agent left as it was so you can ask it to fix things:

| Step | Stops when |
|---|---|
| the worktree is clean and the local default branch isn't behind origin's | there are uncommitted changes (`/ship`), or you need to pull |
| the branch is rebased onto the default branch, in the agent's worktree | it conflicts: the rebase is undone, the files are listed; ask the agent to rebase |
| the project's checks run in the worktree, on the rebased branch | they fail, or none are set (below) |
| the default branch is fast-forwarded to the branch, then `agent_done` | the main checkout's own changes are in the way |

The checks are the command in `git config agent.check`, once per clone (see [Once per
project](#once-per-project)): nothing goes into the project. It runs in your shell, so a shell function
works too. Without one `agent_land` stops; `--no-check` lands anyway. The main checkout moves along when it
has the default branch out; otherwise only the branch moves.

`agent_done` only removes things when nothing would be lost: it stops if the worktree has uncommitted
changes, and without `--force` if the branch has commits that aren't in the default branch. A commit counts as
merged when it's in the local default branch or in origin's, so an agent that pushed its work straight to
`origin/main` can be finished without pulling first. Ignored files (`.env`, `node_modules`) are in no commit,
so a worktree that has any goes to the Trash whole instead of being removed. It works from anywhere in the
repo, the worktree itself included. A tool that locks its worktree (`claude -w` did) holds the lock while it
runs, so `agent_done` closes the window first, which ends the tool, and waits a moment for the lock to go.
Before deleting the branch it saves the agent's last commit in
`refs/agents/<name>`, and the conversation stays, so [`agent_resume`](#going-back-to-an-agent) can bring the
agent back. Tab completes the names of the repo's agent worktrees.


Going back to an agent
---
```sh
agent_resume                  # pick one of the repo's agent conversations in fzf, newest first
agent_resume fix-login        # resume fix-login's newest conversation in a new window
agent_resume 4eb428c6-…       # resume one by its session id, when an agent has several
```

`agent_resume` brings a finished agent back where it was, with the tool that had the conversation: in its own
worktree, on a branch `worktree-<name>`, in a new tmux window named after it, like `agent`. Tab completes the
names, with each conversation's title.

The picker lists each conversation's agent, the tool, when it was last active, its title (or the last prompt)
and its session id; the preview shows how the conversation ends. Its keys are every picker's
([tmux](tmux.md#picker-keys)): it opens in normal mode, like nvim, `j`/`k` move, `/` filters, `jj` goes back
to moving through what the filter matched, `Enter` resumes, `q` quits. Piped (`agent_resume | …`), it prints
the list instead.

When the worktree is gone, `agent_resume` makes it again at the same path, so the tool finds its conversation
there:

| What `agent_done` left | The new worktree starts from |
|---|---|
| the agent's work merged | the default branch, which holds that work |
| the work dropped with `--force` | the agent's last commit, saved in `refs/agents/<name>` |
| the branch, because the worktree was removed some other way | that branch |

`refs/agents/<name>` is a hidden ref: it keeps the commits from being cleaned up by git and doesn't show in
`git branch`. `git for-each-ref refs/agents` lists them, and `git update-ref -d refs/agents/<name>` drops one
for good. After a reboot, the tool's own continue (Claude Code: `claude --continue`) in the agent's window
picks up the last conversation instead.

Adding a skill
---
1. Write `config/agent/skills/<name>/SKILL.md` (a `name` and a `description` in its front matter).
2. Start a new `claude` or `codex`: the wrapper links it into `~/.claude/skills` or `~/.agents/skills` (a
   session that is already running may need a restart).
3. Add it to the table in [claude](claude.md#skills) and commit.

Adding a tool
---
1. Write `zsh/functions/<tool>.zsh` with the seven functions of [One layer, any tool](#one-layer-any-tool),
   each with a usage comment, and a wrapper for the tool's settings and a `setup_<tool>` if it has config
   (`codex.zsh` is the shortest model; `setup_<tool>` goes into `setup_dotfiles` and [setup](setup.md)).
2. Wire its hooks in a file in `config/<tool>/` that runs the scripts of `config/agent/hooks`, as
   `config/codex/hooks.json` does: `no-recursive-rm.sh` before a shell command, `tmux-state.sh` with
   `idle`, `working`, `waiting`, `done` and `off`, and `answer.sh` on Stop (listed first; Claude Code runs an
   event's hooks in parallel, so the order doesn't
   matter). `_agent_<tool>_hooks` prints that file. A tool that has no hooks
   (a plain CLI, an open model's) can't use `answer.sh`. `_agent_<tool>_ask` quotes each reply word, and
   `{prompt}` must be a whole word, so no shell syntax can be put in the command line: the tool's command is a
   small script that runs the tool and writes `$AGENT_ASK_DIR/answer.<n>` and then `<n>` to
   `$AGENT_ASK_DIR/turn` itself, like the stub in `checks/behaviour.zsh` (`run_agent_ask`). Follow-ups assume a
   TUI that accepts a bracketed paste.
3. Add the tool's command name to the `@agent-pane` test in `config/tmux/tmux.conf`, one alternative per tool.
4. Write `docs/<tool>.md` and add the tool to the table above, [README](../README.md) and
   [vim keys](vim-keys.md) if it has a full-screen interface.
   `_agent_<tool>_ask` must start `read` so the tool can't change the project's files (Claude Code: its
   read-only wrapper option; Codex: its read-only sandbox), and put `{prompt}` where the prompt goes;
   `agent_ask` finds the tool by that function, nothing else to register.
5. `checks/check_dotfiles`: it fails for a missing function or hooks file and a hooks file without the `rm`
   guard or `answer.sh`, and warns for a missing mark or an `@agent-pane` that doesn't name the tool.

Keys
---
| Key | Action |
|---|---|
| `cmd+shift+j` (`C-a a`) | the overview of all agents, `Enter` jumps there; the keys of every picker ([picker keys](tmux.md#picker-keys)) |
| `cmd+shift+space` (`C-a A`) | the next agent that needs you, in any session: waiting ones first, then done ones (which turn idle as you see them); again for the one after; says so when none is left |
| `cmd+shift+0` / `cmd+0` | back to the session / window you came from |

Commands
---
| Command | Does |
|---|---|
| `agent [--tool <t>] <name> [prompt]` | the tool in a worktree and window of its own ([Starting an agent](#starting-an-agent)) |
| `agent_review [--tool <t>] <name> [args]` | a read-only reviewer beside the agent, running `/code-review` on its branch ([Reviewing an agent](#reviewing-an-agent)) |
| `agent_land [--no-check] <name>` | rebase, check, merge into the default branch and finish the agent ([Finishing an agent](#finishing-an-agent)) |
| `agent_ci [--tool <t>] <number>` | an agent that fixes pull request `<number>`'s failing checks ([Fixing a pull request's CI](#fixing-a-pull-requests-ci)) |
| `agent_ask[_edit] --tool <t> [--model <m>] <prompt>` | another tool answers a question, or with `agent_ask_edit` does a task in its own worktree; also `--to <id>`, `--wait <id>`, `--list`, `--close <id>` ([Asking another agent](#asking-another-agent)) |
| `agent_done [--force] [name]` | list the agents, or finish one ([Finishing an agent](#finishing-an-agent)) |
| `agent_resume [name \| id]` | pick or resume an agent's conversation ([Going back to an agent](#going-back-to-an-agent)) |

Config
---
- **`zsh/functions/agent.zsh`**: the agent functions and the interface above; `_agent_tool` picks the tool.
- **`zsh/bin/agent_ask`** → `~/.local/bin/agent_ask`, linked by `setup_agent` (part of `setup_dotfiles`): a script
  on `PATH`, not a function, because the tools' shells don't load `.zshrc`. It sources `agent.zsh` and the tool
  adapters from the repo for the interface. `setup_agent` also links it as `~/.local/bin/agent_ask_edit`: the
  script takes its mode from the name it is called by.
- **`config/tmux/tmux.conf`**, section "agents": the `@agent-pane` test (a pane the hooks marked, or one
  running an agent tool), the state marks and their counts in the status bar; `config/tmux/agents` and
  `next-agent` read them.
- **`git config agent.tool`** (default `claude`) and **`git config agent.check`**: per clone, per Mac or
  global, never in a project.
- **The worktrees** are `.claude/worktrees/<name>` in the main checkout, which the global gitignore hides.
- **`config/agent/hooks/`**: the hook scripts every tool shares; `~/.claude/hooks` and `~/.codex/hooks` link
  here. The scripts need zsh and jq; a formatter, tmux or terminal-notifier that isn't there is skipped.

  | Script | Does |
  |---|---|
  | `no-recursive-rm.sh` | before a shell command: refuses deletes that can't be undone (`rm -r` / `rm -rf`, `find … -delete`, `git clean -f`) and tells the agent to move things to the trash instead (`git stash -u` for untracked files) |
  | `format.sh` | after the agent edits or writes a file: formats it with the language's formatter, if installed and the project uses it: prettier, stylua and ruff only where the project has their config, `shfmt` where it has an `.editorconfig`, `goimports`/`gofmt` always (Go has one style). It reads Claude Code's Edit/Write input, so it is wired there only |
  | `bell.sh` | the agent needs input or has finished: rings the bell in its tmux pane, so the window turns yellow and Ghostty bounces in the Dock; does nothing outside tmux |
  | `notify.sh [tool name]` | the agent asks for permission or a question: a macOS notification titled with the tool's name (default Claude Code) unless you're looking at the agent's tmux window; clicking it jumps there ([Noticing an agent that waits](#noticing-an-agent-that-waits)); does nothing outside tmux or off macOS |
  | `answer.sh` | on Stop: for a child started by `agent_ask` (it has `AGENT_ASK_DIR`), writes the turn's last message, the hook's `last_assistant_message`, to the child's state directory for `agent_ask` to print (each file written whole and moved into place); does nothing in any other session or for a state directory that is a symlink or outside `~/.local/state/agent-ask`. `bell.sh` and `tmux-state.sh` are quiet at Stop for such a child, so a child that has only answered doesn't ring the bell or turn green: nobody is waiting for it but the agent that asked |
  | `tmux-state.sh <state>` | records the agent's state (working, waiting, done) in its tmux pane for the marks in [Noticing an agent that waits](#noticing-an-agent-that-waits); for Claude Code it also watches the screen to see whether you approved a permission prompt (other tools stay waiting until their next hook) |
- **`config/agent/skills/`**: the skills every tool gets, one folder with a `SKILL.md` each. `link_agent_skills
  <dir>` links them into a tool's skills directory (`setup_claude` and the `claude` wrapper do it for
  `~/.claude/skills`, which stays a real directory because the skills claude.ai syncs live there too;
  `setup_codex` and the `codex` wrapper for `~/.agents/skills`) and removes the links of deleted ones, so a new
  skill is there from the next start. Which commands they are: [claude](claude.md#skills).
- **`config/agent/AGENTS.md`**: the instructions for every project, for every tool: delete to the trash, work
  on a branch, merge and push only when asked; before you `/clear`, list what would be lost with the context
  and where it gets saved. `~/.claude/AGENTS.md` and `~/.codex/AGENTS.md` link to it, and Claude Code's
  `CLAUDE.md` imports it.
- **Each tool's own files**: Claude Code's are in [claude](claude.md#config), Codex's in
  [codex](codex.md#config).

To look out for
---
- **`agent_review` reads only what Claude Code's tools let it**: the Edit and Write tools are taken away, but
  a Bash command could still write; in auto mode the classifier and the sandbox stop most of that, not all.
- **A reviewer's conversation** is told apart by its first prompt, `/code-review`: one you start by hand with
  that prompt in an agent's worktree is left out of `agent_resume` too.
- **Review comments are a code tour named `review`**: `,n` and `;n` open it, which closes another open tour
  (`;o` reopens that one). It lives in `.codetour/review.json`, which the global gitignore hides in every
  repo, so the agent doesn't commit it.
- **An asked child waits for approvals like any agent**: in a read-only ask a permission prompt (the child
  wants a command that isn't allowed) stops it until you answer in its window `ask-<id>`; `agent_ask` says so on
  stderr and keeps waiting until the timeout. `agent_ask --to` refuses while the child waits on such a dialog
  (its `@agent` is *waiting*): pasted text acts as keys there, and one letter answers it. This was seen live,
  when a pasted message approved a command and saved a "don't ask again" rule.
- **`agent_ask` checks first that the tmux server answers** and fails with "can't reach the tmux server"
  otherwise. In Claude Code the call then wasn't `agent_ask` on its own (a pipe, `cd`, `$(…)` or backticks keep
  it in the sandbox); in Codex the call has to ask for the escalation option (sandbox_permissions
  "require_escalated") with a justification, which the `ask` skill says ([codex](codex.md#config)).
- **The child is a whole session**: it costs what any session costs, reads the project's instructions and takes
  a few seconds to start. For a one-line question, a quick look at the code does it faster.
- **Follow-ups are pasted, not typed**: bracketed paste keeps the tools' own keys from firing (typing `$` opens
  Codex's skill list), and the text has its control characters removed and a lead line before it, so it can't
  send keys or start a command of the tool's own. A child that is still working refuses a follow-up:
  `agent_ask --wait <id>` first.
- **The limits on asking are soft**: a child's depth is an environment variable, which anything that starts a
  process can set, and the cap of 4 is counted by window name, so two callers at once can go one over.
- **Read-only covers the project's files, not MCP tools or the network**: a read-only child can still call an
  MCP tool or fetch a page. Don't read "can't change files" as more than that.
- **This repo's `zsh/` is closed to a sandboxed Claude**: `agent_ask` runs outside the sandbox and sources
  `zsh/functions`, so Claude edits those files with its Edit tool ([claude](claude.md#sandbox)).
- **A child's window shows in `cmd+j` and the overview** like any agent's; `agent_ask --close` removes it.
- **Codex as a child works (read-only, tried live)**, and so does Codex asking Claude Code: Codex runs the Stop
  hook only once `/hooks` has trusted `config/codex/hooks.json` ([codex](codex.md#once-per-mac)); until then an
  ask of Codex gets no answer. In tmux the `codex` wrapper passes `--no-daemon`, or the shared server's hooks
  would miss `AGENT_ASK_DIR` ([codex](codex.md#to-look-out-for)). A Codex child of `agent_ask_edit` isn't
  verified.
- **`agent_land` rebases the agent's branch under it**: when the agent is still working, let it finish its
  turn first, or its next edit lands on the rebased files.

Decisions
---
- **One layer, a tool per backend, not one script per tool**: worktrees, windows, marks, review, resume and
  landing are the same job whichever tool runs, so they live once in `agent.zsh` and a tool is only the six
  functions that say how to start, resume, review and read it ("One tool per job").
- **Worktrees stay in `.claude/worktrees/` for every tool**: the agents and conversations that already exist
  are found there, and a rename would orphan them. This is the "Exceptions say why" entry for the directory's
  name, `_agent_worktrees` in `agent.zsh`.
- **The CI agent on a branch of its own, `worktree-ci-<number>`**: the pull request's branch is often
  checked out in the clone already, and git checks a branch out in one place only. The price is the push
  command, `git push origin HEAD:<branch>`, as a plain `git push` refuses a branch whose name differs.
- **The CI agent reads the logs itself**: its prompt names the failing checks and the `gh run view` that
  prints each log, rather than carrying the logs, which run to thousands of lines and would be typed into its
  window. `gh run view` is allowed without asking in Claude Code's settings.
- **The child is interactive, in a tmux window, not headless** (`claude -p`, `codex exec`): its marks, permission
  prompts and notifications work, you can watch it or take over, and it takes follow-ups. The price is a whole
  session and a Stop hook to read the answer from.
- **It runs outside the caller's sandbox because the tmux server starts it**: Codex can't write `~/.codex`
  inside Claude Code's sandbox, and Seatbelt sandboxes don't nest, so a child started from the caller's shell
  would fail or inherit the wrong limits. The child has its own sandbox and approvals instead: nothing is turned
  off. This is why `agent_ask` and `agent_ask_edit` are in Claude Code's `sandbox.excludedCommands` and
  Codex's rules cover both ([claude](claude.md#sandbox), [codex](codex.md#config)).
- **The answer comes back through the Stop hook's `last_assistant_message`**, not by reading the screen or the
  transcript: both tools give hooks the same field, so `answer.sh` is shared ("One tool per job").
- **Read-only Claude Code isn't plan mode**: plan mode stalls on a task-like prompt at `AskUserQuestion` or
  `ExitPlanMode` and never ends its turn, so the answer never comes. `claude --read-only` denies the edit tools,
  denies writes to the checkout and its `.git` in the sandbox, lets no command run outside the sandbox, denies
  `git * --output*` and keeps the default permission mode.
- **Follow-ups are pasted with bracketed paste and cleaned**, as in "To look out for".
- **Two command names for read and edit, not `--edit`**: the permission rules of both tools match a command's
  name reliably and an argument not (a quoted `'--edit'` slips past), so the edit mode is `agent_ask_edit`, one
  script linked twice, and asks first, follow-ups included.
- **State is guarded from the child**: Claude Code's sandbox denies writing `~/.local/state/agent-ask`, the
  pane is tagged with the child's id, and `answer.sh` refuses a symlinked directory.
- **No flags pass through, no nesting, 4 children** (soft limits, see "To look out for"): the caller is an
  agent that may have been told something by a file it read; it must not be able to start a child with a looser
  sandbox, start a tree of them, or fill the session with windows.
- **One `agent_ask` for every direction**, not a script per pair of tools: a tool is added by the interface
  function and the hooks wiring, and every tool can ask and be asked ("One tool per job").
