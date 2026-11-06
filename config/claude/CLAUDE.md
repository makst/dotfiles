# How I work, in every project

- **Deleting**: never `rm -rf`. Move things to the trash (`trash <path>` on macOS, `gio trash <path>` on
  Linux) so they can be put back. A hook blocks recursive `rm`, `find -delete` and `git clean -f`.
- **Git**: work on a branch, not on the default one. Commit when I ask; merge and push only when I ask.
  Commits use my git identity; the only Claude line is the `Co-Authored-By` trailer.
- **Before I clear**: when a task is done, before offering to commit or merge, list what would be lost with
  the context (open items, ideas not taken, options I declined, gotchas) and say which memory file each one
  goes into, so I can check the list and then `/clear`.
- **Models**: subagents run on Haiku unless given another model. When splitting up work, keep Haiku for
  searching, reading and checking; pass Sonnet or Opus to a part that needs judgment (design, tricky code, a
  review that mustn't miss things), and say which model each agent gets and why. When the conversation itself
  would be better served by another model, bigger or smaller, suggest it (`/model`).
