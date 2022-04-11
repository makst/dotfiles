[![Build Status](https://travis-ci.org/makst/dotfiles.svg?branch=master)](https://travis-ci.org/makst/dotfiles)

About
---
`dotfiles` on [ansible](https://www.ansible.com/) fully automate configuration of Mac OS X development machine, inlcuding setting up non-dev apps and settings (check [osx-host](roles/osx-host) role).

Install from scratch
---
**Warning:**
Make sure you fork this repo and adjust it to your own preferences before even starting the setup.

1. Install brew, git, pip, ansible.
2. Clone this repo.
3. From inside this repo, run
   ```
   $ ln -s $(pwd)/.zshrc $HOME/.zshrc
   $ install_from_scratch
   ```
4. Copy GPG key to location, specified in `gpg_key_file` variable.
5. Run
    ```
    $ ansible-galaxy install -r requirements.yml
    $ ansible-playbook -i hosts playbooks/setup_dev_env.yml
    ```
    and provide ansible with the variables it asks for (ssh password, pass utility git origin).

6. Add newly generated ssh keys to github/etc.
7. Save passphrase[s] of newly generated ssh keys to your password manager (`pass`, in case of this repo).

Usage
---
After setup is done, you can execute only parts of the setup by specifying tag[s].
```
$ ansible-playbook -i hosts playbooks/setup_dev_env.yml -t <tags>
```

Tags:
* `brew` [[tasks](roles/common/tasks/brew_setup.yml)] - setup [brew](https://brew.sh/) taps, packages, cask apps
* `sdkman` [[tasks](playbooks/setup_dev_env.yml)] - [SDKMAN!](https://sdkman.io/) is a tool for managing JDK environments and tools: java, scala, maven, etc.
* `git` [[tasks](roles/dev-host/tasks/git_setup.yml)] - symlink git dotfiles, setup [git hooks](roles/dev-host/templates/dotfiles_git_hooks) for dotfiles repo
* `gpg` [[tasks](roles/dev-host/tasks/gpg_import.yml)] - import gpg key
* `pip` [[tasks](roles/dev-host/tasks/pip_install.yml)] - install pip packages
* `iterm2` [[tasks](roles/dev-host/tasks/iterm2_setup.yml)] - setup [iterm2](https://iterm2.com/) to use custom folder for preferences
* `node` [[tasks](roles/dev-host/tasks/node_setup.yml)] - download and install [nvm](https://github.com/creationix/nvm), node, npm packages
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
