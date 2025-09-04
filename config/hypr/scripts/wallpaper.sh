#!/bin/bash

directory=~/dotfiles/resources/Wallpapers/everforest
monitor=`hyprctl monitors | grep Monitor | awk '{print $2}'`

if [ -d "$directory" ]; then
    random_background=$(find "$directory" -type f \( -iname "*.jpg" -o -iname "*.png" \)  | shuf -n 1)

    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload $random_background
    
    for monitor in $(hyprctl monitors | grep Monitor | awk '{print $2}'); do
        hyprctl hyprpaper wallpaper "$monitor,$random_background"
    done

fi
