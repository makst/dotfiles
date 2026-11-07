#!/usr/bin/env zsh
# Shell functions for the whole install and checking it (docs/setup.md): setup_dotfiles and its Mac-wide
# steps, reload_dotfiles, check_dotfiles, check_mac. Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_brew: installs the Brewfile's packages (see the Brewfile for what and why) with `brew bundle`, then
# fix_completion_dirs, since an install can leave a completion directory zsh calls insecure.
function setup_brew() {
  print "=> Installing brew packages from the Brewfile"
  brew bundle --file="$real_script_dir/Brewfile"
  local bundle=$?
  # also after a failed bundle: the packages it did install may have changed permissions
  fix_completion_dirs
  return $bundle
}

# fix_completion_dirs: removes group and other write access from the completion directories under Homebrew's
# prefix that zsh's compaudit calls insecure. An install can leave one group-writable (/opt/homebrew/share,
# once); zsh then asks once a day whether to use them and, told no, loads no completion at all. Anything
# insecure outside Homebrew's prefix is only listed, to look at by hand.
function fix_completion_dirs() {
  autoload -Uz compaudit
  local d
  for d in ${(f)"$(compaudit 2> /dev/null)"}; do
    if [[ $d == $HOMEBREW_PREFIX/* ]]; then
      chmod go-w $d && print "=> chmod go-w $d"
    else
      print -u2 "insecure for zsh completion, outside Homebrew, left alone: $d"
    fi
  done
  return 0
}

# setup_caps_lock: Caps Lock becomes (right) Ctrl, now with hidutil and at every login with a LaunchAgent,
# since hidutil's mappings don't survive a reboot (https://apple.stackexchange.com/a/283253).
function setup_caps_lock() {
  local mapping='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000e4}]}'
  hidutil property --set "$mapping"

  # hidutil mappings are lost on reboot, so re-apply it at every login
  local label="com.makst.capslock-to-ctrl"
  local plist="$HOME/Library/LaunchAgents/$label.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>$mapping</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST
  launchctl bootout "gui/$(id -u)/$label" 2> /dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
}

# setup_macos_defaults: the macOS settings these dotfiles rely on, for keys held down in vim.
function setup_macos_defaults() {
  # fast key repeat (the fastest System Settings offers), for held vim motions; applies after logging out and in
  defaults write -g KeyRepeat -int 2
  defaults write -g InitialKeyRepeat -int 15
  # a held key repeats in Ghostty instead of offering accented characters; restart Ghostty
  defaults write com.mitchellh.ghostty ApplePressAndHoldEnabled -bool false
}

# setup_touch_id_sudo: Touch ID for sudo, also inside tmux (pam-reattach from the Brewfile). Uses sudo itself,
# so it isn't part of setup_dotfiles. /etc/pam.d/sudo_local survives macOS updates, unlike /etc/pam.d/sudo.
function setup_touch_id_sudo() {
  printf '%s\n' \
    "auth       optional       $HOMEBREW_PREFIX/lib/pam/pam_reattach.so ignore_ssh" \
    "auth       sufficient     pam_tid.so" | sudo tee /etc/pam.d/sudo_local > /dev/null
}

# setup_machine [<name> <home|work>]: this Mac's own settings, kept out of the repo in ~/.config/dotfiles. Asks
# the first time for its name (used for its keys on GitHub) and whether it's home-like or work-like (the
# Brewfile can install packages for one kind only); then creates the files git, zsh, brew and Claude Code load
# from there, from config/machine, leaving existing ones alone. Also points ~/dotfiles at this clone, wherever
# it is, since ~/.ssh/config and ~/.gitconfig use that path.
function setup_machine() {
  local dir=~/.config/dotfiles name=$1 kind=$2 file
  if [[ -e ~/dotfiles && ! -L ~/dotfiles && ! ~/dotfiles -ef $real_script_dir ]]; then
    print -u2 "~/dotfiles exists and isn't this repo ($real_script_dir); move it away and rerun"
  else
    [[ ~/dotfiles -ef $real_script_dir ]] || ln -sfn $real_script_dir ~/dotfiles
  fi

  mkdir -p $dir
  [[ -z $name && -r $dir/name ]] && name=$(<$dir/name)
  [[ -z $kind && -r $dir/kind ]] && kind=$(<$dir/kind)
  local suggested=${(L)${HOST%%.*}}
  until [[ -n $name && $name != *[^[:alnum:]_-]* ]]; do
    read -r "name?Name for this Mac (letters, digits, - and _; shown with its keys on GitHub) [$suggested]: " ||
      return 1
    name=${name:-$suggested}
  done
  until [[ $kind == (home|work) ]]; do
    print "Is it home-like or work-like? Every Mac gets all the shared apps; the kind only adds what the"
    read -r "kind?Brewfile marks for home or for work [home/work]: " || return 1
  done
  print -r -- $name > $dir/name
  print -r -- $kind > $dir/kind

  for file in $real_script_dir/config/machine/*(N); do
    [[ -e $dir/${file:t} ]] || cp $file $dir/
  done

  [[ $(git config --file $dir/gitconfig commit.gpgsign) == true ]] ||
    print "Commits on this Mac aren't signed until its Secretive keys exist: see 'A new Mac' in docs/setup.md."
  return 0
}

# setup_dotfiles: the whole setup, idempotent; rerun after a `git pull` when reload_dotfiles (run by the git
# hooks) says so. A step that fails doesn't stop the others (on a managed work Mac, MDM may block one, or an app
# may already be installed outside Homebrew); the failed ones are listed at the end, to fix and run again on
# their own.
function setup_dotfiles() {
  # everything below needs the Mac's name and kind
  setup_machine || return
  local step
  local -a failed
  for step in setup_brew setup_fzf setup_atuin setup_btop setup_readline setup_node setup_python setup_ssh \
    setup_git setup_tmux setup_nvim setup_ghostty setup_claude setup_caps_lock setup_macos_defaults \
    setup_window_management setup_vscode setup_ideavim; do
    print -P "%F{blue}=> $step%f"
    $step || failed+=$step
  done
  if (( $#failed )); then
    print -u2 -P "%F{red}Failed: ${(j:, :)failed}.%f Fix the cause (see the output above) and run each again."
    return 1
  fi
}

# reload_dotfiles [<commit>]: makes the running programs read their config as it is now in this checkout: the
# tmux server, Ghostty (SIGUSR2, Ghostty 1.2 and later; older ones would quit) and AeroSpace, each when it runs.
# The links put a pulled change on disk at once, but these keep the config they started with, and tmux's popups
# the environment the server started with. With a commit (the git hooks in .githooks pass the one before a pull,
# rebase or switch), only what changed since then, and it lists what's left to do by hand: open shells, nvim,
# Android Studio, setup steps. Prints nothing when nothing it knows about changed.
function reload_dotfiles() {
  setopt local_options extended_glob
  local -a files reloaded todo
  if [[ -n $1 ]]; then
    files=(${(f)"$(git -C $real_script_dir diff --name-only $1 HEAD --)"})
    (( $#files )) || return 0
  fi
  local -i all=$(( ! $#files ))

  if (( all || $files[(I)config/tmux/tmux.conf] )) && tmux list-sessions &> /dev/null; then
    tmux source-file ~/.config/tmux/tmux.conf && reloaded+=tmux
  fi
  # the ghostty on PATH, else the app's own (Ghostty doesn't put it on PATH)
  local ghostty=ghostty version
  whence ghostty > /dev/null || ghostty=/Applications/Ghostty.app/Contents/MacOS/ghostty
  if (( all || $files[(I)config/ghostty/*] )) && pgrep -qx ghostty; then
    version=${${(M)${(f)"$($ghostty +version 2> /dev/null)"}:#Ghostty *}#Ghostty }
    if [[ $version == (<2->.*|1.<2->*) ]]; then
      pkill -USR2 -x ghostty && reloaded+=Ghostty
    else
      todo+="Ghostty: cmd+shift+, reloads its config"
    fi
  fi
  if (( all || $files[(I)config/aerospace/*] )) && pgrep -qx AeroSpace; then
    aerospace reload-config && reloaded+=AeroSpace
  fi

  if (( ! all )); then
    (( $files[(I)(.zshrc|.fzf.zsh|zsh/*)] )) && todo+='zsh: `exec zsh` in the shells that are open'
    (( $files[(I)config/nvim/^lazy-lock.json] )) && todo+='nvim: restart the ones that are open'
    (( $files[(I)config/nvim/lazy-lock.json] )) && todo+='nvim: `:Lazy restore` installs the pinned plugins'
    (( $files[(I)(Brewfile|config/machine/Brewfile)] )) && todo+='Brewfile: `setup_brew` installs what it added'
    (( $files[(I)config/ideavim/*] )) && todo+='Android Studio: `:source ~/.ideavimrc`'
    # a link added or changed in a setup step (a line that starts with it: this one only mentions it)
    # (skills aren't on the list: the claude wrapper links new ones when it starts)
    [[ -n $(git -C $real_script_dir diff $1 HEAD -G '^[[:space:]]*ln -sfn' --name-only -- zsh/functions) ]] &&
      todo+='links: `setup_dotfiles` makes the new ones'
  fi

  (( $#reloaded )) && print -P "%F{blue}dotfiles:%f reloaded ${(j:, :)reloaded}"
  (( $#todo )) && print -P "%F{blue}dotfiles:%f still to do" && print -rl -- "  - "$^todo
  return 0
}

# check_dotfiles [-v]: the checks CI runs on every push (.github/workflows/check.yml), to run before
# committing. Runs checks/check_dotfiles from this repo, wherever the shell is; it prints what fails and
# returns 1. -v (CI uses it) lists every check with its result and time. Without real_script_dir (a Claude Code
# shell started from a zsh older than its export: the snapshot keeps this function but not the variable) it
# finds the repo through the ~/.zshrc link, as .zshrc does.
function check_dotfiles() {
  ${real_script_dir:-${${:-$HOME/.zshrc}:A:h}}/checks/check_dotfiles "$@"
}

# check_mac [--scripted]: whether this Mac is set up as the repo says, after a pull or on a Mac that hasn't
# been used for a while; check_dotfiles checks the repo, this the Mac it runs on. Checks every link the setup
# makes, this Mac's files in ~/.config/dotfiles, the Brewfile's packages, nvim's plugins against
# lazy-lock.json, tmux's plugins, node and python, VS Code's extensions, the repo's git hooks, the ssh include,
# the login shell, that a new zsh and nvim start without errors, and the steps of "A new Mac" done by hand:
# the ssh agent, commit signing and, on a work Mac signed in to gcloud, Claude's Viewer service account
# (docs/gcloud.md). --scripted leaves those out, for checks/fresh_mac, which can only run the
# scripts. Changes nothing: prints each problem with the step that fixes it and returns 1, or one line when
# all is well. The macOS settings the setup makes once (key repeat, Caps Lock, the Dock) aren't checked.
function check_mac() {
  setopt local_options extended_glob
  local repo=${real_script_dir:-${${:-$HOME/.zshrc}:A:h}} dir=~/.config/dotfiles
  local -i by_hand=1
  [[ $1 == --scripted ]] && by_hand=0
  local -a problems
  local -A seen
  local dst src where link target step file name commit key

  # the links, as checks/lib.zsh reads them from the setup's ln lines; each is fixed by the function it's in
  while IFS=$'\t' read -r dst src where; do
    (( $+seen[$dst] )) && continue
    seen[$dst]=1
    link=${dst/#\~/$HOME}
    target=${${src/#./$repo}/#$repo\//$repo/}
    [[ -L $link && -e $link && $link -ef $target ]] && continue
    step=prepare-zsh-install.sh
    [[ $where == zsh/functions/*:* ]] &&
      step=$(awk -v n=${where##*:} 'NR > n { exit } /^function / { f = $2 } END { sub(/\(.*/, "", f); print f }' $repo/${where%:*})
    if [[ $target == $repo ]]; then
      target="this repo"
    else
      target=${target#$repo/}
    fi
    problems+="$dst isn't a link to $target: $step"
  done < <(cd $repo && source checks/lib.zsh && links_index)

  # this Mac's files
  for file in name kind $repo/config/machine/*(N:t); do
    [[ -r $dir/$file ]] || problems+="~/.config/dotfiles/$file is missing: setup_machine"
  done
  [[ ! -r $dir/kind || $(<$dir/kind) == (home|work) ]] ||
    problems+="~/.config/dotfiles/kind is neither home nor work: setup_machine <name> <home|work>"
  [[ ! -r $dir/claude.json ]] || jq -e . $dir/claude.json > /dev/null 2>&1 ||
    problems+="~/.config/dotfiles/claude.json isn't valid JSON: fix it by hand"
  [[ ! -r $dir/gitconfig ]] || git config --file $dir/gitconfig --list > /dev/null 2>&1 ||
    problems+="~/.config/dotfiles/gitconfig doesn't parse: fix it by hand"

  # packages and plugins
  brew bundle check --file=$repo/Brewfile --no-upgrade > /dev/null 2>&1 ||
    problems+="Brewfile packages are missing (brew bundle check --verbose lists them): setup_brew"
  local -a stale=()
  while IFS=$'\t' read -r name commit; do
    [[ $(git -C ${XDG_DATA_HOME:-~/.local/share}/nvim/lazy/$name rev-parse HEAD 2> /dev/null) == $commit ]] ||
      stale+=$name
  done < <(jq -r 'to_entries[] | "\(.key)\t\(.value.commit)"' $repo/config/nvim/lazy-lock.json)
  (( $#stale )) && problems+="nvim plugins not at lazy-lock.json's version (${(j:, :)stale}): setup_nvim"
  stale=()
  for name in ${${(f)"$(sed -nE "s/^set -g @plugin '([^']+)'.*/\1/p" $repo/config/tmux/tmux.conf)"}:t}; do
    [[ -d ~/.tmux/plugins/$name ]] || stale+=$name
  done
  (( $#stale )) && problems+="tmux plugins missing (${(j:, :)stale}): setup_tmux"
  # fnm's default node, not Homebrew's (a dependency of the language servers)
  fnm exec --using=default -- tsc --version > /dev/null 2>&1 ||
    problems+="fnm has no default node with typescript: setup_node"
  [[ -x ~/.local/bin/python ]] || problems+="no ~/.local/bin/python: setup_python"
  if (( $+commands[code] )); then
    local -a installed=(${(Lf)"$(code --list-extensions 2> /dev/null)"})
    stale=()
    for name in ${${(f)"$(<$repo/config/vscode/extensions.txt)"}%%[[:space:]]#\#*}; do
      [[ -n $name ]] && (( ! $installed[(Ie)${(L)name}] )) && stale+=$name
    done
    (( $#stale )) && problems+="VS Code extensions missing (${(j:, :)stale}): setup_vscode"
  fi

  # git, ssh and the shell
  [[ $(git -C $repo config core.hooksPath) == .githooks ]] ||
    problems+="the repo's git hooks are off, so a pull doesn't reload anything: setup_git"
  # the steps done by hand: Secretive's agent, and the signing key secretive_key made
  if (( by_hand )); then
    [[ -S $SSH_AUTH_SOCK ]] || problems+="no ssh agent (Secretive's isn't running?): open Secretive"
    if [[ $(git config --file $dir/gitconfig commit.gpgsign 2> /dev/null) != true ]]; then
      problems+="commits on this Mac aren't signed: docs/setup.md, \"A new Mac\", step 4"
    else
      key=$(git config --file $dir/gitconfig user.signingkey)
      key=${key/#\~/$HOME}
      if [[ ! -r $key ]]; then
        problems+="the signing key ${key/#$HOME/~} is missing: secretive_key signing"
      else
        grep -qF -- ${${=$(<$key)}[2]} $repo/config/git/allowed_signers ||
          problems+="this Mac's signing key isn't in config/git/allowed_signers: secretive_key signing"
      fi
    fi
    # a work Mac signed in to gcloud: Claude should act as the Viewer service account, not as you
    [[ -r $dir/kind && $(<$dir/kind) == work && -s ${CLOUDSDK_CONFIG:-~/.config/gcloud}/credentials.db ]] &&
      ! jq -e '.env.CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT' $dir/claude.json > /dev/null 2>&1 &&
      problems+="Claude Code uses your own gcloud login: docs/gcloud.md, \"Read-only for real\""
  fi
  grep -qxF "Include ~/dotfiles/config/ssh/config" ~/.ssh/config 2> /dev/null ||
    problems+="~/.ssh/config doesn't include the repo's config/ssh/config: setup_ssh"
  [[ $SHELL == $HOMEBREW_PREFIX/bin/zsh ]] ||
    problems+="the login shell is $SHELL, not Homebrew's zsh: prepare-zsh-install.sh"
  local errors=$(zsh -i -c exit < /dev/null 2>&1 > /dev/null | grep -v "can't change option: zle")
  [[ -z $errors ]] || problems+="a new zsh prints errors (${(j:; :)${(f)errors}}): run zsh -i to see them"
  errors=$(nvim --headless +qa 2>&1 > /dev/null)
  [[ -z $errors ]] || problems+="nvim prints errors on start (${(j:; :)${(f)errors}}): setup_nvim"

  if (( $#problems )); then
    local s=s
    (( $#problems == 1 )) && s=
    print -u2 -P "%F{red}check_mac: $#problems problem$s%f, each with what fixes it:"
    print -u2 -rl -- "  - "$^problems
    return 1
  fi
  print -P "%F{green}check_mac:%f this Mac is set up as the repo says"
}
