#!/bin/bash

declare -A SOUND_DEVICES=(
    ["AC:80:04:E3:7D:42:87"]="Sony WH"
    ["EC:81:93:E6:0D:BA"]="Wonder BOOM"
    ["78:04:E3:7D:42:87"]="Huawei FreeBuds"
)

PRIORITY_MACS=("AC:80:04:E3:7D:42:87" "EC:81:93:E6:0D:BA")
BT_SERVICE="bluetooth"
SCAN_DURATION=10
MAX_RETRIES=3

bluetooth_on() {
    bluetoothctl show | grep -q "Powered: yes"
}

bluetooth_toggle() {
    if bluetooth_on; then
        bluetoothctl power off
        notify-send "Bluetooth" "Off"
    else
        bluetoothctl power on
        sleep 2
        bluetooth_connect
    fi
}

bluetooth_errors(){
    ERRORS=$(journalctl -u "$BT_SERVICE" --since "15 seconds ago" -p err --no-pager)

  if [[ -n "$ERRORS" && "$ERRORS" != "-- No entries --" ]]; then
        echo "$ERRORS"
        notify-send "Bluetooth Error:" "$ERRORS"
        systemctl restart "$BT_SERVICE"
        sleep 2
        bluetoothctl power on
    fi
}

safe_connect() {
    mac="$1"
    name="${DEVICES[$mac]}"
    attempt=0

    while [ "$attempt" -lt "$MAX_RETRIES" ]; do
        echo "Intentando conectar a $name ($mac), intento $((attempt+1))..."
        bluetoothctl connect "$mac" | tee /tmp/bt_connect_log.txt

        if grep -q "Connection successful" /tmp/bt_connect_log.txt; then
            echo "✅ Conectado a $name"
            notify-send "Bluetooth" "Conectado a $name"
            route_audio "$mac"
            echo " $name"
            return 0
        elif grep -qE "Operation already in progress|Bad State|Device or resource busy" /tmp/bt_connect_log.txt; then
            echo "⚠️ Estado inconsistente, reiniciando Bluetooth..."
            systemctl restart "$BT_SERVICE"
            sleep 2
            bluetoothctl power on
        elif grep -qE "Connection refused|Host is down" /tmp/bt_connect_log.txt; then
            echo "⛔ $name no disponible. Esperando..."
            sleep 5
        fi

        # Verificar errores en el journal
        bluetooth_errors

        attempt=$((attempt + 1))
    done

    echo "❌ Fallo al conectar a $name después de $MAX_RETRIES intentos."
    notify-send "Bluetooth" "No se pudo conectar a $name"
    return 1
}


bluetooth_connect() {
    bluetoothctl scan on &
    SCAN_PID=$!
    sleep "$SCAN_DURATION"
    kill "$SCAN_PID"

    CONNECTED=0
    for mac in "${PRIORITY_MACS[@]}"; do
        safe_connect "$mac" && {
            CONNECTED=1
            break
        }
    done

    if [ "$CONNECTED" -eq 0 ]; then
        echo "❌ No se pudo conectar a ningún dispositivo"
        echo " Error"
    fi
}

route_audio() {
    mac="$1"
    pulse_mac=${mac//:/_}
    sink="bluez_sink.${pulse_mac}.a2dp_sink"
    pactl set-default-sink "$sink" && \
        notify-send "Audio" "Salida cambiada a ${DEVICES[$mac]}"
}

status_bluetooth() {
    if is_bluetooth_on; then
        current_sink=$(pactl info | grep "Default Sink" | grep -o 'bluez_sink\.[^[:space:]]*')
        mac=$(echo "$current_sink" | sed -E 's/bluez_sink\.([0-9A-Fa-f_]+)\.a2dp_sink/\1/' | tr '_' ':' | tr '[:lower:]' '[:upper:]')
        name="${DEVICES[$mac]}"
        [[ -n "$name" ]] && echo " $name" || echo " ON"
    else
        echo " OFF"
    fi
}

# === EJECUCIÓN ===
case "$1" in
    toggle) bluetooth_toggle ;;
    connect) bluetooth_connect ;;
    status) bluetooth_status ;;
    *) echo "Uso: $0 {toggle|connect|status}" ;;
esac

