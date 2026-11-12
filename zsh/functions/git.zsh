#!/usr/bin/env zsh
# Shell functions for git (config/git, docs/git.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_git: links ~/.gitconfig and the global gitignore, and turns on this repo's hooks (.githooks), which
# run reload_dotfiles after a pull, rebase or branch switch.
function setup_git() {
  keep_real "$HOME/.gitconfig" &&
    ln -sfn "$real_script_dir/config/git/.gitconfig" "$HOME/.gitconfig" || return
  mkdir -p "$HOME/.config/git"
  keep_real "$HOME/.config/git/ignore" &&
    ln -sfn "$real_script_dir/config/git/ignore" "$HOME/.config/git/ignore" || return
  git -C "$real_script_dir" config core.hooksPath .githooks
}

# gsw [branch]: switch branch. With a name, as `git go`: switch to it, creating it if needed. Without one, pick
# a local or remote branch, newest commit first, with its log as the preview; a remote one is checked out as
# a tracking branch (git switch's guess). Typing filters the names only, not the subjects.
function gsw() {
  (( $# )) && { git go "$1"; return }
  source $_fzf_picker
  local branch
  branch=$(git for-each-ref --sort=-committerdate --format=$'%(refname:short)\t%(refname:short)\t\e[90m%(committerdate:relative) · %(subject)\e[0m' \
      --exclude 'refs/remotes/*/HEAD' refs/heads refs/remotes |
    picker branches --insert --with-nth $'{2}\t{3}' --nth 1 --tabstop 2 \
      --header 'type to filter (branch names), jj for j/k · Enter switches · Esc quits' \
      --preview 'git log --oneline --graph --color=always -20 {1}' --preview-window $picker_preview) || return
  branch=${branch%%$'\t'*}
  # a remote branch: switch to the local one of that name, which git creates tracking the remote
  git show-ref --verify --quiet refs/heads/$branch || [[ $branch != */* ]] || branch=${branch#*/}
  git switch $branch
}

# greview: the files this branch changes since it left the default branch, committed or not, in nvim's ;g
# picker (config/nvim/lua/user/git/changes.lua): Enter opens one beside its old side to read and comment on
# (,n), M-p sends the comments to the agent; Esc quits nvim again. zsh's ;g in normal mode runs it.
function greview() {
  git rev-parse --show-toplevel > /dev/null || return
  nvim +'lua require("user.git.changes").pick({ quit = true })'
}

# gfix: commit what's staged as a fixup of a commit picked from those not yet on the upstream (or on main,
# where there's no upstream), with the commit as the preview. `git rebase -i --autosquash <base>` folds it in.
function gfix() {
  git diff --cached --quiet && { print -u2 "gfix: nothing staged"; return 1 }
  source $_fzf_picker
  local base commit
  base=$(git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2> /dev/null)
  [[ -n $base && $(git rev-list --count $base..HEAD) -gt 0 ]] || base=$(git merge-base HEAD origin/main 2> /dev/null || git merge-base HEAD main)
  commit=$(git log --format=$'%H\t%h %s \e[90m%cr\e[0m' $base..HEAD |
    picker fixup --insert --header 'type to filter, jj for j/k · Enter makes the fixup · Esc quits' \
      --preview 'git show --stat --patch --color=always {1}' --preview-window $picker_preview) || return
  git commit --fixup ${commit%%$'\t'*}
}
