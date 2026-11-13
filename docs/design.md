design
===

The principles every key, file, page and change here follows, and the two keyboard tables that apply them.
The README sums them up; this page is where they are defined, and where a change that can't follow one says
why.

What it is
---
Six principles, one per question: how the keys work (Learn it once), where a thing is (One search away),
where on its page (Same shape, every page), which tool does it (One tool per job), what happens when it goes
wrong (Safe to try) and what keeps a rule true (A rule has a check). One rule holds under all six.

### Exceptions say why
Something that can't follow a principle says what it does instead and why, in the place where the rule would
be looked up, so the gap is a decision and not an accident.

| Principle | Where the reason goes |
|---|---|
| Learn it once | the cell of the key table ([Same key, every layer](#same-key-every-layer)), or the tool's entry in [vim keys](vim-keys.md), as for Xcode |
| One search away | the file's top comment, or its doc |
| Same shape, every page | the page's Decisions |
| One tool per job | the page's Decisions, as VS Code has for debugging ([debugging](debugging.md#decisions)) |
| Safe to try | the page's "To look out for", next to what can't be run again or taken back |
| A rule has a check | the "Not checked" column in [A rule has a check](#a-rule-has-a-check) |

### Learn it once
The design principle behind every key here: learn a move once and it works on every layer, from a line of
text up to a macOS workspace.

1. **Vim is the grammar.** Anything that takes keys moves like vim: `h/j/k/l`, `g`/`G` for the ends,
   `ctrl+d`/`ctrl+u` for half a page, `/` to search and `n`/`N` for the next match, `v` to select and `y` to
   copy, `q` to quit. Where a tool lets you type, typing and moving are separate modes and `jj` leaves typing.
   A list is no different: the picker has a normal mode with the same keys ([picker keys](tmux.md#picker-keys)).
2. **The key names the action, the modifier names the layer.** Splits, panes, windows, sessions and workspaces
   nest, and the same key does the same thing at each level: `h/j/k/l` goes that way, `Space` to the next one,
   `0` back to the last. Each layer has its own modifier ([How the keyboard is split](#how-the-keyboard-is-split),
   [Same key, every layer](#same-key-every-layer)).
3. **nvim is the reference.** `,` starts an action and `;` opens a picker. Another tool with a leader or a
   normal mode borrows nvim's key for the same action ([vim keys](vim-keys.md)).
4. **Set it, don't hope for it.** A tool whose own keys already follow is left alone and noted as such; one
   that can follow with some config gets that config here.

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
   Two kinds of file are fixed by their tools and have none: nvim's `init.lua` in a plugin's folder holds only
   the `require` lines for its `config.lua` and `keymaps.lua` (that is how nvim loads a folder), and JSON
   files can't hold comments (their doc says who uses them).
4. **Look, don't recall.** Something you check often (sessions, windows, agents, paste buffers, the docs,
   history) opens as a list with a live preview, so you see the state and go to it in one step.

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
   repeats the shape inside it.
2. **One kind per section.** Explanation doesn't go into a key table and steps don't go into "What it is";
   a sentence that would belong elsewhere moves there and is linked.
3. **The README is the only tutorial.** "Install from scratch" and "A typical day" walk through the whole
   setup once; everything else assumes you have it.
4. **The page is the config.** A change updates its page in the same commit, and an idea not built yet stays
   out of the pages until it is, so a page says neither less nor more than what runs.

### One tool per job
The design principle behind which tool does what: every job has one tool that owns it, and the other tools
hand the job to it instead of doing it their own way.

| Job | Owner | How the other tools reach it |
|---|---|---|
| Terminals, panes and anything long-running | tmux | Ghostty's `cmd` keys become tmux commands; agents get a tmux window each (`agent`); pickers open in tmux popups, nvim's shells (`,tt`, `,tm`, Android's Gradle and logcat) in tmux panes |
| Editing text | nvim | `EDITOR`, git's `core.editor`, `git difftool` and `git mergetool`, zsh's `vv`, Claude Code's `ctrl+g`, `man` (`MANPAGER`); VS Code and Android Studio borrow its keys ([vim keys](vim-keys.md)) |
| Reading long output | `less`, for anything a renderer has coloured; nvim for man pages | git's pager (delta) and `mdv` (glow) colour their output and hand it to `less`; `man` opens in nvim (`MANPAGER`); bat only colours files in the pickers' previews ([zsh](zsh.md#decisions)) |
| Choosing from a list | fzf, through `picker` (`config/tmux/picker.zsh`) | tmux popups, zsh widgets, nvim's fzf-lua; every fzf reads `config/fzf/fzfrc` |
| Projects | a tmux session per directory, from zoxide's list | `cmd+k` in tmux, `tm` in the shell |
| Directories you visit | zoxide | `z`, the project picker (`cmd+k`, and `;p` in zsh's normal mode) |
| Shell history | atuin | `C-r` in zsh, in the picker |
| Git: staging, committing, history, reviewing | git, with fugitive in nvim on top; delta and difftastic for diffs; gh for GitHub | `gs` and `,gs` (status), `;g` and `greview` (the branch's changes), nvim's `,go` / `,gp` / `,gn` through gh; git's pager and the pickers' previews are delta |
| Copying | the macOS clipboard | nvim (`unnamedplus`), tmux (`pbcopy`, OSC 52 over ssh), fzf (`ctrl-y`), VS Code and Android Studio |
| Reading what has scrolled by | tmux's copy mode | `C-a Enter` or the mouse wheel enters it, `C-a /` (`cmd+f`) searches it; vi keys, `v` selects and `y` copies to the macOS clipboard ([tmux](tmux.md#decisions)) |
| Telling you something happened elsewhere | a macOS notification (terminal-notifier) you can click, and a mark in tmux's status line | Claude Code's hooks for agents that wait or finish, the GitHub watcher for pull requests ([github](github.md)) |
| Files to open | nvim-tree inside nvim, yazi in the shell, both on `,e` | one key, the tool depends on where you are ([neovim](neovim.md#decisions)) |
| Formatting | the formatter the project configures (prettier, ruff, stylua, shfmt, gofmt, …) | conform in nvim on save, Claude Code's format hook after its edits; neither brings a style of its own |
| Language versions | fnm for node, uv for python | `setup_node` and `setup_python`; fnm installs a project's pinned node on `cd`; Homebrew's node, which nvim's language servers run on, stays off `PATH` ([neovim](neovim.md#decisions)) |
| Containers | podman in its VM | `docker` and `docker compose` are podman ([podman](podman.md)) |
| SSH keys | Secretive | git signs and pushes through its agent ([git](git.md)) |
| Colours | the base16 theme, as the terminal's 16 ANSI colours | every tool that draws in the terminal ([theme](theme.md)) |

1. **Join before you add.** Before adding a tool, a plugin or a script, check whether the tools already here
   can do it wired together: nvim in a tmux pane rather than a terminal emulator inside nvim, git's editor set
   to nvim rather than a second editor. A new one comes in only for a job none of them does, and its Brewfile
   comment or doc names the job.
2. **One owner per job.** A tool that needs a job calls the owner (`$EDITOR`, `tmux display-popup`, `picker`)
   rather than carrying its own copy, and the copy already running where there is one. So the job looks and
   works the same wherever it starts, and its keys, its state and its fixes live in one place. Choosing from a
   list (a session, a window, an agent, a conversation, a command from history) is one picker with one look,
   and a tool with a list of its own gets its output wrapped in the picker wherever it can be; plain fzf keeps
   three keys in the shell ([fzf](fzf.md#decisions)).
3. **Meet at the seams.** Where two tools touch, crossing from one to the other takes no thought: `C-h/j/k/l`
   crosses nvim splits and tmux panes, OSC 52 carries a copy through tmux and ssh, focus events reload files in
   nvim when you come back to its pane, `fzfrc` gives nvim's pickers the shell's look.

### Safe to try
The design principle behind every command and change here: trying something costs nothing, because a step
can be run again and a change can be taken back.

1. **Run it again.** Every `setup_<tool>` leaves a Mac that is already set up as it is, so `setup_dotfiles`
   is rerun after a pull, after a failed step or when in doubt, and a step that fails doesn't stop the others
   ([setup](setup.md#what-it-is)). Homebrew is the exception: a rerun upgrades
   ([setup](setup.md#to-look-out-for)).
2. **Trash, don't delete.** Nothing here deletes for good: scripts move things to the Trash, a setup step
   moves a real file there before it links over it (`keep_real`), a hook stops Claude Code's recursive `rm`
   ([claude-code](claude-code.md#hooks)), and a Brewfile package that is dropped stays commented out at the
   bottom.
3. **Looking changes nothing.** What reports on state only reports: `check_dotfiles` and `check_mac` print
   each problem with the step that fixes it and leave the fixing to you, Claude Code reads AWS and Google
   Cloud but can't change them ([aws](aws.md), [gcloud](gcloud.md)), and `agent_done` removes a worktree only
   when nothing would be lost ([claude-code](claude-code.md#finishing-an-agent)).
4. **One step back.** A change is made on a branch (an agent's in a worktree of its own), nvim's plugins are
   pinned (`lazy-lock.json`) so an update is a commit, and swapping something familiar for something new goes in a
   commit of its own, so `git revert` brings the old one back and keeps the rest. What isn't pinned is
   listed ([setup](setup.md#to-look-out-for)).
5. **The live setup stays valid.** The config files are links into this repo, so an edit is live at once:
   each step leaves them loadable (`zsh -n`, `jq -e .`), and keys and anything interactive are tried in a tmux
   server of their own (`tmux -L probe`) before the running one gets them.

### A rule has a check
The design principle behind the rules themselves: a rule that nothing checks holds only as long as it is
remembered, so a rule here is checked by `check_dotfiles`, or is listed as not checked.

1. **The check comes with the rule.** A rule a script can test gets a check in the same commit, in the group
   of `checks/` it belongs to ([setup](setup.md#checks)), and the check's comment names the rule, so a grep
   for the rule's name finds what holds it.
2. **Fast enough to run every time.** All of `check_dotfiles` takes about a second, so it runs before every
   commit and on every push. What takes longer stays out of it and has its own moment: `checks/mutate` when a
   check looks like it lets something through, `checks/fresh_mac` after changing a setup step.
3. **Fail what breaks, warn what drifts.** A check fails the run for what breaks the setup (a file that
   doesn't parse, a step or script that can't run, a key on another layer's modifier, a link or path to
   something that isn't there), for what could lose something and for what gets published (a secret, an
   address, a commit). One that compares the docs or a convention with the config warns.
4. **Check the checks.** A check that stays green on a broken repo is worse than none: `checks/mutate` breaks
   the repo on purpose, says which check missed it and lists the checks that have no break
   ([setup](setup.md#testing-the-checks)).

What the checks hold of each principle, and what is left to reading the change. `docs/setup.md`, "Checks",
has every check.

| Principle | Checked | Not checked |
|---|---|---|
| Learn it once | each layer keeps to its modifier; Ghostty's `cmd` keys reach tmux bindings; `docs/vim-keys.md` agrees with nvim, VS Code and IdeaVim on the keys it lists and has an entry for every TUI in the Brewfile | that a tool's keys are vim's (only that it has an entry); that a new key joins its family in "Same key, every layer"; that every nvim key is in `docs/vim-keys.md` and in the other editors |
| One search away | each file starts with a comment; every picker is in `config/tmux/picker.zsh`'s list; every nvim key set with `vim.keymap.set` is in a `keymaps.lua` and has a desc; the links, paths and names in the docs exist; setup steps and symlinks agree with `docs/setup.md` | that the top comment names who uses the file; nvim keys a plugin takes as a table; that a tool's parts carry its name; that a thing is defined only once; that state has a list with a preview |
| Same shape, every page | the order of a page's sections; a heading has an empty line above it; the README links every page | one kind per section; that a page says what the config does, beyond the names it mentions; that a change and its page are one commit |
| One tool per job | no zsh file runs `fzf` or `fzf-tmux` itself | lists in nvim; a second tool for any other job in the table; the seams |
| Safe to try | the hook blocks the recursive `rm` forms in `checks/rm-hook.cases`; no code deletes recursively; every link the setup makes keeps a real file (`keep_real`); nvim's plugins are pinned; zsh, JSON, TOML, YAML, Lua, tmux, git, ssh, Ghostty, starship, fzf and AeroSpace config parses or loads in its tool | that a setup step can be run twice (`checks/fresh_mac` runs each once); that what reports changes nothing; that a replacement has its own commit; `ideavimrc`, which nothing parses; secrets in git's history |
| A rule has a check | `checks/mutate`, by hand, with the list of checks that have no break | that a new rule got a check; how long `check_dotfiles` takes; that a check's level follows item 3; that this table is complete |

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
| `Option` (Alt) | AeroSpace, globally; the few it leaves free reach the terminal, for keys inside a list (fzf: `alt-a` mark all, `ctrl-alt-n/p` scroll the preview; nvim's pickers and tmux's tree: `alt-d` delete, `alt-r` reword, `alt-p` paste into the agent, `alt-n` / `alt-g` from `;g` to `;n` and back: alt plus the picker's letter) | `alt+h` focus window left, `alt+2` workspace 2 |
| `Caps Lock` | remapped to Ctrl | |
| `,` | nvim leader, and zsh's normal mode for the same tools | `,e` file tree (zsh: yazi), `,gs` git status |
| `;` | nvim pickers (fzf-lua, harpoon), and zsh's normal mode for the same lists | `;f` files, `;r` grep, `;b` open files |
| `jj` | leave insert mode, in nvim, zsh, Claude Code, VS Code, Android Studio, readline REPLs (bash, psql) and every picker (the top of `config/tmux/picker.zsh` lists them) | |
| `C-r` / `C-t` | history (atuin's, in fzf), files, in zsh | |

### Same key, every layer
A move you know on one layer works on the others: the key stays the same and the modifier picks the layer,
from nvim splits up to AeroSpace workspaces. A new key joins one of these families where it can.

| Key | nvim splits | tmux panes | tmux windows | AeroSpace |
|---|---|---|---|---|
| `Space`: the next one, cycling | `Space` | `C-Space` | – (`cmd+space` is Spotlight; `cmd+]`; agents that need you: `cmd+shift+space`) | `alt+space` (windows on the workspace) |
| `h/j/k/l`: the one in that direction | `C-h/j/k/l` | `C-h/j/k/l` | – | `alt+h/j/k/l` (windows) |
| `[` / `]`: previous / next | – (`[` / `]` start nvim's motions) | – (`ctrl+[` is Esc) | `cmd+[` / `cmd+]` (sessions: `C-a (` / `C-a )`, no `cmd` key: too easy to mix up with windows) | `alt+[` / `alt+]` (workspaces with windows) |
| `1`…`9`: by number | a count: `3 Space` | – (`C-h/j/k/l` is enough) | `cmd+1`…`9` | `alt+1`…`9` (workspaces) |
| `0`: back to the last one | `Backspace` (`0` is start of line) | `ctrl+0` | `cmd+0` (sessions: `cmd+shift+0`) | `alt+0` (workspace) |
| `z`: zoom, and back | `,z` | `C-a z` (`cmd+shift+enter`: `cmd+z` is undo) | – | `alt+z` (fills the workspace) |
| `Shift+h/j/k/l`: resize | arrow keys (`H J K L` walk the syntax tree) | `C-a H/J/K/L` | – | `alt+shift+h/j/k/l` |
| `=`: all the same size | `,=` | `C-a =` | – | `alt+=` |
| `Shift+Ctrl+h/j/k/l`: move it that way | `C-w H/J/K/L` (nvim's own) | – (not bound; tmux's own `C-a {` / `}` swap panes) | – (not bound) | `alt+ctrl+shift+h/j/k/l` (the window, through the layout) |
| split | `,sv` / `,ss` | `cmd+d` / `cmd+shift+d` (`C-a \|` / `C-a -`) | `cmd+t` (a new window) | `alt+e` (side by side / stacked; new windows tile themselves) |
| close | `,q` (the window, without saving) | `cmd+w` (`C-a x`) | `C-a &` (tmux's own); any window or session: `d` in the tree (`cmd+j`) | – (the app closes it: `cmd+w`) |

`Space`, `Backspace` and `,z` in nvim do the same in VS Code and Android Studio, `,=` in VS Code ([vim
keys](vim-keys.md); VS Code goes to the previous editor group, as it doesn't track the last one).
A "–" cell means the layer has no such key. Where the reason isn't in the cell: tmux windows sit in a row, so
`[` / `]` and the numbers are their directions; a window is always full size (no zoom, resize or `=`); and
splitting and closing differ in letter from layer to layer (`,sv` / `cmd+d`, `,q` / `cmd+w`) because
`cmd+d` and `cmd+w` are the Mac's own keys for them, which Ghostty hands to tmux.
`C-Space` goes to tmux in every pane, nvim's too, so nvim's completion opens with `Tab` instead.
In zsh's completion list (fzf-tab), `[` / `]` go to the previous / next group of completions.
In nvim, one letter is one area: `,` plus the letter acts on it, `;` plus the letter lists it. `,m` / `;m` mark a
file / list the marked ones (harpoon), `,n` / `;n` write a review comment / list them, `,g…` / `;g` act through
git / list the branch's changed files.
`?` lists the keys, searchable: `;?` in nvim (VS Code and Android Studio too), `C-a ?` in tmux, `g?` in fugitive's
buffers, and `?` in normal mode in every picker; `ctrl+/` shows / hides a picker's preview.

Decisions
---
- **One page for the principles, not sections of the README**: the README is the overview and the tutorial;
  the principles are what every change is checked against, so they get a page of their own that `docs/`,
  `CLAUDE.md` and the checks refer to.
- **"Exceptions say why" once, not as the last item of each principle**: it was the same rule three times,
  and the docs' principle had none. Stated once, it covers every principle, new ones too.
- **The picker belongs to "One tool per job"**, not to "Learn it once" or "One search away": those two keep
  what is theirs (its keys are vim's, state opens in a list) and point to the owner.
