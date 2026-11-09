#!/usr/bin/env zsh
# Shell functions for ssh and the keys of each Mac in Secretive (config/ssh, docs/git.md, "One set of keys per
# Mac"). Sourced by .zshrc with the rest of zsh/functions/*.zsh; each function's comment says what it does.

# setup_ssh: includes the repo's config/ssh/config at the top of ~/.ssh/config (the rest of that file stays
# this Mac's own) and removes what the old ssh-ident and keychain setups left behind.
function setup_ssh() {
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  touch ~/.ssh/config

  # shared settings (keychain, agent, which key for which host) come from the repo
  local include="Include ~/dotfiles/config/ssh/config"
  if ! grep -qxF "$include" ~/.ssh/config; then
    { print -r -- "$include"; print; cat ~/.ssh/config } > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config
  fi

  # ssh-ident used to stand in for ssh, scp and sftp
  local tool
  for tool in ssh scp sftp; do
    [[ ${"$(readlink ~/bin/$tool 2> /dev/null)":t} == ssh-ident ]] && rm ~/bin/$tool
  done

  # the keys are in Secretive now (config/ssh/config), so the login item that loaded keychain keys into macOS's
  # own agent goes
  local label="com.makst.ssh-add" plist="$HOME/Library/LaunchAgents/com.makst.ssh-add.plist"
  if [[ -e $plist ]]; then
    launchctl bootout "gui/$(id -u)/$label" 2> /dev/null
    rm $plist
  fi
}

