GitHub
===

A watcher that tells you when your pull requests' checks pass or fail, when they're approved or need changes,
when someone asks you by name for a review, and when someone mentions you or comments on your thread, without
a browser tab open on GitHub.

What it is
---
- **`config/github/watch`** runs every minute, started by a LaunchAgent that `setup_github` makes. It asks
  GitHub through `gh` for your open pull requests, the open ones that ask you by name for a review, and your
  unread notifications from the last week, then compares them with what it saw last time
  (`~/.local/state/github/state.json`).
- **A macOS notification** comes for each change, through terminal-notifier. Clicking it opens the pull
  request or issue in the browser. A newer one about the same pull request replaces the older one.
- **A mark in tmux's status line**, right of the Claude Code agents, shows what's open now. Each part shows only
  when its count isn't zero:

  | Mark | Counts |
  |---|---|
  | red 󰅙 | your pull requests whose checks failed |
  | green 󰗠 | your pull requests that are approved, with checks passing, not drafts: ready to merge |
  | blue 󰈈 | open pull requests that ask you by name for a review |
  | magenta 󰊤 | unread notifications about you from the last week: mentions, comments on your threads, assignments |

- **Left out**: reviews asked of a team you're in (they come by the hundred; your own requests are counted)
  and CI notifications (the checks of your pull requests cover them).
- The first run, and the first after more than a day asleep, only records what's there, so a backlog doesn't
  arrive as a flood of notifications.

Once per Mac
---
1. `gh auth login`, if `gh auth status` says you aren't logged in. The `repo` scope it asks for by default
   includes notifications.
