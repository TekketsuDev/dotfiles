#!/usr/bin/env bash

DEST_USER="root"
DEST_IP="192.168.0.2"
DEST_PATH="~/dotfiles"

INCLUDE=(
  .zshrc
  .zprofile
  scripts
  .stow-local-ignore
  .config
)

BASE=~/dotfiles
TO_SEND=()

for item in "${INCLUDE[@]}"; do
  TO_SEND+=("$BASE/$item")
done

ssh "$DEST_USER@$DEST_IP" "rm -rf $DEST_PATH && mkdir -p $DEST_PATH"

scp -r "${TO_SEND[@]}" "$DEST_USER@$DEST_IP:$DEST_PATH"
