#!/bin/bash

set -euo pipefail  # Exit on error

DOTFILES_DIR="$HOME/dotfiles"
OHMYZSH_DIR="$HOME/.config/.oh-my-zsh"

# Check if the ZSH variable is set correctly, if not, set it
if [[ -z "$ZSH" ]]; then
    echo "Setting ZSH variable..."
    echo "export ZSH=\"$OHMYZSH_DIR\"" >> "$HOME/dotfiles/.config/.zsh/modules/env.zsh"
fi

# Navigate to the dotfiles directory
cd "$DOTFILES_DIR"

# Fetch latest updates from remote
git fetch origin main

# Get commit hashes
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

# Check if local repo is up-to-date
if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
    echo "⚠️  Your dotfiles repository is outdated!"
    echo "Local commit:  $LOCAL_COMMIT"
    echo "Remote commit: $REMOTE_COMMIT"
    read -p "Would you like to update before continuing? (y/n) " choice

    if [[ "$choice" == "y" ]]; then
        if [[ $(git status --porcelain) ]]; then
            echo "⚠️  You have uncommitted changes. Please commit or stash them first."
            exit 1
        fi
        echo "Updating dotfiles repository..."
        git pull --rebase origin main
    else
        echo "Proceeding with outdated dotfiles..."
    fi
fi

# Check if Oh My Zsh is installed
if [[ ! -d "$OHMYZSH_DIR" ]]; then
    echo "Installing Oh My Zsh in $OHMYZSH_DIR..."
    # Install Oh My Zsh to the desired location
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OHMYZSH_DIR"
fi

# Symlink the .zshrc to use custom Oh My Zsh location
echo "Setting up .zshrc to use custom Oh My Zsh location..."
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Proceed with Stow after ensuring dotfiles are updated
echo "Select dotfile categories to install:"
echo "1) Terminal (Zsh, Tmux, Alacritty)"
echo "2) UI (Hyprland, Waybar, etc.)"
echo "3) Editor (Neovim, VSCode)"
echo "4) Git"
echo "5) Scripts"
echo "6) Everything"

read -p "Enter number(s) (e.g., 1 3 4): " choices

# Stow only the selected categories
for choice in $choices; do
    case $choice in
        1) stow -d "$DOTFILES_DIR" -t "$HOME" terminal ;;
        2) stow -d "$DOTFILES_DIR" -t "$HOME" ui ;;
        3) stow -d "$DOTFILES_DIR" -t "$HOME" editor ;;
        4) stow -d "$DOTFILES_DIR" -t "$HOME" git ;;
        5) stow -d "$DOTFILES_DIR" -t "$HOME" scripts ;;
        6) stow -d "$DOTFILES_DIR" -t "$HOME" terminal ui editor git scripts ;;
        *) echo "Invalid option: $choice" ;;
    esac
done
