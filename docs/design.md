design
===

The principles every key, file and page here follows, and the two keyboard tables that apply them. The README
sums them up; this page is where they are defined, and where a change that can't follow one says why.

What it is
---
Three principles, one per question a newcomer asks: how do I move (Learn it once), where is it (One search
away), where on the page (Same shape, every page).

### Learn it once
The design principle behind every key here: learn a move once and it works on every layer, from a line of
text up to a macOS workspace.

1. **Vim is the grammar.** Anything that takes keys moves like vim: `h/j/k/l`, `g`/`G` for the ends,
   `ctrl+d`/`ctrl+u` for half a page, `/` to search and `n`/`N` for the next match, `v` to select and `y` to
   copy, `q` to quit. Where a tool lets you type, typing and moving are separate modes and `jj` leaves typing.
2. **The key names the action, the modifier names the layer.** Splits, panes, windows, sessions and workspaces
   nest, and the same key does the same thing at each level: `h/j/k/l` goes that way, `Space` to the next one,
   `0` back to the last. nvim has no modifier or `ctrl`, tmux `ctrl`, `C-a` or `cmd`, AeroSpace `alt`
   ([Same key, every layer](#same-key-every-layer)).
3. **nvim is the reference.** `,` starts an action and `;` opens a picker. Another tool with a leader or a
   normal mode borrows nvim's key for the same action ([vim keys](vim-keys.md)).
4. **Set it, don't hope for it.** A tool whose own keys already follow is left alone and noted as such; one
   that can follow with some config gets that config here; one that can't (Xcode) is written down as an
   exception.
5. **One picker.** Choosing from a list (a session, a window, an agent, a conversation, a command from
   history) happens in the same fzf picker, `config/tmux/picker.zsh`: the same look, the same normal mode
   with `j`/`k` and `/`, `jj` back from typing. A tool with a list of its own gets its output wrapped in the
   picker rather than learnt on its own, wherever it can be ([picker keys](tmux.md#picker-keys)).
6. **Exceptions say why.** When a key can't follow, because macOS, another layer or the tool itself has it,
   the table shows what is used instead and why, so the gap is a decision and not an accident.

### One search away
The design principle behind how files and lists are laid out: anything here is found with one search in a
picker, not by remembering where it is, and anything running is looked at in a list, not recalled as a command.

1. **The file name says the kind, the folder says the tool.** Things of one kind have the same name
   everywhere: each nvim plugin is `lua/user/<plugin>/` with a `config.lua` and a `keymaps.lua`; each tool has
   `config/<tool>/`, `docs/<tool>.md` and `setup_<tool>`. Search for the kind (`;f keymaps`, `setup_<Tab>`)
   and you get all of them; search for the tool (`;f tmux`) and you get every part of it.
2. **One place per thing.** A key, a setting or a setup step is defined once, in the file its name points to.
   Everywhere else refers to it by file and section (`docs/design.md`, "Same key, every layer"), so one grep
   finds the definition and everything that relies on it.
3. **Files say who uses them.** The comment at the top of a file says what links it, loads it or calls it
   (`config/tmux/picker.zsh` lists every picker built on it), so a thing can be followed in both directions.
4. **Look, don't recall.** Something you check often (sessions, windows, agents, paste buffers, the docs,
   history) opens in the picker with a live preview, so you see the state and go to it in one step.
5. **Exceptions say why.** A file that holds several kinds, or a list without a picker, says why in its top
   comment or its doc.

### Same shape, every page
The design principle behind the docs: every `docs/<tool>.md` has the same sections in the same order, so you
know where to look before you open the page. The sections follow [Diátaxis](https://diataxis.fr), which sorts
writing by what the reader is doing (understanding, doing a task, looking something up), but they stay on one
page per tool instead of four folders, so a tool is still one search away.

| Section | Kind | What goes in it |
|---|---|---|
| What it is | explanation | the model and why it is set up this way: what loads what, what nests in what |
| Once per Mac / Once per project | how-to | steps to run, in order, each one a command or a click |
| A heading per task | how-to | named for the task ("Switching schemes"), short steps, no background |
| Keys | reference | the key table, nothing but rows; a line above it may say which layer it is |
| Commands | reference | the same for commands, aliases and functions you type |
| Config | reference | which files, where they link, what each setting changes |
| To look out for | how-to | gotchas and their fixes, one bullet each |
| Decisions | explanation | "X, not Y, because …": what was tried or dropped, so it isn't tried again |

1. **Leave out, don't reorder.** A page skips the sections it doesn't need; the ones it has come in this
   order. A page that covers several areas (mobile: iOS, Android) gives each area a top-level section and
   repeats the shape inside it. `check_dotfiles` checks the order.
2. **One kind per section.** Explanation doesn't go into a key table and steps don't go into "What it is";
   a sentence that would belong elsewhere moves there and is linked.
3. **The README is the only tutorial.** "Install from scratch" and "A typical day" walk through the whole
   setup once; everything else assumes you have it.
4. **Docs describe what exists.** An idea not built yet stays out of the pages until it is.

Keys
---
The two tables that put "Learn it once" on the keyboard: which layer owns which modifier, and which keys mean
the same on every layer.

### How the keyboard is split
Every tool owns its own modifier, so the layers don't fight over keys:

| Keys | Owner | Examples |
|---|---|---|
| `Cmd` | Ghostty, translated into tmux commands | `cmd+t` new window, `cmd+d` split, `cmd+k` session picker |
| `C-a` | tmux prefix | `C-a f` session picker, `C-a w` session tree, `C-a z` zoom |
| `C-h/j/k/l` | tmux panes *and* nvim splits, seamlessly | |
| `Option` (Alt) | AeroSpace, globally | `alt+h` focus window left, `alt+2` workspace 2 |
| `Caps Lock` | remapped to Ctrl | |
| `,` | nvim leader, and zsh's normal mode for the same tools | `,e` file tree (zsh: yazi), `,lg` lazygit |
| `;` | nvim pickers (fzf-lua, harpoon), and zsh's normal mode for the same lists | `;f` files, `;r` grep, `;p` projects |
| `jj` | leave insert mode, in nvim, zsh, Claude Code, VS Code, Android Studio and the fzf pickers (`cmd+k`, `cmd+j`, `cmd+shift+j`, `C-r`, `agent_resume`, nvim's and zsh's `;` pickers, `gsw`, `gfix`, the kubectl ones) | |
| `C-r` / `C-t` | history (atuin's, in fzf), files, in zsh | |

### Same key, every layer
A move you know on one layer works on the others: the key stays the same and the modifier picks the layer,
from nvim splits up to AeroSpace workspaces. A new key joins one of these families where it can.

| Key | nvim splits | tmux panes | tmux windows | AeroSpace |
|---|---|---|---|---|
| `Space`: the next one, cycling | `Space` | `C-Space` | – (`cmd+space` is Spotlight; `cmd+]`; agents that need you: `cmd+shift+space`) | `alt+space` (windows on the workspace) |
| `h/j/k/l`: the one in that direction | `C-h/j/k/l` | `C-h/j/k/l` | – | `alt+h/j/k/l` (windows) |
| `[` / `]`: previous / next | – (`[` / `]` start nvim's motions) | – (`ctrl+[` is Esc) | `cmd+[` / `cmd+]` (sessions: none, too easy to mix up with windows) | `alt+[` / `alt+]` (workspaces with windows) |
| `1`…`9`: by number | a count: `3 Space` | – (`C-h/j/k/l` is enough) | `cmd+1`…`9` | `alt+1`…`9` (workspaces) |
| `0`: back to the last one | `Backspace` (`0` is start of line) | `ctrl+0` | `cmd+0` (sessions: `cmd+shift+0`) | `alt+0` (workspace) |
| `z`: zoom, and back | `,z` | `C-a z` (`cmd+shift+enter`: `cmd+z` is undo) | – | `alt+z` (fills the workspace) |
| `Shift+h/j/k/l`: resize | arrow keys (`H J K L` walk the syntax tree) | `C-a H/J/K/L` | – | `alt+shift+h/j/k/l` |
| `=`: all the same size | `,=` | `C-a =` | – | `alt+=` |

`Space`, `Backspace` and `,z` in nvim do the same in VS Code and Android Studio, `,=` in VS Code ([vim
keys](vim-keys.md); VS Code goes to the previous editor group, as it doesn't track the last one).
`C-Space` goes to tmux in every pane, nvim's too, so nvim's completion opens with `Tab` instead.
In zsh's completion list (fzf-tab), `[` / `]` go to the previous / next group of completions.
`?` lists the keys, searchable: `;?` in nvim (VS Code and Android Studio too), `C-a ?` in tmux, `?` in lazygit,
and `?` in normal mode in every picker; `ctrl+/` shows / hides a picker's preview.

Decisions
---
- **One page for the principles, not sections of the README**: the README is the overview and the tutorial;
  the principles are what every change is checked against, so they get a page of their own that `docs/`,
  `CLAUDE.md` and the checks refer to.
