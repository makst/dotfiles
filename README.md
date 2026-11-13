dotfiles
===

A keyboard-driven macOS development setup for Apple silicon. Ghostty opens straight into tmux, tmux holds
the shells, nvim sessions and Claude Code agents, and one base16 colour scheme is shared by all of them.

<details>
<summary><b>Show GIF</b></summary>

A quick tour: `cmd+k` opens a project as a session, `git diff` through delta, `;f` finds a file in nvim,
`cmd+d` puts a shell next to it, `C-h` and `C-l` cross between them, `cmd+w` closes the nvim pane, `gs` shows
git status in nvim, `cmd+j` shows every session.

![A quick tour: cmd+k opens a project as a session, git diff through delta, ;f finds a file in nvim, cmd+d puts a shell next to it, C-h and C-l cross between them, cmd+w closes the nvim pane, gs shows git status in nvim, cmd+j shows every session](docs/img/tour.gif)

</details>

| Layer | Tool | Docs |
|---|---|---|
| Install and update | Homebrew (`Brewfile`), `setup_dotfiles`, `check_dotfiles` (also CI), `check_mac` | [setup](docs/setup.md) |
| Terminal | Ghostty | [ghostty](docs/ghostty.md) |
| Sessions, windows, panes | tmux + session picker | [tmux](docs/tmux.md) |
| Shell | zsh (no framework, vi mode), starship, atuin, zoxide, fnm, uv | [zsh](docs/zsh.md) |
| Fuzzy finding | fzf, fzf-tab, fd, bat, eza | [fzf](docs/fzf.md) |
| Editor | Neovim (lazy.nvim, LSP, treesitter, fzf-lua) | [nvim](docs/nvim.md) |
| Version control | git, delta, difftastic, fugitive (in nvim), gh, Secretive (SSH keys) | [git](docs/git.md) |
| AI agents | Claude Code in tmux windows and git worktrees | [claude](docs/claude.md) |
| iOS and Android apps | nvim (sourcekit-lsp, xcodebuild.nvim; kotlin-lsp, Gradle) next to Xcode and Android Studio | [mobile](docs/mobile.md) |
| Vim keys everywhere | nvim's keys in VS Code (vim extension) and Android Studio (IdeaVim) | [vim-keys](docs/vim-keys.md) |
| AWS | aws CLI with SSO logins; Claude Code reads, can't change | [aws](docs/aws.md) |
| Google Cloud | gcloud, bq, gsutil on work Macs; Claude Code reads, can't change | [gcloud](docs/gcloud.md) |
| Containers | podman in a VM as `docker` and `docker compose`, no Docker Desktop | [podman](docs/podman.md) |
| Kubernetes deploys | argocd CLI: what's deployed, healthy, in sync | [argocd](docs/argocd.md) |
| GitHub | a watcher: notifications and a tmux mark for your pull requests' checks and reviews, mentions, comments | [github](docs/github.md) |
| Debugging | VS Code next to nvim (`,vo`), for backends and the web | [debugging](docs/debugging.md) |
| Colours | base16 scheme for nvim, Ghostty and everything else | [theme](docs/theme.md) |
| Window manager | AeroSpace (tiling, workspaces, SIP stays on) | [AeroSpace](docs/aerospace.md) |
| GIFs in these docs | VHS tapes, rendered by `make_gifs` | [gifs](docs/gifs.md) |
| Design | the principles every key, file, page and change follows; which layer owns which modifier | [design](docs/design.md) |

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

How it is designed
---
Six principles decide where every key, file, page and tool goes and how a change is made, so learning one
part of the setup teaches the rest. [design](docs/design.md) defines them:

- **Learn it once**: vim is the grammar, the key names the action and the modifier the layer, nvim is the
  reference.
- **One search away**: the file name says the kind and the folder the tool, each thing is defined in one
  place, and state you check opens in a list with a preview.
- **Same shape, every page**: every `docs/<tool>.md` has the same sections in the same order, and says what
  the config does, no less and no more.
- **One tool per job**: each job (terminals, editing, lists, projects, git) has one tool that owns it, and the
  others hand it over instead of doing it their own way; every list is the same picker.
- **Safe to try**: a setup step can be run again, nothing deletes for good, and a change can be taken back.
- **A rule has a check**: `check_dotfiles` checks a rule in about a second, or the rule is listed as not
  checked.

Whatever can't follow one says why, where the rule would be looked up.

Each layer owns a modifier ([how the keyboard is split](docs/design.md#how-the-keyboard-is-split)), and a move
you know on one layer works on the others ([same key, every layer](docs/design.md#same-key-every-layer)).

Switching sessions and windows
---
| Key | Action |
|---|---|
| `cmd+j` | every session and window as tmux's tree, in fzf with a live preview; `j`/`k` move, `/` filters, `Enter` switches, `d` kills, `r` renames |
| `cmd+shift+j` | only the Claude Code agents, most urgent first: their state, what each works on, a live preview of its screen |
| `cmd+g` | your pull requests and GitHub notifications, most urgent first: checks or the thread in the preview, Enter opens it |
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
5. `agent_review fix-login` puts a reviewer beside it; `agent_land fix-login` rebases, checks and merges the
   finished work.

Repository layout
---
```
Brewfile                  every package and app, commented by purpose
prepare-zsh-install.sh    first-run bootstrap (bash, before zsh exists)
.zshrc                    sources zsh/*; everything else is linked from config/
zsh/                      shell config, aliases, functions/<tool>.zsh (setup_dotfiles: functions/setup.zsh)
config/atuin/             shell history search
config/btop/              btop: vim keys, the terminal's colours
config/readline/          vi mode in REPLs (inputrc for GNU readline, editrc for libedit)
config/fzf/               fzf.zsh: fzf and fzf-tab configuration, the zsh pickers; fzfrc: the look and keys every fzf reads
config/glow/              mdv's Markdown style
config/ghostty/           Ghostty config and the generated base16 theme
config/tmux/              tmux.conf and the pickers (sessions, windows, agents, paste buffers)
config/nvim/              Neovim: one directory per plugin under lua/user/
config/starship.toml      prompt
config/git/.gitconfig     git
config/ssh/config         ssh: Secretive agent, which key for which host
config/aerospace/         window manager
config/vscode/            VS Code, the debugger: settings (with nvim's keys) and the extensions to install
config/ideavim/           nvim's keys in Android Studio (IdeaVim)
config/claude/            Claude Code: settings, global CLAUDE.md, hooks, status line, skills
config/machine/           templates for this Mac's own files in ~/.config/dotfiles
docs/                     this documentation; tapes/ and img/ are the GIFs in it
.githooks/                reload the live setup after a pull, rebase or branch switch
.github/                  CI: check_dotfiles and the fresh-Mac rehearsal
checks/                   check_dotfiles: the checks run before a commit and on CI; mutate tests them;
                          fresh_mac rehearses a new Mac
CLAUDE.md                 instructions for Claude Code working on this repo
```

The same repo serves any number of Macs, e.g. one for home and one for work. What only one Mac needs (work email,
work plugins for Claude Code, extra packages, shell settings) lives outside the repo in `~/.config/dotfiles`,
see [setup](docs/setup.md#several-macs). Secrets go in files that are gitignored and loaded when
present: `zsh/.private` (shell, e.g. tokens) and `config/nvim/lua/user/hidden/init.lua` (nvim).
