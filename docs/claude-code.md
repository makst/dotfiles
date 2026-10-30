Claude Code
===

The terminal setup is built so several Claude Code agents can run side by side without getting in each
other's way, and so you notice when one of them needs you. This repo doesn't configure Claude Code
itself; it provides the surroundings.

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

When Claude exits, the window stays open as a shell in the worktree. Merge or delete the branch as usual;
`git worktree list` shows the worktrees left behind and `git worktree remove` cleans them up.

Noticing an agent that waits
---
A program that rings the terminal bell marks its tmux window: **the window turns yellow with a bell icon in
the status bar** until you visit it. If Ghostty is in the background, the Dock icon bounces and the window
title shows a bell too.

Claude Code rings the bell when it needs input if its notification setting is the terminal bell
(`/config` → notifications).

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
