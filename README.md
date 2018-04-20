look at this repo https://github.com/geerlingguy/mac-dev-playbook/
It also uses ansible to setup mac.

Fresh installation
===
1. Copy GPG key to location, specified in `gpg_key_file` variable.
2. Refer to the installation section of the beforementioned repo (even though nothing from it is used directly)
3. Switch pass remote from https one to git
4. Add newly generated ssh keys to github/etc.
5. Fetch repositories (these dotfiles only setup dir structure and add origins to repos, you have to `git fetch`).
6. Save passphrase[s] of newly generated ssh keys to your password manager (`pass`, in case of this repo).
7. Change PATH to `~/bin:$PATH` after `ssh-ident` installation
8. Change the shell to zsh `chsh -s /bin/zsh`

Usage
===
`roles/<role>/vars/main.yml` in each role is supposed to contain secret information. The format of the secret information is described in `roles/<role>/vars/main.example.yml` file. It's loaded automatically by ansible.

Acknowledgements
===
Inspired by lots of repositories and articles, but most importantly, next ones:
* https://github.com/mathiasbynens/dotfiles
* https://github.com/geerlingguy/mac-dev-playbook and https://blog.vandenbrand.org/2016/01/04/how-to-automate-your-mac-os-x-setup-with-ansible/ (inspiration to create dotfiles in ansible)
* https://github.com/stephenmckinney/dotfiles (I've got an inspiration for iterm settings from here)

TODO
===
- add dotfiles (~~git, zsh~~, vscode, vim)
- create installation script for fresh install
- extend usage section