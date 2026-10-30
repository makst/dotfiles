fzf and friends
===

fzf is the fuzzy finder behind most "pick something" moments in the shell: files, directories,
completions, tmux sessions, colour schemes, cheatsheets. A few small tools feed it or show its previews.

| Tool | Role |
|---|---|
| [fzf](https://github.com/junegunn/fzf) | the finder |
| [fd](https://github.com/sharkdp/fd) | lists files and directories for fzf: fast, respects `.gitignore`, includes dotfiles |
| [bat](https://github.com/sharkdp/bat) | file previews with syntax highlighting |
| [eza](https://github.com/eza-community/eza) | directory previews as a tree |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | content search (`fif`, nvim) |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | zsh's `Tab` completion menu replaced by fzf |
| [navi](https://github.com/denisidoro/navi) | interactive cheatsheets |

Config: `.fzf.zsh` (linked to `~/.fzf.zsh`), loaded by zsh after `bindkey -v`, which would otherwise reset its key bindings.

Shell keys
---
| Key | Action |
|---|---|
| `C-r` | search history with [atuin](zsh.md#history), put the chosen command on the command line |
| `C-t` | pick files (several with `Tab`) and insert their paths |
| `Alt+C` (also `Option+C` → `ç`) | `cd` into a subdirectory |
| `**<Tab>` | fzf completion after a command, e.g. `vim **<Tab>`, `cd **<Tab>`, `kill **<Tab>` |
| `C-g` | navi cheatsheets |

Inside any fzf list
---
| Key | Action |
|---|---|
| `Tab` / `Shift+Tab` | mark / unmark (multi-select is on everywhere) |
| `C-a` | mark all |
| `?` | show / hide the preview (hidden by default) |
| `C-n` / `C-p` | scroll the preview a line; `C-Alt+n` / `C-Alt+p` half a page |
| `C-y` | copy the marked entries to the clipboard |
| `C-j` / `C-k` or arrows | move |

fzf takes 60 % of the screen below the command line instead of going full screen, with its prompt and best
matches at the top.
Previews show files with bat and directories as an eza tree. Colours are ANSI ones and follow the
[theme](theme.md).

Search syntax worth remembering: `'exact`, `^prefix`, `suffix$`, `!exclude`, and `a | b` for either.

Completion (fzf-tab)
---
Every `Tab` completion opens in fzf instead of zsh's menu: type to filter, `Enter` to accept.

- Completions are grouped (commands, aliases, files, …); `,` and `.` switch groups.
- `cd <Tab>` previews each directory's contents.
- Files are coloured like `ls`.
- `git checkout <Tab>` keeps git's own order (recent branches first) instead of sorting.

Find in files
---
`fif <text>` lists the files containing the text; the preview shows the matches with context. For the
same in nvim, use `;r` (live grep), see [neovim](neovim.md#finding-things).

Cheatsheets (navi)
---
`C-g` opens navi: pick a command from a cheatsheet, fill in its placeholders (often with suggestions from
a command), and it lands on your command line. Besides the community sheets, navi reads the ones in
`data_dir/navi/cheats/`. Add a `.cheat` file there for commands you keep looking up; see
[navi's docs](https://github.com/denisidoro/navi/tree/master/docs).
