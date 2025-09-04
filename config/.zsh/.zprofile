if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    echo "✅ Launching Hyprland from .zprofile" >> ~/.zprofile.log
    HYPRLAND_LOG_WLR=1 HYPRLAND_DEBUG=1 Hyprland > ~/hyprland.log 2>&1
fi

