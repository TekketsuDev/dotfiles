#!/bin/bash

set -euo pipefail

CORE_SCRIPT="/home/tekketsu/dotfiles/scripts/installer/packages/package_core.sh"

#source "$CORE_SCRIPT"

if [ "$SHELL" != "/usr/bin/zsh" ]; then
  echo "Changing shell to zsh..."
  chsh -s /bin/zsh
fi

export ZSH_CUSTOM="$HOME/.config/.oh-my-zsh/custom"

if [ ! -d "$HOME/.config/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# zsh-autosuggestions

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi
