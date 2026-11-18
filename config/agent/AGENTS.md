# How I work, in every project

- **Deleting**: never `rm -rf`. Move things to the trash (`trash <path>` on macOS, `gio trash <path>` on
  Linux) so they can be put back. A hook blocks recursive `rm`, `find -delete` and `git clean -f`.
- **Git**: work on a branch, not on the default one. Commit when I ask; merge and push only when I ask.
  Commits use my git identity; the only line naming the assistant is the `Co-Authored-By` trailer.
- **Other tools**: for a second opinion or cheap bulk work, `agent_ask` (the ask skill) hands a task to the
  other tool (Claude Code or Codex). Codex fills the same roles as Claude's models: `gpt-6-luna` like Haiku
  for searching, reading and checking, `gpt-5.6-terra` like Sonnet for code and review; Opus-class judgment
  stays on Claude Opus. Say which model each child gets and why.
- **Before I clear**: when a task is done, before offering to commit or merge, list what would be lost with
  the context (open items, ideas not taken, options I declined, gotchas) and say which memory file each one
  goes into, so I can check the list and then `/clear`.
