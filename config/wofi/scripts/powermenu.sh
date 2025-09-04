#!/bin/bash

entries=" Lock\n⭮ Reboot\n⏻ Shutdown\n⇠ Logout\n⏾ Suspend"

selected=$(echo -e "$entries" | wofi --width 450 --height 360 --dmenu \
    --style ~/dotfiles/config/wofi/themes/everforest.css \
    --no-search --no-scroll --cache-file /dev/null | awk '{print tolower($2)}')

case $selected in
  lock)
    hyprlock -c ~/.config/hypr/hyprlock.conf;;
  logout)
    exec hyprctl dispatch exit NOW;;
  suspend)
    exec systemctl suspend;;
  reboot)
    exec systemctl reboot;;
  shutdown)
    exec systemctl poweroff -i;;
esac

