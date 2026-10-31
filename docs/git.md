git
===

Plain git with current defaults, delta and difftastic for diffs, signed commits, a few aliases, lazygit for
staging and history, and SSH keys that live in the Secure Enclave (Secretive).

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
- **`git pull` rebases** your local commits onto the fetched ones, so it never makes a merge commit;
  `git merge` commits list the merged commits. `git fetch` drops branches
  deleted on the remote. `git push` on a new branch creates and tracks it on origin.
- **Rebases** stash and restore uncommitted changes and move stacked branches along (`updateRefs`).
- **`git status` stays fast** in big repos: git's file-system monitor runs per repo, untracked files are
  cached.
- **`git branch`** lists recently used branches first. New repos start on `main`.
- **Ignored in every repo** (`config/git/ignore`, linked to `~/.config/git/ignore`): `.DS_Store`, Claude
  Code's agent worktrees (`.claude/worktrees/`) and personal `.claude/settings.local.json`.
- **Editor** is nvim and shows the diff below the commit message; `git difftool` and
  `git mergetool` open nvim's diff mode.

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
`ssh-keygen` signs through the agent in `SSH_AUTH_SOCK`, which `zsh/.exports` points at Secretive's. The
signing key is a Secretive key that doesn't ask for Touch ID, so commits, rebases and amends never prompt.

- **GitHub** shows the commits as *Verified* once the public key is added as a **signing** key:
  `secretive_key signing` does that (see [SSH keys](#ssh-keys)).
- **Locally**, `git log --show-signature` checks signatures against `config/git/allowed_signers`. It also
  keeps the earlier RSA and ed25519 keys, so older commits still verify.
- For a repo where signing is unwanted: `git config commit.gpgsign false` inside it.

In nvim
---
Changed lines are marked in the sign column (gitsigns), `,gb` shows blame and `,go` opens the file on
GitHub. See [neovim](neovim.md#git).

SSH keys
---
The keys are made by [Secretive](https://github.com/maxgoedjen/secretive) in the Mac's Secure Enclave. The
private halves can't be read or copied, not even by malware running as you; a key can only be *used*, through
Secretive's agent, which shows a notification each time. The price: no backups, so a new Mac means new keys,
and they are ECDSA P-256 (the only kind the Secure Enclave makes), which GitHub and GitLab accept like
ed25519.

There are two keys:

| Key | Touch ID | Used for |
|---|---|---|
| `push` | on every use | ssh to GitHub and GitLab: push, pull, fetch, clone |
| `signing` | never | signing commits and tags |

So only connections to a server prompt; signing, which happens on every commit, doesn't. A stolen session can
still sign while you're logged in, but can't push without your finger.

- `config/ssh/config` is included at the top of `~/.ssh/config`. It sends every host to Secretive's agent
  (`IdentityAgent`) and gives GitHub and GitLab only the push key. Private hosts go in `~/.ssh/config` below
  the include; one that still uses a key file reads its passphrase from the keychain (`UseKeychain`, after
  `ssh-add --apple-use-keychain <key>` once).
- **Making the keys**: in the Secretive app, create a key named `push` with *Require Authentication* on, and
  one named `signing` with it off. Then `secretive_key push` and `secretive_key signing`: each copies the
  public key to `~/.ssh/identities/secretive/<role>.pub` (which the ssh and git config point to) and adds it
  to GitHub, the push key for ssh and the signing key for signing (and to `config/git/allowed_signers`:
  commit that). For GitLab, `secretive_key push` copies the public key and opens the page to paste it. Named
  them differently? `secretive_key push "GitHub push"`.
- `ssh-add -l` lists the keys Secretive offers; `ssh -T git@github.com` checks the push key.

`setup_ssh` adds the include line, removes the `com.makst.ssh-add` login item (which loaded keychain keys
into macOS's own agent before Secretive) and the `ssh`/`scp`/`sftp` links to ssh-ident, which earlier
versions of this repo used.
