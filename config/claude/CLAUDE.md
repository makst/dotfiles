# How I work, in every project

@~/.claude/AGENTS.md

- **Models**: subagents run on Haiku unless given another model. When splitting up work, keep Haiku for
  searching, reading and checking; pass Sonnet or Opus to a part that needs judgment (design, tricky code, a
  review that mustn't miss things), and say which model each agent gets and why. When the conversation itself
  would be better served by another model, bigger or smaller, suggest it (`/model`).
