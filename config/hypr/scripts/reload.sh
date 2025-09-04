#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/dotfiles/resources/Wallpapers"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/madoka-1.png"

ENV_FILE="$HOME/.config/hypr/env.zsh"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

get_monitors() {
  if [[ -n "$HYPAPER_MONITORS" ]]; then
    echo "$HYPAPER_MONITORS" | xargs
  else
    hyprctl monitors -j | jq -r '.[].name' | xargs
  fi
}

get_wallpaper() {
  local current_wall
  current_wall=$(hyprctl hyprpaper listloaded | grep -oP '/.*' | head -n 1)

  local new_wall
  new_wall=$(find "$WALLPAPER_DIR" -type f | grep -v "$(basename "$current_wall")" | shuf -n 1)

  if [[ -z "$new_wall" ]]; then
    echo "$DEFAULT_WALLPAPER"
  else
    echo "$new_wall"
  fi
}


MONITORS=$(get_monitors)
if [[ -z "$MONITORS" ]]; then
  exit 1
fi

WALLPAPER=$(get_wallpaper)

CURRENT_WALL=$(hyprctl hyprpaper listloaded | grep -oP '/.*' | head -n 1)
if [[ -z "$CURRENT_WALL" ]]; then
  sleep 0.5
  hyprctl hyprpaper preload "$WALLPAPER"
  for monitor in $MONITORS; do
    hyprctl hyprpaper wallpaper "$monitor, $WALLPAPER"
  done
else
  hyprctl hyprpaper unload all
  hyprctl hyprpaper preload "$WALLPAPER"
  for monitor in $MONITORS; do
    hyprctl hyprpaper wallpaper "$monitor, $WALLPAPER"
  done
fi

