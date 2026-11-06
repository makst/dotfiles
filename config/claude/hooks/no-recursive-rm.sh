#!/bin/zsh
# PreToolUse on Bash: refuse a delete that can't be undone (rm -r, find -delete, git clean -f) and point Claude
# to the Trash instead, so whatever an agent deletes can be put back. The command is split into words by zsh's
# own parser, so the delete is found as any command of a list, pipeline or later line, after its other options
# (rm -f -r, git -C dir clean -fd), behind a path (/bin/rm, \rm) or a wrapper (sudo, env, xargs, nice, time,
# command, find -exec), and inside $(…), `…`, sh -c '…' and eval. Text that only mentions it passes: echo
# "rm -rf", a comment, a here-document, git rm -r, git clean -n. The cases it must get right are in the
# dotfiles' checks/rm-hook.cases.

setopt extended_glob

# wrappers that run the command after them, and their options that take a value
typeset -A wrappers=(
  sudo 'u g h p C D R T U r t' doas 'u C' env 'u S P C' nice 'n' xargs 'I J L P R S E d n s'
  timeout '' caffeinate 't w' nohup '' time '' command '' builtin '' exec 'a' noglob '' nocorrect ''
)

# deletes_for_good <command line>: succeeds when the command line runs rm with -r, -R or --recursive,
# find with -delete, or git clean with -f and without -n
deletes_for_good() {
  local line delim word name inner
  local -a lines words
  # a here-document's lines are data, not commands
  for line in "${(@f)1}"; do
    if [[ -n $delim ]]; then
      [[ ${line##$'\t'#} == $delim ]] && delim=
      continue
    fi
    lines+=$line
    [[ $line == (#b)*'<<'(-|)[[:space:]]#[\'\"]#([A-Za-z0-9_]##)* && $line != *'<<<'* ]] && delim=$match[2]
  done
  words=(${(Z+C+)${(F)lines}})

  local -i i=1 start=1
  while (( i <= $#words )); do
    word=$words[i]
    # what $(…), `…` and <(…) run
    if [[ $word == *(\$\(|\<\(|\>\()* ]]; then
      inner=${word#*(\$|\<|\>)\(}
      deletes_for_good "${inner%\)*}" && return 0
    fi
    if [[ $word == *\`*\`* ]]; then
      inner=${word#*\`}
      deletes_for_good "${inner%\`*}" && return 0
    fi
    if [[ $word == (\;|\;\;|\&|\&\&|\||\|\||\|\&|\(|\)|\{|\}|\!|if|then|else|elif|while|until|do) ]]; then
      start=1
    elif (( start )); then
      name=${${(Q)word}#\\}
      name=${name:t}
      if [[ $name == [A-Za-z_][A-Za-z0-9_]#=* ]]; then
        # an assignment before the command
      elif (( $+wrappers[$name] )); then
        # the wrapper's options, and the value of those that take one; timeout's duration
        while [[ $words[i+1] == -* ]]; do
          (( i++ ))
          [[ $words[i] == -[a-zA-Z] && " $wrappers[$name] " == *" ${words[i]#-} "* ]] && (( i++ ))
        done
        [[ $name == timeout ]] && (( i++ ))
      else
        start=0
        case $name in
          (rm)
            while (( ++i <= $#words )); do
              [[ $words[i] == (\;|\;\;|\&|\&\&|\||\|\||\|\&|\)|--) ]] && break
              [[ ${(Q)words[i]} == (-[a-zA-Z]#[rR][a-zA-Z]#|--recursive) ]] && return 0
            done
            continue
            ;;
          (find)
            # -delete deletes what it finds; -exec runs the words after it, up to \; or +
            while (( ++i <= $#words )); do
              [[ $words[i] == (\;|\&\&|\|\||\||\)) ]] && break
              [[ $words[i] == -delete ]] && return 0
              if [[ $words[i] == -(exec|execdir|ok|okdir) ]]; then
                local -a run=()
                while (( ++i <= $#words )) && [[ $words[i] != (\\\;|\'\;\'|+) ]]; do run+=$words[i]; done
                deletes_for_good "${(j: :)run}" && return 0
              fi
            done
            continue
            ;;
          (git)
            # git's own options before the subcommand; -C and -c take a value
            while [[ $words[i+1] == -* ]]; do
              (( i++ ))
              [[ $words[i] == -[Cc] ]] && (( i++ ))
            done
            [[ ${(Q)words[i+1]} == clean ]] || continue
            (( i++ ))
            # git clean deletes only with -f (clean.requireForce), and nothing with -n
            local -i force=0 dry=0
            while (( ++i <= $#words )); do
              [[ $words[i] == (\;|\;\;|\&|\&\&|\||\|\||\|\&|\)|--) ]] && break
              case ${(Q)words[i]} in
                (--force) force=1 ;;
                (--dry-run) dry=1 ;;
                (-[a-zA-Z]##)
                  [[ ${(Q)words[i]} == *f* ]] && force=1
                  [[ ${(Q)words[i]} == *n* ]] && dry=1
                  ;;
              esac
            done
            (( force && !dry )) && return 0
            continue
            ;;
          (sh|bash|zsh|dash|ksh)
            [[ $words[i+1] == -[a-z]#c[a-z]# ]] && deletes_for_good "${(Q)words[i+2]}" && return 0
            ;;
          (eval)
            deletes_for_good "${(Q)${(j: :)words[i+1,-1]}}" && return 0
            ;;
        esac
      fi
    fi
    (( i++ ))
  done
  return 1
}

command=$(jq -r '.tool_input.command // empty')
if deletes_for_good "$command"; then
  jq -n '{hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Deletes that cannot be undone (rm -r, find -delete, git clean -f) are blocked. Move it to the trash instead: `trash <path>` on macOS, `gio trash <path>` on Linux; for untracked files in git, `git stash -u` keeps them."
  }}'
fi
exit 0
