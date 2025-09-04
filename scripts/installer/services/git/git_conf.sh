#!/bin/bash

set -e

PROFILE_PATH="${DOTFILES:-$HOME/dotfiles/env/installer/.gitprofile_personal}"

if ! git config --global user.name &>/dev/null; then

  ssh-keygen -t ed25519 -C "$GIT_EMAIL"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  xclip -sel clip < ~/.ssh/id_rsa.pub

  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  git config --global core.editor "$DEFAULT_EDITOR"
  git config --global init.defaultBranch main

fi

