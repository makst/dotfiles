look at this repo https://github.com/geerlingguy/mac-dev-playbook/
It also uses ansible to setup mac.

Installation
===
1. Copy GPG key to location, specified in `gpg_key_file` variable.
2. Refer to the installation section of the beforementioned repo.
3. Switch pass remote from https one to git
4. 

Usage
===
`roles/<role>/vars/main.yml` in each role is supposed to contain secret information. The format of the secret information is described in `roles/<role>/vars/main.example.yml` file. It's loaded automatically by ansible.


TODO
===
- setup zsh
- add dotfiles (git, zsh, vscode)
- setup repos
- setup git hook to automatically encrypt/decrypt encrypted dotfiles (brave)
- change github and gitlab passwords to the ones easier to use ( as it has to be easy to set this up on new machine)
