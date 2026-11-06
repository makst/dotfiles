---
name: handoff
description: Get ready for /clear - save what this conversation knows that nothing else records into memory, then print one line to paste after /clear to pick the work up again. Use only when the user runs /handoff.
argument-hint: "[what to focus on]"
disable-model-invocation: true
---

The user is about to `/clear` and wants nothing worth keeping to go with the context. Running /handoff is
their go-ahead to write memory files; it is not a go-ahead to commit, push or change any other file.
Arguments: $ARGUMENTS

1. **Collect** what only this conversation holds: open items and the next step, ideas not taken, options the
   user declined and why, gotchas found on the way, decisions and the reason behind them, and the state of
   the work (branch, uncommitted changes, what was tested, what wasn't). Leave out what the repo already
   records (code, git history, `CLAUDE.md`, docs) and what only mattered to this conversation.
2. **Place** each item: read the memory index and update the memory file that already covers the topic;
   start a new one only when none does, and add it to the index. Follow the memory format from your
   instructions; dates are absolute. Delete or correct memories this conversation proved wrong. If memory is
   switched off, put the list in the reply instead and say so.
3. **Write** the files.
4. **Report** in a short list: each item, one line, and the file it went into (new or updated), plus
   anything deliberately not saved. The user checks this list before clearing; fix what they correct.
5. **Resume line**, last, in a code block: one line to paste after `/clear` that names the task, the memory
   file to read first, the branch if the work is on one, and the next step, e.g.
   `Continue the status line colours: read claude-statusline.md, branch fix/ctx-colours, next: test at 50%.`
   If nothing is left to do, say so instead of giving a line.
