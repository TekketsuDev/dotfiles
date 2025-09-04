#!/usr/bin/env bash
SAVE_DIR="$HOME/Notes/Brain/Data/Screenshots"
mkdir -p "$SAVE_DIR"

FILENAME="screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$SAVE_DIR/$FILENAME"

REGION=$(slurp)
[ -z "$REGION" ] && exit 1

grim -g "$REGION" "$FILEPATH"
wl-copy --type image/png < "$FILEPATH"

notify-send "📸 Screenshot saved" "$FILEPATH and copied to clipboard"

