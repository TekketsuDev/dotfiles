#!/bin/bash

declare -A DEVICE_NAMES=(
  ["AC:80:0A:45:26:CE"]="WH-1000XM4"
  ["EC:81:93:E6:0D:BA"]="WONDERBOOM 2"
)

DEFAULT_SINK=$(pactl info | grep "Default Sink" | awk '{print $3}')
MAC=$(echo "$DEFAULT_SINK" | grep -oE '([A-F0-9]{2}_){5}[A-F0-9]{2}' | tr '_' ':')

NAME="${DEVICE_NAMES[$MAC]}"
[[ -n "$NAME" ]] && echo " $NAME" || echo " OFF"

