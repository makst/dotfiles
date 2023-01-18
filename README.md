- [About](#about)
- [Install from scratch](#install-from-scratch)
- [Working with the full installation](#working-with-the-full-installation)
- [TODO](#todo)

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
   $ .prepare-zsh-install.sh
   $ exec zsh
   $ setup_dotfiles # idempotent, can be executed after every `git pull`
   ```

Working with the full installation
---
Discover [functions](./zsh/.functions) that you can run/rerun/modify to set up your dev environment.