2. `setup_github` (part of `setup_dotfiles`) loads the watcher; the mark appears within a minute.
3. The first notification asks whether terminal-notifier may send notifications: allow it (see
   [claude-code](claude-code.md#to-look-out-for) if it was declined).

Keys
---
The picker: `cmd+g` (`C-a g`) opens it in a tmux popup. It lists what the watcher found, most urgent first, with
the status line's marks; two more for your own pull requests: cyan 󰔟 checks running, grey 󰘬 the rest (draft,
waiting for review, changes requested). It opens in normal mode, with the keys of every picker
([tmux](tmux.md#picker-keys)); the letters below act in normal mode and type themselves after `/`.

| Key | Action |
|---|---|
| `cmd+g` / `C-a g` | open the picker |
| `Enter` | open it in the browser |
| `c` | check out the pull request: a new window `pr-<number>` in its repo's session runs `gh pr checkout`; the repo must be a clone zoxide knows |
| `r` | mark the notification read on GitHub; it leaves the list at once and the status line's mark within seconds |
| `R` | rerun the failed jobs of your pull request's last failed run |
| `f` | start an agent that fixes your pull request's failing checks: `agent_ci` in the repo's clone ([claude-code](claude-code.md#fixing-a-pull-requests-ci)); what goes wrong shows in tmux's message line |
| `ctrl+/` | show / hide the preview: a pull request's checks and description, or the thread with its comments |

Commands
---
| Command | What it does |
|---|---|
| `setup_github` | links `~/.config/github`, writes the LaunchAgent and (re)loads it; rerun after moving the repo |
| `~/dotfiles/config/github/watch` | one run now, instead of waiting for the next minute |
| `launchctl kickstart gui/$UID/com.makst.github-watch` | the same, through launchd |
| `launchctl bootout gui/$UID/com.makst.github-watch` | stops the watcher until the next `setup_github` |

Config
---
| Part | Where | What it does |
|---|---|---|
| Watcher | `config/github/watch` | asks GitHub, sends the notifications, sets tmux's `@github` |
| Picker | `config/github/inbox`, through `~/.config/github/` | the list behind `cmd+g`, from the watcher's state file; previews and actions ask gh |
| LaunchAgent | `~/Library/LaunchAgents/com.makst.github-watch.plist`, written by `setup_github` | runs the watcher every 60 s with Homebrew's `PATH` |
| State | `~/.local/state/github/state.json` | what the last run saw; delete it to start over without notifications |
| Last error | `~/.local/state/github/error` | why the last run failed; gone after a run that works; `check_mac` reports it |
| Mark | `status-right` in `config/tmux/tmux.conf` | shows `@github` |
| Keys | `bind g` in `config/tmux/tmux.conf`, `super+g` in `config/ghostty/config` | open the picker in a popup |

To look out for
---
- **No mark and no notifications**: `check_mac` says whether the watcher is loaded and why its last run
  failed. `gh: HTTP 401` means gh's login expired: `gh auth refresh`.
- **Work repos missing**: an organisation with single sign-on only shows up once gh's token is authorised for
  it (`gh auth refresh`, then authorise it on GitHub when asked).
- **Cost**: each run is one GraphQL query (1 of the 5,000 points an hour) and three or four pages of
  notifications, so about 200 of the 5,000 requests an hour gh may make. It takes about half a second of CPU a
  minute and a few seconds of waiting on the network, in the background.
- **No "not modified"**: GitHub's notifications API is meant to answer 304 to `If-Modified-Since` without
  counting it against the limit, but through `gh api` it always answers 200 with the full list (tested), so
  every run pays. Asking only for what changed would save nothing.
- **Team review requests fill the first page**: with hundreds of them unread, the newest 100 notifications can
  all be review requests and push a mention or comment off the first page. That's why the watcher reads every
  page of the last week, and why a notification older than a week isn't counted, even when unread; open your
  inbox on GitHub for those.
- **Running it from Claude Code**: inside Claude Code's sandbox `gh` can't read its token from the keychain and
  says the login is invalid; run the watcher with the sandbox off, or from a shell.
- **Trying changes without real notifications**: put stand-ins for `gh`, `terminal-notifier` and `tmux` first
  on `PATH` that answer from JSON files and print what they're asked, and point `XDG_STATE_HOME` at a scratch
  directory, so the real state and tmux stay untouched. Run it once to record, change the JSON, run it again.
  The stand-in notifier's output is thrown away by the watcher: trace with `zsh -x` to see the calls.
- **Checking the mark**: `capture-pane` doesn't include the status line. `tmux display -p '#{T:status-right}'`
  prints it expanded, with its `#[fg=…]` styles, on a separate server (`tmux -L probe`).

Decisions
---
- **Our own watcher, not gh-dash or gh-notify**: they're inboxes you open, and they don't tell you anything
  while closed. The watcher brings changes to you, the way the Claude Code agents' marks and notifications do,
  through the same terminal-notifier and the same status line ([design](design.md#one-tool-per-job)).
- **The list from the state file, not from GitHub**: the picker opens at once and costs no request; it
  is as fresh as the watcher's last run, a minute at most. Only the preview and the keys ask GitHub.
- **`cmd+g`, though it's Ghostty's find next**: `cmd+f` already goes to tmux's search, which uses `n` and `N`,
  so Ghostty's own search keys do nothing here; g names GitHub, as j and k name the other pickers' lists.
- **The CI agent on a branch of its own, `worktree-ci-<number>`**: the pull request's branch is often
  checked out in the clone already, and git checks a branch out in one place only. The price is the push
  command, `git push origin HEAD:<branch>`, as a plain `git push` refuses a branch whose name differs.
- **The CI agent reads the logs itself**: its prompt names the failing checks and the `gh run view` that prints
  each log, rather than carrying the logs, which run to thousands of lines and would be typed into its window.
  `gh run view` is allowed without asking in Claude Code's settings.
- **`R` and `f` both, not one**: a flaky test needs a rerun, not an agent; you decide which it is.
- **launchd, not tmux's `#()`**: tmux reruns a `#()` command every status refresh and per client, and it would
  stop when tmux isn't running; the LaunchAgent runs once a minute either way.
- **Only reviews asked of you by name**: team requests (hundreds open at a time) would turn the notifications
  into noise.
