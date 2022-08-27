#!/bin/bash

ln -s $(pwd) $HOME/dotfiles
ln -s $(pwd)/.zshrc $HOME/.zshrc

echo "=> Installing brew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "=> Installing zsh"
brew install zsh

echo "=> Installing Oh My Zsh"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "=> Setting zsh as the default terminal"
chsh -s $(which zsh)
