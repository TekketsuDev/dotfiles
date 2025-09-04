#!/bin/bash

# Mapeo de dispositivos en orden de prioridad
DEVICES=("AC:80:0A:45:26:CE" "EC:81:93:E6:0D:BA" "78:04:E3:7D:42:87")  
declare -A DEVICE_NAMES=(
    ["AC:80:0A:45:26:CE"]="WH-1000XM4"
    ["EC:81:93:E6:0D:BA"]="WONDERBOOM 2"
)

# Obtener MAC del sink actual (default)
DEFAULT_SINK=$(pactl info | grep "Default Sink" | awk '{print $3}')
DEFAULT_MAC=$(echo "$DEFAULT_SINK" | grep -oE '([A-F0-9]{2}_){5}[A-F0-9]{2}' | tr '_' ':')

# Obtener dispositivos Bluetooth conectados
CONNECTED_MACS=($(bluetoothctl devices Connected | awk '{print $2}'))

# Determinar el dispositivo actual
CURRENT=""
for dev in "${DEVICES[@]}"; do
    if [[ "$DEFAULT_MAC" == "$dev" ]]; then
        CURRENT="$dev"
        break
    fi
done

# Buscar el siguiente dispositivo conectado distinto
NEXT=""
for i in "${!DEVICES[@]}"; do
    if [[ "${DEVICES[$i]}" == "$CURRENT" ]]; then
        NEXT_INDEX=$(( (i + 1) % ${#DEVICES[@]} ))
        CANDIDATE="${DEVICES[$NEXT_INDEX]}"
        if printf '%s\n' "${CONNECTED_MACS[@]}" | grep -q "$CANDIDATE"; then
            NEXT="$CANDIDATE"
            break
        fi
    fi
done

# Si no hay otro conectado, intentar conectar dispositivos en orden
if [[ -z "$NEXT" ]]; then
    for dev in "${DEVICES[@]}"; do
        if bluetoothctl connect "$dev" | grep -q "Connection successful"; then
            if [[ "$dev" == "$CURRENT" ]]; then
                exit 0
            fi
            NEXT="$dev"
            notify-send "Bluetooth" "Conectado a ${DEVICE_NAMES[$dev]}"
            break
        fi
    done
fi

if [[ -z "$NEXT" ]]; then
    notify-send "Bluetooth" "No se pudo conectar a ningún dispositivo."
    exit 1
fi

if [[ "$NEXT" == "$CURRENT" ]]; then
    exit 0
fi

SINK_NAME=$(pactl list short sinks | grep "$(echo "$NEXT" | tr ':' '_')" | awk '{print $2}')

if [[ -z "$SINK_NAME" ]]; then
    notify-send "Bluetooth" "Sink no encontrado para ${DEVICE_NAMES[$NEXT]}"
    exit 1
fi

pactl set-default-sink "$SINK_NAME"

for input in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl move-sink-input "$input" "$SINK_NAME"
done

notify-send "Bluetooth" "Audio cambiado a ${DEVICE_NAMES[$NEXT]}"

