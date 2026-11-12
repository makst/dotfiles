fzf and friends
===

fzf is the fuzzy finder behind most "pick something" moments in the shell: files, directories,
completions, tmux sessions, colour schemes. A few small tools feed it or show its previews.

What it is
---
| Tool | Role |
|---|---|
| [fzf](https://github.com/junegunn/fzf) | the finder |
| [fd](https://github.com/sharkdp/fd) | lists files and directories for fzf: fast, respects `.gitignore`, includes dotfiles |
| [bat](https://github.com/sharkdp/bat) | file previews with syntax highlighting |
| [eza](https://github.com/eza-community/eza) | directory previews as a tree |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | content search (`fif`, `;r`, nvim) |
| [glow](https://github.com/charmbracelet/glow) | renders markdown in the terminal for `mdv` |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | zsh's `Tab` completion menu replaced by fzf |

- **One look everywhere**: every fzf, in the shell, in tmux popups and in nvim (fzf-lua,
  [neovim](neovim.md#finding-things)), reads the same `config/fzf/fzfrc`. fzf takes 60 % of the screen below
  the command line instead of going full screen, with its prompt and best matches at the top. The prompt, the
  list and the preview each sit in a rounded box of their own, all the same width; a picker's header (its line
  of keys) sits at the top of the list's box, above a line. A bar marks the current line only. Previews show
  files with bat and directories as an eza tree. Colours are ANSI ones and follow the [theme](theme.md).
- **Search syntax** worth remembering: `'exact`, `^prefix`, `suffix$`, `!exclude`, and `a | b` for either.

Completing with Tab (fzf-tab)
---
Every `Tab` completion opens in fzf instead of zsh's menu, looking like every other fzf: type to filter,
`Enter` to accept.

- Completions are grouped (commands, aliases, files, …); `[` and `]` switch to the previous / next group.
- `cd <Tab>` previews each directory's contents.
- Files are coloured like `ls`.
- `git checkout <Tab>` keeps git's own order (recent branches first) instead of sorting.

Reading Markdown (mdv)
---
- `mdv [dir]` picks a markdown file under `dir` (default: the current directory) in the picker and opens it
  rendered in glow's pager. The picker opens in normal mode: `j`/`k` go through the files while the preview
  below shows each one rendered, wrapped to the pane's width; `/` filters, `jj` goes back
  ([picker keys](tmux.md#picker-keys)). Only one file can be picked, and `q` leaves the pager.
- `mdv <file>` skips the list and opens that file.
- `mds [dir]` shows the same files in the browser instead: a local site with the folders as a sidebar,
  search, and a reload whenever a file is saved (MkDocs with the Material theme, through `uvx`, on
  `127.0.0.1:8000`, or `MDS_PORT`). Nothing is installed or written into the folder, and nothing leaves the
  Mac; a folder with its own `mkdocs.yml` is served with that. `C-c` stops it.

glow renders headings blue, inline code red, links cyan, quotes grey, following the [theme](theme.md).

Finding in files
---
`fif [text]` (`;r` in normal mode) greps the project with rg as you type, starting from the text; the
preview shows the match in its file, and Enter opens it in nvim at that line. In nvim it's the same key,
`;r` (live grep), see [neovim](neovim.md#finding-things).

Keys
---
### Shell keys

<details>
<summary><b>Show GIF</b></summary>

`C-t` puts a picked file on the command line, `**<Tab>` completes a directory.

![C-t puts a picked file on the command line, **<Tab> completes a directory](img/fzf.gif)

</details>

| Key | Action |
|---|---|
| `C-r` | search [atuin's history](zsh.md#searching-history), put the chosen command on the command line |
| `C-t` | pick files (several with `Tab`) and insert their paths |
| `Alt+C` | `cd` into a subdirectory |
| `**<Tab>` | fzf completion after a command, e.g. `vim **<Tab>`, `cd **<Tab>`, `kill **<Tab>` |
| `;f` / `;a`, `;g`, `;r`, `;p` | in normal mode: nvim's pickers in the shell, files, the branch's changes, grep, projects ([zsh](zsh.md#vi-mode)) |

### Inside any fzf list

| Key | Action |
|---|---|
| `Tab` / `Shift+Tab` | mark / unmark (not in the pickers, `cmd+k`, `cmd+j`, `cmd+shift+j`, `cmd+g`, `C-a P`, `C-r`, `agent_resume`, `mdv`, `zi`, `change_theme`: they take one line) |
| `Alt+a` | mark all (`C-a` is the tmux prefix) |
| `C-/` | show / hide the preview (hidden by default, shown from the start in the pickers); `?` is a character to type, in the pickers' normal mode it lists the keys |
| `C-Alt+n` / `C-Alt+p` | scroll the preview half a page |
| `C-y` | copy the marked entries to the clipboard |
| `C-n` / `C-p`, `C-j` / `C-k` or arrows | move, while typing too (`C-n` / `C-p` as in nvim's completion) |

Config
---
| File | Contains |
|---|---|
| `.fzf.zsh` (linked to `~/.fzf.zsh`) | the shell's fzf keys and widgets, `FZF_DEFAULT_OPTS_FILE` for the shell |
| `config/fzf/fzfrc` | the look and keys of every fzf; read each time fzf opens, through `FZF_DEFAULT_OPTS_FILE`, set by `.fzf.zsh` for the shell and by `tmux.conf` for the pickers in tmux popups |
| `config/glow/ansi.json` | glow's style for `mdv`, in the terminal's 16 colours |

To look out for
---
- `.fzf.zsh` is loaded by zsh after `bindkey -v`, which would otherwise reset its key bindings.
- `C-t`, `Alt+C` and fzf-tab are plain fzf, not the [picker](tmux.md#picker-keys): no normal mode, so `jj` and
  `j`/`k` don't work there (type to filter, the arrow keys move); why is in [Decisions](#decisions).
- In `mdv`, code blocks are plain: glow's highlighter only takes fixed colours.

Decisions
---
- **`C-n` / `C-p` move through the list, not the preview**: they are next / previous in nvim's completion and
  command line and in zsh's menu, so they mean the same in a picker, while typing too. The preview scrolls only
  half a page at a time (`C-Alt+n` / `C-Alt+p`), which is enough for a glance.
- **fzf's options in a file, not in the environment**: an edit to `fzfrc` shows in the next fzf, without a new
  shell or restarting tmux. The tmux server keeps the environment it started with, and the options used to
  live there.
- **`C-t`, `Alt+C` and fzf-tab stay plain fzf, not the picker**: `C-t` and `Alt+C` pick several paths with
  `Tab` and put them on the command line, and fzf-tab completes inside it, which the picker (one line, its own
  window) can't do. Every other list goes through the picker (`docs/design.md`, "One tool per job").
- **glow's own style in 16 colours**, so `mdv` follows the theme like everything else.
