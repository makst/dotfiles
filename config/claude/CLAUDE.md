# How I work, in every project

- **Deleting**: never `rm -rf`. Move things to the Trash with `trash <path>` (macOS) or `mv <path> ~/.Trash/`,
  so they can be put back. A hook blocks recursive `rm`.
- **Git**: work on a branch, not on the default one. Commit when I ask; merge and push only when I ask.
  Commits use my git identity; the only Claude line is the `Co-Authored-By` trailer.
- **Signing and pushing**: commits are signed with an SSH key in Secretive (Secure Enclave), through
  `SSH_AUTH_SOCK`. The push key asks for Touch ID, so a push waits for me.
- **Machine**: Apple silicon Mac, native arm64 only. Homebrew lives in `/opt/homebrew`; don't suggest Intel
  builds, Rosetta or `/usr/local`.
- **Shell**: zsh. `eza`, `bat`, `fd`, `rg`, `jq`, `gh`, `delta` and `difftastic` are installed.
