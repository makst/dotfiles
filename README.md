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
| Install and update | Homebrew (`Brewfile`), `setup_dotfiles`, `check_dotfiles` (also CI) | [setup](docs/setup.md) |
| Terminal | Ghostty | [ghostty](docs/ghostty.md) |
| Sessions, windows, panes | tmux + session picker | [tmux](docs/tmux.md) |
| Shell | zsh (no framework, vi mode), starship, atuin, zoxide, fnm, uv | [zsh](docs/zsh.md) |
| Fuzzy finding | fzf, fzf-tab, fd, bat, eza | [fzf](docs/fzf.md) |
| Editor | Neovim (lazy.nvim, LSP, treesitter, telescope) | [neovim](docs/neovim.md) |
| Version control | git, delta, difftastic, lazygit, gh, Secretive (SSH keys) | [git](docs/git.md) |
| AI agents | Claude Code in tmux windows and git worktrees | [claude-code](docs/claude-code.md) |
| iOS apps | nvim (sourcekit-lsp, xcodebuild.nvim) next to Xcode | [mobile](docs/mobile.md) |
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

iOS projects
---
Code is edited in nvim, Xcode stays open for previews, signing and debugging. More in
[mobile](docs/mobile.md).

**Once per Mac**, after `setup_dotfiles` (which installs xcode-build-server, xcbeautify and swiftformat):

1. Install Xcode from the App Store.
2. Make it the active toolchain and accept its licence:
   ```sh
   sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -license accept
   ```
3. In nvim, `:checkhealth xcodebuild` should show nothing missing.

**Once per project**, in nvim at the project's root:

1. `,iS`: pick the project or workspace, the scheme, the test plan and the device. This writes
   `buildServer.json` and `.nvim/xcodebuild/` into the project; the global gitignore keeps them out of git.
2. `,ib` to build once, so sourcekit-lsp has an index: completion and go-to-definition work from then on.

Then `,ir` builds and runs, `,it` runs the tests and `,io` opens the current line in Xcode.

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
| `,` | nvim leader | `,e` file tree, `,lg` lazygit |
| `;` | nvim pickers (telescope, harpoon) | `;f` files, `;r` grep |
| `jj` | leave insert mode, in nvim and in zsh | |
| `C-r` / `C-t` | atuin history, fzf files, in zsh | |

Switching sessions and windows
---
| Key | Action |
|---|---|
| `cmd+j` | every session and window as a tree with live previews; move with arrows or `j`/`k`, `Enter` switches |
| `cmd+k` | fuzzy-find a running session or a project directory, which becomes a session (`tm` outside tmux) |
| `cmd+shift+[` / `cmd+shift+]` | previous / next session |
| `cmd+[` / `cmd+]`, `cmd+1`…`9` | previous / next window, window by number |
| `C-a l` | back to the last window |
| `cmd+r` / `cmd+shift+r` | rename the window / session |

More in [tmux](docs/tmux.md#keys).

A typical day
---
1. Open Ghostty: you land in the tmux session `main`, exactly as you left it, even after a reboot.
2. `cmd+k`, type part of a project name: a tmux session for that directory opens (or is reused).
3. `vim .` in one window, `cmd+d` for a shell next to it, `C-h`/`C-l` to move between them.
4. `agent fix-login "the login form rejects valid emails"` starts Claude Code in its own worktree and
   window; when it needs you, its window turns yellow in the status bar.

Repository layout
---
```
Brewfile                  every package and app, commented by purpose
prepare-zsh-install.sh    first-run bootstrap (bash, before zsh exists)
.zshrc                    sources zsh/*; everything else is linked from config/
zsh/                      shell config, aliases, functions (setup_dotfiles lives in .functions)
config/atuin/             shell history search
.fzf.zsh                  fzf and fzf-tab configuration
config/ghostty/           Ghostty config and the generated base16 theme
config/tmux/              tmux.conf and the session picker
config/nvim/              Neovim: one directory per plugin under lua/user/
config/starship.toml      prompt
config/git/.gitconfig     git
config/ssh/config         ssh: Secretive agent, which key for which host
config/aerospace/         window manager
config/claude/            Claude Code: settings, global CLAUDE.md, hooks, status line
config/machine/           templates for this Mac's own files in ~/.config/dotfiles
docs/                     this documentation; tapes/ and img/ are the GIFs in it
CLAUDE.md                 instructions for Claude Code working on this repo
```

The same repo serves any number of Macs, e.g. one for home and one for work. What only one Mac needs (work email,
work plugins for Claude Code, extra packages, shell settings) lives outside the repo in `~/.config/dotfiles`,
see [setup](docs/setup.md#several-macs). Secrets go in files that are gitignored and loaded when
present: `zsh/.private` (shell, e.g. tokens) and `config/nvim/lua/user/hidden/init.lua` (nvim).
