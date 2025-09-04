#!/bin/bash

USER="tekketsu"  # ← pon aquí tu nombre de usuario real
HDMI="HDMI-A-1"
LAPTOP="eDP-1"

STATUS=$(cat /sys/class/drm/card0-${HDMI}/status)

# Detectar runtime real del usuario (Hyprland)
USER_ID=$(id -u $USER)
RUNTIME_DIR="/run/user/$USER_ID"

# Exportar entorno para Hyprland
export DISPLAY=:0
export XDG_RUNTIME_DIR="$RUNTIME_DIR"

if [ "$STATUS" = "connected" ]; then
    echo "HDMI conectado, apagando $LAPTOP" >> /tmp/hotplug.log
    #sudo -u "$USER" XDG_RUNTIME_DIR="$RUNTIME_DIR" hyprctl dispatch dpms off "$LAPTOP" >> /tmp/hotplug.log 2>&1
    hyprctl keyword monitor "eDP-1, disable"
    sudo -u "$USER" XDG_RUNTIME_DIR="$RUNTIME_DIR" notify-send "HDMI conectado"
else
    echo "HDMI desconectado, encendiendo $LAPTOP" >> /tmp/hotplug.log
    #sudo -u "$USER" XDG_RUNTIME_DIR="$RUNTIME_DIR" hyprctl dispatch dpms on "$LAPTOP" >> /tmp/hotplug.log 2>&1
     hyprctl keyword monitor "eDP-1,2880x1800@120,0x0,1.6"
    sudo -u "$USER" XDG_RUNTIME_DIR="$RUNTIME_DIR" notify-send "HDMI desconectado"
fi

