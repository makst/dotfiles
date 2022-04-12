real_script_dir="$(dirname "$(stat -f '%Y' ~/.zshrc)")"

# Load the shell dotfiles:
for file in "$real_script_dir"/zsh/.{zshdefault,exports,aliases,kubectl_aliases,functions,private}; do
  # source `file` if it's a `readable file`
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;

echo "Execute 'install_and_update_zsh_plugins' to update custom zsh plugins"
sleep 2 && clear