# secretive_key <push|signing> [name]: use the Secretive key called <name> (default: the role) as the push or
# the signing key. Make the key in the Secretive app first: push with "Require Authentication" (Touch ID for
# every ssh connection: push, pull, fetch), signing without it (commits and rebases don't ask). Copies its
# public key to ~/.ssh/identities/secretive/<role>.pub, which config/ssh/config and config/git/.gitconfig use,
# and adds it to GitHub: push as an ssh key (also copied for the GitLab page that opens), signing as a
# signing key and to config/git/allowed_signers.
function secretive_key() {
  local role=${1:?usage: secretive_key <push|signing> [name in Secretive]} name=${2:-$1}
  [[ $role == (push|signing) ]] || { print -u2 "the role is push or signing"; return 1 }

  # Secretive keeps each public key in a file named after its hash; find the one whose comment has the name
  local dir=~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys pub
  local -a found words
  for pub in $dir/*.pub(N); do
    words=(${="$(<$pub)"})
    [[ ${(L)${(j:-:)words[3,-1]}} == *${(L)name// /-}* ]] && found+=$pub
  done
  if (( $#found != 1 )); then
    print -u2 "${#found} Secretive keys match '$name'; pass the name as the second argument. Keys:"
    for pub in $dir/*.pub(N); do words=(${="$(<$pub)"}); print -u2 "  ${words[3,-1]}"; done
    return 1
  fi

  # GitHub lists the key under this Mac's name (setup_machine)
  local machine=${HOST%%.*}
  [[ -r ~/.config/dotfiles/name ]] && machine=$(<~/.config/dotfiles/name)
  local key=~/.ssh/identities/secretive/$role.pub title="$machine (Secretive)"
  mkdir -p ${key:h} && chmod 700 ${key:h}
  cp $found[1] $key || return
  words=(${="$(<$key)"})

  # adding ssh keys needs one more permission than gh asks for at login
  gh auth status 2>&1 | grep -q admin:public_key || gh auth refresh -h github.com -s admin:public_key || return
  case $role in
    push)
      gh ssh-key add $key --type authentication --title $title || return
      pbcopy < $key
      open https://gitlab.com/-/user_settings/ssh_keys
      print "public key copied, paste it on the GitLab page that opened"
      ;;
    signing)
      gh ssh-key add $key --type signing --title $title || return
      # the Mac's name after the key, so retire_mac finds it
      local signer="$(git config user.email) namespaces=\"git\" ${words[1]} ${words[2]} $machine"
      local signers=$real_script_dir/config/git/allowed_signers
      grep -qF -- ${words[2]} $signers || print -r -- $signer >> $signers
      # sign from now on, on this Mac only (config/git/.gitconfig includes this file)
      local machine_git=~/.config/dotfiles/gitconfig
      git config --file $machine_git user.signingkey ${key/#$HOME/\~}
      git config --file $machine_git commit.gpgsign true
      git config --file $machine_git tag.gpgsign true
      ;;
  esac
}

# _github_keys [name]: the GitHub account's ssh keys as "<push|signing> <id> <title>" lines, only those whose
# title is the Mac's name or starts with it (secretive_key titles them "<name> (Secretive)"), any case.
function _github_keys() {
  local name=${(L)1} kind endpoint
  for kind endpoint in push user/keys signing user/ssh_signing_keys; do
    gh api $endpoint | jq -r --arg kind $kind --arg n "$name" '.[]
      | select($n == "" or (.title | ascii_downcase) == $n or (.title | ascii_downcase | startswith($n + " ")))
      | "\($kind) \(.id) \(.title)"' || return
  done
}

# mac_keys: every Mac's keys in one list: the push and signing keys on GitHub, by title, and the signing keys
# config/git/allowed_signers trusts, with the Mac's name and, for a retired one, when it stopped.
function mac_keys() {
  print "On GitHub:"
  _github_keys | sed 's/^/  /' || return
  print "\nIn config/git/allowed_signers:"
  local line
  local -a words
  for line in "${(@f)$(<$real_script_dir/config/git/allowed_signers)}"; do
    [[ $line == (\#*|) ]] && continue
    words=(${=line})
    print -r -- "  ${words[3]} ${${words[5,-1]}:-(no name)}${${(M)words[2]:#*valid-before=*}:+, retired before ${${words[2]##*valid-before=}//\"}}"
  done
}

# retire_mac <name>: stop trusting a Mac that is sold, wiped, handed back or lost; run it on another Mac. After
# asking, deletes the GitHub keys titled with its name and marks its line in config/git/allowed_signers
# valid-before this moment instead of deleting it, so the commits it signed until now still verify and
# anything signed with its key later doesn't. Lists what's left to do by hand: GitLab, servers, committing.
function retire_mac() {
  local name=${1:?usage: retire_mac <name of the Mac, as mac_keys shows it>}
  local signers=$real_script_dir/config/git/allowed_signers now=$(date +%Y%m%d%H%M%S) line kind id title endpoint
  local -a github words lines
  github=(${(f)"$(_github_keys $name)"}) || return

  # its signing keys: named after it in allowed_signers, or uploaded to GitHub under its name
  local -a signing_keys=(${(f)"$(gh api user/ssh_signing_keys |
    jq -r --arg n "${(L)name}" '.[] | select((.title | ascii_downcase) == $n or (.title | ascii_downcase |
    startswith($n + " "))) | .key | split(" ")[1]')"})
  local -i marked=0
  for line in "${(@f)$(<$signers)}"; do
    words=(${=line})
    if [[ $line != \#* && $words[2] != *valid-before=* ]] &&
      [[ ${(L)${(j: :)words[5,-1]}} == ${(L)name}(| *) || -n ${(M)signing_keys:#$words[4]} ]]; then
      words[2]+=",valid-before=\"$now\""
      line=${(j: :)words}
      marked+=1
    fi
    lines+=$line
  done

  if (( !$#github && !marked )); then
    print -u2 "no keys found for '$name'; mac_keys lists the names"
    return 1
  fi
  print "Retiring $name:"
  for line in $github; do print -r -- "  delete on GitHub: $line"; done
  (( marked )) && print "  mark $marked key(s) in config/git/allowed_signers valid-before=$now"
  read -q "?Go ahead? [y/N] " || { print; return 1 }
  print

  gh auth status 2>&1 | grep -q admin:ssh_signing_key ||
    gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key || return
  for line in $github; do
    words=(${=line})
    kind=$words[1] id=$words[2] title=${words[3,-1]}
    endpoint=user/keys
    [[ $kind == signing ]] && endpoint=user/ssh_signing_keys
    gh api -X DELETE $endpoint/$id && print -r -- "deleted $kind key: $title"
  done
  (( marked )) && print -rl -- $lines > $signers

  print "\nLeft to do by hand:"
  (( marked )) && print "  - commit config/git/allowed_signers"
  print "  - GitLab: delete its key on https://gitlab.com/-/user_settings/ssh_keys"
  print "  - servers: remove its key from ~/.ssh/authorized_keys"
  print "  - tokens only that Mac had (cloud CLIs, API keys made for it): revoke them where they were made"
}
