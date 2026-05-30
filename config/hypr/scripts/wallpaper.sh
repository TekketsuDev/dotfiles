#!/bin/bash

WALLPAPER_DIR=~/dotfiles/resources/Wallpapers/everforest
HOUR=$(date +%H)

# Day: 07:00–20:00 → summer-day, otherwise summer-night
if [[ "$HOUR" -ge 7 && "$HOUR" -lt 20 ]]; then
  WALLPAPER="$WALLPAPER_DIR/summer-day.png"
else
  WALLPAPER="$WALLPAPER_DIR/summer-night.png"
fi

hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALLPAPER"

for monitor in $(hyprctl monitors | grep Monitor | awk '{print $2}'); do
  hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER"
done
