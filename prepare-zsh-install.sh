#!/bin/bash
# Safe to rerun: every step skips what is already done.
set -e

cd "$(dirname "$0")"
DOTFILES="$(pwd)"

ln -sfn "$DOTFILES" "$HOME/dotfiles"

# Keep an existing, non-symlinked .zshrc around instead of silently replacing it.
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
  echo "=> Moved existing ~/.zshrc to ~/.zshrc.backup"
fi
ln -sfn "$DOTFILES/.zshrc" "$HOME/.zshrc"

echo "=> Installing brew"
# Apple silicon uses /opt/homebrew. A Homebrew in /usr/local on such a Mac is an old x86_64 install
# (running under Rosetta, no bottles), so it is deliberately not used.
if [ "$(uname -m)" = "arm64" ]; then BREW_BIN=/opt/homebrew/bin/brew; else BREW_BIN=/usr/local/bin/brew; fi
if [ ! -x "$BREW_BIN" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Put brew on PATH for this script.
eval "$("$BREW_BIN" shellenv)"

echo "=> Installing zsh"
brew list zsh > /dev/null 2>&1 || brew install zsh

echo "=> Setting Homebrew's zsh as the login shell"
ZSH_BIN="$(brew --prefix)/bin/zsh"
# chsh only accepts shells that are listed in /etc/shells.
grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
[ "$SHELL" = "$ZSH_BIN" ] || chsh -s "$ZSH_BIN"

echo "=> Done. Now run: exec zsh && setup_dotfiles"
