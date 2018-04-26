About
---
`dotfiles` on [ansible](https://www.ansible.com/) fully automate configuration of Mac OS X development machine, inlcuding setting up non-dev apps and settings (check [osx-host](roles/osx-host) role).

Setup
---
**Warning:**
Make sure you fork this repo and adjust it to your own preferences before even starting the setup.

1. Clone this repo.
2. Copy GPG key to location, specified in `gpg_key_file` variable.
3. Run
    ```
    $ ansible-playbook -i hosts playbooks/setup_dev_env.yml
    ```
    and provide ansible with the variables it asks for (ssh password, pass utility git origin).

4. Add newly generated ssh keys to github/etc.
5. Save passphrase[s] of newly generated ssh keys to your password manager (`pass`, in case of this repo).
6. Change PATH to `~/bin:$PATH` after `ssh-ident` installation
7. Change the shell to zsh `chsh -s /bin/zsh`

Usage
---
After setup is done, you can execute only parts of the setup by specifying tag[s].
```
$ ansible-playbook -i hosts playbooks/setup_dev_env.yml -t <tags>
```

Tags:
* `brew` [[tasks](roles/common/tasks/brew_setup.yml)] - setup [brew](https://brew.sh/) taps, packages, cask apps
* `git` [[tasks](roles/dev-host/tasks/git_setup.yml)] - symlink git dotfiles, setup [git hooks](roles/dev-host/templates/dotfiles_git_hooks) for dotfiles repo
* `gpg` [[tasks](roles/dev-host/tasks/gpg_import.yml)] - import gpg key
* `iterm2` [[tasks](roles/dev-host/tasks/iterm2_setup.yml)] - setup [iterm2](https://iterm2.com/) to use custom folder for preferences
* `nvm` [[tasks](roles/dev-host/tasks/nvm_setup.yml)] - download and install [nvm](https://github.com/creationix/nvm)
* `pass` [[tasks](roles/dev-host/tasks/password_manager_setup.yml)] - setup [password manager](https://www.passwordstore.org/)
* `ssh-ident` [[tasks](roles/dev-host/tasks/ssh_ident_setup.yml)] - download and install [ssh-ident](https://github.com/ccontavalli/ssh-ident)
* `ssh` [[tasks](roles/dev-host/tasks/ssh_setup.yml)] - create ssh keys based on specified `ssh_keys` variable data
* `vscode` [[tasks](roles/dev-host/tasks/vscode_setup.yml)] - symlink vscode settings and install vscode extensions
* `zsh` [[tasks](roles/dev-host/tasks/zsh_setup.yml)] - ensure zsh and oh-my-zsh are installed and symlinked
* `permissions` - make sure the files have correct permissions
* `dock` [[tasks](roles/osx-host/tasks/dock_setup.yml)] - dock preferences
* `finder` [[tasks](roles/osx-host/tasks/finder_setup.yml)] - finder settings
* `systemuiserver` [[tasks](roles/osx-host/tasks/systemuiserver_setup.yml)] - systemuiserver(specifically, menu bar) settings (battery, clock, bluetooth)
* `mission-control` [[tasks](roles/osx-host/tasks/mission_control_setup.yml)] - mission control settings

Note:
`roles/<role>/vars/main.yml` in each role is supposed to contain secret information. The format of the secret information is described in `roles/<role>/vars/main.example.yml` file. It's loaded automatically by ansible.

Thanks to
---
Inspired by lots of repositories and articles, but most importantly:
* https://github.com/mathiasbynens/dotfiles - awesome collection of settings.
* https://github.com/geerlingguy/mac-dev-playbook and https://blog.vandenbrand.org/2016/01/04/how-to-automate-your-mac-os-x-setup-with-ansible/ - a lot of valuable info on how to start with ansible dotfiles.

TODO
---
- travis.yml
- tmux setup
- change setup to a single `sh` file, which should guide the user during the first installation
