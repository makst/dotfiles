Vim keys everywhere
===

nvim's keys are the reference: the editors and tools next to it get the same keys, as far as each one can.
VS Code (the vim extension) and Android Studio (IdeaVim) get nvim's leader `,`, `jj`, the `;` pickers and
the `,` mappings, set in files in this repo. Xcode only has a plain vim mode. The shell, Claude Code's prompt,
tmux and the TUIs use vim keys too.

Adding a key
---
1. Bind it in nvim, in the plugin's `keymaps.lua` under `config/nvim/lua/user/` (see [nvim](nvim.md)).
2. In the same commit, add it to VS Code (`config/vscode/settings.json`, `vim.*`) and Android Studio
   (`config/ideavim/ideavimrc`) when the IDE has a matching action. In Android Studio, `:action` (or the
   IdeaVim icon in the status bar → Track Action IDs) shows the action ids.
3. Add a row to [Shared keys](#shared-keys), or to [Not shared](#not-shared) with the reason.

Keys
---
### Shared keys

`·` means the IDE's own behaviour, no mapping needed; `–` means it doesn't have it.

| Key | Does | nvim | VS Code | Android Studio | Xcode |
|---|---|---|---|---|---|
| `jj` | leave insert mode (zsh, Claude Code, readline REPLs and the fzf pickers too) | ✓ | ✓ | ✓ | – |
| `,` | leader | ✓ | ✓ | ✓ | – |
| `x` | delete a character without yanking it | ✓ | ✓ | ✓ | – |
| yank / paste | system clipboard | ✓ | ✓ | ✓ | – |
| `m` | jump anywhere on screen by label | flash | easymotion (2 chars) | AceJump | – |
| `ys` `ds` `cs`, `S` | surround | ✓ | ✓ | ✓ | – |
| `gc` / `gcc` | comment | ✓ | · | ✓ | – |
| `C-h/j/k/l` | to the split left/down/up/right | ✓ (and tmux panes) | ✓ | ✓ | – |
| `Space` | to the next split, cycling | ✓ | ✓ | ✓ | – |
| `Backspace` | back to the last split | ✓ | ✓ (the previous group) | ✓ | – |
| `;f` | find a file | ✓ | ✓ (quick open) | ✓ (go to file) | – |
| `;g` | the branch's changed files, to review | ✓ (since the default branch, committed or not) | ✓ (Source Control: uncommitted only) | ✓ (Commit window: uncommitted only) | – |
| `;r` / `;s` | grep the project / the word under the cursor | ✓ | ✓ | ✓ | – |
| `;b` | open files, most recent first | ✓ | ✓ | ✓ | – |
| `;d` / `;w` | symbols in this file / in the project | ✓ | ✓ | ✓ | – |
| `;e` | diagnostics | ✓ | ✓ (Problems) | ✓ (Problems) | – |
| `;?` | the keys, searchable | ✓ (every key with a desc) | ✓ (Keyboard Shortcuts, VS Code's own, not the vim ones) | ✓ (`:map`, the vim ones, a plain list) | – |
| `;p` | projects | – (a tmux session each: `cmd+k`) | ✓ (recent) | ✓ (recent) | – |
| `gd` / `gr` | definition / references | ✓ | · / ✓ | ✓ | – |
| `ga` | code actions / quick fix | ✓ | ✓ | ✓ | – |
| `,rn` | rename | ✓ | ✓ | ✓ | – |
| `]d` / `[d` | next / previous diagnostic | ✓ | ✓ | ✓ | – |
| `,hd` / `,hs` | hover docs / signature | ✓ | ✓ | ✓ | – |
| `,e` / `,f` | file tree / this file in it | ✓ | ✓ | ✓ | – |
| `,w` / `,q` | save / close | ✓ | ✓ | ✓ | – |
| `,bd` | close buffer | ✓ | ✓ | ✓ | – |
| `]b` / `[b` | next / previous buffer | ✓ | ✓ | ✓ | – |
| `,bb` | the previous buffer | ✓ | ✓ | – | – |
| `,sv` / `,ss` | split side by side / stacked | ✓ | ✓ | ✓ | – |
| `,z` | zoom the split, and back | ✓ | ✓ | ✓ | – |
| `,=` | make all splits equal | ✓ | ✓ | – | – |
| `,so` | outline | ✓ | ✓ | ✓ | – |
| `,sr` | search and replace in the project | ✓ | ✓ | ✓ | – |
| `,xx` | all diagnostics | ✓ | ✓ | ✓ | – |
| `,re` | reload the config | ✓ | – | ✓ | – |

### Debugging

These exist in the IDEs only: nvim has no debugger (its `,d` is free apart from `,dt` / `,do` for diff).

| Key | Does | VS Code | Android Studio |
|---|---|---|---|
| `,db` | toggle a breakpoint | ✓ | ✓ |
| `,ds` | start debugging | ✓ | ✓ |
| `,dc` | continue | ✓ | ✓ |
| `,dn` / `,di` / `,du` | step over (next) / into / out | ✓ | ✓ |
| `,dx` | stop | ✓ | ✓ |

In Android Studio, `,ar` runs the app and `,ax` stops it, like nvim's `,a` keys.

### Not shared

- **`H` `J` `K` `L`** walk the syntax tree in nvim (treewalker); the IDEs keep vim's meaning (top of screen,
  join lines, …).
- **Harpoon** (`;m`, `;j`, `;k`, `,m`), code tours (`;o`, `;l`) and review comments (`,n`, `;n`), git
  (`,g…`), terminals (`,tt`, `,tm`) and the `,a` / `,i` / `,vo` keys that open the IDEs stay in nvim.

Config
---
How each tool gets its vim keys:

- **VS Code**: the vim extension (`vscodevim.vim`, installed by `setup_vscode`), configured in
  `config/vscode/settings.json`. Keys VS Code itself wants (`cmd+…`) still work.
- **Android Studio**: IdeaVim and AceJump, installed by `setup_ideavim` (Android Studio closed), which also
  links `~/.ideavimrc`. `C-h/j/k/l` go to IdeaVim rather than the IDE's own shortcuts. After editing the
  file, `,re` reloads it.
- **Xcode**: Editor → Vim Mode. Motions, operators, text objects and `:` commands work; Xcode can't take
  mappings, so no leader, `jj` or `;` pickers.
- **zsh**: vi mode, `jj` leaves insert mode. In normal mode nvim's find keys work too: `;f` / `;a` files, `;g`
  changed files, `;r` grep, `;p` projects, `,gs` git status, `,e` yazi (see [zsh](zsh.md#vi-mode)).
- **fzf pickers** ([all of them](tmux.md#pickers)): a normal mode with `j`/`k`, `g`/`G`, `/` to filter and
  `jj` back from typing (see [tmux](tmux.md#picker-keys)).
- **Claude Code**: the prompt is in vim mode (`editorMode` in `config/claude/settings.json`), `jj` leaves
  insert mode (`vimInsertModeRemaps`). Motions, operators and text objects work; no other mappings. In
  normal mode, `j`/`k` at the first or last line go through earlier prompts, and `/` searches them.
- **tmux**: copy mode uses vi keys, `v` selects, `y` copies (see [tmux](tmux.md)); `C-h/j/k/l` cross into
  nvim.
- **AeroSpace**: `alt+h/j/k/l` move between windows (see [AeroSpace](aerospace.md)).
- **REPLs**: vi mode in everything that reads a line with GNU readline (bash, psql; `config/readline/inputrc`,
  with `jj`) or libedit (sqlite3, lldb, python; `config/readline/editrc`, Esc only: libedit can't wait for
  the second `j`, so a `j` before any other letter would be lost). Python runs its basic REPL
  (`PYTHON_BASIC_REPL=1`, `zsh/.exports`).
- **atuin** (`atuin search -i`; `C-r` is a picker): `keymap_mode = "auto"` in `config/atuin/config.toml`,
  vi keys starting in the mode the shell is in.
- **glow** (`mdv`): its pager is `less` (`PAGER` in `zsh/.exports`), so `j`/`k`, `/` and `q`.
- **btop**: `vim_keys` in `config/btop/btop.conf`: `h/j/k/l`, `g`/`G` move in lists; help and kill move to
  `H` and `K`.
- **fugitive** (`gs`, `,gs`): its status, blame and log are nvim buffers, so all of vim's keys; its own (`s`,
  `u`, `cc`, …) are listed by `g?`.
- **yazi, less, man**: `j`/`k`, `/` to search, out of the box.

To look out for
---
- Claude Code's `/config` → Editor mode turns vim mode off, but writes through the link into the repo, so for
  every Mac.
- In REPLs that use libedit, `jj` doesn't leave insert mode: libedit can't wait for the second `j`.
- node's REPL has no vi mode.

Decisions
---
- **Python's basic REPL**: from 3.13 on, Python's own REPL ignores `~/.editrc`; the basic one has vi keys, but
  no colours or multi-line editing.
