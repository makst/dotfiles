dotfiles
===

A keyboard-driven macOS development setup for Apple silicon. Ghostty opens straight into tmux, tmux holds
the shells, nvim sessions and Claude Code agents, and one base16 colour scheme is shared by all of them.

<details>
<summary><b>Show GIF</b></summary>

A quick tour: `cmd+k` opens a project as a session, `git diff` through delta, `;f` finds a file in nvim,
`cmd+d` puts a shell next to it, `C-h` and `C-l` cross between them, `cmd+w` closes the nvim pane, `lg` opens
lazygit, `cmd+j` shows every session.

![A quick tour: cmd+k opens a project as a session, git diff through delta, ;f finds a file in nvim, cmd+d puts a shell next to it, C-h and C-l cross between them, cmd+w closes the nvim pane, lg opens lazygit, cmd+j shows every session](docs/img/tour.gif)

</details>

| Layer | Tool | Docs |
|---|---|---|
| Install and update | Homebrew (`Brewfile`), `setup_dotfiles`, `check_dotfiles` (also CI), `check_mac` | [setup](docs/setup.md) |
| Terminal | Ghostty | [ghostty](docs/ghostty.md) |
| Sessions, windows, panes | tmux + session picker | [tmux](docs/tmux.md) |
| Shell | zsh (no framework, vi mode), starship, atuin, zoxide, fnm, uv | [zsh](docs/zsh.md) |
| Fuzzy finding | fzf, fzf-tab, fd, bat, eza | [fzf](docs/fzf.md) |
| Editor | Neovim (lazy.nvim, LSP, treesitter, fzf-lua) | [neovim](docs/neovim.md) |
| Version control | git, delta, difftastic, lazygit, gh, Secretive (SSH keys) | [git](docs/git.md) |
| AI agents | Claude Code in tmux windows and git worktrees | [claude-code](docs/claude-code.md) |
| iOS and Android apps | nvim (sourcekit-lsp, xcodebuild.nvim; kotlin-lsp, Gradle) next to Xcode and Android Studio | [mobile](docs/mobile.md) |
| Vim keys everywhere | nvim's keys in VS Code (vim extension) and Android Studio (IdeaVim) | [vim-keys](docs/vim-keys.md) |
| Google Cloud | gcloud, bq, gsutil on work Macs; Claude Code reads, can't change | [gcloud](docs/gcloud.md) |
| Debugging | VS Code next to nvim (`,vo`), for backends and the web | [debugging](docs/debugging.md) |
| Colours | base16 scheme for nvim, Ghostty and everything else | [theme](docs/theme.md) |
| Window manager | AeroSpace (tiling, workspaces, SIP stays on) | [window-management](docs/window-management.md) |
| GIFs in these docs | VHS tapes, rendered by `make_gifs` | [gifs](docs/gifs.md) |

Install from scratch
---
**Fork this repo first** and change at least the git identity in `config/git/.gitconfig`: it is set up for
one person.

```sh
git clone <your fork> ~/repos/dotfiles && cd ~/repos/dotfiles
./prepare-zsh-install.sh   # Homebrew, zsh, links ~/.zshrc, makes zsh the login shell
exec zsh
setup_dotfiles             # asks the Mac's name and kind once, then everything; rerun after `git pull`
```

