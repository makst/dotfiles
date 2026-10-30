git
===

Plain git with a readable diff, a few aliases, lazygit for staging and history, and ssh-ident for keys.

Config: `config/git/.gitconfig` (linked to `~/.gitconfig`). **Change `[user]` in your fork.** It holds the
GitHub noreply address, so commits don't expose a private email.

Behaviour
---
- **Diffs and logs** go through [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy): no `+`/`-`
  columns, changed words highlighted within lines, file headers that stand out. Short output isn't paged.
- **Typos are corrected**: `git stauts` runs `git status` after a moment.
- **Renames and copies** are detected in diffs.
- **`git pull` merges** (no rebase); merge commits list the merged commits.
- **Editor** is nvim (`vim` links to it), **difftool** is nvim's diff mode (`git difftool`).

Aliases
---
| Alias | Does |
|---|---|
| `git go <branch>` | switch to the branch, creating it if needed |
| `git get <branch>` | check out `origin/<branch>` as a tracking branch |
| `git lca` | log with hash, date, committer and author on one line each |
| `git aliases` | list all aliases |

Oh My Zsh's git plugin adds the short shell aliases (`gst`, `gco`, `gcb`, `gp`, `gl`, `glog`, …).

lazygit
---
`lg` in a shell, `,lg` inside nvim (a floating window that remembers its state per project). The quickest
way to stage hunks or single lines, write commits, rebase interactively, and browse branches and history.
`?` shows the keys for the current panel.

It uses lazygit's default config; nothing is customised here.

In nvim
---
Changed lines are marked in the sign column (gitsigns), `,gb` shows blame and `,go` opens the file on
GitHub. See [neovim](neovim.md#git).

SSH keys (ssh-ident)
---
`ssh`, `scp` and `sftp` (and so git over ssh) go through [ssh-ident](https://github.com/ccontavalli/ssh-ident),
which starts an ssh-agent on first use and loads the key when it's first needed, asking for the passphrase
once. There's no need to run `ssh-add` or to start an agent in the shell.

ssh-ident can also keep separate agents and keys per identity (e.g. work and personal), chosen by the
directory you're in or the host you connect to; that's configured in `~/.ssh-ident`, which is not part of
this repo.

`install_ssh_ident` downloads it to `~/bin` and patches two incompatibilities with current macOS and
Python (an `env python` shebang, a too-small ioctl buffer). If ssh ever behaves oddly, `/usr/bin/ssh`
bypasses it.
