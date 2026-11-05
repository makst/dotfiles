Vim keys everywhere
===

nvim's keys are the reference: the editors and tools next to it get the same keys, as far as each one can.
VS Code (the vim extension) and Android Studio (IdeaVim) get nvim's leader `,`, `jj`, the `;` pickers and
the `,` mappings, set in files in this repo. Xcode only has a plain vim mode. The shell, Claude Code's prompt,
tmux and the TUIs use vim keys too.

What changes where: nvim's keys are in `config/nvim/lua/user/` (see [neovim](neovim.md)), VS Code's in
`config/vscode/settings.json` (`vim.*`), Android Studio's in `config/ideavim/ideavimrc`. A key added or
changed in nvim goes into the other two in the same commit, when the IDE has a matching action.

Shared keys
---
`·` means the IDE's own behaviour, no mapping needed; `–` means it doesn't have it.

| Key | Does | nvim | VS Code | Android Studio | Xcode |
|---|---|---|---|---|---|
| `jj` | leave insert mode (zsh, Claude Code and the fzf pickers too) | ✓ | ✓ | ✓ | – |
| `,` | leader | ✓ | ✓ | ✓ | – |
| `x` | delete a character without yanking it | ✓ | ✓ | ✓ | – |
| yank / paste | system clipboard | ✓ | ✓ | ✓ | – |
| `m` | jump anywhere on screen by label | flash | easymotion (2 chars) | AceJump | – |
| `ys` `ds` `cs`, `S` | surround | ✓ | ✓ | ✓ | – |
| `gc` / `gcc` | comment | ✓ | · | ✓ | – |
| `C-h/j/k/l` | to the split left/down/up/right | ✓ (and tmux panes) | ✓ | ✓ | – |
| `Space` | to the next split, cycling | ✓ | ✓ | ✓ | – |
| `Backspace` | back to the last split | ✓ | ✓ (the previous group) | ✓ | – |
| `;f` / `;g` | find a file / a file in git | ✓ | ✓ (both: quick open) | ✓ (both: go to file) | – |
| `;r` / `;s` | grep the project / the word under the cursor | ✓ | ✓ | ✓ | – |
| `;b` | open files, most recent first | ✓ | ✓ | ✓ | – |
| `;d` / `;w` | symbols in this file / in the project | ✓ | ✓ | ✓ | – |
| `;e` | diagnostics | ✓ | ✓ (Problems) | ✓ (Problems) | – |
| `;p` | projects | ✓ | ✓ (recent) | ✓ (recent) | – |
| `gd` / `gr` | definition / references | ✓ | · / ✓ | ✓ | – |
| `gre` | rename | ✓ | ✓ | ✓ | – |
| `]d` / `[d` | next / previous diagnostic | ✓ | ✓ | ✓ | – |
| `,hd` / `,hs` | hover docs / signature | ✓ | ✓ | ✓ | – |
| `,e` / `,f` | file tree / this file in it | ✓ | ✓ | ✓ | – |
| `,w` / `,q` | save / close | ✓ | ✓ | ✓ | – |
| `,bd` `,bn` `,bp` | close buffer, next, previous | ✓ | ✓ | ✓ | – |
| `,bb` | the previous buffer | ✓ | ✓ | – | – |
| `,sv` / `,ss` | split side by side / stacked | ✓ | ✓ | ✓ | – |
| `,zi` / `,zo` | zoom the split in / out | ✓ | ✓ | ✓ (toggle) | – |
| `,so` | outline | ✓ | ✓ | ✓ | – |
| `,sr` | search and replace in the project | ✓ | ✓ | ✓ | – |
| `,xx` | all diagnostics | ✓ | ✓ | ✓ | – |
| `,re` | reload the config | ✓ | – | ✓ | – |

Debugging happens in the IDEs, so these exist there only (nvim has no debugger; its `,d` is free apart from
`,dt` / `,do` for diff):

| Key | Does | VS Code | Android Studio |
|---|---|---|---|
| `,db` | toggle a breakpoint | ✓ | ✓ |
| `,ds` | start debugging | ✓ | ✓ |
| `,dc` | continue | ✓ | ✓ |
| `,dn` / `,di` / `,du` | step over (next) / into / out | ✓ | ✓ |
| `,dx` | stop | ✓ | ✓ |

And in Android Studio, `,ar` runs the app and `,ax` stops it, like nvim's `,a` keys.

Not shared:
- **`H` `J` `K` `L`** walk the syntax tree in nvim (treewalker); the IDEs keep vim's meaning (top of screen,
  join lines, …).
- **`gc` in nvim** is the LSP code action in buffers with a language server (`gcc` still comments); the IDEs
  keep `gc` for comments and use their own key for quick fixes (`cmd+.` in VS Code, `alt+enter` in Android
  Studio).
- **Harpoon** (`;m`, `;j`, `;k`, `,m`), git (`,g…`), terminals (`,lg`, `,tt`) and the `,a` /
  `,i` / `,vo` keys that open the IDEs stay in nvim.

Each tool
---
- **VS Code**: the vim extension (`vscodevim.vim`, installed by `setup_vscode`), configured in
  `config/vscode/settings.json`. Keys VS Code itself wants (`cmd+…`) still work.
- **Android Studio**: IdeaVim and AceJump, installed by `setup_ideavim` (Android Studio closed), which also
  links `~/.ideavimrc`. `C-h/j/k/l` go to IdeaVim rather than the IDE's own shortcuts. After editing the
  file, `,re` reloads it. In any IDE, `:action` (or the IdeaVim icon in the status bar → Track Action IDs)
  shows the action ids for new mappings.
- **Xcode**: Editor → Vim Mode. Motions, operators, text objects and `:` commands work; Xcode can't take
  mappings, so no leader, `jj` or `;` pickers.
- **zsh**: vi mode, `jj` leaves insert mode (see [zsh](zsh.md)).
- **fzf pickers** (`cmd+k`, `cmd+j`, `cmd+shift+j`, `agent_resume`): a normal mode with `j`/`k`, `g`/`G`, `/` to filter
  and `jj` back from typing (see [tmux](tmux.md#picker-keys)).
- **Claude Code**: the prompt is in vim mode (`editorMode` in `config/claude/settings.json`), `jj` leaves
  insert mode (`vimInsertModeRemaps`). Motions, operators and text objects work; no other mappings. In
  normal mode, `j`/`k` at the first or last line go through earlier prompts, and `/` searches them.
  `/config` → Editor mode turns it off, but writes through the link into the repo, so for every Mac.
- **tmux**: copy mode uses vi keys, `v` selects, `y` copies (see [tmux](tmux.md)); `C-h/j/k/l` cross into
  nvim.
- **AeroSpace**: `alt+h/j/k/l` move between windows (see [window management](window-management.md)).
- **lazygit, yazi, less, man**: `j`/`k`, `/` to search, out of the box.
