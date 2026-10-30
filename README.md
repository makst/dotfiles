- [About](#about)
- [Install from scratch](#install-from-scratch)
- [Working with the full installation](#working-with-the-full-installation)

About
---
MacOS development setup.

Install from scratch
---
**Warning:**
Make sure you fork this repo and adjust it to your own preferences before even starting the setup.

1. Install git.
2. Clone this repo.
3. From inside this repo, run
   ```
   $ ./prepare-zsh-install.sh
   $ exec zsh
   $ setup_dotfiles # idempotent, can be executed after every `git pull`
   ```

   `prepare-zsh-install.sh` links the dotfiles into `$HOME`, installs Homebrew (native `/opt/homebrew` on Apple
   silicon), zsh and Oh My Zsh, and makes Homebrew's zsh your login shell. `setup_dotfiles` then installs the
   packages from the [Brewfile](./Brewfile) (including nvim), the zsh plugins, node, ssh-ident, links the git, tmux, nvim and Ghostty config and remaps Caps Lock to Ctrl at every login.

   yabai and skhd are installed by the Brewfile, but `setup_window_management` is not part of `setup_dotfiles`:
   run it yourself after reading the SIP notes in that function.

Working with the full installation
---
Discover [functions](./zsh/.functions) that you can run/rerun/modify to set up your dev environment.
