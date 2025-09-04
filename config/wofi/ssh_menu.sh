#!/bin/bash
# Lista de servidores SSH
hosts=("proxmox" "debian-core" "backups" "piruleta" "archLap" "zen")

# Mostrar opciones con Wofi
selected_host=$(printf "%s\n" "${hosts[@]}" | wofi --dmenu --config ~/.config/wofi/config --style ~/.config/wofi/style.css)

# Si selecciona algo, abrir SSH
if [[ -n "$selected_host" ]]; then
    kitty -e ssh "$selected_host" # Puedes cambiar `kitty` por tu terminal preferida
fi