Then follow [A new Mac](docs/setup.md#a-new-mac): Accessibility access, the SSH keys in Secretive and what
only this Mac needs. [docs/setup.md](docs/setup.md) also lists what each step does and every symlink.

Learn it once
---
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
   normal mode borrows nvim's key for the same action ([vim keys](docs/vim-keys.md)).
4. **Set it, don't hope for it.** A tool whose own keys already follow is left alone and noted as such; one
   that can follow with some config gets that config here; one that can't (Xcode) is written down as an
   exception.
5. **One picker.** Choosing from a list (a session, a window, an agent, a conversation, a command from
   history) happens in the same fzf picker, `config/tmux/picker.zsh`: the same look, the same normal mode
   with `j`/`k` and `/`, `jj` back from typing. A tool with a list of its own gets its output wrapped in the
   picker rather than learnt on its own, wherever it can be ([picker keys](docs/tmux.md#picker-keys)).
6. **Exceptions say why.** When a key can't follow, because macOS, another layer or the tool itself has it,
   the table shows what is used instead and why, so the gap is a decision and not an accident.

One search away
---
The design principle behind how files and lists are laid out: anything here is found with one search in a
picker, not by remembering where it is, and anything running is looked at in a list, not recalled as a command.

1. **The file name says the kind, the folder says the tool.** Things of one kind have the same name
   everywhere: each nvim plugin is `lua/user/<plugin>/` with a `config.lua` and a `keymaps.lua`; each tool has
   `config/<tool>/`, `docs/<tool>.md` and `setup_<tool>`. Search for the kind (`;f keymaps`, `setup_<Tab>`)
   and you get all of them; search for the tool (`;f tmux`) and you get every part of it.
2. **One place per thing.** A key, a setting or a setup step is defined once, in the file its name points to.
   Everywhere else refers to it by file and section (README, "Same key, every layer"), so one grep finds the
   definition and everything that relies on it.
3. **Files say who uses them.** The comment at the top of a file says what links it, loads it or calls it
   (`config/tmux/picker.zsh` lists every picker built on it), so a thing can be followed in both directions.
4. **Look, don't recall.** Something you check often (sessions, windows, agents, paste buffers, the docs,
   history) opens in the picker with a live preview, so you see the state and go to it in one step.
5. **Exceptions say why.** A file that holds several kinds, or a list without a picker, says why in its top
   comment or its doc.

Same shape, every page
---
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
| Config | reference | which files, where they link, what each setting changes |
| To look out for | how-to | gotchas and their fixes, one bullet each |
| Decisions | explanation | "X, not Y, because …": what was tried or dropped, so it isn't tried again |

1. **Leave out, don't reorder.** A page skips the sections it doesn't need; the ones it has come in this
   order. A big page (neovim) repeats the task, Keys and Config sections per area, in the same order.
2. **One kind per section.** Explanation doesn't go into a key table and steps don't go into "What it is";
   a sentence that would belong elsewhere moves there and is linked.
3. **The README is the only tutorial.** "Install from scratch" and "A typical day" walk through the whole
   setup once; everything else assumes you have it.
4. **Exceptions say why.** A page that can't follow the shape (`docs/vim-keys.md` is a single cross-tool
   table) says so in its first paragraph.

How the keyboard is split
---
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

Same key, every layer
---
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
keys](docs/vim-keys.md); VS Code goes to the previous editor group, as it doesn't track the last one).
`C-Space` goes to tmux in every pane, nvim's too, so nvim's completion opens with `Tab` instead.
In zsh's completion list (fzf-tab), `[` / `]` go to the previous / next group of completions.
`?` lists the keys, searchable: `;?` in nvim (VS Code and Android Studio too), `C-a ?` in tmux, `?` in lazygit,
and `?` in normal mode in every picker; `ctrl+/` shows / hides a picker's preview.

Switching sessions and windows
---
| Key | Action |
|---|---|
| `cmd+j` | every session and window as tmux's tree, in fzf with a live preview; `j`/`k` move, `/` filters, `Enter` switches |
| `cmd+shift+j` | only the Claude Code agents, most urgent first: their state, what each works on, a live preview of its screen |
| `cmd+shift+space` | the next agent that needs you, in any session: waiting ones first, then done ones; again for the one after |
| `cmd+k` | fuzzy-find a running session or a project directory, which becomes a session (`tm` outside tmux) |
| `cmd+[` / `cmd+]`, `cmd+1`…`9` | previous / next window, window by number |
| `cmd+0` / `cmd+shift+0` | back to the last window / session |
| `cmd+r` / `cmd+shift+r` | rename the window / session |

More in [tmux](docs/tmux.md#keys).

A typical day
---
1. Open Ghostty: you land in the tmux session `main`, exactly as you left it, even after a reboot.
2. `cmd+k`, type part of a project name: a tmux session for that directory opens (or is reused).
3. `vim .` in one window, `cmd+d` for a shell next to it, `C-h`/`C-l` to move between them.
4. `agent fix-login "the login form rejects valid emails"` starts Claude Code in its own worktree and
   window; its state shows on the window, the session and the status bar: waiting for you, done, working.

Repository layout
---
```
Brewfile                  every package and app, commented by purpose
prepare-zsh-install.sh    first-run bootstrap (bash, before zsh exists)
.zshrc                    sources zsh/*; everything else is linked from config/
zsh/                      shell config, aliases, functions/<tool>.zsh (setup_dotfiles is in setup.zsh)
config/atuin/             shell history search
config/btop/              btop: vim keys, the terminal's colours
config/readline/          vi mode in REPLs (inputrc for GNU readline, editrc for libedit)
.fzf.zsh                  fzf and fzf-tab configuration
config/ghostty/           Ghostty config and the generated base16 theme
config/tmux/              tmux.conf and the pickers (sessions, windows, agents, paste buffers)
config/nvim/              Neovim: one directory per plugin under lua/user/
config/starship.toml      prompt
config/git/.gitconfig     git
config/ssh/config         ssh: Secretive agent, which key for which host
config/aerospace/         window manager
config/vscode/            VS Code, the debugger: settings (with nvim's keys) and the extensions to install
config/ideavim/           nvim's keys in Android Studio (IdeaVim)
config/claude/            Claude Code: settings, global CLAUDE.md, hooks, status line
config/machine/           templates for this Mac's own files in ~/.config/dotfiles
docs/                     this documentation; tapes/ and img/ are the GIFs in it
checks/                   check_dotfiles: the checks run before a commit and on CI; mutate tests them;
                          fresh_mac rehearses a new Mac
CLAUDE.md                 instructions for Claude Code working on this repo
```

The same repo serves any number of Macs, e.g. one for home and one for work. What only one Mac needs (work email,
work plugins for Claude Code, extra packages, shell settings) lives outside the repo in `~/.config/dotfiles`,
see [setup](docs/setup.md#several-macs). Secrets go in files that are gitignored and loaded when
present: `zsh/.private` (shell, e.g. tokens) and `config/nvim/lua/user/hidden/init.lua` (nvim).
