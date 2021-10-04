real_script_dir="$(dirname "$(stat -f '%Y' ~/.zshrc)")"

# Load the shell dotfiles:
for file in "$real_script_dir"/zsh/.{zshdefault,exports,aliases,kubectl_aliases,functions,offline}; do
  # source `file` if it's a `readable file`
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/makst/repos/gitlab_katulu/guard-services/organizations-service/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/makst/repos/gitlab_katulu/guard-services/organizations-service/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/makst/repos/gitlab_katulu/guard-services/organizations-service/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/makst/repos/gitlab_katulu/guard-services/organizations-service/node_modules/tabtab/.completions/sls.zsh
# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[[ -f /Users/makst/repos/gitlab_katulu/guard-services/organizations-service/node_modules/tabtab/.completions/slss.zsh ]] && . /Users/makst/repos/gitlab_katulu/guard-services/organizations-service/node_modules/tabtab/.completions/slss.zsh
