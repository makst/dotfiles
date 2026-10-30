Neovim
===

Neovim from Homebrew, configured in Lua, with LSP, treesitter, telescope and a set of plugins for moving
around quickly. `vim` runs nvim everywhere (a link in `~/bin`), including as git's editor.

Config: `config/nvim/` (linked to `~/.config/nvim`). Reload most of it in place with `,re`; plugin changes
need a restart.

Layout of the config
---
- `init.lua` loads everything in order: options, keymaps, then one module per plugin.
- `lua/user/base.lua` options, `lua/user/keymaps.lua` general keys, `lua/user/plugins.lua` the plugin list.
- `lua/user/<plugin>/` per plugin: `config.lua` (setup) and `keymaps.lua`. To find where a key is defined,
  look in the `keymaps.lua` of the plugin it belongs to.
- `lua/user/hidden/init.lua` is gitignored and loaded if present, for private settings.

**Adding a plugin:** add it to `plugins.lua`, create `lua/user/<name>/` with its config and keymaps,
require it from `init.lua`, restart nvim, then commit the updated `lazy-lock.json`.

Plugins
---
[lazy.nvim](https://github.com/folke/lazy.nvim) installs itself on first start. The exact version of every
plugin is pinned in `lazy-lock.json`, which is committed:

- `:Lazy restore` installs exactly the pinned versions (`setup_dotfiles` does this).
- `:Lazy update` updates everything and rewrites the lock file. Try things out, then commit the lock file,
  or `git checkout lazy-lock.json` and `:Lazy restore` to go back.
- `:Lazy` shows the status of every plugin.

Behaviour worth knowing
---
- **System clipboard**: every yank and delete goes to the macOS clipboard, `p` pastes from it.
- **Files reload when changed on disk** as soon as you come back to nvim, its tmux pane or the buffer.
  Handy with agents and git working on the same files.
- **Format on save** when the language server can format; for JS/TS, eslint additionally fixes what it can.
- 2-space indent with spaces, no line wrapping, case-insensitive search, 10 lines of context when
  scrolling, `:s` shows a live preview of the substitution.
- Diagnostics are shown as icons in the sign column and coloured line numbers, not as text at the end of
  the line. Read them with `]d` / `[d`, `;e` or `,xx`.

Keys
---
The leader is `,`. `;` starts the pickers.

### Changed defaults

These override built-in vim keys, which is easy to forget:

| Key | Now | Built-in meaning you lose |
|---|---|---|
| `jj` (insert) | leave insert mode | |
| `x` | delete without yanking | |
| `m` | hop: jump to any visible word | set a mark (use `:mark`) |
| `H` `J` `K` `L` | treewalker: move by syntax node | screen top, **join lines**, keyword help, screen bottom |
| `Space` | next split | |
| arrow keys | resize the split | move the cursor |
| `Esc` | also clears search highlights | |
| `C-h/j/k/l` | move between splits and tmux panes | |
| `gd`, `gr` | definitions / references in Trouble | |
| `gra`, `gri`, `grn`, `grr`, `grt`, `grx` | removed, so `gr` doesn't wait for a third key | nvim's LSP defaults |

### Files, buffers, windows

| Key | Action |
|---|---|
| `,w` / `,q` | save / **quit without saving** |
| `,bn` `,bp` | next / previous buffer |
| `,bb` | alternate buffer |
| `,bd` / `,bdr` | close buffer / close all other buffers |
| `,bls` | list buffers |
| `,ss` / `,sv` | split horizontally / vertically and go to the new split |
| `,sh` `,sj` `,sk` `,sl` | go to the split left/down/up/right (same as `C-h/j/k/l`, but nvim only) |
| `,zi` / `,zo` | maximise the split / equalise all splits |
| `,dt` / `,do` | diff the visible splits / stop diffing |
| `,re` | reload the config |

### Finding things

Telescope pickers (`;` + letter):

| Key | Picker |
|---|---|
| `;f` | files, including dotfiles, respecting `.gitignore` |
| `;a` | all files, including ignored ones |
| `;g` | files tracked by git |
| `;r` | live grep |
| `;s` | grep the word under the cursor |
| `;b` | open buffers |
| `;d` / `;w` | symbols in this file / in the workspace (LSP) |
| `;e` | diagnostics |
| `;q` | quickfix list |
| `;p` | projects: switches the working directory (and nvim-tree) to the project and finds files in it |
| `;t` | help tags |
| `;;` or `;c` | reopen the last picker with its query and results (the last 100 are kept) |

In a picker: `C-s` sends the marked entries to the quickfix list and opens it, `q` closes it in normal
mode. In `;f` and `;g`, `t` in normal mode shows the file read-only in a side terminal (meant for the
offline cheatsheets in `~/cheatsheets`).

Other ways around:

| Key | Action |
|---|---|
| `m` | hop: labels every visible word, type the label to jump. Works after operators: `dm`, `ym` |
| `,m` / `;m` | harpoon: add the file to the list / open the list (reorder and delete in it) |
| `;j` / `;k` | harpoon: next / previous file in the list |
| `,e` | file tree on the right (`l` opens, `g?` shows all keys) |
| `,f` | file tree with the current file revealed |
| `,so` | outline of the symbols in the file |

The file tree follows the current file and the working directory.

### Code (LSP)

| Key | Action |
|---|---|
| `gd` | definitions (Trouble list) |
| `gr` | references (Trouble list) |
| `gc` | code actions (only where a language server runs; `gcc` and `gc` in visual mode still comment) |
| `gre` | rename |
| `,hd` | hover documentation |
| `,hs` / `C-s` in insert mode | signature help |
| `]d` / `[d` | next / previous diagnostic, with the message in a float |
| `,xx` / `,xd` | Trouble: all diagnostics / this buffer's |

### Syntax-tree navigation (treewalker)

| Key | Action |
|---|---|
| `J` / `K` | next / previous node at the same level (e.g. function to function) |
| `L` / `H` | into the first child / out to the parent |
| `,j` / `,k` | swap the node with the next / previous one |
| `,hn` | briefly highlight the node under the cursor |
| `din`, `yin`, `cin` | operate on the node under the cursor |
| `an` / `in` (visual) | grow / shrink the selection by node (built into nvim) |

All in normal and visual mode, so `vJJ` selects across nodes.

### Completion and snippets

Completion pops up from the language server, its signature help and snippets
([friendly-snippets](https://github.com/rafamadriz/friendly-snippets); TypeScript also gets the JavaScript
ones). The first match shows as grey ghost text.

| Key | Action |
|---|---|
| `Tab` / `S-Tab` | next / previous item; otherwise expand or jump in a snippet; otherwise open completion |
| `C-n` / `C-p` | next / previous item |
| `Enter` | accept |
| `C-Space` / `C-e` | open / close the menu |
| `C-h` / `C-l` | scroll the documentation window |
| `C-j` / `C-k` | next / previous snippet placeholder |

### Git

| Key | Action |
|---|---|
| `,lg` | lazygit in a floating window, one per working directory; same key hides it again |
| `,gb` | blame for the file in a side window |
| `,go` | open the file in the browser on the git host (GitHub) |

gitsigns marks added, changed and deleted lines in the sign column; its actions are available as
`:Gitsigns <Tab>` (stage hunk, preview, blame line, …), with no keys bound.

### Terminals

`,tt` and `,tm` toggle two floating shells per working directory (e.g. one for tests, one for anything
else). They keep running while hidden.

### Search and replace across files

1. Find the matches: `;r` (mark entries with `Tab`, then `C-s`), `:Ack <pattern>` (ripgrep, includes hidden
   files, case-insensitive), or `,av` on a visual selection. The matches land in the quickfix list.
2. Replace:
   - `:Acks /old/new/` substitutes in every file in the quickfix list, or
   - `:Qfreplace` opens the matching lines as one editable buffer; edit them like normal text, `:w` writes
     the changes back to their files.

### Editing helpers

- [vim-surround](https://github.com/tpope/vim-surround): `cs"'` change surrounding quotes, `ds(` delete
  parentheses, `ysiw"` surround a word.
- [vim-abolish](https://github.com/tpope/vim-abolish): `:S/child{,ren}/adult{,s}/` substitutes all case
  and plural variants; `crs` / `crc` / `crm` / `cru` coerce the word to snake / camel / Mixed / UPPER case.
- Brackets and quotes close themselves (autopairs), HTML/JSX tags too (ts-autotag).
- `.` repeats plugin actions too (vim-repeat).
- Indent guides highlight the current scope.

Languages
---
**Language servers** are installed by Mason (`:Mason` shows them): TypeScript/JavaScript (`ts_ls` and
`eslint`), Lua (`lua_ls`, aware of the nvim API), YAML (`yamlls`), Go (`gopls`). Each project's root is the
git root, so a monorepo gets one server instance rather than one per package. Helm templates get syntax
highlighting but no diagnostics, which would all be false alarms.

To add a server: add it to `ensure_installed` in `lua/user/lsp/mason-lspconfig/config.lua`, add a file for
it in `lua/user/lsp/lspconfig/` like the existing ones, and require it in that directory's `init.lua`.
Servers aren't enabled automatically, so the last step matters.

**Treesitter parsers** (highlighting, indentation, treewalker) are listed in `lua/user/treesitter.lua` and
compiled on first start with the `tree-sitter` CLI: TypeScript/TSX/JavaScript, Go (with mod/sum/work
files), Lua, Bash, JSON, YAML, TOML, Markdown, HCL/Terraform, Helm. Add a language there and restart.

Integrations
---
- **tmux**: `C-h/j/k/l` cross between nvim splits and tmux panes; true colour and undercurls work inside
  tmux; focus events trigger the reload of changed files.
- **Theme**: the colour scheme is a base16 one shared with Ghostty, switched with `change_theme`, see
  [theme](theme.md).
- **Status line** (lualine, one for all splits): mode, git branch and diff counts, path relative to the
  working directory, diagnostics, active language servers, position.
