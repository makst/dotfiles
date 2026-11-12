#!/usr/bin/env zsh
# Shell functions for containers with podman (docs/podman.md). Sourced by .zshrc with the rest of
# zsh/functions/*.zsh; each function's comment says what it does.

# _podman_vm_ok: whether this Mac can run podman's VM: podman is installed and the hypervisor is there.
# GitHub's macOS runners have none (no VM inside a VM), so setup_podman and check_mac skip them.
function _podman_vm_ok() {
  (( $+commands[podman] )) && [[ $(sysctl -n kern.hv_support 2> /dev/null) == 1 ]]
}

# setup_podman: links ~/bin/docker to podman, so scripts that look for `docker` find it outside an
# interactive shell too, then makes sure podman's VM exists and runs. A missing VM is created with half the
# cores, a quarter of the memory (4 to 8 GB) and a 100 GB disk that only takes what it uses; `podman machine
# set` changes them later. First removes connections whose VM is gone, which would otherwise make every
# command fail like a network error. Doesn't start the VM at login: it holds its memory while it runs.
function setup_podman() {
  mkdir -p "$HOME/bin"
  keep_real "$HOME/bin/docker" && ln -sfn /opt/homebrew/bin/podman "$HOME/bin/docker" || return
  _podman_vm_ok || { print "podman or the hypervisor is missing: no VM"; return 0 }
  local machine=podman-machine-default name
  # the default machine's name ends in a *
  local -a machines=(${(f)"$(podman machine list --format '{{.Name}}' 2> /dev/null)"})
  machines=(${machines%\*})
  for name in ${(f)"$(podman system connection list --format '{{.Name}}' 2> /dev/null)"}; do
    (( $machines[(Ie)${name%-root}] )) || podman system connection rm $name || return
  done
  if (( ! $machines[(Ie)$machine] )); then
    local -i cpus=$(( $(sysctl -n hw.ncpu) / 2 )) mib=$(( $(sysctl -n hw.memsize) / 4 / 1024 / 1024 ))
    (( mib = mib < 4096 ? 4096 : mib > 8192 ? 8192 : mib ))
    podman machine init --cpus $cpus --memory $mib --disk-size 100 $machine || return
  fi
  [[ $(podman machine inspect --format '{{.State}}' $machine) == running ]] || podman machine start $machine
}
