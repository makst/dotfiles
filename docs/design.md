design
===

The principles every key, file and page here follows, and the two keyboard tables that apply them. The README
sums them up; this page is where they are defined, and where a change that can't follow one says why.

What it is
---
Four principles, one per question a newcomer asks: how do I move (Learn it once), where is it (One search
away), where on the page (Same shape, every page), which tool does it (One tool per job).

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
   picker rather than learnt on its own, wherever it can be ([picker keys](tmux.md#picker-keys)). Plain fzf
   is the exception: `C-t` and `Alt+C` pick several paths with `Tab` and put them on the command line, and
   fzf-tab completes inside it, which the picker (one line, its own window) can't do; they have no normal
   mode, so there `jj` and `j`/`k` don't apply ([fzf](fzf.md#shell-keys)).
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
   comment or its doc. Two are fixed by their tools and need no comment: nvim's `init.lua` in a plugin's folder
   holds only the `require` lines for its `config.lua` and `keymaps.lua` (that is how nvim loads a folder), and
   JSON files can't hold comments (their doc says who uses them). `check_dotfiles` warns about any other file
   without a top comment.

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

### One tool per job
The design principle behind which tool does what: every job has one tool that owns it, and the other tools
hand the job to it instead of doing it their own way. Before adding a tool, a plugin or a script, check whether
the tools already here can do it together.

| Job | Owner | How the other tools reach it |
|---|---|---|
| Terminals, panes and anything long-running | tmux | Ghostty's `cmd` keys become tmux commands; agents get a tmux window each (`agent`); pickers and nvim's lazygit (`,lg`) open in tmux popups, nvim's shells (`,tt`, `,tm`) in tmux panes |
| Editing text | nvim | `EDITOR`, git's `core.editor`, `git difftool` and `git mergetool`, zsh's `vv`, Claude Code's `ctrl+g`; VS Code and Android Studio borrow its keys ([vim keys](vim-keys.md)) |
| Choosing from a list | fzf, through `picker` (`config/tmux/picker.zsh`) | tmux popups, zsh widgets, nvim's fzf-lua; every fzf reads `config/fzf/fzfrc` |
| Projects | a tmux session per directory, from zoxide's list | `cmd+k` in tmux, `tm` in the shell |
| Directories you visit | zoxide | `z`, the project pickers (`cmd+k`, `;p`) |
| Shell history | atuin | `C-r` in zsh, in the picker |
| Git: staging, committing, history | git, with lazygit on top; delta and difftastic for diffs | `lg` and `,lg`; git's pager is delta |
| Copying | the macOS clipboard | nvim (`unnamedplus`), tmux (`pbcopy`, OSC 52 over ssh), fzf (`ctrl-y`), VS Code and Android Studio |
| Colours | the base16 theme, as the terminal's 16 ANSI colours | every tool that draws in the terminal ([theme](theme.md)) |

1. **Join before you add.** If the tools already here can do it wired together, that is the way: nvim in a
   tmux pane rather than a terminal emulator inside nvim, git's editor set to nvim rather than a second editor.
   A new tool or plugin comes in only for a job none of them does, and its Brewfile comment or doc names the job.
2. **One owner per job.** A tool that needs a job calls the owner (`$EDITOR`, `tmux display-popup`, `picker`)
   rather than carrying its own copy, and the copy already running where there is one. So the job looks and
   works the same wherever it starts, and its keys, its state and its fixes live in one place.
3. **Meet at the seams.** Where two tools touch, crossing from one to the other takes no thought: `C-h/j/k/l`
   crosses nvim splits and tmux panes, OSC 52 carries a copy through tmux and ssh, focus events reload files in
   nvim when you come back to its pane, `fzfrc` gives nvim's pickers the shell's look.
4. **Exceptions say why.** A tool that keeps its own copy of a job, because the owner can't do it from there,
   says why in its page's Decisions, as VS Code does for debugging ([debugging](debugging.md#decisions)).

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
| `Shift+Ctrl+h/j/k/l`: move it that way | `C-w H/J/K/L` (nvim's own) | – (not bound; tmux's own `C-a {` / `}` swap panes) | – (not bound) | `alt+ctrl+shift+h/j/k/l` (the window, through the layout) |
| split | `,sv` / `,ss` | `cmd+d` / `cmd+shift+d` (`C-a \|` / `C-a -`) | `cmd+t` (a new window) | – (windows tile themselves) |
| close | `,q` (the window, without saving) | `cmd+w` (`C-a x`) | `C-a &` (tmux's own) | – (the app closes it: `cmd+w`) |

`Space`, `Backspace` and `,z` in nvim do the same in VS Code and Android Studio, `,=` in VS Code ([vim
keys](vim-keys.md); VS Code goes to the previous editor group, as it doesn't track the last one).
A "–" cell means the layer has no such key. Where the reason isn't in the cell: tmux windows sit in a row, so
`[` / `]` and the numbers are their directions; a window is always full size (no zoom, resize or `=`); and
splitting and closing differ in letter from layer to layer (`,sv` / `cmd+d`, `,q` / `cmd+w`) because
`cmd+d` and `cmd+w` are the Mac's own keys for them, which Ghostty hands to tmux.
`C-Space` goes to tmux in every pane, nvim's too, so nvim's completion opens with `Tab` instead.
In zsh's completion list (fzf-tab), `[` / `]` go to the previous / next group of completions.
`?` lists the keys, searchable: `;?` in nvim (VS Code and Android Studio too), `C-a ?` in tmux, `?` in lazygit,
and `?` in normal mode in every picker; `ctrl+/` shows / hides a picker's preview.

Decisions
---
- **One page for the principles, not sections of the README**: the README is the overview and the tutorial;
  the principles are what every change is checked against, so they get a page of their own that `docs/`,
  `CLAUDE.md` and the checks refer to.
