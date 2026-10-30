git
===

Plain git with current defaults, delta and difftastic for diffs, signed commits, a few aliases, lazygit for
staging and history, and the macOS keychain for SSH keys.

Config: `config/git/.gitconfig` (linked to `~/.gitconfig`). **Change `[user]` in your fork.** It holds the
GitHub noreply address, so commits don't expose a private email.

Behaviour
---
- **Diffs, logs and `git add -p`** go through [delta](https://github.com/dandavison/delta): syntax
  highlighting in the terminal's colours, line numbers, changed words highlighted within lines, moved
  lines in their own colour. `n` / `N` jump between files.
- **Structural diffs** with [difftastic](https://difftastic.wilfred.me.uk): `git dft`, `git dlog`,
  `git dshow` compare syntax trees, so reformatting and re-wrapping don't show up as changes.
- **Better hunks and conflicts**: the histogram diff algorithm; conflict markers show the common ancestor
  too (`zdiff3`); `rerere` remembers how a conflict was resolved and replays it.
- **Signed commits and tags** with your SSH key, see [below](#signing).
- **Typos**: `git stauts` suggests `git status` and asks before running it.
- **Renames and copies** are detected in diffs.
- **`git pull` merges** (no rebase); merge commits list the merged commits. `git fetch` drops branches
  deleted on the remote. `git push` on a new branch creates and tracks it on origin.
- **Rebases** stash and restore uncommitted changes and move stacked branches along (`updateRefs`).
- **`git status` stays fast** in big repos: git's file-system monitor runs per repo, untracked files are
  cached.
- **`git branch`** lists recently used branches first. New repos start on `main`.
- **Editor** is nvim and shows the diff below the commit message; **difftool** is nvim's diff mode
  (`git difftool`).

Aliases
---
| Alias | Does |
|---|---|
| `git go <branch>` | switch to the branch, creating it if needed |
| `git dft`, `git dlog`, `git dshow` | `diff`, `log -p`, `show` through difftastic |
| `git get <branch>` | check out `origin/<branch>` as a tracking branch |
| `git lca` | log with hash, date, committer and author on one line each |
| `git aliases` | list all aliases |


lazygit
---
`lg` in a shell, `,lg` inside nvim (a floating window that remembers its state per project). The quickest
way to stage hunks or single lines, write commits, rebase interactively, and browse branches and history.
`?` shows the keys for the current panel.

It uses lazygit's default config; nothing is customised here.

Signing
---
Commits and tags are signed with the SSH key in `user.signingkey` (`gpg.format = ssh`); no GPG needed.
`ssh-keygen` signs through the ssh-agent, so the key has to be in it (see [SSH keys](#ssh-keys)); if it
isn't, signing asks for the passphrase.

- **GitHub** shows the commits as *Verified* once the same public key is added as a **signing** key
  (separate from the authentication key, though it can be the same file):
  `gh ssh-key add ~/.ssh/identities/github_personal/id_rsa.pub --type signing`.
- **Locally**, `git log --show-signature` checks signatures against `config/git/allowed_signers`.
- For a repo where signing is unwanted: `git config commit.gpgsign false` inside it.

In nvim
---
Changed lines are marked in the sign column (gitsigns), `,gb` shows blame and `,go` opens the file on
GitHub. See [neovim](neovim.md#git).

SSH keys
---
macOS's own ssh-agent and keychain hold the keys; nothing runs in the shell for it.

- `config/ssh/config` is included at the top of `~/.ssh/config` and sets `UseKeychain` and
  `AddKeysToAgent` for every host, and which key GitHub and GitLab get. Private hosts go in
  `~/.ssh/config` below the include.
- **Once per key**, store its passphrase in the keychain:
  `ssh-add --apple-use-keychain ~/.ssh/identities/github_personal/id_rsa`.
- From then on ssh never asks: a login item (`com.makst.ssh-add`) loads the keychain's keys into the agent
  at login, and any other key is added the first time it's used. `ssh-add -l` lists what's loaded.

`setup_ssh` adds the include line, installs the login item and removes the `ssh`/`scp`/`sftp` links to
ssh-ident, which earlier versions of this repo used.
