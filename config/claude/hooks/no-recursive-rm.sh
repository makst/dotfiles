#!/bin/zsh
# PreToolUse on Bash: refuse `rm -r` / `rm -rf` / `rm --recursive` and point Claude to the Trash instead, so
# whatever an agent deletes can be put back.

command=$(jq -r '.tool_input.command // empty')
# rm at the start of the command or after ; & | ( or sudo, with an option that contains r/R or is --recursive
if [[ $command =~ '(^|[;&|(]|sudo)[[:space:]]*rm[[:space:]]+(-[a-zA-Z]*[rR]|--recursive)' ]]; then
  jq -n '{hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Recursive rm is blocked. Move it to the Trash instead: `trash <path>` (macOS), or `mv <path> ~/.Trash/`."
  }}'
fi
exit 0
