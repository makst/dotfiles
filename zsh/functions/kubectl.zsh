#!/usr/bin/env zsh
# Shell functions for kubectl (docs/zsh.md, "Aliases"; the k… aliases are in zsh/.aliases). Sourced by .zshrc
# with the rest of zsh/functions/*.zsh. Each picks what it works on when it isn't given: through picker
# (config/tmux/picker.zsh), so they work like every other list.

# _kube_pick <name> <action> <preview> <command…>: pick one of the lines the command prints, with the action
# Enter does in the header and the preview run on the line's first word, and print that word.
function _kube_pick() {
  local name=$1 header=$2 preview=$3
  shift 3
  source $_fzf_picker
  local line
  line=$("$@" | awk '{ print $1 "\t" $0 }' |
    picker $name --insert --header "type to filter, jj for j/k · Enter $header · Esc quits" \
      --preview $preview --preview-window $picker_preview) || return
  print -r -- ${line%%$'\t'*}
}

# kctx [context]: switch kubectl's context, picking it from the kubeconfig's when not given, with the
# context's cluster and namespace as the preview.
function kctx() {
  local ctx=$1
  [[ -n $ctx ]] || ctx=$(_kube_pick contexts 'switches' 'kubectl config get-contexts {1}' \
    kubectl config get-contexts -o name) || return
  kubectl config use-context $ctx
}

# kns [namespace]: set the current context's namespace, picking it from the cluster's when not given, with
# its pods as the preview.
function kns() {
  local ns=$1
  [[ -n $ns ]] || ns=$(_kube_pick namespaces 'sets it' 'kubectl get pods -n {1}' \
    kubectl get namespaces --no-headers -o custom-columns=:metadata.name) || return
  kubectl config set-context --current --namespace $ns
}

# klo [pod] [kubectl logs options…]: follow a pod's logs, picking the pod from the namespace's when not
# given (or when the first argument is an option), with its last log lines as the preview.
function klo() {
  local pod
  if [[ -n $1 && $1 != -* ]]; then pod=$1; shift
  else pod=$(_kube_pick pods 'follows its logs' 'kubectl logs --tail 50 {1}' kubectl get pods --no-headers) || return
  fi
  kubectl logs -f $pod "$@"
}

# kex [pod] [command…]: a shell (or the command) in a pod, picking the pod when not given, with its
# description as the preview. The shell is bash where the image has it, else sh.
function kex() {
  local pod
  if [[ -n $1 && $1 != -* ]]; then pod=$1; shift
  else pod=$(_kube_pick pods 'opens a shell' 'kubectl describe pod {1}' kubectl get pods --no-headers) || return
  fi
  (( $# )) || set -- sh -c 'command -v bash > /dev/null && exec bash || exec sh'
  kubectl exec -it $pod -- "$@"
}
